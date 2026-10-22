extends RefCounted
## Reads the actual unencrypted ActorX animation exports from Spike Volleyball.
## Bone hierarchy and sampled transforms are preserved; root travel is removed by Avatar.
var names: Array[String] = []
var parents: Array[int] = []
var positions := PackedVector3Array()
var rotations: Array[Quaternion] = []
var frames := 0
var fps := 30.0
var duration := 1.0
var source := ""
var contact_time := 0.0
var ground_y := 0.0
var contact_offset := Vector3.ZERO
var jump_boost := 0.0
var travel_speed := 3.2

static func fixed_string(f: FileAccess, count: int) -> String:
	var bytes := f.get_buffer(count)
	var end := bytes.find(0)
	return bytes.slice(0, end if end >= 0 else bytes.size()).get_string_from_ascii()

func load_hierarchy(path: String) -> void:
	# UE4 PSA exports contain names but intentionally omit the hierarchy.
	# Restore the hierarchy from the matching original skeletal mesh PSK.
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return
	while f.get_position() + 32 <= f.get_length():
		var tag := fixed_string(f, 20)
		f.get_32()
		var size := f.get_32()
		var count := f.get_32()
		var start := f.get_position()
		if tag == "REFSKELT":
			var skeleton_names: Array[String] = []
			var skeleton_parents: Array[int] = []
			for i in count:
				f.seek(start + i * size)
				var name := fixed_string(f, 64)
				f.get_32()
				f.get_32()
				var parent := f.get_32()
				skeleton_names.append(name)
				skeleton_parents.append(parent)
			for i in count:
				var idx := names.find(skeleton_names[i])
				var parent := skeleton_parents[i]
				if idx >= 0 and parent >= 0 and parent < count:
					parents[idx] = names.find(skeleton_names[parent])
			return
		f.seek(start + size * count)

func load_file(path: String) -> bool:
	source = path
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing licensed animation: " + path)
		return false
	while f.get_position() + 32 <= f.get_length():
		var tag := fixed_string(f, 20)
		f.get_32()
		var size := f.get_32()
		var count := f.get_32()
		var start := f.get_position()
		if size * count > f.get_length() - start:
			push_error("Invalid ActorX chunk: " + path)
			return false
		if tag.begins_with("BONENAMES"):
			for i in count:
				f.seek(start + i * size)
				names.append(fixed_string(f, 64))
				f.get_32()
				f.get_32()
				parents.append(f.get_32())
		elif tag.begins_with("ANIMINFO") and count > 0:
			f.seek(start + 128)
			f.get_32() # total bones
			f.get_32()
			f.get_32()
			f.get_32()
			f.get_float()
			f.get_float()
			fps = f.get_float()
			f.get_32()
			f.get_32()
			frames = f.get_32()
		elif tag.begins_with("ANIMKEYS"):
			positions.resize(count)
			rotations.resize(count)
			for i in count:
				positions[i] = Vector3(f.get_float(), f.get_float(), f.get_float())
				var q := Quaternion(f.get_float(), f.get_float(), f.get_float(), f.get_float()).normalized()
				# ActorX stores child rotations conjugated relative to its root.
				if i % maxi(1, names.size()) != 0:
					q = q.inverse()
				rotations[i] = q
				f.get_float()
		f.seek(start + size * count)
	if names.is_empty() or frames < 1 or positions.size() < frames * names.size():
		push_error("Incomplete ActorX animation: " + path)
		return false
	duration = float(frames - 1) / maxf(fps, 1.0)
	contact_time = duration * 0.45
	return true

func detect_contact(action: String) -> void:
	jump_boost = {"attack":0.46, "block":0.50, "float":0.25, "power":0.36, "set":0.10, "fast_set":0.10, "dump":0.10}.get(action, 0.0)
	# Explicit provisional animation events, inferred from the real sampled hand arc.
	# They are visual events; ball simulation remains the gameplay authority.
	var first := pose(0, false)
	var finish := pose(duration, false)
	var hips_index := names.find("Hips")
	if hips_index >= 0:
		travel_speed = maxf(0.8, first[hips_index].origin.distance_to(finish[hips_index].origin) * 0.01 / maxf(duration, 0.01))
	var left_foot := names.find("LeftToeBase")
	var right_foot := names.find("RightToeBase")
	if left_foot >= 0 and right_foot >= 0:
		ground_y = minf(first[left_foot].origin.z, first[right_foot].origin.z) * 0.01 - 0.055
	for frame in frames:
		var ground_sample := pose(float(frame) / fps, false)
		if left_foot >= 0 and right_foot >= 0:
			ground_y = minf(ground_y, minf(ground_sample[left_foot].origin.z, ground_sample[right_foot].origin.z) * 0.01 - 0.055)
	if action in ["idle", "relaxed", "ready", "block_ready", "walk", "backwalk", "backpedal", "run", "run_right", "shuffle_left", "shuffle_right", "serve_idle"]: return
	var hand := names.find("RightHand")
	if hand < 0: return
	var highest := -INF
	for frame in frames:
		var sample: Array[Transform3D] = pose(float(frame) / fps, false)
		var hand_position := sample[hand].origin
		var score := hand_position.z
		if action in ["receive", "recovery", "dive"]:
			var other: Vector3 = sample[names.find("LeftHand")].origin
			var hips: Vector3 = sample[names.find("Hips")].origin
			score = -(hand_position.y + other.y) * 0.5 + hips.y
			if action in ["recovery","dive"]: score = -hand_position.y + hips.y
			if hand_position.z > (125 if action in ["recovery","dive"] else 150): score = -INF
		if score > highest:
			highest = score
			contact_time = float(frame) / fps
	var sample := pose(contact_time, false)
	var hips: Vector3 = sample[names.find("Hips")].origin
	var contact: Vector3 = sample[hand].origin
	if action in ["receive", "set", "fast_set", "block"]:
		contact = (contact + sample[names.find("LeftHand")].origin) * 0.5
	contact_offset = Vector3(contact.x - hips.x, contact.z, -(contact.y - hips.y)) * 0.01 - Vector3(0, ground_y, 0)
	contact_offset.y += jump_boost
	if action in ["receive", "set", "fast_set"]: contact_offset.y += 0.07

func pose(time: float, looped: bool) -> Array[Transform3D]:
	var t := fposmod(time, maxf(duration, 0.001)) if looped else clampf(time, 0, duration)
	var frame := minf(t * fps, frames - 1.0)
	var a := int(frame)
	var b := mini(a + 1, frames - 1)
	var blend := frame - a
	var result: Array[Transform3D] = []
	result.resize(names.size())
	for i in names.size():
		var ia := a * names.size() + i
		var ib := b * names.size() + i
		var pos := positions[ia].lerp(positions[ib], blend)
		var rot := rotations[ia].slerp(rotations[ib], blend)
		var local := Transform3D(Basis(rot), pos)
		result[i] = result[parents[i]] * local if i > 0 and parents[i] < i else local
	return result

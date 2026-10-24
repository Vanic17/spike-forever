extends SceneTree
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")
const Attack = preload("res://src/attack_motion41.gd")

func _initialize() -> void:
	var source = PSA.new()
	assert(source.load_file("res://assets/active/" + Attack.SOURCE + ".psa"))
	source.load_hierarchy("res://assets/active/skeleton.psk")
	source.detect_contact("attack")
	var hand: int = source.names.find("RightHand")
	var left: int = source.names.find("LeftHand")
	var feet: Array[int] = [source.names.find("LeftFoot"), source.names.find("RightFoot"), source.names.find("Hips"), 0]
	var max_delta := 0.0
	var max_left := 0.0
	var max_length_error := 0.0
	var previous_time := -0.001
	for index in 481:
		var t: float = source.duration * float(index) / 480.0
		var sampled: float = Attack.source_time(t, source.contact_time, source.duration)
		assert(sampled >= previous_time)
		previous_time = sampled
		var original := normalized(source, sampled)
		var shaped := Attack.shape(original, source.names, source.parents, t, source.contact_time, source.duration)
		max_delta = maxf(max_delta, original[hand].origin.distance_to(shaped[hand].origin))
		max_left = maxf(max_left, original[left].origin.distance_to(shaped[left].origin))
		for bone in shaped.size():
			var parent: int = source.parents[bone]
			if bone <= 0 or parent < 0 or parent >= bone: continue
			var before: float = original[bone].origin.distance_to(original[parent].origin)
			var after: float = shaped[bone].origin.distance_to(shaped[parent].origin)
			max_length_error = maxf(max_length_error, absf(before - after))
		for foot in feet:
			assert(original[foot].is_equal_approx(shaped[foot]))
		if index == 0 or index == 480:
			for bone in shaped.size(): assert(original[bone].is_equal_approx(shaped[bone]))
	var contact_pose := normalized(source, source.contact_time)
	var shaped_contact := Attack.shape(contact_pose, source.names, source.parents, source.contact_time, source.contact_time, source.duration)
	assert(Attack.source_time(source.contact_time, source.contact_time, source.duration) == source.contact_time)
	assert(contact_pose[hand].origin.distance_to(shaped_contact[hand].origin) < 0.000001)
	var max_adapt := 0.0
	for delta in [Vector3(.4,.25,.35), Vector3(-.45,-.3,-.4), Vector3(0,.3,.25), Vector3(0,0,0), Vector3(4,4,4)]:
		var adapted := Attack.adapt(shaped_contact, source.names, source.parents, shaped_contact[hand].origin + delta, 1.0)
		var travel: float = shaped_contact[hand].origin.distance_to(adapted[hand].origin)
		max_adapt = maxf(max_adapt, travel)
		assert(adapted[hand].origin.distance_to(shaped_contact[hand].origin + delta) <= delta.length() + 0.001)
		assert(travel <= Attack.MAX_ADAPT_HAND_TRAVEL + 0.001)
		for foot in feet: assert(shaped_contact[foot].is_equal_approx(adapted[foot]))
		for bone in adapted.size():
			var parent: int = source.parents[bone]
			if bone <= 0 or parent < 0 or parent >= bone: continue
			assert(absf(adapted[bone].origin.distance_to(adapted[parent].origin) - shaped_contact[bone].origin.distance_to(shaped_contact[parent].origin)) < 0.00001)
	assert(max_delta > 0.035)
	assert(max_left > 0.025)
	assert(max_length_error < 0.00001)
	print("ATTACK41 PASS source=", Attack.SOURCE, " bones=", source.names.size(), " contact=", source.contact_time, " duration=", source.duration, " authored_right_delta_m=", max_delta, " free_arm_delta_m=", max_left, " length_error_m=", max_length_error, " max_adapt_m=", max_adapt)
	quit()

func normalized(source, time: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = source.pose(time, false)
	var root: Vector3 = result[0].origin
	var offset: Vector3 = -(PSK.axis * Vector3(root.x, root.y, 0)) * 0.01 - source.body_center - Vector3(0, source.ground_y, 0)
	var jump: float = (time - source.contact_time) / 0.36
	offset.y += source.jump_boost * maxf(0.0, 1.0 - jump * jump)
	for bone in result.size():
		result[bone] = PSK.to_godot(result[bone])
		result[bone].origin += offset
	return result

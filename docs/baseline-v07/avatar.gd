extends Node3D
## Source animations, normalized root travel, skinning and bounded two-bone contact IK.
const PSK = preload("res://src/psk.gd")
const Assets = preload("res://src/source_assets.gd")
const MovementIntent = preload("res://src/movement_intent.gd")
var clips: Dictionary
var model_bank: Dictionary
var clip_name := "idle"
var animation_time := 0.0
var animation_speed := 1.0
var looping := true
var team := 0
var number := 1
var target := Vector3.ZERO
var velocity := Vector3.ZERO
var motion_lock := 0.0
var skeleton: Skeleton3D
var visual_root: Node3D
var animation_bones: Array[int] = []
var indicator: MeshInstance3D
var jersey_number: Label3D
var last_pose: Array[Transform3D] = []
var blend_pose: Array[Transform3D] = []
var blend_left := 0.0
var contact_scheduled := false
var hand_adjust := 0.0
var stride_phase := 0.0
var step_cooldown := 0.0
var tint: Color
var reach_target := Vector3.ZERO
var reach_weight := 0.0
var reach_action := ""
var ready_stance := false
var relaxed_stance := false
var block_ready_stance := false
var look_target := Vector3.ZERO
var acceleration := Vector3.ZERO
var steering_target := Vector3.ZERO
var steering_ready := false
var locomotion_action := "idle"
var foot_anchors := [Vector3.ZERO, Vector3.ZERO]
var foot_planted := [false, false]
var foot_corrections := 0
var body_lean := Vector2.ZERO
var cloth_material: StandardMaterial3D
var libero_active := false
var intent = MovementIntent.new()
var visual_context := "normal"
var effort := 0.0
var blend_source_name := ""
var blend_source_time := 0.0
var blend_source_speed := 1.0
var blend_source_loop := true
var blend_duration := 0.20
var travel_animation_time := 0.0
var travel_animation_name := "walk"
var head_angles := Vector2.ZERO
var idle_time := 0.0
var pending_pose_dt := 0.0
var render_at_draw := false
const BLEND_TIME := 0.20

func setup(bank: Dictionary, side: int, jersey: int, models: Dictionary = {}) -> void:
	clips = bank
	model_bank = models
	team = side
	number = jersey
	intent.configure(team, number)
	idle_time = float(number) * 1.618
	render_at_draw = DisplayServer.get_name() != "headless"
	tint = Color("1e4989") if team == 0 else Color("f4f0e8")
	visual_root = Node3D.new()
	add_child(visual_root)
	if models.has("body") and clips.has("idle"):
		setup_meshes()
	else:
		var capsule := MeshInstance3D.new()
		capsule.mesh = CapsuleMesh.new()
		capsule.position.y = 1
		visual_root.add_child(capsule)
	indicator = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34
	ring.outer_radius = 0.365
	ring.rings = 32
	ring.ring_segments = 6
	indicator.mesh = ring
	indicator.position.y = 0.028
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d9db9a")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator.material_override = m
	indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(indicator)
	animation_time = float(number) * 0.27
	apply_pose(0)

func setup_meshes() -> void:
	var body = model_bank.body
	skeleton = Skeleton3D.new()
	visual_root.add_child(skeleton)
	for i in body.names.size():
		skeleton.add_bone(body.names[i])
		if i > 0: skeleton.set_bone_parent(i, body.parents[i])
		skeleton.set_bone_rest(i, body.rest[i])
		animation_bones.append(clips.idle.names.find(body.names[i]))
	skeleton.reset_bone_poses()
	var skin := skeleton.create_skin_from_rest_transforms()
	for part in model_bank:
		var node := MeshInstance3D.new()
		node.mesh = model_bank[part].mesh
		node.skin = skin
		visual_root.add_child(node)
		node.skeleton = node.get_path_to(skeleton)
		var m: StandardMaterial3D
		match part:
			"body": m = Assets.material("T_Char_Body_Caucasian_M_01_Base.png", "T_Char_Body_Generic_M_Normal.png", Color.WHITE, 0.58)
			"head": m = Assets.material("T_Char_Head_Caucasian_M_02_Base.png", "T_Char_Head_Caucasian_M_02_Normal.png", Color.WHITE, 0.60)
			"cloth": m = Assets.material("T_Char_Cloth_FRA_Base_Home.png" if team == 0 else "T_Char_Cloth_FRA_Base_Away.png", "T_Char_Cloth_MyTeam_Normal.png", Color.WHITE, 0.85)
			"eyes": m = Assets.material("T_Char_Eye_Brown_Base.png", "", Color.WHITE, 0.22)
			"hair":
				m = Assets.material("", "", Color("211b18"), 0.88)
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.albedo_texture = Assets.texture("HairClump02_Alpha.png")
				m.alpha_scissor_threshold = 0.35
			"shoes": m = Assets.material("", "SK_Char_Shoe_M_01_Normal.png", Color("c6c7c5"), 0.6)
			_: m = Assets.material("", "", tint)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if part == "cloth": cloth_material = m
		node.material_override = m
		node.extra_cull_margin = 3
	jersey_number = Label3D.new()
	jersey_number.text = str(number)
	jersey_number.font_size = 70
	jersey_number.pixel_size = 0.0026
	jersey_number.modulate = Color.WHITE if team == 0 else Color("182d52")
	jersey_number.outline_size = 0
	jersey_number.rotation.y = PI
	visual_root.add_child(jersey_number)

func set_libero(value: bool) -> void:
	libero_active = value
	if cloth_material:
		cloth_material.albedo_texture = Assets.texture("T_Char_Cloth_FRA_Base_Away.png" if (team == 0) == value else "T_Char_Cloth_FRA_Base_Home.png")
	if jersey_number:
		jersey_number.text = "7" if value else str(number)
		jersey_number.modulate = Color("182d52") if (team == 0) == value else Color.WHITE

func play(action: String, speed: float = 1.0, loop: bool = false) -> void:
	if not clips.has(action): return
	if clip_name == action and looping and loop: return
	start_blend()
	clip_name = action
	animation_time = 0
	animation_speed = speed
	looping = loop
	contact_scheduled = false

func start_blend() -> void:
	if not last_pose.is_empty():
		blend_pose = last_pose.duplicate()
		blend_source_name = clip_name
		blend_source_time = animation_time
		blend_source_speed = animation_speed
		blend_source_loop = looping
		blend_duration = 0.18 + intent.individuality * 0.07
		if visual_context == "quick": blend_duration = 0.13 + intent.individuality * 0.035
		blend_left = blend_duration

func prepare_contact(action: String, remaining: float) -> void:
	if not clips.has(action): return
	if clip_name != action:
		start_blend()
	clip_name = action
	looping = false
	animation_speed = 1.15
	animation_time = maxf(0, clips[action].contact_time - maxf(0, remaining) * animation_speed)
	contact_scheduled = true
	if remaining <= 0:
		blend_left = 0
		apply_pose(0)

func contact_local(action: String) -> Vector3:
	if not clips.has(action):
		return Vector3(0, {"receive":1.15,"set":2.4,"fast_set":2.4,"attack":3.25,"block":3.1,"float":2.8,"power":3.2}.get(action,1.2), 0.4)
	return clips[action].contact_offset

func stance_for_contact(action: String, contact: Vector3) -> Vector3:
	var direction := Basis(Vector3.UP, PI if team == 0 else 0)
	var offset := direction * contact_local(action)
	return Vector3(contact.x - offset.x, 0, contact.z - offset.z)

func contact_world(action: String) -> Vector3:
	return global_transform * contact_local(action)

func current_hand(left: bool) -> Vector3:
	if last_pose.is_empty(): return contact_world("serve_idle")
	var idx: int = clips.idle.names.find("LeftHand" if left else "RightHand")
	return global_transform * last_pose[idx].origin

func rotate_subtree(pose: Array[Transform3D], joint: int, rotation: Basis, hierarchy: Array[int]) -> void:
	var pivot := pose[joint].origin
	for j in pose.size():
		var ancestor := j
		var found := false
		for hop in 24:
			if ancestor == joint:
				found = true
				break
			if ancestor <= 0 or ancestor >= hierarchy.size(): break
			ancestor = hierarchy[ancestor]
		if found:
			pose[j].origin = pivot + rotation * (pose[j].origin - pivot)
			pose[j].basis = rotation * pose[j].basis

func solve_arm(pose: Array[Transform3D], side: String, target_point: Vector3, hierarchy: Array[int]) -> void:
	var names: Array[String] = clips.idle.names
	var shoulder := names.find(side + "Arm")
	var elbow := names.find(side + "ForeArm")
	var wrist := names.find(side + "Hand")
	if shoulder < 0 or elbow < 0 or wrist < 0: return
	var s := pose[shoulder].origin
	var e := pose[elbow].origin
	var w := pose[wrist].origin
	var target := w.lerp(target_point, reach_weight)
	# Reach correction is bounded by anatomy and a small local correction radius.
	target = w + (target - w).limit_length(0.38)
	var upper := s.distance_to(e)
	var lower := e.distance_to(w)
	var direction := (target - s).normalized()
	var distance := clampf(s.distance_to(target), absf(upper - lower) + 0.002, upper + lower - 0.002)
	var pole := e - s - direction * (e - s).dot(direction)
	if pole.length() < 0.001: pole = Vector3(-1 if side == "Left" else 1, 0, 0)
	pole = pole.normalized()
	var cosine := clampf((upper * upper + distance * distance - lower * lower) / maxf(0.0001, 2 * upper * distance), -1, 1)
	var new_elbow := s + direction * cosine * upper + pole * sqrt(maxf(0, 1 - cosine * cosine)) * upper
	rotate_subtree(pose, shoulder, Basis(Quaternion((e - s).normalized(), (new_elbow - s).normalized())), hierarchy)
	var forearm := pose[wrist].origin - pose[elbow].origin
	var desired := s + direction * distance - pose[elbow].origin
	rotate_subtree(pose, elbow, Basis(Quaternion(forearm.normalized(), desired.normalized())), hierarchy)

func locomotion(speed: float, dt: float) -> void:
	stride_phase += speed * dt
	if clips.is_empty(): return
	if contact_scheduled: return
	if not looping and animation_time < clips[clip_name].contact_time + (0.58 if clip_name in ["attack", "block", "float", "power"] else 0.24): return
	if speed < 0.18:
		var idle_action := "ready" if ready_stance and clips.has("ready") else "idle"
		if relaxed_stance and clips.has("relaxed"): idle_action = "relaxed"
		if block_ready_stance and clips.has("block_ready"): idle_action = "block_ready"
		if clip_name != idle_action:
			play(idle_action, 1, true)
			animation_time = fposmod(float(number) * 1.618, clips[idle_action].duration)
			animation_speed = 0.93 + intent.individuality * 0.15
	else:
		var local_velocity := global_basis.inverse() * velocity
		var action := "walk" if speed < 2.1 and clips.has("walk") else "run"
		if absf(local_velocity.x) > absf(local_velocity.z) * 1.3:
			action = "shuffle_left" if local_velocity.x < 0 else "shuffle_right"
		elif local_velocity.z < -0.3 and clips.has("backpedal"):
			action = "backwalk" if speed < 2.1 and clips.has("backwalk") else "backpedal"
		# Hysteresis prevents toggling gait around the walking threshold.
		if clip_name == "walk" and action == "run" and speed < 2.6: action = "walk"
		if clip_name == "run" and action == "walk" and speed > 1.7: action = "run"
		var playback := clampf(speed / clips[action].travel_speed, 0.25, 2.2)
		travel_animation_name = action
		if clip_name != action:
			var old_phase := fposmod(animation_time / maxf(clips[clip_name].duration, 0.01), 1.0)
			play(action, playback, true)
			animation_time = old_phase * clips[action].duration
		else: animation_speed = playback

func tick(dt: float, selected: bool, render_pose: bool = true) -> void:
	if indicator: indicator.visible = selected
	step_cooldown = maxf(0, step_cooldown - dt)
	idle_time += dt * (0.93 + intent.individuality * 0.15)
	var local_acceleration := global_basis.inverse() * acceleration
	var local_velocity := global_basis.inverse() * velocity
	var lean := Vector2(clampf(local_acceleration.x * -0.004, -0.09, 0.09), clampf(local_acceleration.z * 0.003 + local_velocity.z * 0.012, -0.10, 0.12))
	body_lean = body_lean.lerp(lean if looping else Vector2.ZERO, 1.0 - exp(-dt * 8.0))
	if clips.has(travel_animation_name): travel_animation_time += dt * clampf(velocity.length() / clips[travel_animation_name].travel_speed, 0.12, 2.2)
	if blend_left > 0: blend_source_time += dt * blend_source_speed
	if not clips.has(clip_name): return
	if not contact_scheduled: animation_time += dt * animation_speed
	contact_scheduled = false
	if not looping and animation_time > clips[clip_name].duration:
		play("idle", 1, true)
	blend_left = maxf(0, blend_left - dt)
	if render_pose:
		if render_at_draw: pending_pose_dt += dt
		else: apply_pose(dt)

func _process(_dt: float) -> void:
	# Movement stays at 120 Hz; skinning uses the latest state once per drawn
	# frame instead of calculating two poses that would never both be displayed.
	if pending_pose_dt > 0:
		apply_pose(pending_pose_dt)
		pending_pose_dt = 0.0

func apply_pose(_dt: float) -> void:
	if not skeleton or not clips.has(clip_name): return
	var clip = clips[clip_name]
	var normalized := normalized_pose(clip_name, animation_time, looping)
	# Blend local joint rotations, then rebuild the hierarchy. Interpolating
	# world-space joints shortens limbs and collapses knees during transitions.
	if blend_left > 0 and blend_pose.size() == normalized.size():
		var outgoing := normalized_pose(blend_source_name, blend_source_time, blend_source_loop) if clips.has(blend_source_name) else blend_pose
		normalized = blend_hierarchy(outgoing, normalized, smoothstep(0, 1, 1.0 - blend_left / blend_duration), clip.parents)
	if looping and clip_name not in ["idle", "relaxed", "ready", "block_ready", "serve_idle"]:
		var seam := smoothstep(0.86, 1.0, fposmod(animation_time, clip.duration) / clip.duration)
		if seam > 0:
			var initial: Array[Transform3D] = clip.pose(0, false)
			var initial_hips: Vector3 = initial[clip.names.find("Hips")].origin
			for i in initial.size(): initial[i] = PSK.to_godot(initial[i]); initial[i].origin += Vector3(-initial_hips.x, -clip.ground_y * 100, initial_hips.y) * 0.01
			normalized = blend_hierarchy(normalized, initial, seam, clip.parents)
		if velocity.length() < 1.25:
			var idle_name := "block_ready" if block_ready_stance else ("ready" if ready_stance else "relaxed")
			if clips.has(idle_name):
				var resting := normalized_pose(idle_name, idle_time, true)
				normalized = blend_hierarchy(resting, normalized, smoothstep(0.10, 1.25, velocity.length()), clip.parents)
	# Continue stepping under a preparing upper body; keep the original takeoff
	# and landing once the source jump begins. Contact sampling at dt=0 is exact.
	if _dt > 0 and clip_name in ["receive", "set", "fast_set", "attack"] and velocity.length() > 0.35 and animation_time < clip.contact_time:
		var remaining: float = (clip.contact_time - animation_time) / maxf(animation_speed, 0.01)
		var fade_start := 0.37 if clip_name == "attack" else 0.16
		var leg_weight := smoothstep(fade_start, fade_start + 0.16, remaining)
		if leg_weight > 0 and clips.has(travel_animation_name):
			var steps := normalized_pose(travel_animation_name, travel_animation_time, true)
			normalized = layer_legs(normalized, steps, leg_weight, clip.parents, clip.names)
	if _dt > 0:
		if looping:
			var hip: int = clip.names.find("Hips")
			if hip >= 0: rotate_subtree(normalized, hip, Basis(Vector3.FORWARD, body_lean.x) * Basis(Vector3.RIGHT, body_lean.y), clip.parents)
		plant_feet(normalized, clip, _dt)
		var head: int = clip.names.find("Head")
		if head >= 0:
			var sight := global_transform.affine_inverse() * look_target - normalized[head].origin
			var yaw := clampf(atan2(sight.x, maxf(0.5, sight.z)), -0.48, 0.48)
			var pitch := clampf(-atan2(sight.y, maxf(0.5, Vector2(sight.x, sight.z).length())), -0.36, 0.32)
			head_angles = head_angles.lerp(Vector2(yaw, pitch), 1.0 - exp(-_dt * (6.0 + intent.individuality * 3.0)))
			rotate_subtree(normalized, head, Basis(Vector3.UP, head_angles.x) * Basis(Vector3.RIGHT, head_angles.y), clip.parents)
	# Source root travel must not move a mesh independently of its gameplay actor.
	if reach_weight > 0.001 and reach_action in ["receive", "set", "fast_set", "attack", "float", "power"]:
		var point := global_transform.affine_inverse() * reach_target
		if reach_action in ["receive", "set", "fast_set"]:
			solve_arm(normalized, "Left", point + Vector3(0.105, -0.07, 0), clip.parents)
			solve_arm(normalized, "Right", point + Vector3(-0.105, -0.07, 0), clip.parents)
		else:
			solve_arm(normalized, "Right", point - Vector3(0, 0, 0.085), clip.parents)
	if clip_name == "block" and absf(hand_adjust) > 0.01:
		for side in ["Left", "Right"]:
			var shoulder: int = clip.names.find(side + "Arm")
			var hand: int = clip.names.find(side + "Hand")
			var delta := global_basis.inverse() * Vector3(hand_adjust * 0.23, 0, 0)
			var pivot: Vector3 = normalized[shoulder].origin
			var arm: Vector3 = normalized[hand].origin - pivot
			var turn := Basis(Quaternion(arm.normalized(), (arm + delta).normalized()))
			for j in normalized.size():
				var ancestor := j
				var descendant := false
				for hop in 16:
					if ancestor == shoulder:
						descendant = true
						break
					if ancestor <= 0 or ancestor >= clip.parents.size(): break
					ancestor = clip.parents[ancestor]
				if descendant:
					normalized[j].origin = pivot + turn * (normalized[j].origin - pivot)
					normalized[j].basis = turn * normalized[j].basis
	last_pose = normalized
	var body = model_bank.body
	for i in body.names.size():
		var idx: int = animation_bones[i]
		if idx < 0: continue
		var local := normalized[idx]
		if i > 0:
			var parent_idx: int = animation_bones[body.parents[i]]
			if parent_idx >= 0: local = normalized[parent_idx].affine_inverse() * local
		skeleton.set_bone_pose_position(i, local.origin)
		skeleton.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
	if jersey_number:
		var spine: int = clip.names.find("Spine2")
		jersey_number.position = normalized[spine].origin + Vector3(0, -0.05, -0.17)

func normalized_pose(name: String, time: float, loop: bool) -> Array[Transform3D]:
	var clip = clips[name]
	var source: Array[Transform3D] = clip.pose(time, loop)
	var hips: Vector3 = source[clip.names.find("Hips")].origin
	var offset := Vector3(-hips.x, -clip.ground_y * 100, hips.y) * 0.01
	var jump_phase: float = (time - clip.contact_time) / 0.36
	offset.y += clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
	for i in source.size():
		source[i] = PSK.to_godot(source[i])
		source[i].origin += offset
	return source

func layer_legs(base: Array[Transform3D], steps: Array[Transform3D], weight: float, hierarchy: Array[int], names: Array[String]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.resize(base.size())
	var roots := [names.find("LeftUpLeg"), names.find("RightUpLeg")]
	for i in base.size():
		var ancestor := i
		var lower := false
		for hop in 12:
			if ancestor in roots:
				lower = true
				break
			if ancestor <= 0: break
			ancestor = hierarchy[ancestor]
		var parent := hierarchy[i]
		var local := base[i]
		if parent >= 0 and parent < i: local = base[parent].affine_inverse() * local
		if lower and parent >= 0 and parent < i:
			var target := steps[parent].affine_inverse() * steps[i]
			local = Transform3D(Basis(local.basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(), weight)), local.origin.lerp(target.origin, weight))
		result[i] = result[parent] * local if parent >= 0 and parent < i else local
	return result

func blend_hierarchy(a: Array[Transform3D], b: Array[Transform3D], weight: float, hierarchy: Array[int]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.resize(b.size())
	for i in b.size():
		var parent := hierarchy[i]
		var first := a[i]
		var second := b[i]
		if parent >= 0 and parent < i:
			first = a[parent].affine_inverse() * first
			second = b[parent].affine_inverse() * second
		var local := Transform3D(Basis(first.basis.get_rotation_quaternion().slerp(second.basis.get_rotation_quaternion(), weight)), first.origin.lerp(second.origin, weight))
		result[i] = result[parent] * local if parent >= 0 and parent < i else local
	return result

func plant_feet(pose: Array[Transform3D], clip, _dt: float) -> void:
	var jumping: bool = clip_name in ["attack", "block", "float", "power", "set", "fast_set"] and absf(animation_time - clip.contact_time) < 0.48
	for side_index in 2:
		var side := "Left" if side_index == 0 else "Right"
		var hip: int = clip.names.find(side + "UpLeg")
		var knee: int = clip.names.find(side + "Leg")
		var foot: int = clip.names.find(side + "Foot")
		var toe: int = clip.names.find(side + "ToeBase")
		if hip < 0 or knee < 0 or foot < 0 or toe < 0: continue
		var world := global_transform * pose[foot].origin
		var low: bool = pose[toe].origin.y < 0.13
		if jumping or not low or (foot_planted[side_index] and world.distance_to(foot_anchors[side_index]) > 0.24):
			foot_planted[side_index] = false
			continue
		if not foot_planted[side_index]:
			foot_anchors[side_index] = world
			foot_anchors[side_index].y += 0.055 - pose[toe].origin.y
			foot_planted[side_index] = true
		var goal: Vector3 = global_transform.affine_inverse() * foot_anchors[side_index]
		goal = pose[foot].origin + (goal - pose[foot].origin).limit_length(0.16)
		var s := pose[hip].origin
		var e := pose[knee].origin
		var w := pose[foot].origin
		var upper := s.distance_to(e)
		var lower := e.distance_to(w)
		var direction := (goal - s).normalized()
		var distance := clampf(s.distance_to(goal), absf(upper - lower) + 0.002, upper + lower - 0.002)
		var pole := e - s - direction * (e - s).dot(direction)
		if pole.length() < 0.001: pole = Vector3.FORWARD
		var cosine := clampf((upper * upper + distance * distance - lower * lower) / (2 * upper * distance), -1, 1)
		var next_knee := s + direction * cosine * upper + pole.normalized() * sqrt(maxf(0, 1 - cosine * cosine)) * upper
		rotate_subtree(pose, hip, Basis(Quaternion((e - s).normalized(), (next_knee - s).normalized())), clip.parents)
		rotate_subtree(pose, knee, Basis(Quaternion((pose[foot].origin - pose[knee].origin).normalized(), (s + direction * distance - pose[knee].origin).normalized())), clip.parents)
		foot_corrections += 1

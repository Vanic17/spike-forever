extends Node3D
## Source animations, normalized root travel, skinning and bounded two-bone contact IK.
const PSK = preload("res://src/psk.gd")
const Assets = preload("res://src/source_assets.gd")
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

func setup(bank: Dictionary, side: int, jersey: int, models: Dictionary = {}) -> void:
	clips = bank
	model_bank = models
	team = side
	number = jersey
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
		blend_left = 0.13

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
	if not looping and animation_time < clips[clip_name].contact_time + (0.30 if clip_name in ["attack", "block"] else 0.16): return
	if speed < 0.18:
		var idle_action := "ready" if ready_stance and clips.has("ready") else "idle"
		if clip_name != idle_action:
			play(idle_action, 1, true)
			animation_time = float(number) * 0.19
	else:
		var local_velocity := global_basis.inverse() * velocity
		var action := "run"
		if absf(local_velocity.x) > absf(local_velocity.z) * 1.3:
			action = "shuffle_left" if local_velocity.x < 0 else "shuffle_right"
		elif local_velocity.z < -0.3 and clips.has("backpedal"): action = "backpedal"
		var playback := clampf(speed / (2.5 if action.begins_with("shuffle") else 4.8), 0.65, 1.85)
		if clip_name != action:
			var old_phase := fposmod(animation_time / maxf(clips[clip_name].duration, 0.01), 1.0)
			play(action, playback, true)
			animation_time = old_phase * clips[action].duration
		else: animation_speed = playback

func tick(dt: float, selected: bool, render_pose: bool = true) -> void:
	if indicator: indicator.visible = selected
	step_cooldown = maxf(0, step_cooldown - dt)
	if not clips.has(clip_name): return
	if not contact_scheduled: animation_time += dt * animation_speed
	contact_scheduled = false
	if not looping and animation_time > clips[clip_name].duration:
		play("idle", 1, true)
	blend_left = maxf(0, blend_left - dt)
	if render_pose: apply_pose(dt)

func apply_pose(_dt: float) -> void:
	if not skeleton or not clips.has(clip_name): return
	var clip = clips[clip_name]
	var source: Array[Transform3D] = clip.pose(animation_time, looping)
	var hips: Vector3 = source[clip.names.find("Hips")].origin
	var offset := Vector3(-hips.x, -clip.ground_y * 100, hips.y) * 0.01
	var jump_phase: float = (animation_time - clip.contact_time) / 0.36
	offset.y += clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
	var normalized: Array[Transform3D] = []
	normalized.resize(source.size())
	for i in source.size():
		normalized[i] = PSK.to_godot(source[i])
		normalized[i].origin += offset
		if blend_left > 0 and blend_pose.size() == source.size():
			normalized[i] = blend_pose[i].interpolate_with(normalized[i], 1.0 - blend_left / 0.13)
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

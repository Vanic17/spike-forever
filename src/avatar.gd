extends Node3D
## Source animations, normalized root travel, skinning and bounded two-bone contact IK.
const AnimationExpansion = preload("res://src/animation_expansion.gd")
const PSK = preload("res://src/psk.gd")
const Assets = preload("res://src/source_assets.gd")
const ClubKits = preload("res://src/club_kits.gd")
const MovementIntent = preload("res://src/movement_intent.gd")
const PoseTree = preload("res://src/pose_animation_tree.gd")
const MotionPrototypes = preload("res://src/motion_prototypes.gd")
const PoseHierarchy = preload("res://src/pose_hierarchy.gd")
var subtree_indices: Array = []
# All active clips are validated and preconverted. F6 or --psa-original can
# still select the original parser; it remains the per-clip failure fallback.
static var native_animation_enabled := not "--psa-original" in OS.get_cmdline_user_args()
var pose_tree: Node3D
var native_pose_pass := false
var middle_ready:=false
var middle_load:=0.0
var middle_load_age:=0.0
var wrist_tip_variant:=""
var native_transition_influence := 0.35 if native_animation_enabled else 0.0
var clips: Dictionary
var source_clips: Dictionary
var variant_names: Dictionary = {}
var setting_yaw := 0.0
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
var power_transfer_from:=Vector3(0.2,1.2,0.4)
var power_transfer_start:=0.0
var skeleton: Skeleton3D
var visual_root: Node3D
var animation_bones: Array[int] = []
var indicator: MeshInstance3D
var jersey_number: Label3D
var roster_identity: Dictionary={}
var left_handed:=false
var mirror_bones: PackedInt32Array=[]
var libero_identity: Dictionary={}
var kit_identity: Dictionary={}
var libero_kit: Dictionary={}
var body_parts: Dictionary={}
var yield_turn:=0.0
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
var post_point := false
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
var cloth_material: Material
var libero_active := false
var intent = MovementIntent.new()
var visual_context := "normal"
var effort := 0.0
var dive_yaw := 0.0
var blend_source_name := ""
var blend_source_time := 0.0
var blend_source_speed := 1.0
var blend_source_loop := true
var blend_duration := 0.20
var travel_animation_time := 0.0
var travel_animation_name := "walk"
var travel_animation_speed := 1.0
var travel_blend_source_name := "walk"
var travel_blend_source_time := 0.0
var travel_blend_source_speed := 1.0
var travel_blend_left := 0.0
var travel_blend_duration := 0.16
var travel_blend_rotations: Array[Quaternion] = []
var travel_blend_positions: Array[Vector3] = []
var travel_change_age := 1.0
var head_angles := Vector2.ZERO
var blend_rotation_offsets: Array[Quaternion] = []
var blend_position_offsets: Array[Vector3] = []
var foot_weights := [0.0,0.0]
var gait_change_age := 1.0
var idle_time := 0.0
var pending_pose_dt := 0.0
var render_at_draw := false
const BLEND_TIME := 0.20

func setup(bank: Dictionary, side: int, jersey: int, models: Dictionary = {}) -> void:
	source_clips = bank
	if bank.has("idle"): subtree_indices = PoseHierarchy.descendants(bank.idle.parents)
	clips = bank.duplicate()
	for action in ["idle","ready","relaxed","block_ready","run","walk","backwalk","backpedal","shuffle_left","shuffle_right","cross_left","cross_right"]:
		var variant := AnimationExpansion.stance_or_gait(action,side,jersey)
		if source_clips.has(variant):
			clips[action]=source_clips[variant]
			variant_names[action]=variant
	model_bank = models
	team = side
	setting_yaw = PI if team==0 else 0.0
	number = jersey
	intent.configure(team, number)
	idle_time = float(number) * 1.618
	render_at_draw = DisplayServer.get_name() != "headless"
	tint = Color("1e4989") if team == 0 else Color("f4f0e8")
	visual_root = Node3D.new()
	add_child(visual_root)
	if models.has("body") and clips.has("idle"):
		setup_meshes()
		if native_animation_enabled: ensure_native_tree()
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
		node.mesh = ClubKits.mesh_with_print_uv(model_bank[part].mesh) if part == "cloth" else model_bank[part].mesh
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
		body_parts[part]=node
		node.extra_cull_margin = 3
	jersey_number = Label3D.new()
	jersey_number.text = ["OH1","MB1","OPP","OH2","MB2","S"][number-1]
	jersey_number.font_size = 52
	jersey_number.pixel_size = 0.0026
	jersey_number.modulate = Color.WHITE if team == 0 else Color("182d52")
	jersey_number.outline_size = 0
	jersey_number.rotation.y = PI
	visual_root.add_child(jersey_number)

func set_libero(value: bool) -> void:
	if value == libero_active: return
	libero_active = value
	if not roster_identity.is_empty():
		apply_identity()
		return
	if cloth_material:
		cloth_material.albedo_texture = Assets.texture("T_Char_Cloth_FRA_Base_Away.png" if (team == 0) == value else "T_Char_Cloth_FRA_Base_Home.png")
	if jersey_number:
		jersey_number.text = "L" if value else ["OH1","MB1","OPP","OH2","MB2","S"][number-1]
		jersey_number.modulate = Color("182d52") if (team == 0) == value else Color.WHITE

func role_label() -> String:
	return "L" if libero_active else ["OH1","MB1","OPP","OH2","MB2","S"][number-1]

func set_roster_identity(player: Dictionary,libero: Dictionary,kit: Dictionary,contrast: Dictionary) -> void:
	roster_identity=player; libero_identity=libero; kit_identity=kit; libero_kit=contrast
	apply_identity()

func apply_identity() -> void:
	var person: Dictionary=libero_identity if libero_active else roster_identity
	left_handed=person.get("dominant_hand","right")=="left"
	var kit: Dictionary=libero_kit if libero_active else kit_identity
	var primary=Color(kit.get("primary_hex_approx","#17458A"))
	if libero_active and primary.is_equal_approx(Color(kit_identity.get("primary_hex_approx","#17458A"))): primary=Color(kit_identity.get("secondary_hex_approx","#F5F5F5"))
	if cloth_material:
		if kit.has("texture"):
			cloth_material = ClubKits.material(self,person,kit)
		else:
			var fallback := StandardMaterial3D.new()
			fallback.albedo_color = primary
			fallback.roughness = 0.85
			fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
			cloth_material = fallback
		body_parts.cloth.material_override=cloth_material
	if jersey_number:
		jersey_number.text=str(int(person.jersey_number)) if person.get("jersey_number")!=null else "?"
		jersey_number.modulate=Color.WHITE if primary.get_luminance()<0.45 else Color("14243a")
		jersey_number.visible = not kit.has("texture")
	var appearance: Dictionary=person.get("appearance",{})
	preload("res://src/player_appearance.gd").apply(self,appearance)

func play(action: String, speed: float = 1.0, loop: bool = false) -> void:
	if not clips.has(action): return
	if action!="attack": wrist_tip_variant=""
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
		blend_source_name = "source:"+str(variant_names.get(clip_name,clip_name))
		blend_source_time = animation_time
		blend_source_speed = animation_speed
		blend_source_loop = looping
		blend_duration = 0.18 + intent.individuality * 0.07
		if visual_context == "quick": blend_duration = 0.13 + intent.individuality * 0.035
		blend_left = blend_duration
		# A new transition can begin while the previous one is still blending.
		# Continue from the actually displayed composite pose, including its
		# planted feet, instead of snapping back to a raw outgoing clip.
		blend_rotation_offsets.clear()
		blend_position_offsets.clear()
		var outgoing := normalized_pose(clip_name,animation_time,looping)
		for i in last_pose.size():
			var first: Transform3D = outgoing[i]
			var visible: Transform3D = last_pose[i]
			var parent: int = clips[clip_name].parents[i]
			if parent>=0 and parent<i:
				first=outgoing[parent].affine_inverse()*first
				visible=last_pose[parent].affine_inverse()*visible
			blend_rotation_offsets.append(first.basis.get_rotation_quaternion().inverse()*visible.basis.get_rotation_quaternion())
			blend_position_offsets.append(visible.origin-first.origin)

func prepare_contact(action: String, remaining: float) -> void:
	if not clips.has(action): return
	if clip_name != action:
		start_blend()
	clip_name = action
	looping = false
	animation_speed = 1.15-0.25*smoothstep(0.2,0.4,remaining) if action=="attack" else 1.15
	# Extend the running preparation, then retain the original speed for the
	# last 200ms and the contact. The intervening rate changes smoothly.
	var source_remaining:=maxf(0,remaining)*1.15
	if action=="attack": source_remaining=attack_source_remaining(maxf(0,remaining))
	animation_time = maxf(0, clips[action].contact_time - source_remaining)
	contact_scheduled = true
	if remaining <= 0:
		blend_left = 0
		apply_pose(0)

func preparation_lead(action: String, requested: float) -> float:
	# Do not hold frame zero while waiting for the source clip to catch up.
	# The existing ball deadline and the 1.15 contact playback stay authoritative.
	if not clips.has(action): return requested
	var prefix: float=clips[action].contact_time/1.15
	if action=="attack": prefix=attack_clock_seconds(clips[action].contact_time)
	return minf(requested,prefix)

func attack_source_remaining(seconds: float) -> float:
	if seconds<=0.2: return seconds*1.15
	if seconds>=0.4: return 0.435+(seconds-0.4)*0.90
	var u: float=(seconds-0.2)/0.2
	return 0.23+1.15*(seconds-0.2)-0.05*(u*u*u-0.5*u*u*u*u)

func attack_clock_seconds(source_seconds: float) -> float:
	if source_seconds<=0.23: return source_seconds/1.15
	if source_seconds>=0.435: return 0.4+(source_seconds-0.435)/0.90
	var low:=0.2; var high:=0.4
	for iteration in 10:
		var middle: float=(low+high)*0.5
		if attack_source_remaining(middle)<source_seconds: low=middle
		else: high=middle
	return (low+high)*0.5

func recovery_speed_scale() -> float:
	# A grounded forearm pass has no landing to wait for. Source-driven dives,
	# serves and the decoy have their own recovery path in main.gd.
	if motion_lock <= 0 or looping or clip_name == "receive": return 1.0
	return lerpf(0.35, 1.0, smoothstep(0.0, 0.12, 0.12-motion_lock))

func contact_local(action: String) -> Vector3:
	if not clips.has(action):
		return Vector3(0, {"receive":1.15,"recovery":0.65,"dive":0.65,"dump":2.5,"set":2.4,"fast_set":2.4,"attack":3.25,"block":3.1,"float":2.8,"power":3.2}.get(action,1.2), 0.4)
	var result: Vector3=clips[action].contact_offset
	if left_handed and action in ["attack","power","float","dump","serve_idle"]: result.x=-result.x
	return result

func select_variant(action: String, variant: String = "") -> void:
	var selected := variant if source_clips.has(variant) else action
	if not source_clips.has(selected): return
	if clips.get(action)==source_clips[selected]: return
	if clip_name==action:
		if not looping and animation_time>=clips[action].contact_time and animation_time<clips[action].recovery_end: return
		start_blend()
	clips[action]=source_clips[selected]
	variant_names[action]=selected

func action_root_motion(action: String, time: float) -> Vector3:
	var result: Vector3=clips[action].root_motion(time) if clips.has(action) else Vector3.ZERO
	if left_handed and action in ["attack","power","float","dump","serve_idle"]: result.x=-result.x
	return result

func contact_recovery_remaining() -> float:
	if not clips.has(clip_name) or looping: return 0.0
	return maxf(0,(clips[clip_name].recovery_end+0.12-animation_time)/maxf(animation_speed,0.01))

func stance_for_contact(action: String, contact: Vector3) -> Vector3:
	var direction := Basis(Vector3.UP, PI if team == 0 else 0)
	if action == "dive": direction = Basis(Vector3.UP,dive_yaw)
	if action in ["set","fast_set"]: direction = Basis(Vector3.UP,setting_yaw)
	var offset := direction * contact_local(action)
	return Vector3(contact.x - offset.x, 0, contact.z - offset.z)

func contact_world(action: String) -> Vector3:
	return global_transform * contact_local(action)

func current_hand(left: bool) -> Vector3:
	if left_handed and clip_name in ["attack","power","float","dump","serve_idle"]: left=not left
	if last_pose.is_empty(): return contact_world("serve_idle")
	var idx: int = clips.idle.names.find("LeftHand" if left else "RightHand")
	return global_transform * last_pose[idx].origin

func current_joint(name: String) -> Vector3:
	if last_pose.is_empty(): return contact_world("block")
	var index: int = clips.idle.names.find(name)
	return global_transform*last_pose[index].origin if index>=0 else contact_world("block")

func rotate_subtree(pose: Array[Transform3D], joint: int, rotation: Basis, hierarchy: Array[int]) -> void:
	if joint < 0 or joint >= pose.size(): return
	var pivot := pose[joint].origin
	var indices: Array = subtree_indices if subtree_indices.size() == hierarchy.size() else PoseHierarchy.descendants(hierarchy)
	for j in indices[joint]:
		pose[j].origin = pivot + rotation * (pose[j].origin - pivot)
		pose[j].basis = rotation * pose[j].basis

func solve_arm(pose: Array[Transform3D], side: String, target_point: Vector3, hierarchy: Array[int], correction_limit: float = 0.38) -> void:
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
	target = w + (target - w).limit_length(correction_limit)
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
	gait_change_age += dt
	if clips.is_empty(): return
	# Contact preparation owns the upper body, but its feet still have to read
	# a lateral correction or backward step. Previously this returned with the
	# last running direction frozen until the actual ball contact.
	update_travel_gait(speed,dt)
	if contact_scheduled: return
	if post_point and not looping and contact_recovery_remaining()<=0:
		play("relaxed",1,true)
	if clip_name in ["dive","recovery"] and not looping and contact_recovery_remaining()>0: return
	if not looping and animation_time < maxf(clips[clip_name].recovery_end+0.08,clips[clip_name].contact_time+0.38) and clip_name in ["attack","block","float","power","set","fast_set","dump"]: return
	if not looping and animation_time < clips[clip_name].contact_time+0.24: return
	if speed < 0.18:
		var idle_action := "ready" if ready_stance and clips.has("ready") else "idle"
		if relaxed_stance and clips.has("relaxed"): idle_action = "relaxed"
		if block_ready_stance and clips.has("block_ready"): idle_action = "block_ready"
		if clip_name != idle_action:
			play(idle_action, 1, true)
			animation_time = fposmod(float(number) * 1.618, clips[idle_action].duration)
			animation_speed = 0.93 + intent.individuality * 0.15
	else:
		var action := choose_gait(speed,clip_name)
		if gait_change_age<0.18 and looping and clip_name in ["walk","run","shuffle_left","shuffle_right","cross_left","cross_right","backwalk","backpedal"] and action!=clip_name: action=clip_name
		var playback := clampf(speed / clips[action].travel_speed, 0.25, 2.2)
		if clip_name != action:
			var next_time := match_gait_time(action)
			play(action, playback, true)
			animation_time = next_time
			gait_change_age=0.0
		else: animation_speed = lerpf(animation_speed,playback,1.0-exp(-dt*14.0))

func choose_gait(speed: float, previous: String) -> String:
	# A regrouping athlete walks upright; defensive cross/back steps contain
	# squat preparation that has no purpose after the whistle.
	if post_point: return "walk" if speed<2.6 else "run"
	var local_velocity := global_basis.inverse() * velocity
	var approach_run: bool=intent.task=="approach" or (clip_name=="attack" and not looping and animation_time<clips.attack.takeoff_time)
	if approach_run and speed>1.25 and local_velocity.z>0.15:
		return "run"
	var walking := speed < (2.6 if previous in ["walk","backwalk"] else 1.7)
	var action := "walk" if walking and clips.has("walk") else "run"
	# Retain lateral footwork through a shallow diagonal correction instead of
	# switching to a forward stride and back around one angular threshold.
	var lateral_threshold := 0.95 if previous in ["shuffle_left","shuffle_right","cross_left","cross_right"] else 1.3
	if absf(local_velocity.x)>absf(local_velocity.z)*lateral_threshold:
		# Source labels refer to the athlete facing +Z: L travels +X, R -X.
		action="shuffle_right" if local_velocity.x<0 else "shuffle_left"
		var crossing := "cross_right" if local_velocity.x<0 else "cross_left"
		if speed > (2.35 if previous.begins_with("cross_") else 3.0) and clips.has(crossing): action=crossing
	elif local_velocity.z<(-0.10 if previous in ["backwalk","backpedal"] else -0.30) and clips.has("backpedal"):
		action="backwalk" if walking and clips.has("backwalk") else "backpedal"
	if block_ready_stance and action in ["shuffle_left","shuffle_right"] and clips.has("wall_"+action): return "wall_"+action
	return action

func update_travel_gait(speed: float, dt: float) -> void:
	travel_change_age+=dt
	if speed<0.18: return
	var action := choose_gait(speed,travel_animation_name)
	if not clips.has(action): return
	if action!=travel_animation_name and travel_change_age>=0.12:
		var visible := travel_pose()
		var raw := gait_pose(travel_animation_name,travel_animation_time)
		travel_blend_rotations.clear()
		travel_blend_positions.clear()
		for i in visible.size():
			var parent: int=clips[action].parents[i]
			var from: Transform3D=raw[i]
			var shown: Transform3D=visible[i]
			if parent>=0 and parent<i:
				from=raw[parent].affine_inverse()*from
				shown=visible[parent].affine_inverse()*shown
			travel_blend_rotations.append(from.basis.get_rotation_quaternion().inverse()*shown.basis.get_rotation_quaternion())
			travel_blend_positions.append(shown.origin-from.origin)
		travel_blend_source_name=travel_animation_name
		travel_blend_source_time=travel_animation_time
		travel_blend_source_speed=travel_animation_speed
		travel_animation_name=action
		travel_animation_time=match_gait_time(action)
		travel_animation_speed=clampf(speed/clips[action].travel_speed,0.25,2.2)
		travel_blend_left=travel_blend_duration
		travel_change_age=0.0
	else:
		var playback := clampf(speed/clips[travel_animation_name].travel_speed,0.12,2.2)
		travel_animation_speed=lerpf(travel_animation_speed,playback,1.0-exp(-dt*14.0))

func travel_pose() -> Array[Transform3D]:
	var pose := gait_pose(travel_animation_name,travel_animation_time)
	if travel_blend_left>0 and clips.has(travel_blend_source_name):
		var outgoing := gait_pose(travel_blend_source_name,travel_blend_source_time)
		if travel_blend_rotations.size()==outgoing.size(): outgoing=apply_blend_offsets(outgoing,clips[travel_animation_name].parents,travel_blend_rotations,travel_blend_positions)
		pose=blend_hierarchy(outgoing,pose,smoothstep(0,1,1.0-travel_blend_left/travel_blend_duration),clips[travel_animation_name].parents)
	return pose

func gait_pose(action: String, time: float) -> Array[Transform3D]:
	var pose := normalized_pose(action,time,true)
	var clip=clips[action]
	# Some exported step cycles end a few centimetres from their first pose.
	# The upper-body locomotion already closes this seam; prepared-action legs
	# need the same treatment or their ankles jump when that cycle wraps.
	var seam := smoothstep(0.86,1.0,fposmod(time,clip.duration)/clip.duration)
	if seam>0: pose=blend_hierarchy(pose,normalized_pose(action,0,false),seam,clip.parents)
	return pose

func match_gait_time(action: String) -> float:
	if last_pose.is_empty(): return 0.0
	var best := INF
	var time := 0.0
	# Walk, lateral steps and backward running start on different support feet.
	# Choose the nearest leg configuration, not the same percentage of a clip.
	for sample in 8:
		var candidate_time: float = clips[action].duration*float(sample)/8.0
		var candidate := normalized_pose(action,candidate_time,true)
		var score := 0.0
		for name in ["LeftUpLeg","LeftLeg","LeftFoot","RightUpLeg","RightLeg","RightFoot"]:
			var i: int = clips[action].names.find(name)
			var parent: int = clips[action].parents[i]
			var a: Transform3D = last_pose[parent].affine_inverse()*last_pose[i]
			var b: Transform3D = candidate[parent].affine_inverse()*candidate[i]
			score+=a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion())
		if score<best:
			best=score
			time=candidate_time
	return time

func tick(dt: float, selected: bool, render_pose: bool = true) -> void:
	middle_load=move_toward(middle_load,1.0 if middle_ready else 0.0,dt*7.0)
	middle_load_age=middle_load_age+dt if middle_ready else 0.0
	if indicator: indicator.visible = selected
	step_cooldown = maxf(0, step_cooldown - dt)
	idle_time += dt * (0.93 + intent.individuality * 0.15)
	var local_acceleration := global_basis.inverse() * acceleration
	var local_velocity := global_basis.inverse() * velocity
	var lean := Vector2(clampf(local_acceleration.x * -0.004, -0.09, 0.09), clampf(local_acceleration.z * 0.003 + local_velocity.z * 0.012, -0.10, 0.12))
	body_lean = body_lean.lerp(lean if looping else Vector2.ZERO, 1.0 - exp(-dt * 8.0))
	if clips.has(travel_animation_name): travel_animation_time += dt * travel_animation_speed
	if travel_blend_left>0: travel_blend_source_time+=dt*travel_blend_source_speed
	travel_blend_left=maxf(0,travel_blend_left-dt)
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

func ensure_native_tree() -> void:
	if pose_tree != null: return
	pose_tree = PoseTree.new()
	pose_tree.name = "NativePoseEvaluation"
	add_child(pose_tree)
	pose_tree.setup(source_clips, func(name: String,time: float,loop: bool): return psa_normalized_pose("source:"+name,time,loop))

func apply_pose(_dt: float) -> void:
	if not skeleton or not clips.has(clip_name): return
	if native_animation_enabled: ensure_native_tree()
	if pose_tree != null: pose_tree.begin_pose()
	native_pose_pass = native_animation_enabled and pose_tree != null and pose_tree.initialized and pose_tree.library.has_animation(native_clip_name(clip_name))
	# Crossfade the easing profile on A/B switches; never restart an action.
	native_transition_influence = move_toward(native_transition_influence, 0.35 if native_pose_pass else 0.0, _dt * 2.9)
	var clip = clips[clip_name]
	var normalized := normalized_pose(clip_name, animation_time, looping)
	# Blend local joint rotations, then rebuild the hierarchy. Interpolating
	# world-space joints shortens limbs and collapses knees during transitions.
	if blend_left > 0 and blend_pose.size() == normalized.size():
		var outgoing := normalized_pose(blend_source_name, blend_source_time, blend_source_loop) if clips.has(blend_source_name) or blend_source_name.begins_with("source:") else blend_pose
		if blend_rotation_offsets.size()==outgoing.size(): outgoing=continue_blend_source(outgoing,clip.parents)
		var progress := clampf(1.0 - blend_left / blend_duration, 0, 1)
		# Introduce quintic easing progressively, reducing endpoint acceleration.
		# Only the torso gets the new curve; support legs retain their phases.
		var weight := smoothstep(0, 1, progress)
		var incoming := normalized
		normalized = blend_hierarchy(outgoing, incoming, weight, clip.parents)
		if pose_tree != null and pose_tree.initialized and native_transition_influence > 0 and looping:
			var quintic := progress * progress * progress * (progress * (progress * 6.0 - 15.0) + 10.0)
			var desired := lerpf(weight, quintic, native_transition_influence)
			var toward_incoming := desired >= weight
			var correction := absf(desired - weight) / maxf(0.000001, 1.0 - weight if toward_incoming else weight)
			normalized = pose_tree.mix(normalized, incoming if toward_incoming else outgoing, correction, false, true)
	if looping and clip_name not in ["idle", "relaxed", "ready", "block_ready", "serve_idle"]:
		var seam := smoothstep(0.86, 1.0, fposmod(animation_time, clip.duration) / clip.duration)
		if seam > 0:
			var initial := normalized_pose(clip_name,0,false)
			normalized = blend_hierarchy(normalized, initial, seam, clip.parents)
		if velocity.length() < 1.25:
			var idle_name := "block_ready" if block_ready_stance else ("ready" if ready_stance else "relaxed")
			if clips.has(idle_name):
				var resting := normalized_pose(idle_name, idle_time, true)
				normalized = blend_hierarchy(resting, normalized, smoothstep(0.10, 1.25, velocity.length()), clip.parents)
	# Continue stepping under a preparing upper body; keep the original takeoff
	# and landing once the source jump begins. Contact sampling at dt=0 is exact.
	if _dt > 0 and clip_name in ["receive", "set", "fast_set", "attack"] and velocity.length() > 0.18:
		var remaining: float = (clip.contact_time - animation_time) / maxf(animation_speed, 0.01)
		if clip_name=="attack": remaining=attack_clock_seconds(clip.contact_time-animation_time)
		var fade_start := 0.37 if clip_name == "attack" else 0.16
		if clip_name=="attack":
			# Reveal the source L-R-L plant before takeoff, instead of keeping
			# a generic walking cycle until the player is already airborne.
			fade_start=maxf(0.37,attack_clock_seconds(maxf(0,clip.contact_time-clip.takeoff_time))+0.045)
		var leg_weight := smoothstep(fade_start, fade_start + 0.16, remaining)
		# Resume the support feet through a grounded pass follow-through;
		# jumping actions keep their original takeoff AND landing intact.
		if clip_name=="receive" and remaining<0:
			leg_weight=smoothstep(0.045,0.18,-remaining)
		leg_weight*=smoothstep(0.18,0.65,velocity.length())
		if leg_weight > 0 and clips.has(travel_animation_name):
			var steps := travel_pose()
			normalized = layer_legs(normalized, steps, leg_weight, clip.parents, clip.names)
	# A middle threatens the quick even before a high set can start its jump
	# clip. Layer the original grounded backswing over the travelling feet.
	if middle_load>0.001 and looping and source_clips.has("attack_v26_01"):
		# Keep the hands in the genuine low backswing. Sampling until the
		# old decoy's takeoff held both hands up like a stationary setter.
		var load_time: float=minf(.075,middle_load_age*.30)
		var ready_pose:=normalized_pose("source:attack_v26_01",load_time,false)
		normalized=mix_upper_pose(normalized,ready_pose,middle_load*.85)
	# A late middle tip changes the wrist, not the jump or the interception
	# height. Keep the already airborne first-tempo body on its own clock.
	if clip_name=="attack" and not wrist_tip_variant.is_empty() and source_clips.has(wrist_tip_variant):
		var wrist=source_clips[wrist_tip_variant]
		var remaining: float=attack_clock_seconds(maxf(0,clip.contact_time-animation_time))
		var wrist_time: float=wrist.contact_time-remaining*1.15+maxf(0,animation_time-clip.contact_time)
		var wrist_pose:=normalized_pose("source:"+wrist_tip_variant,maxf(0,wrist_time),false)
		normalized=mix_upper_pose(normalized,wrist_pose,.85*(1.0-smoothstep(clip.contact_time+.03,clip.contact_time+.20,animation_time)))
	# The new performance follows the real contact target before the existing
	# bounded arm IK. It never moves the actor, legs, ball or action clock.
	if clip_name == "attack" and native_clip_name(clip_name) == "attack_adaptive41" and reach_action == "attack" and reach_weight > 0.001:
		var context_weight := reach_weight * (1.0 - smoothstep(clip.contact_time + 0.04, clip.contact_time + 0.20, animation_time))
		normalized = MotionPrototypes.Attack.adapt(normalized, clip.names, clip.parents, global_transform.affine_inverse() * reach_target, context_weight)
	if _dt > 0:
		# A short shoulder turn accompanies a teammate's clearing sidestep.
		# Keep the source support feet and all contact poses authoritative.
		var local_travel: Vector3=global_basis.inverse()*velocity
		var turn_goal:=clampf(local_travel.x*0.10,-0.28,0.28) if intent.task=="yield" and looping else 0.0
		yield_turn=lerpf(yield_turn,turn_goal,1.0-exp(-_dt*10.0))
		if looping and absf(yield_turn)>0.001:
			var chest: int=clip.names.find("Spine1")
			if chest>=0: rotate_subtree(normalized,chest,Basis(Vector3.UP,yield_turn),clip.parents)
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
	if clip_name=="power" and animation_time<power_transfer_start+0.35:
		# This source tosses with the RIGHT hand. Transfer from the idle hold
		# into that palm once, then preserve the actual original throwing arc.
		var saved_reach := reach_weight
		reach_weight=1.0-smoothstep(power_transfer_start,power_transfer_start+0.35,animation_time)
		solve_arm(normalized,"Left" if left_handed else "Right",power_transfer_from,clip.parents,1.5)
		reach_weight=saved_reach
	if reach_weight > 0.001 and reach_action in ["receive", "recovery", "dive", "dump", "set", "fast_set", "attack", "float", "power", "block"]:
		var point := global_transform.affine_inverse() * reach_target
		if reach_action=="block":
			solve_arm(normalized,"Left",point+Vector3(0.22,0,0),clip.parents)
			solve_arm(normalized,"Right",point-Vector3(0.22,0,0),clip.parents)
		elif reach_action in ["receive", "set", "fast_set"]:
			solve_arm(normalized, "Left", point + Vector3(0.105, -0.07, 0), clip.parents)
			solve_arm(normalized, "Right", point + Vector3(-0.105, -0.07, 0), clip.parents)
		else:
			var left_arm: bool=(not left_handed) if reach_action=="dump" else (left_handed and reach_action in ["attack","power","float"])
			solve_arm(normalized, "Left" if left_arm else "Right", point - Vector3(0, 0, 0.085), clip.parents)
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
	native_pose_pass = false
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
	var native_name := native_clip_name(name)
	var result: Array[Transform3D]
	if native_animation_enabled and pose_tree != null and pose_tree.initialized and pose_tree.library.has_animation(native_name):
		result=pose_tree.sample(native_name, time, loop)
	else: result=psa_normalized_pose(name, time, loop)
	if left_handed and (native_name.begins_with("attack") or native_name.begins_with("dump") or native_name in ["power","float","serve_idle"]):
		if mirror_bones.is_empty():
			for bone in clips.idle.names:
				var opposite: String=bone.replace("Left","@SIDE@").replace("Right","Left").replace("@SIDE@","Right")
				mirror_bones.append(clips.idle.names.find(opposite))
		var original:=result.duplicate()
		var reflect:=Basis(Vector3(-1,0,0),Vector3.UP,Vector3.BACK)
		for i in result.size():
			var from: int=mirror_bones[i]
			if from<0: from=i
			result[i]=Transform3D(reflect*original[from].basis*reflect,reflect*original[from].origin)
	return result

func native_clip_name(name: String) -> String:
	return name.trim_prefix("source:") if name.begins_with("source:") else str(variant_names.get(name, name))

func psa_normalized_pose(name: String, time: float, loop: bool) -> Array[Transform3D]:
	var clip = source_clips[name.trim_prefix("source:")] if name.begins_with("source:") else clips[name]
	var source: Array[Transform3D] = clip.pose(time, loop)
	var source_root: Vector3 = source[0].origin
	var offset: Vector3 = Vector3(-source_root.x, -clip.ground_y * 100, source_root.y) * 0.01-clip.body_center
	var jump_phase: float = (time - clip.contact_time) / 0.36
	offset.y += clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
	for i in source.size():
		source[i] = PSK.to_godot(source[i])
		source[i].origin += offset
	return source

func continue_blend_source(pose: Array[Transform3D], hierarchy: Array[int]) -> Array[Transform3D]:
	return apply_blend_offsets(pose,hierarchy,blend_rotation_offsets,blend_position_offsets)

func apply_blend_offsets(pose: Array[Transform3D], hierarchy: Array[int], rotations: Array[Quaternion], positions: Array[Vector3]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.resize(pose.size())
	for i in pose.size():
		var parent := hierarchy[i]
		var local := pose[i]
		if parent>=0 and parent<i: local=pose[parent].affine_inverse()*local
		local.basis=Basis(local.basis.get_rotation_quaternion()*rotations[i])
		local.origin+=positions[i]
		result[i]=result[parent]*local if parent>=0 and parent<i else local
	return result

func layer_legs(base: Array[Transform3D], steps: Array[Transform3D], weight: float, hierarchy: Array[int], names: Array[String]) -> Array[Transform3D]:
	if native_pose_pass:
		# Build the established pelvis compensation once, then let the native
		# bone filter layer support legs without affecting the receiving arms.
		native_pose_pass = false
		var moving := layer_legs(base, steps, 1.0, hierarchy, names)
		native_pose_pass = true
		return pose_tree.mix(base, moving, weight, true)
	var result: Array[Transform3D] = []
	result.resize(base.size())
	var roots := [names.find("LeftUpLeg"), names.find("RightUpLeg")]
	var pelvis:=names.find("Hips")
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
		if i==pelvis and parent>=0 and parent<i:
			# Carry the moving pelvis with its support legs. Copying straight
			# running legs under a low reception squat pushed feet underground,
			# then snapped the knees upward when the contact layer faded out.
			var moving_pelvis: Transform3D=base[parent].affine_inverse()*steps[i]
			local.origin=local.origin.lerp(moving_pelvis.origin,weight)
			local.basis=Basis(local.basis.get_rotation_quaternion().slerp(moving_pelvis.basis.get_rotation_quaternion(),weight))
		if lower and parent >= 0 and parent < i:
			var target := steps[parent].affine_inverse() * steps[i]
			local = Transform3D(Basis(local.basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(), weight)), local.origin.lerp(target.origin, weight))
		result[i] = result[parent] * local if parent >= 0 and parent < i else local
	return result

func mix_upper_pose(a: Array[Transform3D], b: Array[Transform3D], weight: float) -> Array[Transform3D]:
	if pose_tree!=null and pose_tree.initialized: return pose_tree.mix(a,b,weight,false,true)
	# The PSA fallback uses the same local-space Spine mask. Neither path
	# changes pelvis, feet or the actual jump clock.
	var result: Array[Transform3D]=[]
	var upper: Array=subtree_indices[clips.idle.names.find("Spine")]
	for bone in a.size():
		var parent: int=clips.idle.parents[bone]
		var first: Transform3D=a[parent].affine_inverse()*a[bone] if parent>=0 and parent<bone else a[bone]
		var second: Transform3D=b[parent].affine_inverse()*b[bone] if parent>=0 and parent<bone else b[bone]
		var local:=first
		if bone in upper: local=Transform3D(Basis(first.basis.get_rotation_quaternion().slerp(second.basis.get_rotation_quaternion(),weight)),first.origin.lerp(second.origin,weight))
		result.append(result[parent]*local if parent>=0 and parent<bone else local)
	return result

func blend_hierarchy(a: Array[Transform3D], b: Array[Transform3D], weight: float, hierarchy: Array[int]) -> Array[Transform3D]:
	if native_pose_pass: return pose_tree.mix(a, b, weight)
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
	var jumping: bool = clip_name in ["attack", "block", "float", "power", "set", "fast_set", "dump"] and absf(animation_time - clip.contact_time) < 0.48
	for side_index in 2:
		var side := "Left" if side_index == 0 else "Right"
		var hip: int = clip.names.find(side + "UpLeg")
		var knee: int = clip.names.find(side + "Leg")
		var foot: int = clip.names.find(side + "Foot")
		var toe: int = clip.names.find(side + "ToeBase")
		if hip < 0 or knee < 0 or foot < 0 or toe < 0: continue
		var world := global_transform * pose[foot].origin
		var low: bool = pose[toe].origin.y < 0.105
		var support: bool = low and not jumping and clip_name not in ["dive","recovery"]
		if not support or (foot_planted[side_index] and world.distance_to(foot_anchors[side_index])>0.22): foot_planted[side_index]=false
		if support and not foot_planted[side_index] and foot_weights[side_index]<0.02:
			foot_anchors[side_index] = world
			foot_anchors[side_index].y += 0.055 - pose[toe].origin.y
			foot_planted[side_index] = true
		foot_weights[side_index]=move_toward(foot_weights[side_index],1.0 if foot_planted[side_index] else 0.0,_dt*(9.0 if foot_planted[side_index] else 14.0))
		if foot_weights[side_index]<0.001: continue
		var goal: Vector3 = global_transform.affine_inverse() * foot_anchors[side_index]
		# Fade ankle anchoring in and out. Releasing a planted foot used to drop
		# a full 16cm correction in one frame, visibly teleporting the knee.
		goal = pose[foot].origin + (goal - pose[foot].origin).limit_length(0.10)*foot_weights[side_index]
		var foot_basis := pose[foot].basis
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
		rotate_subtree(pose,foot,foot_basis*pose[foot].basis.inverse(),clip.parents)
		foot_corrections += 1

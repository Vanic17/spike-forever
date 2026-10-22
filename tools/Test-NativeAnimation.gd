extends SceneTree
const Avatar = preload("res://src/avatar.gd")
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")
const Converter = preload("res://src/psa_animation_library.gd")
var checks := 0
var failed := false

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Avatar.native_animation_enabled = true
	var bank: Dictionary = {}
	var sources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/active/sources.json"))
	for action in sources:
		var clip = PSA.new()
		check(clip.load_file("res://assets/active/" + action + ".psa"), "Missing source")
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(action)
		bank[action] = clip
	var body = PSK.new()
	check(body.load_file("res://assets/active/body.psk"), "Missing mesh")
	var native = Avatar.new()
	root.add_child(native)
	native.setup(bank, 0, 1, {"body": body})
	native.render_at_draw = false
	var maximum_position_error := 0.0
	var maximum_angle_error := 0.0
	var converted_clips := 0
	for name in Converter.CLIPS:
		var clip = bank[name]
		converted_clips += 1
		for frame in 53:
			var t: float = clip.duration * (float(frame) + 0.37) / 52.0
			for loop in [false, true]:
				var original: Array[Transform3D] = native.psa_normalized_pose(name, t, loop)
				var converted: Array[Transform3D] = native.normalized_pose(name, t, loop)
				for bone in original.size():
					maximum_position_error = maxf(maximum_position_error, original[bone].origin.distance_to(converted[bone].origin))
					maximum_angle_error = maxf(maximum_angle_error, original[bone].basis.get_rotation_quaternion().angle_to(converted[bone].basis.get_rotation_quaternion()))
		check(native.pose_tree.library.get_animation(name).get_meta("contact_time") == clip.contact_time, "Contact metadata changed")
		# Preserve the analytic jump, including exact contact and between keys.
		for t in [clip.contact_time, clip.contact_time - 0.181, clip.contact_time + 0.137, -0.1, clip.duration + 0.1]:
			var expected: Array[Transform3D] = native.psa_normalized_pose(name, t, false)
			var actual: Array[Transform3D] = native.normalized_pose(name, t, false)
			for joint in ["Hips", "LeftFoot", "RightFoot", "LeftHand", "RightHand"]:
				var bone: int = clip.names.find(joint)
				check(expected[bone].origin.distance_to(actual[bone].origin) < 0.0002, "Native contact/root motion changed: " + name + ":" + joint)
	check(converted_clips == bank.size(), "Some active source clips were not converted")
	check(maximum_position_error < 0.0002, "Native sampling orientation/scale/root error: " + str(maximum_position_error))
	check(maximum_angle_error < 0.002, "Native sampling rotation error: " + str(maximum_angle_error))
	var a: Array[Transform3D] = native.psa_normalized_pose("ready", 0.23, true)
	var b: Array[Transform3D] = native.psa_normalized_pose("shuffle_left", 0.41, true)
	var maximum_blend_error := 0.0
	for step in 11:
		var weight := float(step) / 10.0
		var expected: Array[Transform3D] = native.blend_hierarchy(a, b, weight, bank.idle.parents)
		var actual: Array[Transform3D] = native.pose_tree.mix(a, b, weight)
		for bone in a.size(): maximum_blend_error = maxf(maximum_blend_error, actual[bone].origin.distance_to(expected[bone].origin))
	check(maximum_blend_error < 0.0002, "Native transition blend mismatch: " + str(maximum_blend_error))
	var before_mix_evaluations: int = native.pose_tree.evaluations
	native.pose_tree.mix(a, b, 0.5)
	check(native.pose_tree.evaluations == before_mix_evaluations, "Corrected pose blending must not reevaluate the private skeleton")
	var receiving: Array[Transform3D] = native.psa_normalized_pose("receive", 0.2, false)
	var layered: Array[Transform3D] = native.layer_legs(receiving, b, 1.0, bank.idle.parents, bank.idle.names)
	var masked: Array[Transform3D] = native.pose_tree.mix(receiving, layered, 1.0, true)
	for bone in receiving.size():
		check(masked[bone].origin.distance_to(layered[bone].origin) < 0.0002, "Lower mask mismatch: " + bank.idle.names[bone])
	for weight in [0.2, 0.5, 0.8]:
		var upper: Array[Transform3D] = native.pose_tree.mix(a, b, weight, false, true)
		for bone in a.size():
			var ancestor := bone
			var torso := false
			while ancestor > 0:
				if bank.idle.names[ancestor] == "Spine": torso = true
				ancestor = bank.idle.parents[ancestor]
			if not torso: check(upper[bone].origin.distance_to(a[bone].origin) < 0.0002, "Torso mask moved the support legs")
	var original = Avatar.new()
	root.add_child(original)
	original.setup(bank, 0, 1, {"body": body})
	original.render_at_draw = false
	original.native_transition_influence = 0.0
	var maximum_final_error := 0.0
	var maximum_toggle_error := 0.0
	var maximum_foot_drift := 0.0
	var original_foot_drift := 0.0
	var native_microseconds := 0
	var original_microseconds := 0
	for fps in [60, 120]:
		for action in ["ready", "shuffle_left", "shuffle_right", "receive", "idle", "attack", "receive_left_up", "ready"]:
			for athlete in [native, original]:
				athlete.play(action, 1, action != "receive")
			for frame in 24:
				for athlete in [native, original]:
					Avatar.native_animation_enabled = athlete == native
					athlete.position += Vector3(0.7, 0, 0) / fps
					athlete.velocity = Vector3(0.7, 0, 0)
					athlete.look_target = Vector3(1.0, 1.4, 3)
					athlete.reach_action = "receive"
					athlete.reach_weight = 0.1
					athlete.reach_target = athlete.global_position + Vector3(0, 1.2, 0.8)
					var started := Time.get_ticks_usec()
					athlete.tick(1.0 / fps, false, true)
					if athlete == native: native_microseconds += Time.get_ticks_usec() - started
					else: original_microseconds += Time.get_ticks_usec() - started
				for bone in native.last_pose.size():
					maximum_final_error = maxf(maximum_final_error, native.last_pose[bone].origin.distance_to(original.last_pose[bone].origin))
				for side in 2:
					if native.foot_planted[side] and native.foot_weights[side] > 0.95:
						var foot: int = bank.idle.names.find("LeftFoot" if side == 0 else "RightFoot")
						var world: Vector3 = native.global_transform * native.last_pose[foot].origin
						maximum_foot_drift = maxf(maximum_foot_drift, Vector2(world.x - native.foot_anchors[side].x, world.z - native.foot_anchors[side].z).length())
					if original.foot_planted[side] and original.foot_weights[side] > 0.95:
						var foot: int = bank.idle.names.find("LeftFoot" if side == 0 else "RightFoot")
						var world: Vector3 = original.global_transform * original.last_pose[foot].origin
						original_foot_drift = maxf(original_foot_drift, Vector2(world.x - original.foot_anchors[side].x, world.z - original.foot_anchors[side].z).length())
			Avatar.native_animation_enabled = true
			var visible: Array[Transform3D] = native.last_pose.duplicate()
			native.apply_pose(0)
			var before: Array[Transform3D] = native.last_pose.duplicate()
			Avatar.native_animation_enabled = false
			native.apply_pose(0)
			for bone in before.size(): maximum_toggle_error = maxf(maximum_toggle_error, before[bone].origin.distance_to(native.last_pose[bone].origin))
			# Restore the actual corrected pose; dt=0 deliberately omits foot/head corrections.
			native.last_pose = visible
	# The native quintic visual easing differs intentionally within a transition.
	# Torso easing must preserve the support trajectory, including anchors.
	check(maximum_final_error < 0.02, "Torso easing exceeded transition envelope: " + str(maximum_final_error))
	check(maximum_toggle_error < 0.0002, "Mode switch changed pose: " + str(maximum_toggle_error))
	check(maximum_foot_drift < 0.23, "Foot support exceeded existing anchor release distance")
	check(maximum_foot_drift <= original_foot_drift + 0.001, "Native animation increased planted-foot drift")
	for name in ["receive", "receive_follow", "receive_left_up", "receive_right_up"]:
		for mode in [true, false]:
			Avatar.native_animation_enabled = mode
			native.play("idle", 1, true)
			native.select_variant("receive", name)
			native.prepare_contact("receive", 0)
			check(is_equal_approx(native.animation_time, bank[name].contact_time), "Contact clock changed")
			var expected: Array[Transform3D] = native.psa_normalized_pose("receive", native.animation_time, false)
			# Procedural reach is enabled in this scenario. Verify clock, then
			# isolate sampling parity without disabling production IK.
			var actual: Array[Transform3D] = native.normalized_pose("receive", native.animation_time, false)
			for side in ["LeftHand", "RightHand"]:
				var hand: int = bank[name].names.find(side)
				check(expected[hand].origin.distance_to(actual[hand].origin) < 0.0002, "Reception contact sampling shifted")
		var previous: Array[Transform3D] = native.last_pose.duplicate()
		Avatar.native_animation_enabled = not Avatar.native_animation_enabled
		native.apply_pose(0)
		for bone in previous.size(): check(previous[bone].origin.distance_to(native.last_pose[bone].origin) < 0.0002, "Mode switch popped the visible skeleton")
	check(native.position.is_equal_approx(original.position), "Visual evaluation changed actor motion")
	check(native.foot_corrections > 0, "Foot corrections were lost")
	Avatar.native_animation_enabled = true
	for name in ["attack", "block", "set", "power", "float", "dive"]:
		var expected: Array[Transform3D] = native.psa_normalized_pose(name, 0.21, false)
		var actual: Array[Transform3D] = native.normalized_pose(name, 0.21, false)
		for bone in expected.size(): check(actual[bone].origin.distance_to(expected[bone].origin) < 0.0002, "Extended native action changed pose: " + name)
	# Custom clips continue to use PSA independently of the native clip list.
	native.clips["custom_fallback"] = bank.receive
	var fallback_evaluations: int = native.pose_tree.evaluations
	check(native.normalized_pose("custom_fallback", 0.21, false) == native.psa_normalized_pose("custom_fallback", 0.21, false), "Custom action lost PSA fallback")
	check(native.pose_tree.evaluations == fallback_evaluations, "Fallback action evaluated native rig")
	native.pose_tree.begin_pose()
	var cached_pose: Array[Transform3D] = native.pose_tree.sample("receive", 0.319, false)
	var cached_evaluations: int = native.pose_tree.evaluations
	cached_pose[0].origin += Vector3.ONE
	var cached_again: Array[Transform3D] = native.pose_tree.sample("receive", 0.319, false)
	check(native.pose_tree.evaluations == cached_evaluations, "Repeated immutable clip sample was evaluated twice")
	check(cached_again[0].origin.distance_to(cached_pose[0].origin) > 1.0, "Procedural edits leaked into sample cache")
	Avatar.native_animation_enabled = false
	native.native_transition_influence = 0.0
	native.play("ready", 1, true)
	var previous_evaluations: int = native.pose_tree.evaluations
	native.apply_pose(1.0 / 60.0)
	check(native.pose_tree.evaluations == previous_evaluations, "Original mode still evaluated AnimationTree after handover")
	var incompatible: Dictionary = bank.duplicate()
	var invalid = PSA.new()
	invalid.names = bank.ready.names.duplicate()
	invalid.parents = bank.ready.parents.duplicate()
	invalid.parents[1] = -1
	incompatible.ready = invalid
	var rejected = preload("res://src/pose_animation_tree.gd").new()
	root.add_child(rejected)
	rejected.setup(incompatible, Callable(native, "psa_normalized_pose"))
	check(not rejected.initialized, "Incompatible hierarchy should preserve the PSA fallback")
	rejected.free()
	var library_path := Converter.LIBRARY_PATH
	check(ResourceSaver.save(native.pose_tree.library, library_path) == OK, "AnimationLibrary export failed")
	var reloaded = ResourceLoader.load(library_path, "AnimationLibrary", ResourceLoader.CACHE_MODE_IGNORE)
	check(reloaded is AnimationLibrary and reloaded.get_animation_list().size() == Converter.CLIPS.size(), "AnimationLibrary round trip failed")
	var report := {"checks": checks, "sampling_position_m": maximum_position_error, "sampling_angle_rad": maximum_angle_error, "blend_position_m": maximum_blend_error, "final_position_m": maximum_final_error, "toggle_position_m": maximum_toggle_error, "foot_anchor_drift_m": maximum_foot_drift, "original_foot_anchor_drift_m": original_foot_drift, "native_cpu_us": native_microseconds, "psa_cpu_us": original_microseconds}
	var file := FileAccess.open("res://docs/native-animation-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("NATIVE ANIMATION ", "FAIL" if failed else "PASS", ": ", JSON.stringify(report))
	native.free()
	original.free()
	quit(1 if failed else 0)

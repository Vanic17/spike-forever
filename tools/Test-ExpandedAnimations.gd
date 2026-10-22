extends SceneTree
const Variety = preload("res://src/animation_variety.gd")
const Converter = preload("res://src/psa_animation_library.gd")
const Avatar = preload("res://src/avatar.gd")
var failed := false
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void: call_deferred("run")

func sha(path: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()

func test_visual_plan_latch(game) -> void:
	# read_controls may repeat the same decision throughout the setter's run.
	# Crossing the visual running threshold must not keep changing the hand
	# offset used to reach the same scheduled second contact.
	game.server = 1
	game.rotations = [0, 0]
	game.reset_rally()
	game.possession = 0
	game.setter = 5
	game.receiver = 3
	game.phase = "SET"
	game.incoming_kind = "serve"
	game.pass_quality = 1.0
	game.out_of_system = 1
	game.flight_target = Vector3(0, game.contact_height("set"), 1.5)
	game.shot_serial = 600
	var setter = game.players[5]
	setter.play("idle", 1, true)
	setter.velocity = Vector3.ZERO
	game.plan_attack(0, false)
	var first_hitter: int = game.planned_hitter
	var set_variant: String = setter.variant_names.get("set", "set")
	var fast_variant: String = setter.variant_names.get("fast_set", "fast_set")
	var hit_variant: String = game.players[first_hitter].variant_names.get("attack", "attack")
	var contact_offset: Vector3 = setter.contact_local("set")
	for tick in 4:
		setter.velocity = Vector3(2.8 if tick % 2 == 0 else 0.1, 0, 0)
		game.phase_time = 0.1 + tick * 0.2
		game.plan_attack(0, false)
		check(game.planned_hitter == first_hitter, "A visual plan repeat changed the tactical hitter")
		check(setter.variant_names.get("set", "set") == set_variant, "Same play changed set clip while accelerating/braking")
		check(setter.variant_names.get("fast_set", "fast_set") == fast_variant, "Same play changed fast set clip")
		check(game.players[first_hitter].variant_names.get("attack", "attack") == hit_variant, "Same play changed attack clip")
		check(setter.contact_local("set").is_equal_approx(contact_offset), "Same play moved the scheduled setting hand offset")
	game.plan_attack(2, false)
	check(setter.variant_names.get("set", "set") != set_variant, "New direction did not select a compatible back-set performance")
	check(setter.variant_names.get("fast_set", "fast_set") == "fast_set_back", "New direction retained a front fast-set performance")
	var back_variant: String = setter.variant_names.get("set", "set")
	game.shot_serial += 1
	setter.velocity = Vector3(2.8, 0, 0)
	game.plan_attack(0, false)
	check(setter.variant_names.get("set", "set") == "set_running_front", "A new shot could not select a new arriving performance")
	check(setter.variant_names.get("set", "set") != back_variant, "Visual latch leaked across shots")
	# Resetting to an identical shot key must also forget the old visual plan.
	game.reset_rally()
	game.possession = 0
	game.setter = 5
	game.receiver = 3
	game.phase = "SET"
	game.incoming_kind = "serve"
	game.pass_quality = 1.0
	game.out_of_system = 1
	game.shot_serial = 601
	setter.play("idle", 1, true)
	setter.velocity = Vector3.ZERO
	game.plan_attack(0, false)
	check(setter.variant_names.get("set", "set") == "set", "Rally reset retained an old running-set latch")

func run() -> void:
	var game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.started = true
	game.self_test = true
	game.demo = false
	game.set_process(false)
	game.set_physics_process(false)
	var counts := {"receive": 0, "set": 0, "attack": 0}
	var source_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/active/new_animations_24.json"))
	var seen_hashes: Dictionary = {}
	var seen_motion: Dictionary = {}
	for name in Converter.CLIPS:
		if name not in Variety.CLIPS:
			seen_hashes[sha("res://assets/active/" + name + ".psa")] = name
			seen_motion[hash([game.clips[name].positions, game.clips[name].rotations])] = name
	var chosen: Dictionary = {}
	for serial in 12:
		for point in [Vector3(-1.4, 0, 0), Vector3(1.4, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 1.6)]:
			for speed in [0.0, 2.0]:
				for incoming in ["serve", "spike"]:
					chosen[Variety.receive(point, speed, incoming, serial)] = true
		for back in [false, true]:
			for speed in [0.0, 2.5]:
				for quality in [0.6, 1.0]: chosen[Variety.setting(back, speed, quality, serial)] = true
		for direction in 4:
			for quality in [0.6, 1.0]: chosen[Variety.attack(direction, quality, serial)] = true
	var report: Dictionary = {}
	var maximum_gap := 0.0
	var maximum_native_error := 0.0
	var maximum_transition_pop := 0.0
	var maximum_limb_error := 0.0
	for name in Variety.CLIPS:
		var family: String = name.split("_")[0]
		counts[family] += 1
		check(chosen.has(name), "New animation is unreachable from its contextual selector: " + name)
		check(Converter.CLIPS.has(name) and game.clips.has(name), "New animation missing from runtime/native bank: " + name)
		var path: String = "res://assets/active/" + name + ".psa"
		var digest := sha(path)
		check(not seen_hashes.has(digest), "New clip duplicates a source performance: " + name)
		seen_hashes[digest] = name
		var source := "res://assets/spike/Game/CharactersV1/Animations/" + str(Variety.SOURCES[name])
		check(source_manifest[name].source == Variety.SOURCES[name] and digest == source_manifest[name].sha256, "Active source differs from inventoried original PSA: " + name)
		if FileAccess.file_exists(source): check(digest == sha(source), "Active source differs from the original archive: " + name)
		var clip = game.clips[name]
		var motion_hash: int = hash([clip.positions, clip.rotations])
		check(not seen_motion.has(motion_hash), "Source file differs but keyframe motion is a duplicate: " + name)
		seen_motion[motion_hash] = name
		check(clip.names == game.clips.idle.names and clip.parents == game.clips.idle.parents, "Source hierarchy changed: " + name)
		check(clip.contact_time > 0 and clip.contact_time < clip.duration, "Invalid contact event: " + name)
		var gaps: Array = []
		for mode in [false, true]:
			Avatar.native_animation_enabled = mode
			for index in [0, 6]:
				var athlete = game.players[index]
				athlete.render_at_draw = false
				athlete.play("idle", 1, true)
				athlete.animation_time = 0
				athlete.select_variant(family, name)
				athlete.rotation.y = PI if index < 6 else 0.0
				athlete.setting_yaw = -PI / 2 if index < 6 else PI / 2
				if family == "set": athlete.rotation.y = athlete.setting_yaw
				athlete.reach_weight = 0
				for spot in [Vector3(-2.8, 0, 5), Vector3(0, 0, 1.5), Vector3(2.8, 0, 3.2)]:
					game.ball_pos = Vector3(spot.x, game.contact_height(family), spot.z * (1 if index < 6 else -1))
					athlete.position = athlete.stance_for_contact(family, game.ball_pos)
					check(game.validate_contact(index, family), "New performance missed scheduled ball contact: " + name + " native=" + str(mode))
					if not game.contact_log.is_empty():
						var gap: float = game.contact_log[-1].gap
						gaps.append(gap)
						maximum_gap = maxf(maximum_gap, gap)
				for frame in 11:
					var time: float = clip.duration * (frame + 0.37) / 11.0
					var native: Array[Transform3D] = athlete.normalized_pose(family, time, false)
					var original: Array[Transform3D] = athlete.psa_normalized_pose(family, time, false)
					var first: Array[Transform3D] = athlete.psa_normalized_pose(family, 0, false)
					for bone in native.size():
						check(native[bone].origin.is_finite() and native[bone].basis.is_finite(), "Non-finite joint: " + name)
						maximum_native_error = maxf(maximum_native_error, native[bone].origin.distance_to(original[bone].origin))
					for side in ["Left", "Right"]:
						for pair in [["UpLeg", "Leg"], ["Leg", "Foot"], ["Arm", "ForeArm"], ["ForeArm", "Hand"]]:
							var a: int = clip.names.find(side + pair[0])
							var b: int = clip.names.find(side + pair[1])
							maximum_limb_error = maxf(maximum_limb_error, absf(native[a].origin.distance_to(native[b].origin) - first[a].origin.distance_to(first[b].origin)))
				athlete.reach_weight = 0
				athlete.play("run", 1, true)
				athlete.velocity = Vector3(0.7, 0, 0)
				for frame in 12: athlete.tick(1.0 / 120.0, false, true)
				var previous: Array[Transform3D] = athlete.last_pose.duplicate()
				var root_before: Vector3 = athlete.position
				athlete.play(family, 1, false)
				athlete.apply_pose(0)
				for bone in previous.size(): maximum_transition_pop = maxf(maximum_transition_pop, previous[bone].origin.distance_to(athlete.last_pose[bone].origin))
				check(athlete.position == root_before, "Animation moved the real actor root: " + name)
		var native_clip = game.players[0].pose_tree.library.get_animation(name)
		check(native_clip != null, "Missing preconverted native animation: " + name)
		check(native_clip.get_meta("contact_time") == clip.contact_time, "Native contact clock changed: " + name)
		report[name] = {"source": Variety.SOURCES[name], "sha256": digest, "frames": clip.frames, "duration_s": clip.duration, "contact_s": clip.contact_time, "contact_offset_m": str(clip.contact_offset), "hand_ball_gaps_m": gaps}
	test_visual_plan_latch(game)
	for family in counts: check(counts[family] >= 5, "At least five new distinct performances required: " + family)
	check(maximum_native_error < 0.0002, "New native clips differ from PSA sampling")
	check(maximum_gap <= 0.18, "New animation contact gap exceeded gameplay tolerance")
	check(maximum_transition_pop < 0.0002, "A new performance popped on entry from locomotion")
	check(maximum_limb_error < 0.005, "A new performance distorted arms or legs")
	var output := {"checks": checks, "counts": counts, "clip_total": game.clips.size(), "maximum_gap_m": maximum_gap, "maximum_native_error_m": maximum_native_error, "maximum_transition_pop_m": maximum_transition_pop, "maximum_limb_error_m": maximum_limb_error, "performances": report}
	var file := FileAccess.open("res://docs/v24-expanded-animations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	print("EXPANDED ANIMATIONS ", "FAIL" if failed else "PASS", ": ", JSON.stringify({"checks": checks, "counts": counts, "maximum_gap_m": maximum_gap, "maximum_native_error_m": maximum_native_error, "maximum_transition_pop_m": maximum_transition_pop, "maximum_limb_error_m": maximum_limb_error}))
	game.free()
	quit(1 if failed else 0)

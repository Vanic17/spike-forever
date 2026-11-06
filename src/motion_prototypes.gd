extends RefCounted
## Two authored, immutable PSA-compatible performances. No actor/ball writes.
## Generated once at startup; original PSA objects and native library are untouched.
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")
const Converter = preload("res://src/psa_animation_library.gd")
const Dive = preload("res://src/dive_motion41.gd")
const Attack = preload("res://src/attack_motion41.gd")
const NAMES := ["dive_authored41", "attack_adaptive41", "dump_push54", "receive_front75", "receive_left75", "receive_right75", "dive_hand75", "receive_low76", "receive_low_right76", "receive_slide77", "receive_slide_right77", "dive_slide77", "dive_slide_right77", "defense_miss77", "defense_miss_right77", "attack_reference78", "attack_reference_right78", "attack_middle79", "receive_platform80", "receive_braced80", "receive_knee80", "receive_knee_right80", "dive_platform80", "dive_roll80", "dive_roll_right80", "dive_pancake80", "attack_middle_style80", "attack_middle_style_right80", "set_disguise81"]
const AUTHORS := [Dive, Attack, preload("res://src/dump_motion54.gd"),preload("res://src/defense_front75.gd"),preload("res://src/defense_left75.gd"),preload("res://src/defense_right75.gd"),preload("res://src/defense_hand75.gd"),preload("res://src/defense_low76.gd"),preload("res://src/defense_low_right76.gd"),preload("res://src/defense_slide77.gd"),preload("res://src/defense_slide_right77.gd"),preload("res://src/defense_dive77.gd"),preload("res://src/defense_dive_right77.gd"),preload("res://src/defense_miss77.gd"),preload("res://src/defense_miss_right77.gd"),preload("res://src/attack_reference78.gd"),preload("res://src/attack_reference_right78.gd"),preload("res://src/attack_middle79.gd"),preload("res://src/defense_platform80.gd"),preload("res://src/defense_braced80.gd"),preload("res://src/defense_knee80.gd"),preload("res://src/defense_knee_right80.gd"),preload("res://src/defense_dive_platform80.gd"),preload("res://src/defense_roll80.gd"),preload("res://src/defense_roll_right80.gd"),preload("res://src/defense_pancake80.gd"),preload("res://src/attack_middle_style80.gd"),preload("res://src/attack_middle_style_right80.gd"),preload("res://src/set_disguise_motion81.gd")]
const LIBRARY_PATH := "res://assets/active/native_motion81.res"
const FORMAT := 9
static var enabled := not "--motion-original" in OS.get_cmdline_user_args()
static var generated: Dictionary = {}
static var combined: AnimationLibrary
static var combined_signature := ""

static func register(bank: Dictionary) -> void:
	for i in NAMES.size():
		var name: String = NAMES[i]
		var author = AUTHORS[i]
		if not bank.has(author.SOURCE): continue
		if not generated.has(name): generated[name] = author_clip(bank[author.SOURCE], author, name)
		bank[name] = generated[name]

static func normalized(clip, time: float, loop: bool = false) -> Array[Transform3D]:
	var pose: Array[Transform3D] = clip.pose(time, loop)
	var source_root := pose[0].origin
	var offset: Vector3 = Vector3(-source_root.x, -clip.ground_y * 100, source_root.y) * 0.01 - clip.body_center
	var jump_phase: float = (time - clip.contact_time) / 0.36
	offset.y += clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
	for bone in pose.size():
		pose[bone] = PSK.to_godot(pose[bone])
		pose[bone].origin += offset
	return pose

static func author_clip(base, author, label: String):
	var clip = PSA.new()
	for property in ["names","parents","frames","fps","duration","contact_time","ground_y","contact_offset","jump_boost","travel_speed","body_center","recovery_end","takeoff_time","toss_release_time"]:
		clip.set(property, base.get(property))
	if label=="dive_pancake80":clip.contact_time=minf(base.duration-.70,base.contact_time+.72)
	clip.source = "authored41/" + label + " from " + base.source
	clip.positions.resize(base.positions.size())
	clip.rotations.resize(base.rotations.size())
	var axis_inverse := PSK.axis.inverse()
	for frame in clip.frames:
		var time: float = float(frame) / clip.fps
		var mapped: float = author.source_time(time, clip.contact_time, clip.duration)
		var pose: Array[Transform3D] = normalized(base, mapped)
		if label in ["dive_slide77","dive_slide_right77","defense_miss77","defense_miss_right77"] and time>clip.contact_time+.14:
			pose=preload("res://src/defense_dive77.gd").recovery_pose(pose,normalized(base,clip.contact_time+.14),normalized(base,clip.duration-.025),clip.names,clip.parents,time,clip.contact_time,clip.duration)
		pose = author.shape(pose, clip.names, clip.parents, time, clip.contact_time, clip.duration)
		# Restore source coordinates before storing local ActorX channels. The
		# root travel remains EXACTLY the original and is owned by main.gd.
		var original_root: Vector3 = base.pose(time, false)[0].origin
		var offset: Vector3 = Vector3(-original_root.x, -clip.ground_y * 100, original_root.y) * 0.01 - clip.body_center
		var jump_phase: float = (time - clip.contact_time) / 0.36
		offset.y += clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
		for bone in clip.names.size():
			var local := pose[bone]
			var parent: int = clip.parents[bone]
			if parent >= 0 and parent < bone:
				local = pose[parent].affine_inverse() * local
			else:
				local.origin -= offset
			var index: int = frame * clip.names.size() + bone
			clip.positions[index] = axis_inverse * local.origin * 100.0
			clip.rotations[index] = (axis_inverse * local.basis * PSK.axis).get_rotation_quaternion().normalized()
		# No visual root travel: preserve the exact physical displacement table.
		clip.positions[frame * clip.names.size()].x = base.positions[frame * clip.names.size()].x
		clip.positions[frame * clip.names.size()].y = base.positions[frame * clip.names.size()].y
	if label=="set_disguise81":
		var contact_pose:=normalized(clip,clip.contact_time)
		clip.contact_offset=(contact_pose[clip.names.find("LeftHand")].origin+contact_pose[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
	if label=="dump_push54":
		var contact_pose:=normalized(clip,clip.contact_time)
		clip.contact_offset=contact_pose[clip.names.find("LeftHand")].origin
	if label in ["receive_low76","receive_low_right76","receive_slide77","receive_slide_right77"]:
		var contact_pose:=normalized(clip,clip.contact_time)
		clip.contact_offset=(contact_pose[clip.names.find("LeftHand")].origin+contact_pose[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
	if label in ["receive_platform80","receive_braced80","receive_knee80","receive_knee_right80"]:
		var contact_pose:=normalized(clip,clip.contact_time)
		clip.contact_offset=(contact_pose[clip.names.find("LeftHand")].origin+contact_pose[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
	if label in ["dive_platform80","dive_pancake80"]:
		var contact_pose:=normalized(clip,clip.contact_time)
		clip.contact_offset=contact_pose[clip.names.find("RightHand")].origin+Vector3(0,.105 if label=="dive_pancake80" else 0,.085)
	if label in ["dive_roll80","dive_roll_right80"]:clip.recovery_end=minf(base.duration,clip.contact_time+1.47)
	if label in ["dive_slide77","dive_slide_right77","defense_miss77","defense_miss_right77"]:
		clip.recovery_end=minf(base.recovery_end,clip.contact_time+1.10)
	return clip

static func signature(bank: Dictionary) -> String:
	var parts: Array = [FORMAT]
	for name in NAMES:
		if bank.has(name):
			var clip = bank[name]
			parts.append([name, clip.source, hash(clip.positions), hash(clip.rotations), clip.contact_time, clip.jump_boost])
	return str(hash(parts))

static func supplement(bank: Dictionary) -> AnimationLibrary:
	var stamp := signature(bank)
	if ResourceLoader.exists(LIBRARY_PATH):
		var saved = ResourceLoader.load(LIBRARY_PATH, "AnimationLibrary")
		if saved is AnimationLibrary and saved.get_meta("motion_signature", "") == stamp: return saved
	var library := AnimationLibrary.new()
	for name in NAMES:
		if bank.has(name):
			library.add_animation(name, Converter.make_animation(bank[name], func(time: float): return normalized(bank[name], time)))
	library.set_meta("motion_signature", stamp)
	return library

static func with_supplement(base: AnimationLibrary, bank: Dictionary) -> AnimationLibrary:
	if not bank.has(NAMES[0]) and not bank.has(NAMES[1]): return base
	var stamp := str(base.get_instance_id()) + ":" + signature(bank)
	if combined != null and stamp == combined_signature: return combined
	var library := AnimationLibrary.new()
	for name in base.get_animation_list(): library.add_animation(name, base.get_animation(name))
	var extra := supplement(bank)
	for name in extra.get_animation_list(): library.add_animation(name, extra.get_animation(name))
	combined = library
	combined_signature = stamp
	return library

static func dive_variant(original: String, local_ball: Vector3, velocity: Vector3, height: float, seconds: float) -> String:
	if not enabled or "--motion-attack-only" in OS.get_cmdline_user_args(): return original
	# One prototype only: forward one-hand defence, never a sideways/backward
	# fall chosen because of a random serial. Lateral PSA saves remain available.
	if original == Dive.SOURCE and local_ball.z > 0.15 and absf(local_ball.x) < 0.65 and height < 1.0 and velocity.length() > 5.0 and seconds >= 0.12:
		return NAMES[0]
	return original

static func attack_variant(original: String, direction: int, quality: float, serial: int = -1) -> String:
	if not enabled or "--motion-dive-only" in OS.get_cmdline_user_args(): return original
	if direction in [0,2,3] and quality>=.66 and serial>=0 and posmod(serial,3)==1:
		if original=="attack_pin_left":return "attack_reference78"
		if original=="attack_pin_right":return "attack_reference_right78"
	if direction in [0,2,3] and quality>=.66 and serial>=0 and posmod(serial,3)==2:
		if original=="attack_pin_left":return "attack_middle_style80"
		if original=="attack_pin_right":return "attack_middle_style_right80"
	# Replace only the matching source performance. Its unchanged contact,
	# root travel and recovery metadata preserve the planned ball trajectory
	# and actor deadline. Other approaches, middle attacks and tips stay intact.
	return NAMES[1] if original == Attack.SOURCE and direction in [0, 2, 3] and quality >= 0.72 else original

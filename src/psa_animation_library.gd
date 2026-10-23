extends RefCounted
## Immutable native clips. No gameplay events, node motion or scale tracks.
## The gameplay clock and procedural jump arc remain owned by Avatar.
const CLIPS := ["idle","run","ready","block_ready","relaxed","walk","backwalk","backpedal","receive","set","fast_set","attack","block","float","power","serve_idle","run_right","shuffle_left","shuffle_right","dump","recovery","dive","attack_line","attack_left","set_back","fast_set_back","receive_follow","receive_left_up","receive_right_up","dive_short","attack_decoy","cross_left","cross_right","receive_low","receive_squat","receive_step","receive_left_step","receive_right_step","set_left_front","set_left_back","set_running_front","attack_angle_left","attack_angle_right","attack_pin_left","attack_pin_right","set_short_front","attack_turn","set_short_back","attack_v26_01","attack_v26_02","attack_v26_03","backpedal_v26_01","backwalk_v26_01","block_ready_v26_01","block_v26_01","block_v26_02","block_v26_03","block_v26_05","block_v26_06","block_v26_07","cross_left_v26_01","cross_right_v26_01","dive_v26_01","dive_v26_02","dive_v26_03","dive_v26_04","dive_v26_05","dive_v26_06","fast_set_v26_01","fast_set_v26_02","fast_set_v26_03","fast_set_v26_04","fast_set_v26_05","fast_set_v26_06","fast_set_v26_07","fast_set_v26_08","fast_set_v26_09","fast_set_v26_10","fast_set_v26_11","ready_v26_01","ready_v26_02","ready_v26_03","ready_v26_04","ready_v26_05","ready_v26_06","ready_v26_07","receive_v26_01","receive_v26_02","receive_v26_03","receive_v26_04","receive_v26_05","receive_v26_06","receive_v26_07","receive_v26_08","receive_v26_09","receive_v26_10","receive_v26_11","receive_v26_12","receive_v26_13","receive_v26_14","receive_v26_15","receive_v26_16","receive_v26_17","receive_v26_18","receive_v26_19","receive_v26_20","relaxed_v26_01","relaxed_v26_02","relaxed_v26_03","relaxed_v26_04","relaxed_v26_05","relaxed_v26_06","run_v26_01","run_v26_02","run_v26_03","run_v26_04","set_v26_01","set_v26_02","set_v26_03","set_v26_04","set_v26_05","set_v26_06","shuffle_left_v26_01","shuffle_right_v26_01","walk_v26_01","wall_shuffle_left","wall_shuffle_right"]
const FORMAT_VERSION := 2
const LIBRARY_PATH := "res://assets/active/native_all.res"
static var cached: AnimationLibrary
static var cached_signature := ""

static func make_animation(clip, sample: Callable) -> Animation:
	var animation := Animation.new()
	animation.length = maxf(clip.duration, 0.001)
	# Loop wrapping remains explicitly driven by the existing gameplay clock.
	for bone in clip.names.size():
		for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D]:
			var track := animation.add_track(type)
			animation.track_set_path(track, NodePath("Rig:" + clip.names[bone]))
	for frame in clip.frames:
		var time: float = float(frame) / clip.fps
		var pose: Array[Transform3D] = sample.call(time)
		# A parabola baked at source keyframe rate changes the contact height
		# between keys. Keep this existing correction analytic, not keyframed.
		var jump_phase: float = (time - clip.contact_time) / 0.36
		var jump_height: float = clip.jump_boost * maxf(0, 1.0 - jump_phase * jump_phase)
		for bone in clip.names.size():
			var local := pose[bone]
			var parent: int = clip.parents[bone]
			if parent >= 0 and parent < bone:
				local = pose[parent].affine_inverse() * local
			else:
				local.origin.y -= jump_height
			animation.position_track_insert_key(bone * 2, time, local.origin)
			animation.rotation_track_insert_key(bone * 2 + 1, time, local.basis.get_rotation_quaternion())
	animation.set_meta("psa_source", clip.source)
	animation.set_meta("contact_time", clip.contact_time)
	animation.set_meta("jump_boost", clip.jump_boost)
	animation.set_meta("root_travel", "removed horizontally; gameplay owns actor transform")
	return animation

static func signature(bank: Dictionary) -> String:
	var parts: Array = [FORMAT_VERSION]
	for name in CLIPS:
		if not bank.has(name): continue
		var clip = bank[name]
		parts.append([name, clip.source, clip.frames, clip.fps, clip.contact_time, clip.jump_boost, clip.ground_y, clip.body_center, hash(clip.names), hash(clip.parents), hash(clip.positions), hash(clip.rotations)])
	return str(hash(parts))

static func build(bank: Dictionary, sampler: Callable) -> AnimationLibrary:
	var bank_signature := signature(bank)
	if cached != null and cached_signature == bank_signature: return cached
	# The converter tool writes this resource once. Loading immutable clips is
	# substantially cheaper than rebuilding all native clips at match start.
	if ResourceLoader.exists(LIBRARY_PATH):
		var saved = ResourceLoader.load(LIBRARY_PATH, "AnimationLibrary")
		if saved is AnimationLibrary and saved.get_meta("psa_signature", "") == bank_signature:
			cached = saved
			cached_signature = bank_signature
			return cached
	var library := AnimationLibrary.new()
	for name in CLIPS:
		if bank.has(name):
			library.add_animation(name, make_animation(bank[name], func(time: float): return sampler.call(name, time, false)))
	library.set_meta("psa_signature", bank_signature)
	library.set_meta("converter_version", FORMAT_VERSION)
	cached = library
	cached_signature = bank_signature
	return library

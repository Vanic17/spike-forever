extends Node3D
## Immutable native clips evaluated on a private rig. Corrected pose layers
## stay in local space on CPU: never mutate Animation tracks during playback.
const Converter = preload("res://src/psa_animation_library.gd")
var rig: Skeleton3D
var player: AnimationPlayer
var tree: AnimationTree
var first: AnimationNodeAnimation
var library: AnimationLibrary
var names: Array[String] = []
var parents: Array[int] = []
var lower_mask := PackedByteArray()
var upper_mask := PackedByteArray()
var initialized := false
var evaluations := 0
var sample_cache: Dictionary = {}
var cache_hits := 0

func setup(bank: Dictionary, sampler: Callable) -> void:
	if not bank.has("idle"): return
	names = bank.idle.names
	parents = bank.idle.parents
	for clip_name in Converter.CLIPS:
		if bank.has(clip_name) and (bank[clip_name].names != names or bank[clip_name].parents != parents):
			push_warning("Native animation disabled: incompatible PSA hierarchy: " + clip_name)
			return
	rig = Skeleton3D.new()
	rig.name = "Rig"
	add_child(rig)
	for i in names.size():
		rig.add_bone(names[i])
		if i > 0: rig.set_bone_parent(i, parents[i])
		var lower := names[i] == "Hips"
		var upper := false
		var ancestor := i
		while ancestor > 0:
			if names[ancestor] in ["LeftUpLeg", "RightUpLeg"]: lower = true
			if names[ancestor] == "Spine": upper = true
			ancestor = parents[ancestor]
		lower_mask.append(1 if lower else 0)
		upper_mask.append(1 if upper else 0)
	player = AnimationPlayer.new()
	player.name = "Clips"
	add_child(player)
	library = Converter.build(bank, sampler)
	player.add_animation_library("psa", library)
	var graph := AnimationNodeBlendTree.new()
	first = AnimationNodeAnimation.new()
	first.animation = "psa/idle"
	graph.add_node("Clip", first)
	graph.add_node("Seek", AnimationNodeTimeSeek.new())
	graph.connect_node("Seek", 0, "Clip")
	graph.connect_node("output", 0, "Seek")
	tree = AnimationTree.new()
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.tree_root = graph
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	var expected: Array[Transform3D] = sampler.call("idle", 0.123, false)
	var actual := sample("idle", 0.123, false)
	for bone in expected.size():
		if expected[bone].origin.distance_to(actual[bone].origin) > 0.001 or expected[bone].basis.get_rotation_quaternion().angle_to(actual[bone].basis.get_rotation_quaternion()) > 0.002:
			push_warning("Native animation validation failed; retaining PSA fallback")
			return
	initialized = true

func begin_pose() -> void:
	# Cache scope is one displayed pose. Procedural corrections mutate returned
	# arrays, so the stored sample is always copied on retrieval.
	sample_cache.clear()

func sample(name: String, time: float, loop: bool) -> Array[Transform3D]:
	var animation := library.get_animation(name)
	var t := fposmod(time, animation.length) if loop else clampf(time, 0, animation.length)
	var key := [name, time, loop]
	if sample_cache.has(key):
		cache_hits += 1
		return sample_cache[key].duplicate()
	var native_name := "psa/" + name
	if first.animation != native_name: first.animation = native_name
	tree.set("parameters/Seek/seek_request", t)
	tree.advance(0)
	evaluations += 1
	var result: Array[Transform3D] = []
	for bone in names.size():
		var local := rig.get_bone_pose(bone)
		var parent := parents[bone]
		result.append(result[parent] * local if parent >= 0 and parent < bone else local)
	var jump_phase: float = (time - float(animation.get_meta("contact_time", 0.0))) / 0.36
	var jump_height: float = float(animation.get_meta("jump_boost", 0.0)) * maxf(0, 1.0 - jump_phase * jump_phase)
	if jump_height > 0:
		for bone in result.size(): result[bone].origin.y += jump_height
	if sample_cache.size() >= 12: sample_cache.clear()
	sample_cache[key] = result.duplicate()
	return result

func mix(a: Array[Transform3D], b: Array[Transform3D], weight: float, lower_only: bool = false, upper_only: bool = false) -> Array[Transform3D]:
	if weight <= 0: return a
	if weight >= 1 and not lower_only and not upper_only: return b
	var result: Array[Transform3D] = []
	for bone in names.size():
		var local_a := a[bone]
		var local_b := b[bone]
		var parent := parents[bone]
		if parent >= 0 and parent < bone:
			local_a = a[parent].affine_inverse() * local_a
			local_b = b[parent].affine_inverse() * local_b
		var enabled := (not lower_only or lower_mask[bone] != 0) and (not upper_only or upper_mask[bone] != 0)
		var local := local_a
		if enabled:
			local = Transform3D(Basis(local_a.basis.get_rotation_quaternion().slerp(local_b.basis.get_rotation_quaternion(), weight)), local_a.origin.lerp(local_b.origin, weight))
		result.append(result[parent] * local if parent >= 0 and parent < bone else local)
	return result

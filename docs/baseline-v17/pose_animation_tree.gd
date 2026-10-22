extends Node3D
## AnimationTree writes ONLY this private evaluation rig. Avatar is the sole
## writer of the visible rig, after feet/head/contact corrections.
const Converter = preload("res://src/psa_animation_library.gd")
var rig: Skeleton3D
var player: AnimationPlayer
var tree: AnimationTree
var graph: AnimationNodeBlendTree
var first: AnimationNodeAnimation
var second: AnimationNodeAnimation
var blend: AnimationNodeBlend2
var library: AnimationLibrary
var snapshots: Array[Animation] = []
var names: Array[String] = []
var parents: Array[int] = []
var initialized := false
var evaluations := 0
var configured_mask := ""

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
	player = AnimationPlayer.new()
	player.name = "Clips"
	add_child(player)
	library = Converter.build(bank, sampler)
	player.add_animation_library("psa", library)
	var dynamic := AnimationLibrary.new()
	for label in ["a", "b"]:
		var animation := Animation.new()
		animation.length = 1.0
		for bone in names.size():
			for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D]:
				var track := animation.add_track(type)
				animation.track_set_path(track, NodePath("Rig:" + names[bone]))
				animation.track_insert_key(track, 0, Vector3.ZERO if type == Animation.TYPE_POSITION_3D else Quaternion.IDENTITY)
		snapshots.append(animation)
		dynamic.add_animation(label, animation)
	player.add_animation_library("poses", dynamic)
	graph = AnimationNodeBlendTree.new()
	first = AnimationNodeAnimation.new()
	second = AnimationNodeAnimation.new()
	first.animation = "psa/idle"
	second.animation = "psa/idle"
	graph.add_node("A", first)
	graph.add_node("B", second)
	graph.add_node("SeekA", AnimationNodeTimeSeek.new())
	graph.add_node("SeekB", AnimationNodeTimeSeek.new())
	blend = AnimationNodeBlend2.new()
	graph.add_node("Blend", blend)
	graph.connect_node("SeekA", 0, "A")
	graph.connect_node("SeekB", 0, "B")
	graph.connect_node("Blend", 0, "SeekA")
	graph.connect_node("Blend", 1, "SeekB")
	graph.connect_node("output", 0, "Blend")
	tree = AnimationTree.new()
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.tree_root = graph
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	# Validate the converted basis and units before enabling this backend.
	var expected: Array[Transform3D] = sampler.call("idle", 0.123, false)
	var actual := sample("idle", 0.123, false)
	for bone in expected.size():
		if expected[bone].origin.distance_to(actual[bone].origin) > 0.001 or expected[bone].basis.get_rotation_quaternion().angle_to(actual[bone].basis.get_rotation_quaternion()) > 0.002:
			push_warning("Native animation validation failed; retaining PSA fallback")
			return
	initialized = true

func sample(name: String, time: float, loop: bool) -> Array[Transform3D]:
	var animation := library.get_animation(name)
	var t := fposmod(time, animation.length) if loop else clampf(time, 0, animation.length)
	first.animation = "psa/" + name
	second.animation = first.animation
	blend.filter_enabled = false
	return evaluate(t, t, 0.0)

func mix(a: Array[Transform3D], b: Array[Transform3D], weight: float, lower_only: bool = false, upper_only: bool = false) -> Array[Transform3D]:
	if weight <= 0: return a
	if weight >= 1 and not lower_only and not upper_only: return b
	var reference: Array[Transform3D] = []
	for bone in names.size():
		var local_a := a[bone]
		var local_b := b[bone]
		var parent := parents[bone]
		if parent >= 0 and parent < bone:
			local_a = a[parent].affine_inverse() * local_a
			local_b = b[parent].affine_inverse() * local_b
		reference.append(local_a)
		# Godot 4.5 accumulates rotations relative to RESET/rest. Evaluate
		# deltas around identity, then restore the outgoing local reference.
		# This preserves shortest-arc interpolation even for a rotated pelvis.
		snapshots[1].track_set_key_value(bone * 2, 0, local_b.origin - local_a.origin)
		snapshots[1].track_set_key_value(bone * 2 + 1, 0, local_a.basis.get_rotation_quaternion().inverse() * local_b.basis.get_rotation_quaternion())
	first.animation = "poses/a"
	second.animation = "poses/b"
	blend.filter_enabled = lower_only or upper_only
	var requested_mask := "lower" if lower_only else "upper"
	if blend.filter_enabled and configured_mask != requested_mask:
		for bone in names.size():
			var ancestor := bone
			var lower := names[bone] == "Hips"
			var upper := false
			while ancestor > 0:
				if names[ancestor] in ["LeftUpLeg", "RightUpLeg"]: lower = true
				if names[ancestor] == "Spine": upper = true
				ancestor = parents[ancestor]
			blend.set_filter_path(NodePath("Rig:" + names[bone]), lower if lower_only else upper)
		configured_mask = requested_mask
	evaluate(0, 0, weight)
	var result: Array[Transform3D] = []
	for bone in names.size():
		var delta := rig.get_bone_pose(bone)
		var local := Transform3D(reference[bone].basis * delta.basis, reference[bone].origin + delta.origin)
		var parent := parents[bone]
		result.append(result[parent] * local if parent >= 0 and parent < bone else local)
	return result

func evaluate(a_time: float, b_time: float, weight: float) -> Array[Transform3D]:
	tree.set("parameters/SeekA/seek_request", a_time)
	tree.set("parameters/SeekB/seek_request", b_time)
	tree.set("parameters/Blend/blend_amount", weight)
	tree.advance(0)
	evaluations += 1
	var result: Array[Transform3D] = []
	for bone in names.size():
		var local := rig.get_bone_pose(bone)
		var parent := parents[bone]
		result.append(result[parent] * local if parent >= 0 and parent < bone else local)
	return result

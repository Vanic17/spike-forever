extends Node3D
## Original sampled skeleton animation drives a simple segmented athlete.
## These meshes are original placeholders, not the source game's player models.
var clips: Dictionary
var clip_name := "idle"
var animation_time := 0.0
var animation_speed := 1.0
var looping := true
var team := 0
var number := 1
var segments: Array[Dictionary] = []
var joints: Dictionary = {}
var label: Label3D
var root_height := 0.0
var tint: Color
var target := Vector3.ZERO
var visual_root: Node3D
var indicator: MeshInstance3D
var motion_lock := 0.0
var skeleton: Skeleton3D
var model_bank: Dictionary = {}
var animation_bones: Array[int] = []
const PSK = preload("res://src/psk.gd")

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.75
	return m

func setup(bank: Dictionary, side: int, jersey: int, models: Dictionary = {}) -> void:
	clips = bank
	team = side
	number = jersey
	tint = Color("18c5d5") if side == 0 else Color("f26b44")
	visual_root = Node3D.new()
	add_child(visual_root)
	var skin := material(Color("d7a27a"))
	var shirt := material(tint)
	var shorts := material(Color("102639") if side == 0 else Color("361e2a"))
	var shoe := material(Color("e4eef0"))
	var spec := [
		["Hips", "Spine2", 0.21, shirt],
		["Spine2", "Neck", 0.15, shirt],
		["LeftArm", "LeftForeArm", 0.074, skin],
		["LeftForeArm", "LeftHand", 0.06, skin],
		["RightArm", "RightForeArm", 0.074, skin],
		["RightForeArm", "RightHand", 0.06, skin],
		["Spine2", "LeftArm", 0.115, shirt],
		["Spine2", "RightArm", 0.115, shirt],
		["LeftUpLeg", "LeftLeg", 0.105, shorts],
		["RightUpLeg", "RightLeg", 0.105, shorts],
		["LeftLeg", "LeftFoot", 0.072, skin],
		["RightLeg", "RightFoot", 0.072, skin],
		["LeftFoot", "LeftToeBase", 0.08, shoe],
		["RightFoot", "RightToeBase", 0.08, shoe]]
	var idle = clips.get("idle")
	if idle == null:
		var fallback := MeshInstance3D.new()
		fallback.mesh = CapsuleMesh.new()
		fallback.position.y = 1
		fallback.material_override = shirt
		add_child(fallback)
		return
	for item in spec:
		var a: int = idle.names.find(item[0])
		var b: int = idle.names.find(item[1])
		if a < 0 or b < 0:
			continue
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = item[2] * 0.85
		mesh.bottom_radius = item[2]
		mesh.height = 1
		mesh.radial_segments = 8
		node.mesh = mesh
		node.material_override = item[3]
		visual_root.add_child(node)
		segments.append({"a": a, "b": b, "node": node})
	for bone in ["Head", "LeftHand", "RightHand"]:
		var idx: int = idle.names.find(bone)
		if idx < 0:
			continue
		var sphere := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.125 if bone == "Head" else 0.065
		mesh.height = mesh.radius * 2
		mesh.radial_segments = 12
		mesh.rings = 6
		sphere.mesh = mesh
		sphere.material_override = skin
		visual_root.add_child(sphere)
		joints[idx] = sphere
	label = Label3D.new()
	label.text = str(number)
	label.font_size = 40
	label.pixel_size = 0.007
	label.position.y = 2.35
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint.lightened(0.4)
	add_child(label)
	indicator = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.38
	ring.outer_radius = 0.44
	ring.rings = 20
	ring.ring_segments = 6
	indicator.mesh = ring
	indicator.position.y = 0.025
	indicator.material_override = material(Color("fff0a6"))
	add_child(indicator)
	indicator.visible = false
	animation_time = randf() * idle.duration
	if models.has("body"):
		model_bank = models
		for seg in segments: seg.node.visible = false
		for joint in joints.values(): joint.visible = false
		setup_original_meshes(skin, shirt)

func setup_original_meshes(skin: Material, shirt: Material) -> void:
	var body = model_bank.body
	skeleton = Skeleton3D.new()
	visual_root.add_child(skeleton)
	for i in body.names.size():
		skeleton.add_bone(body.names[i])
		if i > 0: skeleton.set_bone_parent(i, body.parents[i])
		skeleton.set_bone_rest(i, body.rest[i])
		animation_bones.append(clips.idle.names.find(body.names[i]))
	skeleton.reset_bone_poses()
	var bind := skeleton.create_skin_from_rest_transforms()
	for name in model_bank:
		var node := MeshInstance3D.new()
		node.mesh = model_bank[name].mesh
		node.skin = bind
		visual_root.add_child(node)
		node.skeleton = node.get_path_to(skeleton)
		var material: StandardMaterial3D = (shirt if name == "cloth" else skin).duplicate()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		node.material_override = material
		# Motion can leave the rest-pose AABB during takeoff and floor defense.
		node.extra_cull_margin = 3.0

func play(action: String, speed: float = 1.0, loop: bool = false) -> void:
	if not clips.has(action):
		return
	if clip_name != action or not looping:
		animation_time = 0
	clip_name = action
	animation_speed = speed
	looping = loop

func prepare_contact(action: String, remaining: float) -> void:
	if not clips.has(action): return
	var clip = clips[action]
	clip_name = action
	looping = false
	animation_speed = 1.4
	animation_time = maxf(0, clip.contact_time - maxf(0, remaining) * animation_speed)

func tick(dt: float, selected: bool) -> void:
	if indicator:
		indicator.visible = selected
	animation_time += dt * animation_speed
	var clip = clips.get(clip_name)
	if clip == null:
		return
	if not looping and animation_time > clip.duration:
		play("idle", 1, true)
		clip = clips.get("idle")
	var pose: Array[Transform3D] = clip.pose(animation_time, looping)
	if skeleton:
		var body = model_bank.body
		for i in body.names.size():
			var idx := animation_bones[i]
			if idx < 0: continue
			var world: Transform3D = pose[idx]
			if i > 0:
				var parent_idx := animation_bones[body.parents[i]]
				if parent_idx >= 0: world = pose[parent_idx].affine_inverse() * world
			else:
				world.origin.x = 0
				world.origin.y = 0
			var local := PSK.to_godot(world)
			skeleton.set_bone_pose_position(i, local.origin)
			skeleton.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
		return
	var points := PackedVector3Array()
	points.resize(pose.size())
	var origin: Vector3 = pose[0].origin
	for i in pose.size():
		var p := pose[i].origin - Vector3(origin.x, origin.y, 0)
		points[i] = Vector3(p.x, p.z, -p.y) * 0.01
	for segment in segments:
		var a: Vector3 = points[segment.a]
		var b: Vector3 = points[segment.b]
		var node: MeshInstance3D = segment.node
		node.position = (a + b) * 0.5
		var delta := b - a
		if delta.length() > 0.0001:
			var axis := delta.normalized()
			var right := axis.cross(Vector3.FORWARD).normalized()
			if right.length_squared() < 0.01:
				right = axis.cross(Vector3.RIGHT).normalized()
			node.basis = Basis(right, axis, right.cross(axis)).orthonormalized()
			node.scale.y = delta.length()
	for idx in joints:
		joints[idx].position = points[idx]

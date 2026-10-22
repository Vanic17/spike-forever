extends RefCounted
const PSK = preload("res://src/psk.gd")
const Assets = preload("res://src/source_assets.gd")

static func rotate_chain(pose: Array[Transform3D], rig: RefCounted, joint: int, direction: Vector3, child: int) -> void:
	var pivot := pose[joint].origin
	var turn := Basis(Quaternion((pose[child].origin - pivot).normalized(), direction.normalized()))
	for j in pose.size():
		var ancestor := j
		for hop in 32:
			if ancestor == joint:
				pose[j].origin = pivot + turn * (pose[j].origin - pivot)
				pose[j].basis = turn * pose[j].basis
				break
			if ancestor <= 0: break
			ancestor = rig.parents[ancestor]

static func create(variant: int) -> ArrayMesh:
	Assets.initialize()
	if not Assets.files.has("Female_Public_Preview.psk"): return null
	var rig = PSK.new()
	if not rig.load_file(Assets.files["Female_Public_Preview.psk"]): return null
	var rest: Array[Transform3D] = []
	for i in rig.names.size():
		rest.append(rest[rig.parents[i]] * rig.rest[i] if i > 0 else rig.rest[i])
	var pose: Array[Transform3D] = rest.duplicate()
	for i in pose.size(): pose[i].origin.y -= 0.43
	for side in ["Left", "Right"]:
		var thigh: int = rig.names.find(side + "UpLeg")
		var knee: int = rig.names.find(side + "Leg")
		var foot: int = rig.names.find(side + "Foot")
		rotate_chain(pose, rig, thigh, Vector3(0, -0.12, 1), knee)
		rotate_chain(pose, rig, knee, Vector3(0, -1, 0.05), foot)
		var arm: int = rig.names.find(side + "Arm")
		var elbow: int = rig.names.find(side + "ForeArm")
		var hand: int = rig.names.find(side + "Hand")
		var sign := -1 if side == "Right" else 1
		rotate_chain(pose, rig, arm, Vector3(sign * 0.12, -0.9, 0.3 + variant * 0.12), elbow)
		rotate_chain(pose, rig, elbow, Vector3(-sign * 0.3, -0.2 + variant * 0.15, 1), hand)
	var transforms: Array[Transform3D] = []
	for i in pose.size(): transforms.append(pose[i] * rest[i].affine_inverse())
	var result := ArrayMesh.new()
	for surface in rig.mesh.get_surface_count():
		var arrays: Array = rig.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for i in vertices.size():
			var position := Vector3.ZERO
			var normal := Vector3.ZERO
			for j in 4:
				var weight: float = weights[i * 4 + j]
				if weight <= 0: continue
				var bone: int = bones[i * 4 + j]
				position += transforms[bone] * vertices[i] * weight
				normal += transforms[bone].basis * normals[i] * weight
			vertices[i] = position
			normals[i] = normal.normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_BONES] = null
		arrays[Mesh.ARRAY_WEIGHTS] = null
		arrays[Mesh.ARRAY_TANGENT] = null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var name: String = rig.material_names[surface].to_lower()
		var material: StandardMaterial3D
		if "head" in name: material = Assets.material("TX_CROWD_F_Head01_C.png", "", Color.WHITE, 0.8)
		elif "pants" in name: material = Assets.material("SK_CROWD_F__Legs01_C.png", "", Color.WHITE, 0.9)
		else: material = Assets.material("SK_CROWD_F__Torso01_C.png", "", Color.WHITE, 0.9)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.vertex_color_use_as_albedo = true
		result.surface_set_material(surface, material)
	return result

extends RefCounted
## ActorX mesh reader: keeps the source mesh, bone weights and bind transforms.
const PSA = preload("res://src/psa.gd")
var names: Array[String] = []
var parents: Array[int] = []
var rest: Array[Transform3D] = []
var mesh: ArrayMesh
var triangle_count := 0
static var axis := Basis(Vector3.RIGHT, -PI / 2)

static func to_godot(t: Transform3D) -> Transform3D:
	return Transform3D(axis * t.basis * axis.inverse(), axis * t.origin * 0.01)

func load_file(path: String, target_names: Array[String] = []) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return false
	var points := PackedVector3Array()
	var wedges: Array = []
	var triangles := PackedInt32Array()
	var weights: Dictionary = {}
	while f.get_position() + 32 <= f.get_length():
		var tag := PSA.fixed_string(f, 20)
		f.get_32()
		var size := f.get_32()
		var count := f.get_32()
		var start := f.get_position()
		match tag:
			"PNTS0000":
				for i in count: points.append(axis * Vector3(f.get_float(), f.get_float(), f.get_float()) * 0.01)
			"VTXW0000":
				for i in count:
					f.seek(start + i * size)
					var index := f.get_32()
					var uv := Vector2(f.get_float(), f.get_float())
					wedges.append({"point": index, "uv": uv})
			"FACE0000":
				for i in count:
					f.seek(start + i * size)
					triangles.append(f.get_16())
					triangles.append(f.get_16())
					triangles.append(f.get_16())
			"REFSKELT":
				for i in count:
					f.seek(start + i * size)
					names.append(PSA.fixed_string(f, 64))
					f.get_32()
					f.get_32()
					parents.append(f.get_32())
					var q := Quaternion(f.get_float(), f.get_float(), f.get_float(), f.get_float()).normalized()
					if i > 0: q = q.inverse()
					var p := Vector3(f.get_float(), f.get_float(), f.get_float())
					rest.append(to_godot(Transform3D(Basis(q), p)))
			"RAWWEIGHTS":
				for i in count:
					var weight := f.get_float()
					var point := f.get_32()
					var bone := f.get_32()
					if not weights.has(point): weights[point] = []
					weights[point].append([bone, weight])
		f.seek(start + size * count)
	if points.is_empty() or names.is_empty(): return false
	var destination := names if target_names.is_empty() else target_names
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in triangles:
		var wedge: Dictionary = wedges[index]
		var influence: Array = weights.get(wedge.point, [[0, 1.0]])
		influence.sort_custom(func(a, b): return a[1] > b[1])
		var ids := PackedInt32Array([0, 0, 0, 0])
		var values := PackedFloat32Array([0, 0, 0, 0])
		var total := 0.0
		for i in mini(4, influence.size()):
			ids[i] = maxi(0, destination.find(names[influence[i][0]]))
			values[i] = influence[i][1]
			total += values[i]
		if total > 0:
			for i in 4: values[i] /= total
		st.set_bones(ids)
		st.set_weights(values)
		st.set_uv(wedge.uv)
		st.add_vertex(points[wedge.point])
	st.generate_normals()
	st.index()
	mesh = st.commit()
	triangle_count = triangles.size() / 3
	return true

extends SceneTree
var report: Array=[]
func _initialize():call_deferred("run")
func emit(st: SurfaceTool,a: Array,id: int,offset:=Vector3.ZERO):
	st.set_normal(a[Mesh.ARRAY_NORMAL][id]);st.set_uv(a[Mesh.ARRAY_TEX_UV][id]);st.add_vertex(a[Mesh.ARRAY_VERTEX][id]+offset)
func compact(a: Array,indices: PackedInt32Array) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for id in indices:emit(st,a,id)
	st.index();return st.commit()
func simplified(source: ArrayMesh,ratio: float) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for s in source.get_surface_count():
		var a=source.surface_get_arrays(s)
		var optimizer:=ImporterMesh.new();optimizer.add_surface(Mesh.PRIMITIVE_TRIANGLES,a);optimizer.generate_lods(60,25,[])
		var selected: PackedInt32Array=a[Mesh.ARRAY_INDEX];var target:=int(selected.size()*ratio);var distance: int=abs(selected.size()-target)
		for lod in optimizer.get_surface_lod_count(0):
			var candidate: PackedInt32Array=optimizer.get_surface_lod_indices(0,lod)
			if abs(candidate.size()-target)<distance:selected=candidate;distance=abs(candidate.size()-target)
		var part:=compact(a,selected);result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,part.surface_get_arrays(0))
	return result
func scan_head(source: ArrayMesh) -> ArrayMesh:
	var mesh:=ArrayMesh.new()
	for s in source.get_surface_count():
		var a=source.surface_get_arrays(s);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var ids: PackedInt32Array=a[Mesh.ARRAY_INDEX]
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in range(0,ids.size(),3):
			var center: Vector3=(v[ids[face]]+v[ids[face+1]]+v[ids[face+2]])/3
			# Remove the full skin head envelope, preserving the shirt neckline
			# and raised hands. The scan LOD is already reduced offline: another
			# unrestricted simplification here destroys its crown and eyelids.
			if s==0 and center.y>1.11 and center.y<1.53 and absf(center.x)<.23 and center.z<.34:continue
			for k in 3:emit(st,a,ids[face+k])
		st.index();st.commit(mesh)
	for part in ["head0","eyes0"]:
		var source_head: ArrayMesh=load("res://assets/art/quality89/"+part+".res")
		var a=source_head.surface_get_arrays(0);var ids: PackedInt32Array=a[Mesh.ARRAY_INDEX]
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for id in ids:emit(st,a,id,Vector3(0,-.47,0))
		st.index();st.commit(mesh)
	return mesh
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/art/quality89/crowd")
	for variant in 12:
		var source: ArrayMesh=load("res://src/crowd.gd").create(variant)
		for level in 4:
			var mesh: ArrayMesh=simplified(source,[.07,.23,.58,1.0][level])
			if level>=2 and variant in [4,11]:mesh=scan_head(mesh)
			assert(ResourceSaver.save(mesh,"res://assets/art/quality89/crowd/v%02d_l%d.res"%[variant,level],ResourceSaver.FLAG_COMPRESS)==OK)
			var tris:=0
			for s in mesh.get_surface_count():tris+=mesh.surface_get_array_index_len(s)/3
			report.append({"variant":variant,"level":level,"triangles":tris,"scan_head":level>=2 and variant in [4,11]})
	FileAccess.open("res://docs/crowd89-meshes.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"levels":report},"  "))
	print("CROWD89 BUILD PASS ",report.size());quit()

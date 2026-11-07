extends SceneTree
var report: Dictionary={}
func _initialize():call_deferred("run")
func compact(source: ArrayMesh,indices: PackedInt32Array) -> ArrayMesh:
	var a=source.surface_get_arrays(0);var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for id in indices:
		st.set_normal(a[Mesh.ARRAY_NORMAL][id]);st.set_uv(a[Mesh.ARRAY_TEX_UV][id])
		if a[Mesh.ARRAY_COLOR]!=null:st.set_color(a[Mesh.ARRAY_COLOR][id])
		st.set_bones(a[Mesh.ARRAY_BONES].slice(id*4,id*4+4));st.set_weights(a[Mesh.ARRAY_WEIGHTS].slice(id*4,id*4+4));st.add_vertex(a[Mesh.ARRAY_VERTEX][id])
	st.index();st.generate_tangents();return st.commit()
func save(name: String,mesh: ArrayMesh):
	assert(ResourceSaver.save(mesh,"res://assets/art/quality89/"+name+".res",ResourceSaver.FLAG_COMPRESS)==OK)
	report[name]={"triangles":mesh.surface_get_array_index_len(0)/3,"vertices":mesh.surface_get_array_len(0)}
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/art/quality89")
	var stats: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/athlete88-build.json"))
	for part in ["head","eyes"]:
		var source: ArrayMesh=load("res://assets/art/athlete88/"+part+".res")
		var optimizer:=ImporterMesh.new();optimizer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(0));optimizer.generate_lods(60,25,[])
		for level in 3:
			# Below 10k triangles this scan's disconnected eyelid/crown seams
			# collapse visibly. Keep the first stable LOD even on Low; other
			# geometry, hair, textures and crowd density still scale down.
			var target: int=([10000,20000,45000][level] if part=="head" else [400,1000,2000][level])*3
			var selected: PackedInt32Array=source.surface_get_arrays(0)[Mesh.ARRAY_INDEX];var distance: int=abs(selected.size()-target)
			for lod in optimizer.get_surface_lod_count(0):
				var indices: PackedInt32Array=optimizer.get_surface_lod_indices(0,lod)
				if abs(indices.size()-target)<distance:selected=indices;distance=abs(indices.size()-target)
			save(part+str(level),compact(source,selected))
	for part in ["hair","beard"]:
		var source: ArrayMesh=load("res://assets/art/athlete88/"+part+".res")
		var all_indices: PackedInt32Array=source.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		var count: int=int(stats.groom[part+"_strands"])
		for level in 3:
			var stride: int=[12,5,2][level] if part=="hair" else [24,12,4][level]
			var selected:=PackedInt32Array()
			for strand in range(0,count,stride):selected.append_array(all_indices.slice(strand*72,(strand+1)*72))
			if part=="hair":selected.append_array(all_indices.slice(count*72))
			save(part+str(level),compact(source,selected))
	var rig=load("res://src/psk.gd").new();assert(rig.load_file("res://assets/active/body.psk"))
	var appearance=load("res://src/player_appearance.gd")
	var names: Array=appearance.STYLES.values()+appearance.BEARDS.values()
	for name in names:
		var p=appearance.model(name,rig.names);var fitted:=ArrayMesh.new()
		for s in p.mesh.get_surface_count():
			var a=p.mesh.surface_get_arrays(s).duplicate(true);var points: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			for i in points.size():
				points[i].x*=.96 if not "Beard" in name else 1.08
				if points[i].z<0:points[i].z*=.62
			a[Mesh.ARRAY_VERTEX]=points;a[Mesh.ARRAY_TANGENT]=null
			var temp:=ArrayMesh.new();temp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
			var st:=SurfaceTool.new();st.create_from(temp,0);st.generate_normals();st.generate_tangents();st.commit(fitted)
		assert(ResourceSaver.save(fitted,"res://assets/art/quality89/fit_"+name+".res",ResourceSaver.FLAG_COMPRESS)==OK)
	FileAccess.open("res://docs/quality89-meshes.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"levels":report},"  "))
	print("QUALITY89 BUILD PASS ",JSON.stringify(report));quit()


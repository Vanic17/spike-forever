extends SceneTree
func _initialize():
	DirAccess.make_dir_recursive_absolute("res://assets/art/crowd82")
	var rows: Array=[]
	for variant in 12:
		var source=preload("res://src/crowd.gd").create(variant)
		var mesh:=ImporterMesh.new()
		for surface in source.get_surface_count():mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(surface))
		mesh.generate_lods(60,25,[])
		var levels:=0
		for surface in mesh.get_surface_count():levels+=mesh.get_surface_lod_count(surface)
		check_save(mesh.get_mesh(),"res://assets/art/crowd82/crowd_%02d.res"%variant)
		rows.append({"variant":variant,"lod_levels":levels})
	FileAccess.open("res://docs/arena82-lods.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("CROWD82 BUILD PASS ",rows);quit()
func check_save(mesh,path):assert(ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)

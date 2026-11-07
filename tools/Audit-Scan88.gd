extends SceneTree
func _initialize():call_deferred("run")
func run():
	var document=ClassDB.instantiate("FBXDocument");var state=ClassDB.instantiate("FBXState")
	assert(document!=null and state!=null)
	assert(document.append_from_file("res://assets/art/athlete88/source/Head.fbx",state)==OK)
	var scene=document.generate_scene(state);root.add_child(scene)
	var nodes=scene.find_children("*","MeshInstance3D",true,false)
	var data=[]
	for node in nodes:
		var mesh: ArrayMesh=node.mesh
		print("SCAN88 ",node.name," ",mesh.get_aabb()," ",node.global_transform," surfaces ",mesh.get_surface_count())
		for s in mesh.get_surface_count():
			var a=mesh.surface_get_arrays(s)
			data.append({"name":node.name,"vertices":Array(a[Mesh.ARRAY_VERTEX]).map(func(v):var p: Vector3=node.global_transform*v;return [p.x,p.y,p.z]),"normals":Array(a[Mesh.ARRAY_NORMAL]).map(func(v):var n: Vector3=(node.global_basis*v).normalized();return [n.x,n.y,n.z]),"uv":Array(a[Mesh.ARRAY_TEX_UV]).map(func(v):return [v.x,v.y]),"indices":Array(a[Mesh.ARRAY_INDEX])})
	FileAccess.open("res://.runtime/athlete88-scan.json",FileAccess.WRITE).store_string(JSON.stringify(data))
	quit()

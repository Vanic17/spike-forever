extends SceneTree
func _initialize():
	var m: ArrayMesh=load("res://assets/art/athlete88/head.res");var a=m.surface_get_arrays(0)
	var optimizer:=ImporterMesh.new();optimizer.add_surface(Mesh.PRIMITIVE_TRIANGLES,a);optimizer.generate_lods(60,25,[])
	var b=optimizer.get_surface_arrays(0)
	print("LOD89 VERTICES UNCHANGED ",a[Mesh.ARRAY_VERTEX]==b[Mesh.ARRAY_VERTEX]," indices unchanged ",a[Mesh.ARRAY_INDEX]==b[Mesh.ARRAY_INDEX]," before ",a[Mesh.ARRAY_VERTEX].size()," after ",b[Mesh.ARRAY_VERTEX].size())
	quit()

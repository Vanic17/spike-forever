extends SceneTree
func _initialize():
	var crowd=load("res://src/crowd.gd");var mesh=crowd.create(4)
	var rig=crowd.rigs["Male_Public_Preview.psk"]
	var rest: Array=[]
	for i in rig.names.size():rest.append(rig.rest[i] if i==0 else rest[rig.parents[i]]*rig.rest[i])
	print("CROWD89 HEAD ",rest[rig.names.find("Head")]," max ",mesh.get_aabb())
	for s in mesh.get_surface_count():print("CROWD89 SURFACE ",s," tris ",mesh.surface_get_array_index_len(s)/3)
	quit()

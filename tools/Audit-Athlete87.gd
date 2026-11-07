extends SceneTree
const PSK=preload("res://src/psk.gd")
func _initialize():
	var body=PSK.new();assert(body.load_file("res://assets/active/body.psk"))
	var report={"parts":{},"bones":body.names,"rest":body.rest.map(func(t):return str(t))}
	for name in ["head","body","cloth","eyes","shoes","new_head"]:
		var p=PSK.new()
		var path="res://assets/active/"+name+".psk" if name!="new_head" else "res://assets/art/athlete87/source/Game/CharactersV1/01_Character_BodyParts/01_Heads/SK_Char_Head_Tier1_M_Perrin.psk"
		assert(p.load_file(path,body.names))
		var surfaces=[]
		for s in p.mesh.get_surface_count():
			var a=p.mesh.surface_get_arrays(s)
			surfaces.append({"vertices":Array(a[Mesh.ARRAY_VERTEX]).map(func(v):return [v.x,v.y,v.z]),"normals":Array(a[Mesh.ARRAY_NORMAL]).map(func(v):return [v.x,v.y,v.z]),"bones":Array(a[Mesh.ARRAY_BONES]),"weights":Array(a[Mesh.ARRAY_WEIGHTS]),"indices":Array(a[Mesh.ARRAY_INDEX])})
		report.parts[name]={"path":path,"triangles":p.triangle_count,"bounds":str(p.mesh.get_aabb()),"materials":p.material_names,"surfaces":surfaces}
	FileAccess.open("res://.runtime/athlete87-source-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report))
	print("ATHLETE87 AUDIT PASS ",report.parts.new_head.bounds," ",report.parts.new_head.materials)
	quit()

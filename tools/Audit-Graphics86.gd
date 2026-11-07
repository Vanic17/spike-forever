extends SceneTree
func _initialize():call_deferred("run")
func run():
	var psk=load("res://src/psk.gd")
	var body=psk.new();assert(body.load_file("res://assets/active/body.psk"))
	var output={"engine":Engine.get_version_info(),"baseline":"0.85.0","parts":{},"asset_limits":["one generic athlete head","1024px face albedo","two base crowd bodies","existing hair-card geometry"],"source_files":{}}
	for part in ["body","head","cloth","eyes","hair","shoes"]:
		var model=psk.new();assert(model.load_file("res://assets/active/"+part+".psk",body.names))
		var m: ArrayMesh=model.mesh;var vertices:=0;var surfaces: Array=[]
		for i in m.get_surface_count():
			var a: Array=m.surface_get_arrays(i);vertices+=a[Mesh.ARRAY_VERTEX].size()
			surfaces.append({"vertices":a[Mesh.ARRAY_VERTEX].size(),"indices":a[Mesh.ARRAY_INDEX].size(),"bones":a[Mesh.ARRAY_BONES].size(),"weights":a[Mesh.ARRAY_WEIGHTS].size()})
		output.parts[part]={"triangles":model.triangle_count,"vertices":vertices,"bone_names":model.names,"bounds":str(m.get_aabb()),"surfaces":surfaces}
	for file in ["visual_graphics85.gd","arena.gd","arena_branding.gd","source_assets.gd","player_appearance.gd","crowd.gd","club_kit.gdshader","eye_surface85.gdshader","psk.gd"]:
		output.source_files[file]=FileAccess.get_sha256("res://src/"+file)
	FileAccess.open("res://docs/graphics86-audit.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("GRAPHICS86 AUDIT PASS");quit()

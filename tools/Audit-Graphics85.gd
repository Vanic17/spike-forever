extends SceneTree
func _initialize():call_deferred("run")
func run():
	var report: Dictionary={"engine":Engine.get_version_info(),"properties":{},"textures":{}}
	for subject in [StandardMaterial3D.new(),Environment.new(),SpotLight3D.new(),DirectionalLight3D.new(),ReflectionProbe.new()]:
		var fields: Dictionary={}
		for item in subject.get_property_list():
			var name: String=item.name
			if subject is ReflectionProbe or name.contains("subsurf") or name.contains("shadow") or name.contains("roughness") or name.contains("metallic") or name.contains("alpha_antialias") or name.contains("tonemap") or name.contains("ssao") or name.contains("ambient") or name.contains("angular") or name.contains("glow") or name.contains("intensity"):fields[name]=str(subject.get(name))
		report.properties[subject.get_class()]=fields
		if subject is Node:subject.free()
	var source=load("res://src/source_assets.gd");source.initialize()
	for part in ["eyes","head"]:
		var model=load("res://src/psk.gd").new();model.load_file("res://assets/active/"+part+".psk")
		print("GRAPHICS85 MODEL ",part," ",model.material_names," surfaces ",model.mesh.get_surface_count())
	for name in source.files:
		if name.contains("Rough") or name.contains("AORM") or name.contains("Taraflex") or name.contains("Head_Caucasian_M_02") or name.contains("Cloth_MyTeam_Normal"):
			if not name.ends_with(".png"):continue
			var image:=Image.load_from_file(source.files[name]);report.textures[name]={"size":str(image.get_size()),"path":source.files[name]}
	FileAccess.open("res://docs/graphics85-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAPHICS85 AUDIT PASS");quit()

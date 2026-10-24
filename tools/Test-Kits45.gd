extends SceneTree
const Kits=preload("res://src/club_kits.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: Dictionary=Kits.data()
	assert(catalog.clubs.size()==12)
	var count:=0
	for club in catalog.clubs:
		var record: Dictionary=catalog.clubs[club]
		for variant in ["home","away"]:
			var normal: Dictionary=Kits.selection(club,variant)
			var libero: Dictionary=Kits.selection(club,variant,true)
			assert(normal._club_id==club and normal._variant==variant)
			assert(libero._variant==("libero" if record.dedicated_libero else ("away" if variant=="home" else "home")))
			assert(normal.texture!=libero.texture,"Libero must contrast for "+club+" / "+variant)
		for variant in record.variants:
			var kit: Dictionary=record.variants[variant]
			assert(FileAccess.file_exists(kit.texture))
			assert(FileAccess.get_sha256(kit.texture)==kit.sha256)
			var image:=Image.load_from_file(kit.texture)
			assert(image.get_size()==Vector2i(2048,2048))
			count+=1
	assert(count==32)
	var psk=load("res://src/psk.gd").new()
	assert(psk.load_file("res://assets/active/cloth.psk"))
	var mesh: ArrayMesh=Kits.mesh_with_print_uv(psk.mesh)
	assert(mesh==Kits.mesh_with_print_uv(psk.mesh),"Shared mesh must be cached")
	for surface in psk.mesh.get_surface_count():
		var before: Array=psk.mesh.surface_get_arrays(surface)
		var after: Array=mesh.surface_get_arrays(surface)
		for attribute in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS,Mesh.ARRAY_INDEX]:
			if before[attribute]!=after[attribute]:
				print("MESH ATTRIBUTE ROUNDTRIP ",attribute," before=",before[attribute].size()," after=",after[attribute].size())
				var largest:=0.0
				for i in before[attribute].size():
					var a=before[attribute][i]; var b=after[attribute][i]
					largest=maxf(largest,a.distance_to(b) if a is Vector3 or a is Vector2 else absf(float(a)-float(b)))
				print("MESH ATTRIBUTE MAX DELTA ",attribute," ",largest)
				assert(largest<0.001 and attribute in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT],"Skinning and original UV changed")
		assert(after[Mesh.ARRAY_TEX_UV2].size()==before[Mesh.ARRAY_VERTEX].size())
	var avatar=load("res://src/avatar.gd").new()
	root.add_child(avatar)
	var person: Dictionary={"name":"NOME LOCALE ÈDITATO","jersey_number":99}
	var kit: Dictionary=Kits.selection("cisterna-volley","home")
	var material: ShaderMaterial=Kits.material(avatar,person,kit)
	assert(material==Kits.material(avatar,person,kit),"Repeated libero checks cannot allocate more textures")
	assert(Kits.materials.size()==1 and Kits.prints.size()==1)
	person.name="ALTRO NOME"; person.jersey_number=8
	var changed: ShaderMaterial=Kits.material(avatar,person,kit)
	assert(changed!=material and changed.get_shader_parameter("fabric")==material.get_shader_parameter("fabric"))
	assert(changed.get_shader_parameter("identity")!=material.get_shader_parameter("identity"))
	assert(Kits.fabrics.size()==1)
	var report={"clubs":12,"distinct_variants":count,"resolution":2048,"missing_libero_inverts":["allianz-milano","sir-susa-scai-perugia","tinet-prata-di-pordenone","vero-volley-monza"],"original_mesh_attributes_preserved":true,"local_identity_print_updates":true,"shared_fabric_cache":true}
	var output=FileAccess.open("res://docs/kits45-test-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")); output.close()
	print("KITS45 PASS: 12 clubs, 32 kits, both libero choices, mesh/weights/UV unchanged, editable identity and cached fabric")
	quit()

extends SceneTree
func _initialize():call_deferred("run")
func run():
	var code:=GDScript.new();var text:=FileAccess.get_file_as_string("res://tools/Build-Athlete87.gd")
	text=text.replace("extends SceneTree","extends RefCounted")
	var begin:=text.find("func _initialize():");var end:=text.find("func save(")
	text=text.substr(0,begin)+text.substr(end)
	text=text.replace("func strand_mesh(","func old_strand_mesh(")
	text=text.replace("random.randf_range(.003,.008) if beard","random.randf_range(.004,.012) if beard")
	text=text.replace("p.y>1.726","p.y>1.756")
	text+=FileAccess.get_file_as_string("res://tools/Groom88.gdpart")
	code.source_code=text;assert(code.reload()==OK)
	var author=code.new();author.random.seed=89041
	var face: ArrayMesh=load("res://assets/art/athlete88/head.res")
	var full: ArrayMesh=author.fibers(face,true)
	var arrays=full.surface_get_arrays(0);var ids: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var rows: Array=[]
	for level in 4:
		var mesh:=full
		if level<3:
			var stride: int=[24,12,4][level];var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for strand in range(0,int(author.stats.beard_strands),stride):
				for id in ids.slice(strand*72,(strand+1)*72):
					st.set_normal(arrays[Mesh.ARRAY_NORMAL][id]);st.set_uv(arrays[Mesh.ARRAY_TEX_UV][id]);st.set_color(arrays[Mesh.ARRAY_COLOR][id])
					st.set_bones(arrays[Mesh.ARRAY_BONES].slice(id*4,id*4+4));st.set_weights(arrays[Mesh.ARRAY_WEIGHTS].slice(id*4,id*4+4));st.add_vertex(arrays[Mesh.ARRAY_VERTEX][id])
			st.index();mesh=st.commit()
		assert(ResourceSaver.save(mesh,"res://assets/art/quality89/beard_full%d.res"%level,ResourceSaver.FLAG_COMPRESS)==OK)
		rows.append({"level":level,"triangles":mesh.surface_get_array_index_len(0)/3})
	FileAccess.open("res://docs/quality89-beard.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"strands":author.stats.beard_strands,"method":"scan-fitted curved opaque fibres, 4-12 mm; same Head/Neck skinning","levels":rows},"  "))
	print("BEARD89 BUILD PASS ",rows);quit()

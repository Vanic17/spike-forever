extends SceneTree
var game
var checks:=0
var errors: Array[String]=[]
func check(value: bool,message: String):
	checks+=1
	if not value:errors.append(message);push_error(message)
func _initialize():call_deferred("run")
func frames(count: int):
	for i in count:await process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
func fingerprint():return [game.rng.state,game.ball_pos,game.ball_vel,game.phase,game.rotations.duplicate(),game.scores.duplicate(),game.players.map(func(p):return [p.transform,p.clip_name,p.animation_time,p.contact_world("attack")])]
func triangles(mesh: Mesh) -> int:
	var total:=0
	for s in mesh.get_surface_count():total+=mesh.surface_get_array_index_len(s)/3
	return total
func run():
	assert("graphics89" in OS.get_environment("APPDATA").to_lower())
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,720)
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false);p.render_at_draw=false
	for node in game.get_children():
		if node is CanvasLayer:node.hide()
	await frames(12)
	var fidelity=game.arena_visuals.get_node("VisualUpgrade85/VisualUpgrade86/StadiumFidelity89")
	var snapshot=fingerprint();var rows: Array=[]
	for level in 4:
		var data: Dictionary=game.preferences.data.duplicate();data.merge(game.preferences.PRESETS[level],true);check(game.preferences.apply(data,false),"Preset applies")
		Engine.max_fps=30;await frames(12)
		var head: MeshInstance3D=game.players[0].body_parts.head
		var visible_crowd:=0;var crowd_tris:=0
		for node in fidelity.crowd_original:
			visible_crowd+=node.multimesh.visible_instance_count;crowd_tris+=triangles(node.multimesh.mesh)*node.multimesh.visible_instance_count
		var enabled_decor:=0
		for node in fidelity.details:enabled_decor+=int(node.visible)
		var skin: StandardMaterial3D=head.material_override
		rows.append({"level":level,"head_triangles":triangles(head.mesh),"body_triangles":triangles(game.players[1].body_parts.body.mesh),"cloth_triangles":triangles(game.players[1].body_parts.cloth.mesh),"texture_width":skin.albedo_texture.get_width(),"crowd_visible":visible_crowd,"crowd_triangles":crowd_tris,"decor_batches":enabled_decor,"skin_scattering":skin.subsurf_scatter_enabled,"floor_normal":game.arena_visuals.court_material.normal_enabled,"render_scale":root.scaling_3d_scale,"ssao":game.preferences.data.ssao,"reflections":game.preferences.data.reflections})
		check(fingerprint()==snapshot,"Graphics preserve simulation and contacts")
		check(game.players[0].skeleton.get_bone_count()==115,"Original rig preserved")
		if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://docs/graphics89-preset-"+str(level)+".png")
	for i in 3:
		check(rows[i].head_triangles<rows[i+1].head_triangles,"Actual head geometry scales")
		check(rows[i].crowd_triangles<rows[i+1].crowd_triangles,"Actual crowd geometry scales")
	check(rows[0].texture_width<=512 and rows[1].texture_width<=1024 and rows[2].texture_width<=2048 and rows[3].texture_width==4096,"Real texture limits")
	check(rows[0].crowd_visible<rows[3].crowd_visible,"Actual crowd density scales")
	check(rows[0].decor_batches==0 and rows[3].decor_batches>0,"Scenery details really toggle")
	check(not rows[0].floor_normal and rows[3].floor_normal,"Floor detail toggles")
	check(not rows[0].skin_scattering and rows[3].skin_scattering,"Skin rendering cost toggles")
	check(rows[0].cloth_triangles<rows[3].cloth_triangles,"Team garment geometry scales")
	for actor in game.players:
		check(actor.body_parts.cloth.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]!=null,"Kit identity UV preserved")
	var appearance=load("res://src/player_appearance.gd")
	appearance.apply(game.players[0],{"skin_tone":"chiara","hair_style":"pelato","beard":"nessuna"})
	check(not game.players[0].body_parts.hair.visible and not game.players[0].body_parts.beard.visible,"Bald/shaved preferences respected")
	check(game.players[0].body_parts.head.material_override.albedo_texture==load("res://src/source_assets.gd").texture("lambertian.jpg"),"Edited identity preserves scan UV atlas")
	appearance.apply(game.players[0],{"skin_tone":"olivastra","hair_style":"ricci","hair_color":"nero","beard":"piena"})
	check(game.players[0].body_parts.hair.visible and game.players[0].body_parts.beard.visible,"Curly/full beard preferences respected")
	check(game.players[0].body_parts.head.material_override.albedo_texture==load("res://src/source_assets.gd").texture("lambertian.jpg"),"Roster appearance preserves scan UV atlas")
	check(game.players[0].body_parts.head.material_override.albedo_color==appearance.SKIN.olivastra and game.players[0].body_parts.body.material_override.albedo_color==appearance.SKIN.olivastra,"Scan head and body preserve database skin tone")
	var p=game.players[0]
	var texture=game.preferences.data.duplicate();texture.merge(game.preferences.PRESETS[0],true);game.preferences.apply(texture,false);await frames(6)
	check(p.has_meta("visual_quality89") and fidelity.pilot.nails.visible==false,"Low quality persists after identity changes")
	check(p.body_parts.head.material_override.albedo_texture==load("res://src/source_assets.gd").texture("lambertian.jpg") and p.body_parts.head.material_override.albedo_texture.get_width()==512,"Low preset preserves correct scan atlas after edits")
	check(fingerprint()==snapshot,"Appearance/preset changes preserve gameplay")
	var view=load("res://src/view_controls.gd")
	check(view.origin(0).y<view.origin(3).y and view.court_direction(Vector2(.4,-.7),3)==Vector2(.4,-.7),"Lower broadcast framing preserves aim axes")
	game.camera_mode=0;game.set_camera();game.camera.force_update_transform()
	var bounds: Rect2=root.get_visible_rect()
	for point in [Vector3(-4.5,.1,-9),Vector3(4.5,.1,-9),Vector3(-4.5,.1,9),Vector3(4.5,.1,9),Vector3(0,.1,12.4),Vector3(0,7,10.4)]:
		check(not game.camera.is_position_behind(point) and bounds.has_point(game.camera.unproject_position(point)),"Low camera keeps court/server/toss framed "+str(point))
	game.phase="ATTACK";game.set_camera();game.camera.force_update_transform()
	for point in [Vector3(-4.5,.1,-9),Vector3(4.5,.1,-9),Vector3(-4.5,.1,9),Vector3(4.5,.1,9)]:
		check(bounds.has_point(game.camera.unproject_position(point)),"Tighter low rally framing preserves court visibility "+str(point))
	FileAccess.open("res://docs/graphics89-presets.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"checks":checks,"rendered":DisplayServer.get_name()!="headless","presets":rows,"scenery_proxies":game.arena_contacts.shapes.size()},"  "))
	print("GRAPHICS89 TEST ","PASS" if errors.is_empty() else "FAIL"," ",checks," ",JSON.stringify(rows));quit(0 if errors.is_empty() else 1)

extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("strikes96" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,960);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	for child in g.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	for p in g.players:p.hide();p.set_process(false);p.render_at_draw=false
	g.ball.hide();g.marker.hide();g.shadow.hide()
	var layer:=CanvasLayer.new();root.add_child(layer);var label:=Label.new();label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",26);label.add_theme_color_override("font_color",Color.WHITE);layer.add_child(label)
	var p=g.players[0];p.show();var index:=0
	var cases=[
		["PALLONETTO CORTO","attack","attack_shorttip96",false,-3.0],
		["PALLONETTO LUNGO · GESTO CONSERVATO","attack","attack_wrist94",false,-3.0],
		["DIAGONALE STRETTA · BANDA","attack","attack_cut96",false,-3.0],
		["DIAGONALE STRETTA · OPPOSTO MANCINO","attack","attack_cut96",true,3.0],
		["PRIMO TEMPO · PALLA A FILO RETE","set","set_first96",false,0.0],
		["SECONDA · DIETRO LA TESTA (2)","dump","dump_back96",false,0.0],
		["SECONDA · SPINTA RAPIDA (3)","dump","dump_down96",false,0.0],
		["SECONDA · TOCCO LUNGO (7)","dump","dump_forward96",false,0.0]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/strikes96/preview"))
	if "--only-down" in OS.get_cmdline_user_args():cases=[cases[6]];index=228
	if "--pancake" in OS.get_cmdline_user_args():cases=[["PANCAKE · BRACCIO DISTESO","dive","dive_pancake80",false,0.0]];index=304
	for row in cases:
		p.left_handed=row[3];p.position=Vector3(row[4],0,3);p.rotation.y=PI
		p.select_variant(row[1],"attack" if row[1]=="attack" else row[2]);p.play(row[1],1,false);p.blend_left=0;p.reach_weight=0
		p.wrist_tip_variant=row[2] if row[1]=="attack" else ""
		var clip=p.clips[row[1]]
		label.text="STUDIO DI POSA / "+row[0]
		g.camera.position=p.position+Vector3(3.4,2.7,4.9);g.camera.look_at(p.position+Vector3(0,1.95,0));g.camera.fov=39
		if row[1]=="dive":g.camera.position=p.position+Vector3(2.1,1.25,3.0);g.camera.look_at(p.position+Vector3(0,.55,.25));g.camera.fov=43
		for frame in 38:
			p.animation_time=clip.contact_time-.35+frame/45.0;p.apply_pose(0)
			await process_frame;await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			image.save_png("res://.runtime/strikes96/preview/%04d.png"%index);index+=1
			if frame==18:image.save_png("res://docs/strokes96-"+row[2]+("-left" if row[3] else "")+".png")
	print("CAPTURE96 PASS frames=",index);quit()

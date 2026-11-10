extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("serve106" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var folder:="res://.runtime/serve106/preview";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var frame:=0
	for scene in 4:
		g.server=0;g.reset_rally();g.input_team=0;g.serve_type=scene%2;g.use_player_stats=true
		var p=g.players[g.server_index(0)];p.roster_identity={"id":"serve106_preview","ratings":{"battuta":40 if scene<2 else 95}}
		g.form99={"arrows":{str(p.roster_identity.id):"NEUTRAL"}};g.rng.seed=106+scene
		g.camera_mode=0;g.set_camera()
		for tick in 135:
			if tick<40:g.serve_aim106=Vector3(lerpf(0,3.9,tick/39.0),.105,lerpf(-4.5,-7.7,tick/39.0))
			if tick==40:g.press_action("alternate" if scene%2==0 else "action")
			if g.charging and g.current_charge()>=(1.15 if scene==3 else 1.0):g.release_action()
			for sub in 2:g.step(1.0/120)
			for actor in g.players:actor.apply_pose(0)
			g.ball.position=g.ball_pos;g.serve_target106.visual(g)
			await process_frame;await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image();image.save_png(folder+"/%04d.png"%frame)
			if tick==30:image.save_png("res://docs/serve106-preview-%d.png"%scene)
			frame+=1
	print("CAPTURE106 PASS frames=",frame);quit()

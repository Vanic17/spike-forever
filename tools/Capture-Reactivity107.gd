extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("review107" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	for child in g.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	for p in g.players:p.set_process(false);p.render_at_draw=false
	g.rotations=[0,0];g.server=0;g.reset_rally();g.possession=0;g.input_team=0;g.receiver=3;g.rng.seed=104421;g.set_dir=0
	for i in 12:
		var team: int=int(i/6);g.players[i].position=g.Tactics.home_for(g,i,team,0,team==g.server,false)
		if team==0 and g.Tactics.role_for(g,i)=="L":g.receiver=i
	g.players[g.receiver].position=g.Tactics.world(0,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
	g.phase="RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0;g.receive_ball();g.press_action("action")
	g.camera.position=Vector3(-8,3.8,5);g.camera.look_at(Vector3(-3.0,1.3,1.3));g.camera.fov=45
	var folder:="res://.runtime/review107/preview";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	Input.action_press("down")
	for frame in 190:
		if g.phase=="ATTACK":g.armed=true;g.charge=.89;g.input_quality=1;g.aim=Vector2.DOWN
		for sub in 2:g.step(1.0/120)
		for p in g.players:p.apply_pose(0)
		g.ball.position=g.ball_pos
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/%04d.png"%frame)
	Input.action_release("down");print("CAPTURE107 PASS");quit()

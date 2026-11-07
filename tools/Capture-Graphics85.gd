extends SceneTree
const League=preload("res://src/league.gd")
const Kits=preload("res://src/club_kits.gd")
var game
var label:="before"
var metadata: Dictionary={}
func _initialize():call_deferred("run")
func settle(frames: int=24):
	for i in frames:await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String,eye: Vector3,focus: Vector3,fov: float):
	game.camera.position=eye;game.camera.look_at(focus);game.camera.fov=fov
	await settle()
	var path: String="res://docs/graphics85-"+label+"-"+name+".png"
	root.get_texture().get_image().save_png(path)
	metadata[name]={"eye":str(eye),"focus":str(focus),"fov":fov,"path":path}
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	root.mode=Window.MODE_WINDOWED;root.position=Vector2i(19000,19000);root.size=Vector2i(1920,1080);root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.paused=false;game.demo=false;game.match_audio.enabled=false
	for child in game.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	game.preferences.data.merge(game.preferences.PRESETS[2],true);game.preferences.apply(game.preferences.data,false)
	if "--no-sss" in OS.get_cmdline_user_args():game.preferences.data["material_detail"]=1;game.preferences.apply(game.preferences.data,false)
	Engine.max_fps=30;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for p in game.players:p.set_process(false);p.render_at_draw=false
	var db=League.new();var clubs: Array=[];var squads: Array=[]
	for id in ["acqua-santanna-cuneo","cucine-lube-civitanova"]:
		var team: Dictionary=db.teams.filter(func(t):return t.id==id)[0];clubs.append(team);squads.append(db.lineup(team))
	for side in 2:
		game.team_names[side]=clubs[side].name
		for i in 6:game.players[side*6+i].set_roster_identity(squads[side][i],squads[side][6],Kits.selection(clubs[side].id,"home" if side==0 else "away"),Kits.selection(clubs[side].id,"home" if side==0 else "away",true))
	game.set_home_club(clubs[0].id,0)
	await settle(60)
	if "--no-soft-shadow" in OS.get_cmdline_user_args():
		var visuals=game.arena_visuals.get_node_or_null("VisualUpgrade85")
		if visuals!=null and visuals.get("key_light")!=null:visuals.key_light.light_angular_distance=0
	game.replay.enabled=true;game.replay.testing=true;game.replay.set_process(false)
	game.rotations=[0,0];game.server=1;game.rng.seed=40001;game.shot_serial=0;game.reset_rally();game.possession=0;game.receiver=4;game.set_dir=0
	game.players[4].position=game.Tactics.world(0,0,5.5);game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[4].contact_world("receive");game.phase="RECEIVE";game.armed=true;game.input_quality=1;game.incoming_kind="spike";game.incoming_power=.3
	game.receive_ball();game.press_action("action")
	for step in 240:
		if game.phase=="ATTACK":game.armed=true;game.charge=.85;game.input_quality=1
		game.step(1.0/120)
		for p in game.players:p.apply_pose(0)
		game.replay.capture(true)
		if game.phase=="ATTACK" and game.flight_left<.16:break
	game.ball.position=game.ball_pos
	metadata={"resolution":str(root.size),"teams":game.team_names,"seed":40001,"phase":game.phase,"clock":game.clock_time,"ball":str(game.ball_pos),"velocity":str(game.ball_vel),"rng":str(game.rng.state),"players":game.players.map(func(p):return {"transform":str(p.transform),"clip":p.clip_name,"time":p.animation_time,"jersey":p.roster_identity.get("jersey_number",0)})}
	await shot("wide",Vector3(0,9.8,18.4),Vector3(0,.7,-.5),48)
	var p=game.players[0];var head: Vector3=p.current_joint("Head")
	await shot("player",head+p.global_basis*Vector3(.85,.05,2.25),head+Vector3(0,-.18,0),34)
	await shot("court-net",Vector3(9.4,5.6,6.8),Vector3(0,1.2,0),55)
	await shot("crowd",Vector3(5,4.2,-12.0),Vector3(1.0,2.8,-21),59)
	if game.replay.begin():game.replay.show_frame(game.replay.clip[-1].time)
	var target: Vector3=game.players[game.hitter].current_joint("Head")
	await shot("replay",target+Vector3(5.6,1.5,3.5),target+Vector3(0,-.4,0),44)
	FileAccess.open("res://docs/graphics85-"+label+"-capture.json",FileAccess.WRITE).store_string(JSON.stringify(metadata,"  "))
	print("GRAPHICS85 CAPTURE PASS ",label);quit()

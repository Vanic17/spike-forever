extends SceneTree
var game
var benches
var scene
var frame:=0
var stage:=0
var five_captured:=false
var movie:="--scene" in OS.get_cmdline_user_args()
func _initialize(): call_deferred("setup")
func setup():
	root.size=Vector2i(1280,720); root.content_scale_size=root.size; root.mode=Window.MODE_WINDOWED
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	game.started=true; game.paused=false; game.phase="POINT"; game.hud.hide(); game.marker.hide(); game.replay.set_process(false)
	scene=game.substitution_scene; scene.testing=true; scene.set_process(false)
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.hide()
	var db=load("res://src/league.gd").new(); var teams=[db.teams[0],db.teams[1]]; var squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	game.match_management.configure_rosters(teams,squads); game.match_management.lock_lineup()
	for side in 2:
		game.team_names[side]=teams[side].name
		for slot in 6: game.players[side*6+slot].set_roster_identity(squads[side][slot],squads[side][6],load("res://src/club_kits.gd").selection(teams[side].id,"home"),{})
	await process_frame
	benches=game.arena_visuals.get_node("TeamBenches"); benches.set_process(false); benches.sync_identity()
	game.camera.position=Vector3(-3.8,3.8,10.7); game.camera.look_at(Vector3(-7,1,5.9)); game.camera.fov=45
	benches._process(.1); game.scores=[1,0]; game.server=0
	if movie:
		var incoming: Dictionary=game.match_management.bench(0).filter(func(p): return p.role=="outside_hitter")[-1]
		game.paused=true; assert(game.match_management.substitute(0,0,incoming.id).is_empty()); assert(scene.begin()); game.pause_menu.surface.hide()
	stage=1
func _process(_dt: float) -> bool:
	if stage==0: return false
	frame+=1
	if movie:
		scene.advance(1.0/30)
		if scene.active and scene.state=="PLAY" and not five_captured and scene.elapsed>=scene.timeline.meet+.6: screenshot("five"); five_captured=true
		if frame in [75,135,210,270,330]: screenshot("change-"+str(frame))
		if not scene.active and frame>30: print("SIDELINE69 SCENE CAPTURE PASS ",frame); quit()
	else:
		benches._process(1.0/30)
		if frame in [30,90,150]: screenshot("bench-"+str(frame))
		if frame>210: print("SIDELINE69 BENCH CAPTURE PASS"); quit()
	return false
func screenshot(name: String):
	RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/sideline69-"+name+".png"),CONNECT_ONE_SHOT)

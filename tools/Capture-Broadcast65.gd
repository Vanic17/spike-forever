extends SceneTree
var g
var menu
func _initialize(): call_deferred("run")
func shot(name: String):
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/broadcast66-"+name+".png")
func run():
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1920,1080); root.content_scale_size=root.size
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_physics_process(false); g.self_test=true; g.replay.set_process(false)
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): menu=n
	menu.installed_version="999.0.0"; menu.clubs.match_setup(); await shot("setup")
	menu.clubs.hide(); menu.online_menu.open(); await shot("online"); menu.online_menu.hide()
	menu.clubs.editor(); await shot("editor"); menu.clubs.hide(); menu.panel.hide()
	var db=menu.clubs.db; var kits=load("res://src/club_kits.gd")
	for side in 2:
		var club: Dictionary=db.teams.filter(func(t): return t.id==("vero-volley-monza" if side==0 else "rana-verona"))[0]
		var squad: Array=db.lineup(club); g.team_names[side]=club.name
		for i in 6: g.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(club.id,"home"),kits.selection(club.id,"home",true))
	g.started=true; g.server=0; g.rotations=[0,0]; g.reset_rally(); g.scores=[18,17]; g.sets=[1,2]; g.camera_mode=2; g.set_camera()
	g.phase="ATTACK"; g.hitter=0; g.charge=.987; g.attack_tip=false; g.armed=true
	g.TimingResult.put(g,0,"ATTACCO",.987)
	for p in g.players: p.apply_pose(0)
	await shot("hud-tv")
	g.camera_mode=0; g.set_camera(); await shot("hud-front")
	g.replay.testing=true
	for i in 45:
		g.clock_time=i/30.0; g.ball_pos=Vector3(0,2+sin(i*.1),3-i*.1); g.replay.capture(true)
	g.replay.begin(); g.replay.elapsed=.5; g.replay.overlay.queue_redraw(); await shot("transition")
	g.replay.advance(g.replay.TRANSITION_SECONDS); g.replay.advance(.2); await shot("replay")
	g.replay.finish(); print("BROADCAST66 CAPTURE PASS"); g.free(); quit()

extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1920,1080); root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): child.panel.hide(); child.overlay.hide(); child.clubs.hide()
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	var teams: Array=[db.teams[0],db.teams[1]]; var lineups: Array=[db.lineup(teams[0]),db.lineup(teams[1])]
	for side in 2:
		g.team_names[side]=teams[side].name
		for slot in 6: g.players[side*6+slot].set_roster_identity(lineups[side][slot],lineups[side][6],kits.selection(teams[side].id,"home"),kits.selection(teams[side].id,"home",true))
	var m=g.match_management; m.configure_rosters(teams,lineups); m.lock_lineup()
	for i in 6: m.conditions[str(lineups[0][i].id)].fatigue=24+i*8
	g.started=true; g.phase="SERVE"; g.paused=true; g.match_finished=false; g.toss_active=false; g.charging=false
	await process_frame; await process_frame
	m.menu.open(); m.menu.choose_slot(0)
	for size in [Vector2i(1920,1080),Vector2i(1280,720)]:
		root.size=size; root.content_scale_size=size
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/match66-substitutions-"+str(size.y)+".png")
	print("SUBSTITUTIONS66 CAPTURE PASS"); g.free(); quit()

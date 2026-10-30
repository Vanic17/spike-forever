extends SceneTree
var game
func _initialize(): call_deferred("run")
func shot(name: String):
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/patch68-"+name+".png")
func run():
	root.size=Vector2i(1440,900); root.content_scale_size=root.size; root.mode=Window.MODE_WINDOWED
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true
	game.started=true; game.match_audio.enabled=false; game.hud.hide(); game.marker.hide(); game.replay.set_process(false); game.substitution_scene.set_process(false)
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.hide()
	var db=load("res://src/league.gd").new(); var teams=[db.teams[0],db.teams[1]]; var squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	for side in 2:
		game.team_names[side]=teams[side].name
		for slot in 6: game.players[side*6+slot].set_roster_identity(squads[side][slot],squads[side][6],load("res://src/club_kits.gd").selection(teams[side].id,"home"),{})
	game.match_management.configure_rosters(teams,squads); game.match_management.lock_lineup(); game.phase="POINT"
	await process_frame
	var benches=game.arena_visuals.get_node("TeamBenches"); benches.sync_identity(); benches.set_process(false)
	game.camera.position=Vector3(-3.6,4.1,10.5); game.camera.look_at(Vector3(-7.0,1,5.9)); game.camera.fov=45
	benches._process(.1); game.server=0; game.scores=[1,0]
	for i in 23: benches._process(1.0/30)
	await shot("bench")
	game.camera.position=Vector3(-3.2,3.9,4); game.camera.look_at(Vector3(-8,1,0)); await shot("officials")
	game.ball.position=Vector3(0,2,4); game.ball.scale=Vector3.ONE*4
	game.camera.position=Vector3(0,2,6); game.camera.look_at(game.ball.position); game.camera.fov=40
	game.ball.rotation=Vector3(.15,.4,.4); await shot("ball")
	game.ball.rotation=Vector3(1.6,.4,.4); await shot("ball-spin")
	game.ball.scale=Vector3.ONE; game.paused=true
	var incoming: Dictionary={}
	for p in game.match_management.bench(0):
		if game.match_management.eligibility(0,0,p.id).is_empty(): incoming=p; break
	var scene=game.substitution_scene; scene.testing=true
	assert(game.match_management.substitute(0,0,incoming.id).is_empty()); scene.begin(); scene.advance(scene.TRANSITION_SECONDS+.01)
	for t in [.3,2.0,4.0,4.4,6.5]:
		scene.show_scene(t); await shot("change-"+str(t).replace(".","-"))
	scene.finish(); print("CAPTURE68 PASS"); game.free(); quit()

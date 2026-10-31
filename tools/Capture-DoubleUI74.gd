extends SceneTree
var game
func _initialize(): call_deferred("run")
func settle():
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func capture(path: String):
	await settle()
	root.get_texture().get_image().save_png(path)
func run():
	if not ProjectSettings.globalize_path("user://").contains("double74"):
		push_error("Requires isolated double74 APPDATA"); quit(1); return
	root.position=Vector2i(-3000,-3000); root.size=Vector2i(1920,1080); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	await settle()
	var db=load("res://src/league.gd").new(); var teams: Array=[db.teams[0],db.teams[1]]; var squads: Array=[db.lineup(teams[0]),db.lineup(teams[1])]
	var manager=game.match_management; var menu=manager.menu; manager.configure_rosters(teams,squads); manager.lock_lineup()
	game.team_names=[str(teams[0].name),str(teams[1].name)]
	game.started=true; game.phase="SERVE"; game.paused=true; game.charging=false; game.toss_active=false; game.match_finished=false; game.rotations=[3,3]
	for p in game.players: p.libero_active=false
	game.substitution_scene.set_process(false); game.substitution_scene.testing=true
	menu.open(); menu.open_double(); await settle()
	menu.choose_double_opposite(str(menu.rows[0].get_meta("player_id"))); menu.choose_double_setter(str(menu.candidates[0].get_meta("player_id")))
	await capture("res://docs/double74-ui-entry-1080.png")
	root.size=Vector2i(1280,720); root.content_scale_size=root.size; await capture("res://docs/double74-ui-entry-720.png")
	menu.apply_double(); game.substitution_scene.cancel(); game.paused=true; game.rotations[0]=0
	root.size=Vector2i(1920,1080); root.content_scale_size=root.size; menu.open(); menu.open_double()
	await capture("res://docs/double74-ui-return-1080.png")
	TranslationServer.set_locale("en"); menu.refresh(); menu.focus_double_body()
	await capture("res://docs/double74-ui-return-en-1080.png")
	print("DOUBLE UI74 CAPTURE PASS"); game.free(); quit()

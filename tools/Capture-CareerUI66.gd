extends SceneTree
var game
var host
var career
func _initialize(): call_deferred("run")
func shot(id: String):
	await process_frame; await process_frame; await create_timer(.25).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/career66-"+id+".png")
func run():
	root.size=Vector2i(1920,1080); root.content_scale_size=root.size; root.mode=Window.MODE_WINDOWED
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child
	host.installed_version="999.0.0"; host.startup_scan=false
	await process_frame; await process_frame; root.size=Vector2i(1920,1080); root.content_scale_size=root.size
	host.play_hub.open(); await shot("play-hub-1080")
	career=host.career_menu; career.open(); career.show_page("new"); await shot("new-1080")
	career.ensure_manager(); assert(career.manager.new_career(host.clubs.db.teams[0].id,{"seed":66030,"autosave":false,"fatigue":true,"injuries":false},11))
	career.show_page("home"); await shot("home-1080")
	career.show_page("rosa"); await shot("squad-1080")
	career.push("player",career.manager.lineup(career.club())[0].id); await shot("player-1080")
	career.show_page("prematch"); await shot("prematch-1080")
	career.show_page("rosa"); career.formation_screen(career.club()); await shot("formation-1080"); career.close_modal()
	while not career.manager.state.complete: assert(not career.manager.simulate_next().is_empty())
	career.show_page("home"); await shot("completed-1080")
	career.show_page("classifica"); await shot("standings-1080")
	career.selected_comp="playoff"; career.show_page("competizioni"); await shot("bracket-1080")
	career.show_page("archivio"); await shot("archive-1080")
	root.size=Vector2i(1280,720); root.content_scale_size=root.size; career.show_page("classifica"); await shot("standings-720")
	career.show_page("home"); await shot("home-720")
	career.hide(); host.play_hub.hide(); host.clubs.hide(); game.started=true; game.paused=true; game.phase="SERVE"; game.match_finished=false; game.toss_active=false; game.charging=false
	var teams=[host.clubs.db.teams[0],host.clubs.db.teams[1]]; var squads=[host.clubs.db.lineup(teams[0]),host.clubs.db.lineup(teams[1])]
	game.match_management.configure_rosters(teams,squads); game.match_management.lock_lineup(); game.match_management.menu.open(); await shot("substitutions-720")
	game.match_management.menu.choose_slot(0); await shot("bench-720")
	var id=game.match_management.menu.candidates[0].get_meta("player_id"); game.match_management.menu.choose_reserve(id); await shot("confirm-substitution-720")
	root.size=Vector2i(1920,1080); root.content_scale_size=root.size; await shot("confirm-substitution-1080")
	print("CAREER CAPTURE66 PASS desktop and TV / profiles / standings / bracket / substitutes"); game.free(); quit()

extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(file: String):
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+file+".png")
func run():
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,810); root.content_scale_size=root.size
	root.gui_disable_input=true
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true
	var host
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child
	host.installed_version="999.0.0"; game.preferences.dry_run=true
	await process_frame
	await capture("settings53-home-it")
	var values: Dictionary=game.preferences.data.duplicate(); values.language="en"; game.preferences.apply(values,false)
	game.preferences.discover_displays()
	host.settings_menu.open(); await capture("settings53-video-en")
	host.settings_menu.show_page(1); host.settings_menu.graphics_tab.grab_focus(); await capture("settings53-graphics-en")
	host.settings_menu.fields.anisotropy.grab_focus(); await capture("settings53-graphics-detail-en")
	host.settings_menu.close(); host.clubs.match_setup(); await capture("settings53-match-en")
	host.clubs.show_match_formation(0,host.clubs.db.teams[0],host.clubs.formation_buttons[0]); await capture("settings53-formation-en"); host.clubs.formation_dialog.hide()
	host.clubs.hide(); host.online_menu.open(); await capture("settings53-online-en"); host.online_menu.hide()
	host.clubs.hide(); host.clubs.editor(); await capture("settings53-editor-en")
	host.clubs.hide(); game.started=true; game.phase="SET"; game.feedback="ALZATA VELOCE"; game.feedback_left=10
	game.receive_feedback="LEGGERMENTE IN ANTICIPO · 84%"; game.receive_feedback_left=10; game.planned_hitter=0; game.planned_direction=0; game.pass_quality=.84
	await capture("settings53-hud-en")
	print("SETTINGS53 CAPTURE PASS Italian home / English video, graphics, match, editor and HUD")
	game.free(); quit()

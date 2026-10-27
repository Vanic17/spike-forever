extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.mode=Window.MODE_WINDOWED
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var menu
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): menu=n
	menu.installed_version="999.0.0"
	var clubs=menu.clubs; var layouts: Array=[]
	for size in [Vector2i(1440,810),Vector2i(1280,720),Vector2i(1280,600)]:
		root.size=size; root.content_scale_size=size; clubs.match_setup()
		await process_frame; await process_frame; await process_frame
		var pick=clubs.settings_stats
		assert(pick.get_global_rect().end.y<=size.y and pick.get_global_rect().end.x<=size.x)
		assert(pick.selected==0)
		clubs.settings_points.grab_focus()
		var right=InputEventJoypadButton.new(); right.button_index=JOY_BUTTON_DPAD_RIGHT; right.pressed=true; root.push_input(right)
		await process_frame
		assert(pick.has_focus(),"D-pad must reach the optional mode")
		right.pressed=false; root.push_input(right)
		for enabled in [false,true]:
			pick.select(1 if enabled else 0); clubs.setup_start.pressed.emit()
			assert(g.started and g.use_player_stats==enabled)
			for p in g.players: assert(p.roster_identity.ratings.has("difesa"))
			g.return_to_main_menu(); clubs.match_setup(); await process_frame; pick=clubs.settings_stats
		layouts.append(str(size))
	clubs.editor(); clubs.enter_details(); await process_frame
	assert(clubs.inputs.has("rating_difesa"))
	var visited:=false
	for i in 50:
		var owner=root.gui_get_focus_owner()
		if owner==clubs.inputs.rating_difesa.get_line_edit():
			visited=true; clubs.inputs.rating_difesa.value=88
			assert(clubs.player_card.ratings.difesa==88)
		if owner is Button and owner.text=="SALVA MODIFICHE": break
		assert(clubs.focus_editor_step(false)); await process_frame
	assert(visited,"Controller editor must reach the new defense value")
	assert(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text=="SALVA MODIFICHE")
	assert(clubs.player_card.KEYS.size()==6)
	clubs.go_back(); assert(clubs.player_pick.has_focus())
	if "--capture" in OS.get_cmdline_user_args():
		root.size=Vector2i(1440,810); root.content_scale_size=root.size
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/stats63-editor.png")
		clubs.match_setup(); clubs.settings_stats.select(1)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/stats63-offline.png")
		menu.online_menu.open(); menu.online_menu.stats_pick.select(1)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/stats63-online.png")
	FileAccess.open("res://docs/stats63-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"layouts":layouts,"both_modes_launch":true,"controller_stats":true,"controller_defense":visited,"hexagon":true,"circle_back":true},"  "))
	print("STATS UI63 PASS three sizes / mode toggle / D-pad / six editable values / Circle")
	g.free(); quit()

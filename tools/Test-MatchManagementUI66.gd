extends SceneTree
func _initialize(): call_deferred("run")
func joy(button: int):
	var event=InputEventJoypadButton.new(); event.device=9; event.button_index=button; event.pressed=true; root.push_input(event)
	await process_frame
	event=event.duplicate(); event.pressed=false; root.push_input(event); await process_frame
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	var teams: Array=[db.teams[0],db.teams[1]]; var lineups: Array=[db.lineup(teams[0]),db.lineup(teams[1])]
	for side in 2:
		for slot in 6: g.players[side*6+slot].set_roster_identity(lineups[side][slot],lineups[side][6],kits.selection(teams[side].id,"home"),kits.selection(teams[side].id,"home",true))
	g.match_management.configure_rosters(teams,lineups)
	g.match_management.lock_lineup()
	g.started=true; g.phase="SERVE"; g.paused=true; g.match_finished=false; g.toss_active=false; g.charging=false
	await process_frame; await process_frame
	var m=g.match_management; var ui=m.menu
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1024,600)]:
		root.size=size; root.content_scale_size=size; ui.open(); await process_frame; await process_frame
		assert(ui.rows[0].has_focus())
		for i in 12: await joy(JOY_BUTTON_DPAD_DOWN)
		assert(ui.rows[5].has_focus() and ui.incoming.is_empty() and ui.zone==0 and m.counts[0]==0,"Scrolling past the last starter never selects a reserve")
		ui.rows[0].grab_focus()
		await joy(JOY_BUTTON_A); assert(ui.zone==1 and not ui.candidates.is_empty())
		for i in 15: await joy(JOY_BUTTON_DPAD_DOWN)
		assert(ui.incoming.is_empty() and ui.zone==1 and m.counts[0]==0,"Bench focus is only browsing, never a selection")
		ui.candidates[0].grab_focus()
		await joy(JOY_BUTTON_A); assert(ui.confirm_button.has_focus())
		assert(Rect2(Vector2.ZERO,Vector2(size)).encloses(ui.confirm_button.get_global_rect()),"Confirm must remain visible at TV resolutions")
		await joy(JOY_BUTTON_A); assert(m.counts[0]>0 and ui.zone==0)
		for i in 5: await joy(JOY_BUTTON_DPAD_DOWN)
		assert(ui.rows[5].has_focus(),"Controller reaches last court slot")
		assert(ui.left_scroll.get_global_rect().intersects(ui.rows[5].get_global_rect()))
		await joy(JOY_BUTTON_B); assert(not ui.opened and g.paused,"B/Circle returns to pause without resuming")
		m.configure_rosters(teams,lineups)
		m.lock_lineup()
	FileAccess.open("res://docs/match66-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"sizes":["1920x1080","1280x720","1024x600"],"controller_accept":true,"scroll_never_selects":true,"explicit_three_steps":true,"controller_reaches_last_slot":true,"circle_returns_to_pause":true,"confirm_visible":true},"  "))
	print("MATCH MANAGEMENT UI66 PASS controller court/bench/confirm/Circle and three sizes")
	g.free(); quit()

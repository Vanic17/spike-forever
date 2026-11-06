extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var cases: Array=[]
	for scenario in [[JOY_BUTTON_A,false],[JOY_BUTTON_X,false],[JOY_BUTTON_A,true],[JOY_BUTTON_X,true]]:
		var kind: int=scenario[0]
		var p=restart("S");game.server=0;game.rotations=[0,0];game.reset_rally();game.started=true;game.demo=false;game.paused=false
		if scenario[1]:p.position.z=9.2
		check(game.server_index(0)==adapter.controlled_index,"profile owns service")
		var before: Vector3=p.position
		await axis(JOY_AXIS_LEFT_X,.8);await axis(JOY_AXIS_LEFT_Y,-.5)
		for tick in 40:game.step(1.0/120)
		check(p.position.distance_to(before)<.01,"aim stick cannot walk serving player")
		check(game.aim.x>.7 and game.aim.y<-.4,"left stick aims service")
		await button(kind)
		for tick in 20:game.step(1.0/120)
		await button(kind,false);await axis(JOY_AXIS_LEFT_X,0);await axis(JOY_AXIS_LEFT_Y,0)
		for frame in 500:
			if game.phase!="SERVE":break
			game.step(1.0/120)
		var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==adapter.controlled_index and row.action in ["float","power"])
		check(not contacts.is_empty() and game.phase in ["RECEIVE","CPU_RECEIVE"],"shared exhibition toss and serve contact "+str(kind))
		cases.append({"button":kind,"origin":before,"aim":game.aim,"contacts":contacts,"phase":game.phase,"adjusting":game.serve_adjusting,"target":game.serve_adjust_target,"end_position":p.position,"motion":game.serve_motion_active})
	game.phase="SERVE";game.server=1;game.aim=Vector2(-.3,.2);adapter.move_input=Vector2(.9,-.6)
	adapter.apply_controls(0)
	check(game.aim==Vector2(-.3,.2) and adapter.action_actor(0)==-1,"human stick cannot aim opponent CPU service")
	FileAccess.open("res://docs/legend79-service.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":cases,"failures":failures},"  "))
	print("LEGEND SERVE79 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

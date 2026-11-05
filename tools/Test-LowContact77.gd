extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated appdata")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var rows: Array=[]
	for scenario in [[60,-.8],[120,-.8],[60,.8],[120,.8]]:
		var fps: int=scenario[0]
		var p=restart();var index: int=adapter.controlled_index
		p.position=Vector3(0,0,6);p.rotation.y=PI;p.velocity=Vector3.ZERO;p.acceleration=Vector3.ZERO;p.body_lean=Vector2.ZERO;p.play("ready",1,true)
		game.phase="RECEIVE";game.possession=0;game.receiver=index;game.incoming_kind="spike";game.incoming_power=.90;game.winner_team=-1;game.last_touch=1;game.touches=[0,0];game.shot_serial=1
		game.armed=false;game.late_receive=false;game.flight_spin=Vector3.ZERO;game.flight_gravity=game.G
		var target:=Vector3(float(scenario[1]),1.15,4.8);game.select_receive_pose(index,target)
		check(p.variant_names.get("receive","")==("receive_slide77" if target.x<0 else "receive_slide_right77"),"low lateral spike selects matching native performance")
		target.y=p.contact_local("receive").y;p.position=p.stance_for_contact("receive",target);clear_around(index)
		game.ball_pos=Vector3(0,3.5,-2);game.launch(target,.55);game.receive_deadline=game.clock_time+game.flight_left
		var pressed:=false;var limit: float=game.clock_time+1.5
		while game.phase=="RECEIVE" and game.clock_time<limit:
			if not pressed and game.flight_left<.15:await button(JOY_BUTTON_A);await button(JOY_BUTTON_A,false);pressed=true
			game.step(1.0/fps)
		var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action=="receive")
		check(not contacts.is_empty(),"actual low contact succeeds at "+str(fps)+" Hz")
		if not contacts.is_empty():check(contacts[-1].gap<=.18,"native palms meet real ball")
		rows.append({"fps":fps,"contacts":contacts,"events":game.rally_events.slice(maxi(0,game.rally_events.size()-5))})
	FileAccess.open("res://docs/defense77-real-contacts.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"failures":failures},"  "))
	print("LOW CONTACT77 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

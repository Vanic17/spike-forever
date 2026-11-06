extends "res://tools/Test-LegendInputs75.gd"
const Context=preload("res://src/defense_context80.gd")
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var rows: Array=[]
	for fps in [30,60,120]:
		for variant in ["receive_platform80","receive_braced80","receive_knee80","receive_knee_right80"]:
			var p=restart();var index: int=adapter.controlled_index
			game.phase="RECEIVE";game.possession=0;game.receiver=index;game.incoming_kind="spike";game.last_touch=1;game.touches=[0,0];game.winner_team=-1
			p.looping=true;p.select_variant("receive",variant);p.rotation.y=PI;p.velocity=Vector3.ZERO;p.play("ready",1,true)
			var point:=Vector3(0,p.contact_local("receive").y,5.5);p.position=p.stance_for_contact("receive",point);clear_around(index)
			game.ball_pos=point+Vector3(0,2.0,-.8);game.launch(point,.5);game.receive_deadline=game.clock_time+.5
			var pressed:=false;var deadline: float=game.clock_time+1.5
			while game.phase=="RECEIVE" and game.clock_time<deadline:
				if not pressed and game.flight_left<.15:await button(JOY_BUTTON_A);await button(JOY_BUTTON_A,false);pressed=true
				game.step(1.0/fps)
			var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action=="receive")
			check(not contacts.is_empty(),"physical platform "+str([variant,fps]))
			rows.append({"fps":fps,"variant":variant,"contacts":contacts})
		for mode in ["pancake","left_roll","right_roll"]:
			var p=restart();var index: int=adapter.controlled_index
			game.phase="RECEIVE";game.possession=0;game.receiver=index;game.incoming_kind="spike";game.incoming_power=.9;game.last_touch=1;game.touches=[0,0];game.winner_team=-1;game.armed=true;game.input_quality=.95;game.late_receive=false
			p.position=Vector3(0,0,6);p.rotation.y=PI;p.velocity=Vector3.ZERO;p.play("ready",1,true);clear_around(index)
			var expected: String={"pancake":"dive_pancake80","left_roll":"dive_roll80","right_roll":"dive_roll_right80"}[mode]
			var point:=Vector3(0,game.clips[expected].contact_offset.y,4.7) if mode=="pancake" else Vector3(-1.4 if mode=="left_roll" else 1.4,game.clips[expected].contact_offset.y,5.8)
			game.ball_pos=point+Vector3(0,.55 if mode=="pancake" else .62,-.05);game.launch(point,.19 if mode=="pancake" else .24)
			adapter.allow_requested_recovery=true;var queued: bool=game.queue_recovery(true);adapter.allow_requested_recovery=false
			check(queued and p.variant_names.get("dive","")==expected,"extreme contextual plan "+str([mode,fps,p.variant_names.get("dive","")]))
			var deadline: float=game.clock_time+1
			while game.phase=="RECEIVE" and game.clock_time<deadline:game.step(1.0/fps)
			var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action=="dive")
			check(not contacts.is_empty(),"physical extreme save before floor "+str([mode,fps]))
			rows.append({"fps":fps,"variant":expected,"queued":queued,"contacts":contacts,"phase":game.phase})
	var p=restart();game.phase="RECEIVE";game.receiver=adapter.controlled_index;game.incoming_kind="spike";game.winner_team=-1
	p.position=Vector3(0,0,6);p.rotation.y=PI
	for position in [Vector3(0,2.0,4.7),Vector3(0,.7,5.6),Vector3(0,.7,1.0)]:
		game.ball_pos=position;game.ball_vel=Vector3(0,-3,0)
		check(Context.candidates(game,adapter.controlled_index).is_empty(),"no extreme animation for high/close/impossible ball")
	FileAccess.open("res://docs/defense80-contacts.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"failures":failures},"  "))
	print("DEFENSE80 CONTACTS ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

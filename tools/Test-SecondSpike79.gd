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
	for manual in [false,true]:
		for push in [false,true]:
			var p=restart("S");var index: int=adapter.controlled_index
			if not manual:adapter.active=false
			game.rotations=[3,3];game.phase="SET";game.possession=0;game.setter=index;game.input_team=0;game.touches=[1,0];game.last_touch=0
			game.out_of_system=1;game.pass_quality=.95;game.input_quality=.95;game.armed=false;game.late_receive=false;game.setter_dump=false;game.setter_spike=false;game.winner_team=-1
			p.rotation.y=PI;p.velocity=Vector3.ZERO;p.acceleration=Vector3.ZERO;p.play("ready",1,true)
			p.select_variant("dump","dump_push54")
			var action: String="dump" if push else "attack"
			var point:=Vector3(0,p.contact_local(action).y,.75 if push else 2.2)
			p.position=p.stance_for_contact(action,point);p.rotation.y=PI;clear_around(index)
			game.ball_pos=point+Vector3(0,1.2,.2);game.launch(point,.50)
			if manual:await button(JOY_BUTTON_B);await button(JOY_BUTTON_B,false)
			else:game.press_action("dump")
			check(game.setter_dump if push else game.setter_spike,"circle selects correct second touch "+str([manual,push]))
			var packed: Dictionary=preload("res://src/online_state.gd").capture(game)
			var restored: Dictionary=preload("res://src/online_state.gd").decode(preload("res://src/online_state.gd").encode(packed))
			check(restored.setter_spike==game.setter_spike and restored.setter_dump==game.setter_dump,"second-touch choice survives online snapshot")
			var limit: float=game.clock_time+2
			while game.phase=="SET" and game.clock_time<limit:game.step(1.0/120)
			var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action==action)
			check(not contacts.is_empty(),"physical second-touch contact "+str([manual,push]))
			check(game.touches[0]==2,"exactly one second touch, no third/fourth touch")
			cases.append({"manual":manual,"push":push,"contacts":contacts,"incoming":game.incoming_kind,"rejects":game.rally_events.filter(func(row):return row.kind=="contact_rejected")})
	adapter.active=false;game.phase="CPU_SET";game.possession=1;game.setter=11;game.touches=[0,1];game.setter_spike=false
	check(not preload("res://src/setter_spike79.gd").request(game) and not game.setter_spike,"CPU cannot request new spike")
	FileAccess.open("res://docs/second79-gameplay.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":cases,"failures":failures},"  "))
	print("SECOND SPIKE79 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

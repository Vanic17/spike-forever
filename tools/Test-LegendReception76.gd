extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated appdata")
	if not failures.is_empty(): quit(2); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false; game.replay.enabled=false
	for p in game.players: p.set_process(false); p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): child.set_process(false); child.panel.hide(); child.play_hub.hide(); child.legend_menu.hide()
	await settle()
	var rows: Array=[]
	for rotation in 6:
		for duration in [.65,.90,.91,.92,.93]:
			var p=restart(); var index: int=adapter.controlled_index
			game.rotations=[rotation,0]; p.position=Vector3(2,0,6); p.rotation.y=PI
			p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO; p.body_lean=Vector2.ZERO; p.play("ready",1,true)
			clear_around(index)
			game.phase="RECEIVE"; game.possession=0; game.receiver=index; game.incoming_kind="serve"; game.incoming_power=.90; game.winner_team=-1; game.last_touch=1; game.touches=[0,0]
			game.armed=false; game.late_receive=false; game.flight_spin=Vector3.ZERO; game.flight_gravity=game.G
			var target: Vector3=p.contact_world("receive")
			if duration>.91: target=p.position+Basis(Vector3.UP,PI)*Vector3(.9 if duration<.93 else -.9,target.y,.9)
			game.select_receive_pose(index,target)
			target.y=p.contact_local("receive").y
			p.position=p.stance_for_contact("receive",target)
			game.ball_pos=Vector3(0,3.2,-8.8)
			var travel: float=preload("res://src/winning_shot.gd").flight_seconds(game,target,duration,2.85)
			game.launch(target,travel)
			game.receive_deadline=game.clock_time+game.flight_left
			var pressed:=false; var until: float=game.clock_time+travel+1
			while game.clock_time<until and game.phase=="RECEIVE":
				if is_equal_approx(duration,.91): adapter.move_input=Vector2(.7,0) if game.flight_left<.30 and game.flight_left>.10 else Vector2.ZERO
				if not pressed and game.flight_left<.18:
					await button(JOY_BUTTON_A); await button(JOY_BUTTON_A,false); pressed=true
				game.step(1.0/120)
			var success: bool=game.contact_log.any(func(row): return int(row.player)==index and row.action=="receive")
			rows.append({"rotation":rotation,"seconds":duration,"success":success,"phase":game.phase,"armed":game.armed,"offset":game.receive_offset,"feedback":adapter.contact_assist.feedback.duplicate(),"events":game.rally_events.slice(maxi(0,game.rally_events.size()-8))})
			check(success,"timed stationary serve reception P%d %.2fs"%[rotation+1,duration])
	FileAccess.open("res://docs/reception76-real-flights.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"failures":failures},"  "))
	print("RECEPTION76 ","PASS" if failures.is_empty() else "FAIL",failures); game.free(); quit(0 if failures.is_empty() else 1)

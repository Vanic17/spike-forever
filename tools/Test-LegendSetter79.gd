extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated appdata")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var rows: Array=[]
	for rotation in 6:
		for quick in [false,true]:
			for remaining in [.20,.08]:
				var p=restart("S");var index: int=adapter.controlled_index
				game.rotations=[rotation,rotation];game.phase="SET";game.possession=0;game.setter=index;game.touches=[1,0];game.last_touch=0
				game.out_of_system=1;game.pass_quality=.95;game.input_quality=.95;game.armed=false;game.late_receive=false;game.setter_dump=false;game.setter_spike=false
				game.set_dir=rotation%4;game.planned_visual_key="";game.plan_attack(game.set_dir,false)
				p.setting_yaw=-PI/2;p.rotation.y=PI;p.velocity=Vector3.ZERO;p.acceleration=Vector3.ZERO;p.play("ready",1,true)
				var point:=Vector3(.2,p.contact_local("set").y,1.8)
				p.position=p.stance_for_contact("set",point);clear_around(index)
				game.ball_pos=point+Vector3(.15,1.2,1);game.launch(point,.55)
				var pressed:=false;var deadline: float=game.clock_time+2
				while game.phase=="SET" and game.clock_time<deadline:
					if not pressed and game.flight_left<remaining:
						await button(JOY_BUTTON_X if quick else JOY_BUTTON_A);await button(JOY_BUTTON_X if quick else JOY_BUTTON_A,false);pressed=true
					game.step(1.0/120)
				var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action in ["set","fast_set"])
				check(not contacts.is_empty(),"manual setter contact "+str([rotation,quick,remaining]))
				if not contacts.is_empty():check(contacts[-1].action==("fast_set" if quick else "set"),"normal versus quick command "+str(rotation))
				rows.append({"rotation":rotation,"quick":quick,"input_remaining":remaining,"contacts":contacts,"events":game.rally_events.slice(maxi(0,game.rally_events.size()-12))})
	FileAccess.open("res://docs/legend79-setting.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"failures":failures},"  "))
	print("LEGEND SETTER79 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

extends "res://tools/Test-LegendInputs75.gd"
const State=preload("res://src/online_state.gd")
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var cases: Array=[]
	for fps in [30,120]:
		for manual in [false,true]:
			for left in [false,true]:
				for quick in [false,true]:
					for direction in 4:
						var p=restart("S");var index: int=adapter.controlled_index
						if not manual:adapter.active=false
						game.rotations=[3,3];game.phase="SET";game.possession=0;game.setter=index;game.input_team=0;game.touches=[1,0];game.last_touch=0
						game.out_of_system=1;game.pass_quality=.95;game.input_quality=.95;game.armed=false;game.late_receive=false;game.setter_dump=false;game.setter_spike=false;game.setter_disguise=false;game.winner_team=-1
						p.left_handed=left;p.rotation.y=PI;p.velocity=Vector3.ZERO;p.acceleration=Vector3.ZERO;p.play("ready",1,true)
						p.select_variant("dump","dump_push54");p.select_variant("attack")
						var action: String="dump"
						var point:=Vector3(0,game.clips.set_disguise81.contact_offset.y,1.8)
						p.position=p.stance_for_contact(action,point);p.rotation.y=PI;clear_around(index)
						game.ball_pos=point+Vector3(0,1.2,.2);game.launch(point,.60)
						game.set_dir=direction
						var before_pos: Vector3=game.ball_pos;var before_vel: Vector3=game.ball_vel;var before_spin: Vector3=game.flight_spin
						await axis(JOY_AXIS_TRIGGER_RIGHT,1)
						await button(JOY_BUTTON_X if quick else JOY_BUTTON_A);await button(JOY_BUTTON_X if quick else JOY_BUTTON_A,false)
						await axis(JOY_AXIS_TRIGGER_RIGHT,0)
						var label:=str([fps,manual,left,quick,direction])
						check(game.setter_disguise and not game.setter_dump and not game.setter_spike,"R2 plus set requests disguise "+label)
						check(game.planned_fast==quick,"Delivery speed preserved "+label)
						check(not game.dive_motions.has(index),"Set modifier does not dive "+label)
						check(game.ball_pos==before_pos and game.ball_vel==before_vel and game.flight_spin==before_spin,"Conversion never rewrites ball flight "+label)
						check(game.planned_direction==direction,"Direction preserved "+label)
						var restored: Dictionary=State.decode(State.encode(State.capture(game)))
						check(restored.setter_disguise,"Disguise survives online snapshot")
						var end: float=game.clock_time+2;var previous_time: float=p.animation_time;var max_step:=0.0
						while game.phase=="SET" and game.clock_time<end:
							var previous: Vector3=p.position;game.step(1.0/fps)
							max_step=maxf(max_step,previous.distance_to(p.position))
							if p.clip_name=="dump":check(p.animation_time>=previous_time-.015,"No jump rewind "+label+str([previous_time,p.animation_time,game.flight_left]));previous_time=p.animation_time
						var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.variant=="set_disguise81")
						check(contacts.size()==1,"One physical two-hand contact "+label)
						check(game.touches[0]==2 and game.phase=="ATTACK","Set reaches attacker as second touch "+label)
						check(max_step<game.Reference.run_speed()*1.2/fps+.01,"No actor teleport "+label)
						cases.append({"fps":fps,"manual":manual,"left_handed":left,"quick":quick,"direction":direction,"contacts":contacts,"maximum_step_m":max_step,"phase":game.phase,"rejects":game.rally_events.filter(func(row):return row.kind=="contact_rejected")})
	for guard in ["already_armed","too_late","back_row_front_zone","libero","third_touch","bad_pass","unreachable","not_airborne"]:
		var p=restart("S");var index: int=adapter.controlled_index;adapter.active=false
		game.rotations=[3,3];game.phase="SET";game.possession=0;game.setter=index;game.touches=[1,0];game.setter_spike=false;game.setter_dump=false;game.setter_disguise=false;game.armed=false;game.out_of_system=1
		p.left_handed=false;p.rotation.y=PI;p.position=Vector3(0,0,2);p.velocity=Vector3.ZERO;p.play("ready",1,true)
		var target:=Vector3(0,game.clips.set_disguise81.contact_offset.y,1.8)
		game.ball_pos=target+Vector3(0,.8,0);game.launch(target,.12 if guard=="too_late" else .5)
		match guard:
			"already_armed":game.armed=true
			"back_row_front_zone":game.rotations=[0,0]
			"libero":game.setter=4;game.server=1;game.rotations=[0,0]
			"third_touch":game.touches=[2,0]
			"bad_pass":game.out_of_system=-1
			"unreachable":p.position=Vector3(4,0,8)
			"not_airborne":game.airborne=false
		check(not preload("res://src/setter_disguise81.gd").request(game,false) and not game.setter_disguise,"Disguise guard "+guard)
	for manual in [false,true]:
		for quick in [false,true]:
			for allowed in [false,true]:
				var p=restart("S");var index: int=adapter.controlled_index
				if not manual:adapter.active=false
				game.rotations=[0,0];game.phase="SET";game.possession=0;game.setter=index;game.input_team=0;game.touches=[1,0];game.out_of_system=1;game.pass_quality=.95
				game.setter_disguise=false;game.setter_dump=false;game.setter_spike=false;game.armed=false
				p.position=Vector3(0,0,2);p.rotation.y=PI;p.play("ready",1,true);clear_around(index)
				var point:=Vector3(0,p.contact_local("set").y,2)
				game.ball_pos=point+Vector3(0,1,0);game.launch(point,.45)
				# Back-row front-zone jump is unavailable; held RT must still set.
				await axis(JOY_AXIS_TRIGGER_RIGHT,1 if not allowed else 0)
				await button(JOY_BUTTON_X if quick else JOY_BUTTON_A);await button(JOY_BUTTON_X if quick else JOY_BUTTON_A,false)
				await axis(JOY_AXIS_TRIGGER_RIGHT,0)
				check(game.armed and not game.setter_disguise and not game.setter_dump and not game.setter_spike,"Ordinary set fallback / unmodified input "+str([manual,quick,allowed]))
				check(game.fast_set==quick and game.setter_action==("fast_set" if quick else "set"),"Fallback keeps normal/quick delivery")
				check(not game.dive_motions.has(index),"Fallback does not dive")
	# Exercise the actual authoritative command handler for each network side.
	for side in 2:
		for quick in [false,true]:
			var p=restart("S");adapter.active=false
			var net=game.online_session;net.playing=true;net.test_mode=true;net.last_sequence=[-1,-1]
			var index: int=side*6+5;p=game.players[index]
			game.rotations=[3,3];game.phase="SET" if side==0 else "CPU_SET";game.possession=side;game.setter=index;game.input_team=side;game.touches=[1,1];game.out_of_system=1;game.pass_quality=.95
			game.armed=false;game.setter_spike=false;game.setter_dump=false;game.setter_disguise=false
			p.position=Vector3(0,0,1.8*(1 if side==0 else -1));p.rotation.y=PI if side==0 else 0;p.play("ready",1,true)
			var point:=Vector3(0,game.clips.set_disguise81.contact_offset.y,p.position.z)
			game.ball_pos=point+Vector3(0,1.2,0);game.launch(point,.6)
			net.apply_command(side,1,"alternate" if quick else "action",true,{"direction":Vector2(-1,0),"right":1.0,"left":0.0})
			check(game.setter_disguise and game.planned_fast==quick,"Online command carries held RT and speed "+str([side,quick]))
			net.playing=false;game.input_team=0
	adapter.active=false;game.phase="CPU_SET";game.possession=1;game.setter=11;game.setter_spike=true;game.setter_dump=false;game.setter_disguise=false;game.touches=[0,1]
	check(not preload("res://src/setter_disguise81.gd").request(game,false),"CPU never initiates new action")
	var native: bool=game.Avatar.native_animation_enabled
	FileAccess.open("res://docs/setter81-gameplay.json" if native else "res://docs/setter81-fallback.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"native":native,"checks":checks,"cases":cases,"failures":failures},"  "))
	print("SETTER81 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

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
				for push in [false,true]:
					for direction in 4:
						var p=restart("S");var index: int=adapter.controlled_index
						if not manual:adapter.active=false
						game.rotations=[3,3];game.phase="SET";game.possession=0;game.setter=index;game.input_team=0;game.touches=[1,0];game.last_touch=0
						game.out_of_system=1;game.pass_quality=.95;game.input_quality=.95;game.armed=false;game.late_receive=false;game.setter_dump=false;game.setter_spike=false;game.setter_disguise=false;game.winner_team=-1
						p.left_handed=left;p.rotation.y=PI;p.velocity=Vector3.ZERO;p.acceleration=Vector3.ZERO;p.play("ready",1,true)
						p.select_variant("dump","dump_push54");p.select_variant("attack")
						var action: String="dump" if push else "attack"
						var point:=Vector3(0,p.contact_local(action).y,.75 if push else 2.2)
						p.position=p.stance_for_contact(action,point);p.rotation.y=PI;clear_around(index)
						game.ball_pos=point+Vector3(0,1.2,.2);game.launch(point,.60)
						if manual:await button(JOY_BUTTON_B);await button(JOY_BUTTON_B,false)
						else:game.press_action("dump")
						check(game.setter_dump if push else game.setter_spike,"Circle retains original action "+str([fps,manual,left,push,direction]))
						for frame in int(ceil(.07*fps)):game.step(1.0/fps)
						game.set_dir=direction
						var before_pos: Vector3=game.ball_pos;var before_vel: Vector3=game.ball_vel;var before_spin: Vector3=game.flight_spin
						if manual:await button(JOY_BUTTON_A);await button(JOY_BUTTON_A,false)
						else:game.press_action("action")
						var label:=str([fps,manual,left,push,direction])
						check(game.setter_disguise and not game.setter_dump and not game.setter_spike,"Circle Cross converts "+label)
						check(game.ball_pos==before_pos and game.ball_vel==before_vel and game.flight_spin==before_spin,"Conversion never rewrites ball flight "+label)
						check(game.planned_direction==direction,"Direction preserved "+label)
						var restored: Dictionary=State.decode(State.encode(State.capture(game)))
						check(restored.setter_disguise,"Disguise survives online snapshot")
						var end: float=game.clock_time+2;var previous_time: float=p.animation_time;var max_step:=0.0
						while game.phase=="SET" and game.clock_time<end:
							var previous: Vector3=p.position;game.step(1.0/fps)
							max_step=maxf(max_step,previous.distance_to(p.position))
							if p.clip_name=="dump":check(p.animation_time>=previous_time-.015,"No jump rewind "+label);previous_time=p.animation_time
						var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.variant=="set_disguise81")
						check(contacts.size()==1,"One physical two-hand contact "+label)
						check(game.touches[0]==2 and game.phase=="ATTACK","Set reaches attacker as second touch "+label)
						check(max_step<game.Reference.run_speed()*1.2/fps+.01,"No actor teleport "+label)
						cases.append({"fps":fps,"manual":manual,"left_handed":left,"from_push":push,"direction":direction,"contacts":contacts,"maximum_step_m":max_step,"phase":game.phase,"rejects":game.rally_events.filter(func(row):return row.kind=="contact_rejected")})
	for guard in ["expired","too_late","back_row_front_zone","libero","third_touch","no_circle","unreachable","not_airborne"]:
		var p=restart("S");var index: int=adapter.controlled_index;adapter.active=false
		game.rotations=[3,3];game.phase="SET";game.possession=0;game.setter=index;game.touches=[1,0];game.setter_spike=true;game.setter_dump=false;game.setter_disguise=false;game.armed=true
		p.left_handed=false;p.rotation.y=PI;p.position=Vector3(0,0,2);p.velocity=Vector3.ZERO;p.play("ready",1,true)
		var target:=Vector3(0,game.clips.set_disguise81.contact_offset.y,1.8)
		game.ball_pos=target+Vector3(0,.8,0);game.launch(target,.12 if guard=="too_late" else .5)
		preload("res://src/setter_disguise81.gd").offer(game)
		match guard:
			"expired":game.set_meta("second_disguise81",{"actor":index,"rally":game.rally_serial,"until":game.clock_time-.01})
			"back_row_front_zone":game.rotations=[0,0]
			"libero":game.setter=4;game.server=1;game.rotations=[0,0];preload("res://src/setter_disguise81.gd").offer(game)
			"third_touch":game.touches=[2,0]
			"no_circle":game.setter_spike=false
			"unreachable":p.position=Vector3(4,0,8)
			"not_airborne":game.airborne=false
		check(not preload("res://src/setter_disguise81.gd").convert(game) and not game.setter_disguise,"Disguise guard "+guard)
	adapter.active=false;game.phase="CPU_SET";game.possession=1;game.setter=11;game.setter_spike=true;game.setter_dump=false;game.setter_disguise=false;game.touches=[0,1]
	check(not preload("res://src/setter_disguise81.gd").convert(game),"CPU never initiates new action")
	var native: bool=game.Avatar.native_animation_enabled
	FileAccess.open("res://docs/setter81-gameplay.json" if native else "res://docs/setter81-fallback.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"native":native,"checks":checks,"cases":cases,"failures":failures},"  "))
	print("SETTER81 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

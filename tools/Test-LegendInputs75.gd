extends SceneTree
## Real main.tscn, native PSA assets and viewport event dispatch. No button signals
## or direct input handlers are used: only Input.parse_input_event.
const Career=preload("res://src/legend_career.gd")
const Roles={"OH":"outside_hitter","S":"setter","L":"libero"}
var game
var adapter
var manager=Career.new()
var checks:=0
var failures: Array[String]=[]
var report: Dictionary={"dispatch":"Input.parse_input_event -> viewport -> main -> legend adapter","controller_labels":{"A":"Xbox A / PlayStation Cross","X":"Xbox X / PlayStation Square","RB":"RB / R1","RT":"RT / R2","LB":"LB / L1","LT":"LT / L2"}}
var pad_device:=0
var native_events:=0

func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error("LEGEND INPUT75: "+message)
func settle():
	await process_frame
	await process_frame
func dispatch(event: InputEvent):
	native_events+=1; Input.parse_input_event(event); await settle()
func button(index: int,pressed: bool=true):
	var event:=InputEventJoypadButton.new(); event.device=pad_device; event.button_index=index; event.pressed=pressed
	await dispatch(event)
func axis(index: int,value: float):
	var event:=InputEventJoypadMotion.new(); event.device=pad_device; event.axis=index; event.axis_value=value
	await dispatch(event)
func key(code: int,pressed: bool=true,echo: bool=false):
	var event:=InputEventKey.new(); event.physical_keycode=code; event.pressed=pressed; event.echo=echo
	await dispatch(event)
func tick(frames: int):
	for frame in frames: game.step(1.0/120.0)
func clear_around(index: int):
	var subject=game.players[index]
	for other in 6:
		if other!=index and game.players[other].position.distance_to(subject.position)<1.7:
			game.players[other].position=Vector3(-5.5+other*1.7,0,9.5)
func restart(role: String="OH"):
	if adapter.active: adapter.stop()
	var profile: Dictionary=manager.default_profile(); profile.name="Native inputs 75 "+role; profile.role=Roles[role]
	check(manager.new_career(profile,str(manager.starter_clubs()[0].id),{"best_of":3,"autosave":false,"seed":194260,"fatigue":false},12),"create isolated "+role+" career")
	var config: Dictionary=manager.launch_config(); config.seed=194260; config.first_server=0; config.options.fatigue=false
	check(adapter.start(config),"start real shared "+role+" adapter")
	game.self_test=true; game.demo=false; game.replay.enabled=false; game.replay.active=false; game.match_audio.enabled=false
	game.paused=false; game.pause_menu.surface.hide(); game.charging=false; game.armed=false
	root.gui_release_focus()
	return game.players[adapter.controlled_index]
func receive_scene(remaining: float=.2):
	var p=restart(); var index: int=adapter.controlled_index
	p.position=Vector3(-2.2,0,5); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO; p.body_lean=Vector2.ZERO
	p.play("ready",1,true); clear_around(index)
	game.set_phase("RECEIVE"); game.possession=0; game.receiver=index; game.last_touch=1; game.incoming_kind="serve"; game.incoming_power=.8; game.touches=[0,0]
	game.late_receive=false; game.receive_offset=0; game.input_quality=0
	game.airborne=true; game.flight_target=p.contact_world("receive"); game.flight_left=maxf(.001,remaining); game.receive_deadline=game.clock_time+remaining
	game.ball_pos=game.flight_target; game.ball_vel=Vector3(0,-3,0); game.flight_spin=Vector3.ZERO; game.flight_gravity=game.G
	return p
func attack_scene():
	var p=restart(); var index: int=adapter.controlled_index
	p.position=Vector3(3.3,0,3.5); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; p.play("ready",1,true); clear_around(index)
	game.set_phase("ATTACK"); game.possession=0; game.last_touch=0; game.hitter=index; game.hitter_action="attack"; game.planned_hitter=index; game.touches=[2,0]
	game.pass_quality=1; game.out_of_system=1; game.destination=2; game.planned_direction=2; game.plan_attack(2,false)
	game.airborne=false; game.flight_left=100; game.charge=.9; game.ball_pos=p.contact_world("attack")
	return p
func set_scene():
	var p=restart("S"); var index: int=adapter.controlled_index
	p.position=Vector3(0,0,2.6); p.rotation.y=-PI/2; p.setting_yaw=-PI/2; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; p.play("ready",1,true); clear_around(index)
	game.set_phase("SET"); game.possession=0; game.setter=index; game.receiver=0; game.last_touch=0; game.touches=[1,0]
	game.pass_quality=1; game.out_of_system=1; game.set_dir=0; game.planned_hitter=-1; game.setter_dump=false
	game.airborne=true; game.flight_target=p.contact_world("set"); game.ball_pos=game.flight_target; game.ball_vel=Vector3(0,-1,0); game.flight_spin=Vector3.ZERO; game.flight_left=.2
	return p
func has_feedback() -> bool:
	var state: Dictionary=adapter.hud_state()
	return not str(state.get("feedback","")).strip_edges().is_empty() and float(state.get("feedback_left",0))>0

func test_controller_devices():
	var cases: Array=[]
	for device in [0,3,7]:
		pad_device=device
		var p=attack_scene(); var roots: Vector3=p.position
		await button(JOY_BUTTON_A)
		check(game.charging and adapter.buttons.get("action",false),"Xbox A / Cross begins physical charge on device "+str(device))
		game.clock_time+=.15; var before: float=game.charge_start
		await button(JOY_BUTTON_A)
		check(game.charge_start==before,"repeated held A cannot restart charge")
		await button(JOY_BUTTON_A,false)
		check(game.armed and not game.charging and game.charge>0,"A release locks charge once through native dispatch")
		check(p.position==roots,"button charge cannot move athlete root")
		p=attack_scene(); await button(JOY_BUTTON_X)
		check(game.charging and game.attack_tip and game.charge_button=="alternate","Xbox X / Square selects tip charge on device "+str(device))
		await button(JOY_BUTTON_X,false)
		check(game.armed and not game.charging,"Square release arms real tip")
		cases.append({"device":device,"primary_charge":true,"tip_charge":true})
	report.devices=cases; pad_device=0

func test_receive_choices_and_timing():
	var cases: Array=[]
	for remaining in [-.06,.08,.25,.5,.8]:
		var p=receive_scene(remaining)
		game.select_receive_pose(adapter.controlled_index,game.flight_target)
		game.flight_target=p.contact_world("receive")
		game.ball_pos=game.flight_target+Vector3(0,remaining*3,0)
		game.ball_vel=game.BallFlight.velocity_to(game.ball_pos,game.flight_target,remaining,game.flight_spin,game.flight_gravity) if remaining>0 else Vector3(0,-3,0)
		var origin: Vector3=p.position; var ball: Vector3=game.ball_pos
		var target: Vector3=game.flight_target; var left: float=game.flight_left
		# Same instantiated actor, rating, incoming ball and difficulty. Disable
		# the adapter for one legacy press to compare its unchanged timing path.
		adapter.active=false; game.input_team=0
		await button(JOY_BUTTON_A)
		var legacy: float=game.input_quality; var legacy_armed: bool=game.armed
		await button(JOY_BUTTON_A,false)
		adapter.active=true; game.armed=false; game.input_quality=0; game.receive_deadline=game.clock_time+remaining; game.late_receive=false; game.flight_target=target; game.flight_left=left; adapter.buttons.clear()
		await button(JOY_BUTTON_A)
		var easier: float=game.input_quality
		check(game.armed and legacy_armed,"both actual input paths arm reception at "+str(remaining))
		check(easier>=legacy and (is_equal_approx(remaining,.08) or easier>legacy+.02),"career reception timing is easier than legacy on same actor at "+str(remaining))
		check(game.ball_pos==ball and p.position==origin,"receive command preserves incoming flight and root")
		cases.append({"remaining":remaining,"legacy":legacy,"legend":easier,"actual_legend_offset":game.receive_offset})
		await button(JOY_BUTTON_A,false)
	report.timing_same_actor=cases
	var gestures: Array=[]
	for pad_button in [JOY_BUTTON_A,JOY_BUTTON_X]:
		var p=receive_scene(.15); var origin: Vector3=p.position; var ball: Vector3=game.ball_pos; var velocity: Vector3=game.ball_vel
		var original_receive=p.clips.receive
		if pad_button==JOY_BUTTON_X:
			game.flight_target=p.contact_world("set"); game.ball_pos=game.flight_target+Vector3(0,.3,0); game.ball_vel=Vector3(0,-2,0)
			ball=game.ball_pos; velocity=game.ball_vel
		await button(pad_button)
		check(game.armed,"first touch "+str(pad_button)+" is accepted")
		var action: String=adapter.receive_contact_action() if adapter.has_method("receive_contact_action") else "receive"
		check(action==("receive" if pad_button==JOY_BUTTON_A else "set"),"Cross is bagher and Square is overhead first touch")
		check(p.position==origin and game.ball_pos==ball and game.ball_vel==velocity,"gesture choice preserves native ball/root motion")
		# Scene placement establishes the real palms before the contact event.
		# The command itself above must never move either ball or athlete.
		p.position=p.stance_for_contact("receive",game.flight_target); p.rotation.y=PI; p.body_lean=Vector2.ZERO; clear_around(adapter.controlled_index)
		game.ball_pos=game.flight_target; game.receive_ball()
		check(game.contact_log.size()>0 and game.contact_log[-1].action=="receive" and game.contact_log[-1].gap<=.18,"first touch uses chosen native gesture and ordinary physical palm validation")
		if pad_button==JOY_BUTTON_X: check(p.clips.receive==p.source_clips.set,"Square first touch uses actual existing native overhead set source")
		var row: Dictionary=game.match_management.measured.get(manager.state.profile.id,{})
		check(int(row.get("receptions",0))==1 and int(row.get("sets",0))==0,"overhead first touch remains measured as reception, not a second-touch set")
		gestures.append({"button":pad_button,"action":action,"contact":game.contact_log[-1] if not game.contact_log.is_empty() else {},"receptions":int(row.get("receptions",0)),"sets":int(row.get("sets",0))})
		await button(pad_button,false)
		if pad_button==JOY_BUTTON_X:
			adapter.stop()
			check(p.clips.receive==original_receive,"leaving career restores receive source before exhibition resumes")
	report.first_touch_gestures=gestures
	var p=receive_scene(.1); await button(JOY_BUTTON_X)
	check(game.armed and adapter.receive_contact_action()=="receive" and has_feedback(),"Square on low ball clearly falls back to physically available bagher")
	await button(JOY_BUTTON_X,false)
	p=receive_scene(.1); game.flight_left=.02; game.receive_deadline=game.clock_time+.02
	tick(8)
	check(game.test_contacts==0 and not game.armed,"wider timing cannot receive an uncommanded ball")

func test_movement_aim_and_sprint():
	var p=receive_scene(); game.phase="ATTACK"; game.hitter=adapter.controlled_index; game.planned_hitter=game.hitter; game.airborne=false; game.flight_left=100
	var origin: Vector3=p.position
	await axis(JOY_AXIS_LEFT_X,.8); tick(12)
	check(p.position.distance_to(origin)>.02 and adapter.movement_vector().length()>.5,"left stick moves actual created athlete")
	await axis(JOY_AXIS_LEFT_X,0); tick(30)
	check(adapter.movement_vector()==Vector3.ZERO,"left stick release stops movement intent")
	await axis(JOY_AXIS_RIGHT_X,.75); await axis(JOY_AXIS_RIGHT_Y,-.45)
	check(adapter.current_aim().distance_to(Vector2(.75,-.45))<.001,"right stick controls separate actual aim")
	adapter.apply_controls(.1)
	check(game.aim.length()>.1,"right stick reaches shared game aim")
	await axis(JOY_AXIS_RIGHT_X,0); await axis(JOY_AXIS_RIGHT_Y,0)
	p.position=origin; p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO
	await axis(JOY_AXIS_LEFT_X,1); tick(50); var ordinary: float=p.velocity.length()
	p.position=origin; p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO
	await axis(JOY_AXIS_TRIGGER_LEFT,1); tick(50); var sprint: float=p.velocity.length()
	check(sprint>ordinary*1.04,"LT/L2 increases actual running speed")
	await axis(JOY_AXIS_TRIGGER_LEFT,0); await axis(JOY_AXIS_LEFT_X,0)
	check(adapter.sprint_input==0 and adapter.movement_vector()==Vector3.ZERO,"LT and left-stick release rearm cleanly")
	report.movement={"normal_speed":ordinary,"sprint_speed":sprint}

func test_jump_call_set_dump():
	var p=attack_scene(); var origin: Vector3=p.position
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(p.clip_name=="attack" and not adapter.source_motion.is_empty(),"RB/R1 starts native jump attack")
	check(p.position==origin,"jump request starts existing source motion without teleport")
	var jump_time: float=p.animation_time
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(p.animation_time==jump_time,"repeated RB does not restart jump")
	await button(JOY_BUTTON_RIGHT_SHOULDER,false)
	p=restart(); var block_index: int=adapter.controlled_index
	p.position=Vector3(4,0,.68); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.play("ready",1,true); clear_around(block_index)
	game.set_phase("CPU_ATTACK"); game.possession=1; game.last_touch=1; game.hitter=6; game.hitter_action="attack"; game.incoming_kind="spike"
	game.airborne=false; game.flight_left=100; game.block_time=-100; game.block_commanded=false; game.block_rosters.clear(); game.block_orders.clear()
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(p.clip_name=="block" and adapter.source_motion.get("action","")=="block" and block_index in game.blocking_players(0),"RB/R1 at net starts actual manual block and enters native wall")
	await button(JOY_BUTTON_RIGHT_SHOULDER,false)
	p=restart(); var index: int=adapter.controlled_index
	game.set_phase("SET"); game.possession=0; game.setter=5; game.receiver=4; game.last_touch=0; game.touches=[1,0]; game.pass_quality=1; game.out_of_system=1
	game.airborne=false; game.flight_left=100; game.set_dir=0; game.planned_hitter=-1
	await button(JOY_BUTTON_LEFT_SHOULDER)
	check(game.planned_hitter==index,"LB/L1 requests actual manual hitter from AI setter")
	await button(JOY_BUTTON_LEFT_SHOULDER,false)
	game.planned_hitter=-1; await key(KEY_F)
	check(game.planned_hitter==index,"F requests actual manual hitter from AI setter")
	await key(KEY_F,false)
	for pad_button in [JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_B]:
		p=set_scene(); var ball: Vector3=game.ball_pos
		await button(pad_button)
		check(game.armed,"set input "+str(pad_button)+" arms shared second touch")
		check(game.fast_set==(pad_button==JOY_BUTTON_X),"Square selects quick and Cross selects normal set")
		check(game.ball_pos==ball,"second touch choice preserves incoming ball")
		if pad_button==JOY_BUTTON_B: check(has_feedback(),"unavailable B/Circle dump explains normal-set fallback")
		await button(pad_button,false)
	p=set_scene(); index=adapter.controlled_index; game.rotations[0]=3; game.out_of_system=1
	p.position=Vector3(0,0,.8); p.rotation.y=PI; clear_around(index)
	var height: float=p.source_clips.dump_push54.contact_offset.y
	game.ball_pos=Vector3(0,height+.18,.8); game.ball_vel=Vector3(0,-2,0); game.flight_target=Vector3(0,height,.8)
	await button(JOY_BUTTON_B)
	check(game.armed and game.setter_dump and game.setter_action=="dump","legal B/Circle selects real dump gesture")
	await button(JOY_BUTTON_B,false)
	for pad_button in [JOY_BUTTON_A,JOY_BUTTON_X]:
		p=restart(); game.rotations[0]=1; game.server=0; game.reset_rally()
		check(game.server_index(0)==adapter.controlled_index,"serve setup uses created athlete's real rotation")
		await button(pad_button)
		check(game.charging and game.serve_type==(1 if pad_button==JOY_BUTTON_A else 0),"Cross power / Square float starts native serve charge")
		game.clock_time+=.2; await button(pad_button,false)
		check(not game.charging and (game.toss_active or game.serve_adjusting or game.serve_windup_left>0),"serve release enters existing physical service lifecycle")

func dive_scene(far: bool=false):
	var p=receive_scene(); var index: int=adapter.controlled_index
	game.incoming_kind="spike"; game.ball_pos=p.position+Vector3(6 if far else .30,1.6,-.70); game.ball_vel=Vector3(0,-4,0)
	game.flight_target=game.ball_pos; game.flight_left=.2; game.receive_deadline=game.clock_time+.2
	return p
func test_dive_and_trigger_rearm():
	var cases: Array=[]
	for far in [false,true]:
		var p=dive_scene(far); var index: int=adapter.controlled_index; var origin: Vector3=p.position; var ball: Vector3=game.ball_pos
		await axis(JOY_AXIS_TRIGGER_RIGHT,.85)
		check(adapter.buttons.get("dive_trigger",false),"RT/R2 latches rising edge")
		if far: check(not game.dive_motions.has(index) and has_feedback(),"unreachable far RT explains failed dive without fabricated movement")
		else: check(game.dive_motions.has(index),"explicit near RT starts physical manual dive")
		check(p.position==origin and game.ball_pos==ball,"dive request never teleports root or ball")
		var motion: Dictionary=game.dive_motions.get(index,{}).duplicate(true)
		await axis(JOY_AXIS_TRIGGER_RIGHT,.95)
		check(game.dive_motions.get(index,{})==motion,"held trigger cannot restart source dive")
		var maximum:=0.0
		for frame in 18:
			var before: Vector3=p.position; tick(1); maximum=maxf(maximum,p.position.distance_to(before))
		check(maximum<.14,"manual dive root advances within native velocity limit")
		if far: check(game.test_contacts==0,"far dive cannot fabricate ball contact")
		await axis(JOY_AXIS_TRIGGER_RIGHT,0)
		check(not adapter.buttons.get("dive_trigger",false),"trigger release rearms RT")
		cases.append({"far":far,"starts":not motion.is_empty(),"maximum_step":maximum,"contacts":game.test_contacts})
	var p=dive_scene(); var index: int=adapter.controlled_index
	await axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	check(game.dive_motions.has(index),"new trigger press works after a released prior dive")
	await axis(JOY_AXIS_TRIGGER_RIGHT,0)
	report.dives=cases
	p=dive_scene(); index=adapter.controlled_index
	game.ball_pos=p.position+Vector3(.3,5.5,-.7); game.ball_vel=Vector3(0,-1,0); game.flight_left=.95; game.receive_deadline=game.clock_time+.95
	var origin: Vector3=p.position; var ball: Vector3=game.ball_pos
	await axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	check(not game.dive_motions.has(index) and p.position==origin and game.ball_pos==ball and has_feedback(),"early RT gives preparation feedback while preserving physical state")
	var began:=false
	for frame in 48:
		tick(1)
		if game.dive_motions.has(index): began=true; break
	check(began,"early RT is buffered into a reachable native dive without repeated trigger press")
	await axis(JOY_AXIS_TRIGGER_RIGHT,0)
	report.early_dive_buffer=began
	p=dive_scene(); index=adapter.controlled_index
	game.ball_pos=p.position+Vector3(.3,5.5,-.7); game.ball_vel=Vector3(0,-1,0); game.flight_left=.95; game.receive_deadline=game.clock_time+.95
	await axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	check(adapter.contact_assist.pending_dive_until>=0,"early dive request belongs to current flight")
	game.phase="SET"; game.setter=5
	adapter.before_step(1.0/120)
	check(adapter.contact_assist.pending_dive_until<0 and not game.dive_motions.has(index) and game.setter==5,"a prepared dive cannot spill into the teammate's next second touch")
	check(adapter.contact_assist.feedback.is_empty(),"a canceled dive cannot leave a stale queued-request message")
	await axis(JOY_AXIS_TRIGGER_RIGHT,0)
	p=dive_scene(); index=adapter.controlled_index
	game.receiver=3; game.ball_pos=p.position+Vector3(.3,1.6,.7); game.flight_target=game.ball_pos
	var original_deadline: float=game.receive_deadline
	await axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	check(not game.dive_motions.has(index) and game.receiver==3 and game.receive_deadline==original_deadline,"failed backwards manual dive restores the teammate's original contact assignment")
	await axis(JOY_AXIS_TRIGGER_RIGHT,0)

func test_pause_replay_and_keyboard():
	attack_scene(); await button(JOY_BUTTON_A); await axis(JOY_AXIS_LEFT_X,.8); await axis(JOY_AXIS_TRIGGER_LEFT,1); await key(KEY_W)
	await button(JOY_BUTTON_START); await button(JOY_BUTTON_START,false)
	check(game.paused,"native Start pauses match")
	await button(JOY_BUTTON_A,false); await axis(JOY_AXIS_LEFT_X,0); await axis(JOY_AXIS_TRIGGER_LEFT,0); await key(KEY_W,false)
	check(not adapter.buttons.get("action",false) and not adapter.keys.get(KEY_W,false) and adapter.movement_vector()==Vector3.ZERO and adapter.sprint_input==0,"pause consumes GUI input while passive releases clear all held state")
	check(not game.charging,"charge released during pause cannot survive resume")
	await button(JOY_BUTTON_START); await button(JOY_BUTTON_START,false)
	check(not game.paused,"native Start resumes match")
	await button(JOY_BUTTON_A); check(game.charging,"fresh A starts after pause swallowed release"); await button(JOY_BUTTON_A,false)
	attack_scene(); await button(JOY_BUTTON_A); await axis(JOY_AXIS_TRIGGER_RIGHT,.8); await axis(JOY_AXIS_LEFT_X,.8); await axis(JOY_AXIS_RIGHT_X,.7); await axis(JOY_AXIS_TRIGGER_LEFT,1); await key(KEY_W)
	game.charging=false; game.phase="POINT"; game.replay.active=true
	var ball: Vector3=game.ball_pos; var origin: Vector3=game.players[adapter.controlled_index].position; var contacts: int=game.test_contacts
	await button(JOY_BUTTON_A,false); await axis(JOY_AXIS_TRIGGER_RIGHT,0); await axis(JOY_AXIS_LEFT_X,0); await axis(JOY_AXIS_RIGHT_X,0); await axis(JOY_AXIS_TRIGGER_LEFT,0); await key(KEY_W,false)
	check(not adapter.buttons.get("action",false) and not adapter.buttons.get("dive_trigger",false) and not adapter.keys.get(KEY_W,false) and adapter.movement_vector()==Vector3.ZERO and adapter.current_aim()==Vector2.ZERO and adapter.sprint_input==0,"replay swallowed releases clear action, dive, aim, sprint and movement")
	check(not game.charging and game.ball_pos==ball and game.players[adapter.controlled_index].position==origin and game.test_contacts==contacts,"replay release cache cannot act on ball or athlete")
	game.replay.active=false; game.phase="ATTACK"; game.armed=false
	await button(JOY_BUTTON_A); check(game.charging,"fresh A works after replay release"); await button(JOY_BUTTON_A,false)
	var p=attack_scene(); await key(KEY_SPACE); check(game.charging,"Space starts primary charge")
	var start: float=game.charge_start; game.clock_time+=.1; await key(KEY_SPACE,true,true)
	check(game.charge_start==start,"keyboard echo cannot restart charge"); await key(KEY_SPACE,false)
	p=attack_scene(); await key(KEY_Q); check(game.attack_tip and game.charging,"Q starts alternate tip"); await key(KEY_Q,false)
	p=attack_scene(); await key(KEY_R); check(p.clip_name=="attack" and not adapter.source_motion.is_empty(),"R starts physical jump"); await key(KEY_R,false)
	p=dive_scene(); await key(KEY_C); check(game.dive_motions.has(adapter.controlled_index),"C starts physical dive"); await key(KEY_C,false)
	p=set_scene(); await key(KEY_E); check(game.armed,"E requests second-touch dump/fallback"); await key(KEY_E,false)
	p=receive_scene(); await key(KEY_D); await key(KEY_SHIFT); tick(12)
	check(adapter.movement_vector().length()>.5 and p.velocity.length()>.5,"WASD and Shift move athlete")
	await key(KEY_D,false); await key(KEY_SHIFT,false); await key(KEY_RIGHT)
	check(adapter.current_aim()==Vector2.RIGHT,"arrow keys aim separately"); await key(KEY_RIGHT,false)
	check(adapter.current_aim()==Vector2.ZERO and adapter.movement_vector()==Vector3.ZERO,"keyboard releases clear aim and motion")
	var camera: int=game.camera_mode; await key(KEY_V); await key(KEY_V,false)
	check(game.camera_mode!=camera,"V cycles actual camera")
	camera=game.camera_mode; await button(JOY_BUTTON_Y); await button(JOY_BUTTON_Y,false)
	check(game.camera_mode!=camera,"Y/Triangle cycles actual camera")
	report.pause_replay_releases=true

func test_unavailable_feedback():
	var p=receive_scene(); adapter.manual_available=false; await button(JOY_BUTTON_A)
	check(not game.armed and has_feedback(),"substituted/unavailable player action explains why no contact occurs")
	await button(JOY_BUTTON_A,false)
	p=receive_scene(); game.phase="SERVE"; game.server=1; await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(adapter.source_motion.is_empty() and has_feedback(),"jump unavailable during serve has feedback")
	await button(JOY_BUTTON_RIGHT_SHOULDER,false)
	p=attack_scene(); await axis(JOY_AXIS_TRIGGER_RIGHT,.9)
	check(not game.dive_motions.has(adapter.controlled_index) and has_feedback(),"dive unavailable during attack has feedback")
	await axis(JOY_AXIS_TRIGGER_RIGHT,0)
	p=restart("L"); game.phase="CPU_ATTACK"; game.possession=1; game.last_touch=1; p.position=Vector3(0,0,.7); p.play("ready",1,true)
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(adapter.source_motion.is_empty() and has_feedback(),"libero's illegal block is explained")
	await button(JOY_BUTTON_RIGHT_SHOULDER,false)

func run():
	var path: String=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(path.contains("/.runtime/") and path.contains("legend75"),"requires project-local isolated legend75 APPDATA")
	if not failures.is_empty(): quit(2); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false; game.replay.enabled=false
	for p in game.players: p.set_process(false); p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):
			child.startup_scan=false; child.set_process(false); child.panel.hide(); child.play_hub.hide(); child.legend_menu.hide()
	await settle()
	check(game.clips.size()>=137,"native real main loaded all 137 PSA clip sources")
	await test_controller_devices()
	await test_receive_choices_and_timing()
	await test_movement_aim_and_sprint()
	await test_jump_call_set_dump()
	await test_dive_and_trigger_rearm()
	await test_pause_replay_and_keyboard()
	await test_unavailable_feedback()
	report.checks=checks; report.failures=failures; report.native_events=native_events; report.native_clips=game.clips.size(); report.user_path=path
	FileAccess.open("res://docs/legend75-inputs.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND INPUT75 ","PASS" if failures.is_empty() else "FAIL"," ",JSON.stringify(report))
	game.free(); quit(0 if failures.is_empty() else 1)

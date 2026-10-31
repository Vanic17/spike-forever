extends SceneTree
## Real active adapter and the exhibition main.tscn, with native PSA assets.
const Career=preload("res://src/legend_career.gd")
const Tactics=preload("res://src/tactics.gd")
const Roles={"OH":"outside_hitter","MB":"middle_blocker","OPP":"opposite","S":"setter","L":"libero"}
var game
var adapter
var manager=Career.new()
var checks:=0
var failures: Array[String]=[]
var report: Dictionary={}

func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error("LEGEND GAMEPLAY73 "+message)

func button(index: int,pressed: bool=true):
	var input:=InputEventJoypadButton.new(); input.button_index=index; input.pressed=pressed
	game._unhandled_input(input)

func tick(frames: int):
	for frame in frames: game.step(1.0/120.0)

func restart(role: String="OH"):
	if adapter.active: adapter.stop()
	var person: Dictionary=manager.default_profile(); person.name="Gameplay 73 "+role; person.role=Roles[role]
	check(manager.new_career(person,str(manager.starter_clubs()[0].id),{"best_of":3,"autosave":false,"seed":194260,"fatigue":false},12),"create real "+role+" career")
	var config: Dictionary=manager.launch_config(); config.seed=194260; config.first_server=0; config.options.fatigue=false
	check(adapter.start(config),"start actual shared "+role+" adapter")
	game.self_test=true; game.demo=false; game.replay.enabled=false; game.match_audio.enabled=false
	return game.players[adapter.controlled_index]

func clear_around(index: int):
	var subject=game.players[index]
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other!=index and game.players[other].position.distance_to(subject.position)<1.5:
			game.players[other].position.x=clampf(game.players[other].position.x+2.0,-6,6)

func test_roles_and_substitutions():
	var cases: Array=[]
	for role in Roles:
		restart(role)
		var id: String=manager.state.profile.id
		for rotation in 6:
			for serving in [false,true]:
				game.rotations=[rotation,0]; game.server=0 if serving else 1
				game.reset_rally()
				var visible: Array[int]=[]
				for index in 6:
					var p=game.players[index]
					var identity: Dictionary=p.libero_identity if p.libero_active else p.roster_identity
					if str(identity.get("id",""))==id: visible.append(index)
				check(visible.size()<=1,"created "+role+" identity never duplicated on court")
				check(adapter.manual_available==not visible.is_empty(),"actual shared substitution controls availability: "+role+" R"+str(rotation))
				var count:=0
				for index in 12:
					if adapter.owns(index): count+=1
				check(count==visible.size(),"only the actual visible created athlete receives manual ownership")
				if not visible.is_empty(): check(adapter.controlled_index==visible[0],"manual selection follows the created identity through native libero substitutions")
				cases.append({"role":role,"rotation":rotation,"serving":serving,"manual":adapter.manual_available,"index":adapter.controlled_index})
	report.role_cases=cases

func test_receive_and_recovery():
	var p=restart("OH"); var index: int=adapter.controlled_index
	p.position=Vector3(-2.2,0,5.0); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; clear_around(index)
	game.set_phase("RECEIVE"); game.possession=0; game.receiver=index; game.last_touch=1; game.incoming_kind="serve"; game.incoming_power=.8; game.touches=[0,0]
	game.airborne=true; game.flight_target=p.contact_world("receive"); game.flight_left=.08; game.receive_deadline=game.clock_time+.08
	game.ball_pos=game.flight_target; game.ball_vel=Vector3(0,-3,0)
	var expected: float=preload("res://src/legend_contact.gd").quality(.08,game.difficulty_scale())
	var root_before: Vector3=p.position; var ball_before: Vector3=game.ball_pos
	button(JOY_BUTTON_A)
	check(game.armed and absf(game.input_quality-expected)<.00001,"Cross/A uses the manual career timing assistance before the shared contact")
	check(game.ball_pos==ball_before and p.position==root_before,"reception input does not warp ball or body to an authored contact")
	game.receive_ball()
	check(game.phase=="SET" and game.match_management.measured.get(manager.state.profile.id,{}).get("receptions",0)==1,"real commanded native reception produces shared second touch and measured reception")
	check(game.contact_log.size()>0 and game.contact_log[-1].player==index and game.contact_log[-1].gap<=.18,"reception uses the same bounded physical palm validation as exhibition")
	button(JOY_BUTTON_A,false)
	report.receive_timing=expected
	p=restart("OH"); index=adapter.controlled_index
	p.position=Vector3(-1.1,0,5); p.rotation.y=PI; p.velocity=Vector3.ZERO; clear_around(index)
	game.set_phase("RECEIVE"); game.possession=0; game.receiver=index; game.last_touch=1; game.incoming_kind="spike"; game.touches=[0,0]
	game.ball_pos=p.position+Vector3(.30,1.6,-.70); game.ball_vel=Vector3(0,-4,0); game.flight_spin=Vector3.ZERO; game.flight_gravity=game.G; game.airborne=true; game.flight_target=game.ball_pos; game.flight_left=.2
	check(not game.queue_recovery(true) and not game.dive_motions.has(index),"the controlled player never starts an automatic source-driven dive")
	var dive_before: Vector3=p.position
	var trigger:=InputEventJoypadMotion.new(); trigger.axis=JOY_AXIS_TRIGGER_RIGHT; trigger.axis_value=.8
	adapter._input(trigger)
	check(not adapter.buttons.get("dive_trigger",false),"passive raw input never pre-consumes the RT/R2 rising edge")
	game._unhandled_input(trigger)
	check(adapter.buttons.get("dive_trigger",false) and game.dive_motions.has(index),"an explicit RT/R2 event starts the real exhibition dive performance")
	check(game.dive_motions.has(index) and game.players[index].position==dive_before,"manual dive enters the shared root-motion controller without teleporting at request")
	var maximum:=0.0
	for frame in 12:
		var previous: Vector3=p.position; game.step(1.0/120.0); maximum=maxf(maximum,p.position.distance_to(previous))
	check(maximum<.13,"native recovery advances with bounded source motion")
	report.manual_dive_max_step=maximum

func test_buffered_attacks_and_replay_releases():
	var cases: Array=[]
	for alternate in [false,true]:
		var p=restart("OH"); var index: int=adapter.controlled_index
		var setter=game.players[5]
		setter.position=Vector3(0,0,2.6); setter.rotation.y=-PI/2; setter.setting_yaw=-PI/2; setter.velocity=Vector3.ZERO; setter.body_lean=Vector2.ZERO
		p.position=Vector3(3.8,0,3.7); p.rotation.y=PI; p.velocity=Vector3.ZERO
		clear_around(5)
		game.set_phase("SET"); game.possession=0; game.setter=5; game.receiver=4; game.last_touch=0; game.touches=[1,0]; game.pass_quality=1; game.out_of_system=1; game.set_dir=2
		game.plan_attack(2,false)
		check(game.planned_hitter==index and not adapter.owns(5),"buffer scenario retains the AI setter and actual manual pin recipient")
		game.airborne=true; game.flight_target=setter.contact_world("set"); game.ball_pos=game.flight_target; game.ball_vel=Vector3(0,-1,0); game.flight_spin=Vector3.ZERO; game.flight_left=.4
		var kind: String="alternate" if alternate else "action"
		var pad_button: int=JOY_BUTTON_X if alternate else JOY_BUTTON_A
		var before_setter: Vector3=setter.position
		button(pad_button)
		check(adapter.buffered_stroke==kind and game.attack_buffer_start==game.clock_time and game.attack_buffer_power<0,"early held attack is queued through the exhibition attack buffer")
		check(game.setter==5 and not game.armed and not game.charging and setter.position==before_setter,"the attack buffer cannot command or move the AI setter")
		game.clock_time+=.12
		if not alternate:
			# Pick a seed that WOULD trigger the second RNG draw's CPU tip.
			# An AI setter must not select that shot for a human-owned hitter.
			var predictor:=RandomNumberGenerator.new()
			for seed_value in range(1,500):
				predictor.seed=seed_value; predictor.randf()
				if predictor.randf()<.03: game.rng.seed=seed_value; break
		game.set_ball()
		check(game.phase=="ATTACK" and game.hitter==index and game.charging and game.charge_button=="action","the actual shared set carries the early hold into the user's attack")
		check(game.attack_buffer_start<0 and game.attack_buffer_power<0,"the common set consumes its attack buffer once")
		var dt:=1.0/120.0
		var expected: Array=game.BallFlight.advance(game.ball_pos,game.ball_vel,game.flight_spin,dt,game.flight_gravity)
		game.step(dt)
		check(game.ball_pos.is_equal_approx(expected[0]) and game.ball_vel.is_equal_approx(expected[1]),"buffered primary or tip preserves the exhibition physical flight curve")
		check(adapter.buffered_stroke.is_empty(),"the adapter clears the carried stroke after entering the real attack")
		check(game.attack_tip==alternate and game.charge_button==kind and game.charging,"alternate preload selects the original wrist-tip API after the AI set")
		for frame in 15: game.step(dt)
		var expected_charge: float=(game.clock_time-game.charge_start)/game.charge_seconds("attack")
		check(absf(game.current_charge()-expected_charge)<.000001,"preloaded stroke uses the same PlayerStats/exhibition charge curve")
		var before_release: float=game.current_charge()
		button(pad_button,false)
		check(not game.charging and game.armed and absf(game.charge-before_release)<.000001,"releasing the carried button locks its real exhibition power")
		cases.append({"alternate":alternate,"charge":game.charge,"variant":p.variant_names.get("attack","attack"),"setter":game.setter,"hitter":game.hitter})
	report.buffered_attacks=cases
	# Replay/dialogs consume events before main._unhandled_input. The adapter's
	# passive _input must still release buttons/axes without issuing an action.
	game.charging=false; game.armed=false; game.phase="ATTACK"; game.possession=0; game.hitter=adapter.controlled_index
	button(JOY_BUTTON_A)
	check(game.charging and adapter.buttons.get("action",false),"primary hold is active before the replay consumes later input")
	game.charging=false; game.phase="POINT"; game.replay.active=true
	var released:=InputEventJoypadButton.new(); released.button_index=JOY_BUTTON_A; released.pressed=false
	var axis:=InputEventJoypadMotion.new(); axis.axis=JOY_AXIS_LEFT_X; axis.axis_value=0
	var trigger_up:=InputEventJoypadMotion.new(); trigger_up.axis=JOY_AXIS_TRIGGER_RIGHT; trigger_up.axis_value=0
	var key_up:=InputEventKey.new(); key_up.physical_keycode=KEY_W; key_up.pressed=false
	adapter.move_input.x=.8; adapter.buttons.dive_trigger=true; adapter.keys[KEY_W]=true
	var ball_before: Vector3=game.ball_pos; var root_before: Vector3=game.players[adapter.controlled_index].position; var contacts_before: int=game.test_contacts
	adapter._input(released); adapter._input(axis); adapter._input(trigger_up); adapter._input(key_up)
	check(not adapter.buttons.get("action",false) and not adapter.buttons.get("dive_trigger",false) and adapter.move_input.x==0 and not adapter.keys.get(KEY_W,true),"passive input clears swallowed replay releases and held movement")
	check(not game.charging and game.test_contacts==contacts_before and game.ball_pos==ball_before and game.players[adapter.controlled_index].position==root_before,"release caching during replay cannot trigger a stroke, movement or contact")
	game.replay.active=false; game.phase="ATTACK"; game.armed=false; game.charging=false
	button(JOY_BUTTON_A)
	check(game.charging and adapter.buttons.get("action",false),"a fresh primary press works after a release swallowed by replay")
	button(JOY_BUTTON_A,false)
	report.replay_release_cache=true

func test_sets():
	var cases: Array=[]
	for quick in [false,true]:
		var p=restart("S"); var index: int=adapter.controlled_index
		p.position=Vector3(0,0,2.6); p.rotation.y=-PI/2; p.setting_yaw=-PI/2; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; clear_around(index)
		game.set_phase("SET"); game.possession=0; game.setter=index; game.receiver=0; game.last_touch=0; game.touches=[1,0]; game.pass_quality=1; game.input_quality=0; game.out_of_system=1
		game.set_dir=0; game.planned_hitter=-1; game.airborne=true; game.flight_target=p.contact_world("set"); game.ball_pos=game.flight_target; game.ball_vel=Vector3(0,-1,0); game.flight_spin=Vector3.ZERO; game.flight_left=.2
		var velocity: Vector3=game.ball_vel
		button(JOY_BUTTON_X if quick else JOY_BUTTON_A)
		check(game.armed and game.planned_fast==quick and game.fast_set==quick,"normal and quick commands select the same exhibition set APIs")
		check(game.ball_vel==velocity,"choosing set type never replaces the incoming physical trajectory")
		var action: String=game.second_touch_contact_action()
		p.position=p.stance_for_contact(action,game.flight_target); p.rotation.y=p.setting_yaw; p.body_lean=Vector2.ZERO; clear_around(index)
		game.ball_pos=game.flight_target
		game.set_ball()
		check(game.phase=="ATTACK" and game.match_management.measured.get(manager.state.profile.id,{}).get("sets",0)==1,"native shared set contacts the ball and launches the actual planned attacker")
		check(game.contact_log.size()>0 and game.contact_log[-1].gap<=.18,"native set palm contact retains exhibition tolerance")
		cases.append({"quick":quick,"action":action,"hitter":game.hitter,"variant":p.variant_names.get(action,action),"seconds":game.flight_left})
		button(JOY_BUTTON_X if quick else JOY_BUTTON_A,false)
	report.sets=cases

func test_attack_jump():
	var p=restart("OH"); var index: int=adapter.controlled_index
	game.set_phase("ATTACK"); game.possession=0; game.last_touch=0; game.hitter=index; game.hitter_action="attack"; game.pass_quality=1; game.out_of_system=1; game.destination=2; game.planned_direction=2; game.planned_hitter=index; game.fast_set=false; game.touches=[2,0]
	game.plan_attack(2,false)
	p.position=Vector3(3.3,0,1.5); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; p.play("ready",1,true); clear_around(index)
	game.airborne=false; game.flight_left=100; game.armed=true; game.charging=false; game.input_quality=1; game.charge=.90
	game.ball_pos=p.contact_world("attack"); var before: Vector3=game.ball_pos
	check(not game.validate_contact(index,"attack"),"a correctly positioned but unjumped athlete cannot be snapped into an attack")
	check(game.ball_pos==before,"rejected attack leaves the real ball where it is")
	button(JOY_BUTTON_RIGHT_SHOULDER)
	check(p.clip_name=="attack" and not adapter.source_motion.is_empty(),"R1/RB starts the actual native exhibition attack performance")
	check(absf(p.position.y)<.001,"manual native jump does not add a second physical Y trajectory")
	var expected: String=preload("res://src/motion_prototypes.gd").attack_variant("attack_pin_right",2,1)
	check(str(p.variant_names.get("attack","attack"))==expected,"manual pin attack uses the identical exhibition running-attack variant")
	for frame in 100:
		if p.animation_time>=p.clips.attack.contact_time-.02: break
		game.step(1.0/120.0)
	check(adapter.contact_allowed(index,"attack"),"the actual native jump reaches its manual contact window")
	game.ball_pos=p.contact_world("attack")+Vector3(3,0,0)
	check(not game.validate_contact(index,"attack"),"manual jump cannot hit a physically distant ball")
	game.ball_pos=p.contact_world("attack"); before=game.ball_pos
	game.armed=true; game.input_quality=1; game.charge=.9; game.charging=false
	game.attack_ball()
	check(game.phase=="CPU_RECEIVE" and game.match_management.measured.get(manager.state.profile.id,{}).get("attack_attempts",0)==1,"commanded native contact launches the exhibition attack and measured attempt")
	check(game.ball_pos==before,"successful attack redirects velocity without dragging the ball to the palm")
	report.attack_variant=p.variant_names.get("attack","attack")

func test_manual_block():
	var p=restart("OH"); var index: int=adapter.controlled_index
	p.position=Vector3(4.0,0,.68); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.play("ready",1,true); clear_around(index)
	game.set_phase("CPU_ATTACK"); game.possession=1; game.last_touch=1; game.hitter=6; game.hitter_action="attack"; game.incoming_kind="spike"; game.incoming_power=.9; game.airborne=false; game.flight_left=100
	game.block_anchor=-3.0; game.block_count=2; game.block_rosters.clear(); game.block_orders.clear(); game.block_time=-100; game.block_commanded=false
	button(JOY_BUTTON_RIGHT_SHOULDER)
	check(p.clip_name=="block" and adapter.source_motion.get("action","")=="block","R1/RB explicitly starts the native wall performance")
	check(index in game.blocking_players(0),"manually jumping player participates even outside the cached automatic wall")
	for frame in 60:
		if p.animation_time>=p.clips.block.contact_time-.015: break
		game.step(1.0/120.0)
	p.apply_pose(0)
	var hands: Vector3=(p.current_hand(true)+p.current_hand(false))*.5
	game.set_phase("RECEIVE"); game.possession=0; game.last_touch=1; game.incoming_kind="spike"; game.ball_pos=hands; game.ball_vel=Vector3(0,-3,24); game.block_checked=false
	game.try_block(hands-Vector3(0,0,.16),0)
	check(game.block_checked and game.last_touch==0,"the real exhibition palm sweep detects the manually timed block")
	check(game.match_management.measured.get(manager.state.profile.id,{}).get("block_contacts",0)==1,"manual wall contact uses the ordinary measured block statistics")
	report.block_hands=hands

func test_point_continuity():
	restart("OH")
	for index in 12:
		var team:=int(index/6)
		game.players[index].position=Tactics.world(team,-3.0+(index%3)*3.0,2.5 if index%6<3 else 5.3)
		game.players[index].velocity=Vector3.ZERO
	game.server=1; game.phase="POINT"; game.phase_time=4.6
	# The human is already in his legal receiving slot; only the eleven AI
	# athletes are deliberately left in midfield after the previous point.
	game.players[adapter.controlled_index].position=Tactics.serve_position(adapter.controlled_index,0,game.rotations[0],false)
	var roots: Array[Vector3]=[]
	for p in game.players: roots.append(p.position)
	game.reset_rally()
	var reset_jump:=0.0
	for index in 12: reset_jump=maxf(reset_jump,game.players[index].position.distance_to(roots[index]))
	check(reset_jump<.001,"ongoing point reset preserves all twelve world roots")
	game.self_test=false
	for p in game.players: p.render_at_draw=false
	var server: int=game.server_index(1); var old_server: Vector3=game.players[server].position
	var maximum:=0.0; var offender: Dictionary={}; var service_started:=false
	for frame in 1500:
		var before: Array[Vector3]=[]
		for p in game.players: before.append(p.position)
		game.step(1.0/120.0)
		if game.toss_active or game.serve_motion_active: service_started=true
		for index in 12:
			var jump: float=game.players[index].position.distance_to(before[index])
			if jump>maximum: maximum=jump; offender={"frame":frame,"player":index,"phase":game.phase,"before":before[index],"after":game.players[index].position}
	check(maximum<.25,"all twelve players return and rally without teleporting: "+JSON.stringify(offender))
	check(service_started,"the AI server can return from midfield and begin its ordinary native service")
	check(game.test_contacts>0,"native continuity test includes actual physical rally contacts after return to formation")
	check(game.players[server].position.distance_to(old_server)>.5,"the new server actually travels toward the service area")
	report.continuity={"ticks":1500,"reset_jump":reset_jump,"maximum_step":maximum,"largest_step":offender,"ai_service_started":service_started,"points":game.test_points,"contacts":game.test_contacts}
	game.self_test=true
	adapter.stop()
	check(adapter.return_positions.is_empty(),"leaving a fixture clears its old service/rotation destinations")

func run():
	var path: String=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(path.contains("legend73"),"native gameplay test uses isolated APPDATA")
	if not failures.is_empty(): quit(2); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false; game.replay.enabled=false
	for p in game.players: p.set_process(false)
	adapter=game.legend_match
	test_roles_and_substitutions()
	test_receive_and_recovery()
	test_buffered_attacks_and_replay_releases()
	test_sets()
	test_attack_jump()
	test_manual_block()
	test_point_continuity()
	report.checks=checks; report.failures=failures; report.native_clips=game.clips.size()
	FileAccess.open("res://docs/legend73-gameplay-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND GAMEPLAY73 ","PASS" if failures.is_empty() else "FAIL"," ",JSON.stringify(report))
	game.free(); quit(0 if failures.is_empty() else 1)

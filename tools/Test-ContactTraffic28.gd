extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	var results: Array=[]
	for team in 2:
		for fps in [60,120]:
			for scenario in ["standing_barrier","net_middle","prone_barrier","prone_net_middle","receive_pipeline"]:
				prepare(game,team,scenario)
				var initial_contacts: int=game.test_contacts
				var duration: float=game.flight_left
				var physical_deadline:=duration
				var original_position: Vector3=game.ball_pos
				var original_velocity: Vector3=game.ball_vel
				var original_spin: Vector3=game.flight_spin
				var original_gravity: float=game.flight_gravity
				var contact_height: float=game.flight_target.y
				var forearm:=false
				var elapsed:=0.0
				var gap:=INF
				var maximum_step:=0.0
				var stalls:=0
				var trace: Array=[]
				for frame in int(ceil((duration+1.3)*fps)):
					if game.phase not in ["SET","CPU_SET"]: break
					if team==0 and not game.armed: game.press_action("action")
					var prior: Vector3=game.players[game.setter].position
					var speed: float=game.players[game.setter].velocity.length()
					game.step(1.0/fps)
					elapsed+=1.0/fps
					if game.phase in ["SET","CPU_SET"]:
						# A forearm or one-hand source can meet the SAME pass at a
						# lower physical height. Derive each revised deadline from
						# the original integrator state, never the reassigned timer.
						var predicted: Array=game.BallFlight.advance(original_position,original_velocity,original_spin,elapsed,original_gravity)
						assert(game.ball_pos.distance_to(predicted[0])<.005 and game.ball_vel.distance_to(predicted[1])<.005,"Recovery must preserve the original moving ball, not pause or relaunch it")
						assert(game.flight_spin==original_spin and game.flight_gravity==original_gravity)
						if not is_equal_approx(contact_height,game.flight_target.y):
							contact_height=game.flight_target.y
							var crossing: Dictionary=game.BallFlight.intercept(original_position,original_velocity,original_spin,contact_height,original_gravity)
							assert(not crossing.is_empty(),"Changed pose must have a real original-flight intercept")
							physical_deadline=crossing.seconds
						if game.out_of_system<0: forearm=true
					var displacement: float=prior.distance_to(game.players[game.setter].position)
					maximum_step=maxf(maximum_step,displacement)
					if speed>1.0 and displacement<0.002: stalls+=1
					for other in range(team*6,team*6+6):
						if other==game.setter: continue
						for sample in game.compute_footprint_points(other):
							gap=minf(gap,game.players[game.setter].position.distance_to(sample))
					if frame%maxi(1,fps/10)==0: trace.append({"time":elapsed,"setter":game.players[game.setter].position,"target":game.players[game.setter].target,"left":game.flight_left})
				var contact: bool=game.test_contacts==initial_contacts+1 and game.phase in ["ATTACK","CPU_ATTACK"]
				var row={"team":team,"fps":fps,"scenario":scenario,"contact":contact,"deadline":duration,"physical_deadline":physical_deadline,"forearm":forearm,"elapsed":elapsed,"min_gap":gap,"max_step":maximum_step,"stalls":stalls,"trace":trace}
				results.append(row)
				print("CONTACT TRAFFIC28 ",scenario," team=",team," fps=",fps," contact=",contact," gap=",gap," deadline=",duration," elapsed=",elapsed," stalls=",stalls)
	var output=FileAccess.open("res://docs/contact-traffic28-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(results,"  "))
	output.close()
	var failures:=0
	test_lower_interception(game)
	for result in results:
		if not result.contact or result.min_gap<0.975 or result.elapsed>result.physical_deadline+0.025 or result.max_step>9.5/result.fps: failures+=1
	if failures>0:
		push_error("CONTACT TRAFFIC28 FAIL: %d/%d obstructed approaches fail contact, physical clearance, continuity or original deadline"%[failures,results.size()])
		game.free()
		quit(1)
		return
	print("CONTACT TRAFFIC28 PASS: ",results.size()," real second touches / standing barriers, prone+standing, net middle / mirrored teams / 60-120Hz / original deadline and physical clearance")
	game.free()
	quit()

func test_lower_interception(game) -> void:
	for team in 2:
		prepare(game,team,"standing_barrier")
		for other in range(team*6,team*6+5): game.players[other].position=game.Tactics.world(team,-4+(other%3)*4,8.0+other%2)
		var player=game.players[game.setter]
		var point: Vector3=game.Tactics.world(team,0,3.0)
		point.y=player.contact_local("set").y
		game.ball_pos=point+Vector3.UP*0.15
		game.launch(point,0.10)
		player.position=player.stance_for_contact("set",point)+Vector3(1.15,0,0)
		game.next_second_touch_read=-100
		var position_before: Vector3=game.ball_pos
		var velocity_before: Vector3=game.ball_vel
		var spin_before: Vector3=game.flight_spin
		var gravity_before: float=game.flight_gravity
		assert(load("res://src/setter_access.gd").try_low_contact(game),"Reachable forearm contact must replace an unreachable overhead pose")
		assert(game.ball_pos.is_equal_approx(position_before) and game.ball_vel.is_equal_approx(velocity_before),"Recovery must not relaunch or teleport the ball")
		assert(game.flight_spin.is_equal_approx(spin_before) and game.flight_gravity==gravity_before,"Recovery must preserve the same physical flight")
		assert(game.flight_target.y<point.y and game.flight_left>0.10 and game.out_of_system<0 and not game.fast_set)
	print("CONTACT TRAFFIC28 LOWER INTERCEPT PASS: both teams / same position, velocity, spin and gravity / lower physical contact")

func prepare(game,team: int,scenario: String) -> void:
	var recovery: bool=scenario.begins_with("prone")
	if recovery:
		load("res://tools/Test-RecoveryTraffic.gd").prepare_case(game,team)
	else:
		game.rotations=[0,0]
		game.server=1-team
		game.reset_rally()
		game.possession=team
		game.setter=team*6+5
		game.receiver=team*6+4
		game.set_phase("SET" if team==0 else "CPU_SET")
		game.pass_quality=0.7
		game.input_quality=0.98
		game.out_of_system=1
		game.fast_set=false
		for i in range(team*6,team*6+6):
			game.players[i].position=game.Tactics.world(team,-4+(i%3)*4,7.5+(i%2))
			game.players[i].velocity=Vector3.ZERO
			game.players[i].acceleration=Vector3.ZERO
			game.players[i].steering_ready=false
	game.rng.seed=28001
	var setter=game.players[game.setter]
	setter.setting_yaw=-PI/2 if team==0 else PI/2
	setter.rotation.y=setter.setting_yaw
	setter.position=game.Tactics.world(team,-2.5,3.0)
	game.players[team*6+0].position=game.Tactics.world(team,-1.1,2.55)
	game.players[team*6+1].position=game.Tactics.world(team,0.05,1.75)
	game.players[team*6+2].position=game.Tactics.world(team,1.2,2.6)
	if scenario.contains("net_middle"):
		setter.position=game.Tactics.world(team,-2.3,1.0)
		game.players[team*6+0].position=game.Tactics.world(team,-1.0,0.95)
		game.players[team*6+1].position=game.Tactics.world(team,0.2,1.05)
		game.players[team*6+2].position=game.Tactics.world(team,1.4,1.15)
	if not recovery: game.players[game.receiver].position=game.Tactics.world(team,-0.9,4.0)
	if scenario=="receive_pipeline":
		game.ball_pos=game.players[game.receiver].contact_world("receive")
		game.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE")
		game.armed=true
		game.input_quality=1.0
		game.incoming_kind="spike"
		game.incoming_power=0.3
		game.receive_ball()
		game.plan_attack(1,false)
	else:
		var point: Vector3=game.Tactics.world(team,0.65,1.8)
		point.y=game.contact_height("set")
		point=load("res://src/setter_access.gd").clear_target(game,point)
		var duration: float=load("res://src/setter_access.gd").pass_seconds(game,point,game.Reference.receive_seconds(game.pass_quality))
		game.ball_pos=game.players[game.receiver].contact_world("receive")
		game.launch(point,duration)
		game.plan_attack(1,false)
	game.armed=true
	game.input_quality=0.98

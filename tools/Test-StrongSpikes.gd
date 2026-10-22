extends SceneTree
const Reference = preload("res://src/reference_style.gd")
const Flight = preload("res://src/ball_flight.gd")
const Tactics = preload("res://src/tactics.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	for power in [0.0, 0.12, 0.35, 0.60, 0.75]:
		assert(is_equal_approx(Reference.attack_seconds(power, 0.5, false, false), 0.72-power*0.24), "Controlled/medium hits retain their pace")
	for power in [0.85, 1.0]:
		assert(is_equal_approx(Reference.attack_seconds(power, 0.5, true, true), 0.72-power*0.24), "A soft return cannot acquire the hard-hit bonus")
	var previous := Reference.attack_seconds(0.0, 0.5, false, false)
	for tick in range(1,1001):
		var seconds := Reference.attack_seconds(tick/1000.0, 0.5, false, false)
		assert(seconds<previous and previous-seconds<0.0005, "Power response must remain continuous and monotonic")
		previous=seconds
	var origin:=Vector3(-3.4,3.3,1.05)
	var landing:=Vector3(3.0,0.105,-7.0)
	var spin:=Vector3(-20,0,0.5)
	var before_velocity:=Flight.velocity_to(origin,landing,0.48,spin)
	var after_seconds:=Reference.attack_seconds(1.0,0.5,false,false)
	var after_velocity:=Flight.velocity_to(origin,landing,after_seconds,spin)
	var speed_ratio:=Vector2(after_velocity.x,after_velocity.z).length()/Vector2(before_velocity.x,before_velocity.z).length()
	assert(speed_ratio>1.045 and speed_ratio<1.065, "Full-power improvement must remain modest")
	var old_intercept:=Flight.intercept(origin,before_velocity,spin,1.29)
	var new_intercept:=Flight.intercept(origin,after_velocity,spin,1.29)
	assert(new_intercept.seconds<old_intercept.seconds-0.015, "A defender must have genuinely less flight time, not a scripted miss")
	for fps in [30,60,120]:
		var position:=origin
		var velocity:=after_velocity
		var elapsed:=0.0
		while elapsed<after_seconds-0.000001:
			var dt:=minf(1.0/fps,after_seconds-elapsed)
			var next:=Flight.advance(position,velocity,spin,dt)
			position=next[0]
			velocity=next[1]
			elapsed+=dt
		assert(position.distance_to(landing)<0.01, "Existing integrator and target precision remain intact")
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.started=true
	game.demo=false
	var rows: Array[Dictionary]=[]
	var old_points:=0
	var new_points:=0
	for fps in [60,120]:
		for target_x in [-3.4,-2.55,-1.7,-0.85,0.0,0.85,1.7,2.55,3.4]:
			for depth in [3.5,4.2,5.0,5.7,6.4,7.0,7.7,8.4]:
				var target:=Vector3(target_x,0.105,-depth)
				var old:=defend(game,target,0.48,fps)
				var changed:=defend(game,target,after_seconds,fps)
				old_points+=1 if old.point else 0
				new_points+=1 if changed.point else 0
				rows.append({"fps":fps,"target":str(target),"before":old,"after":changed})
	var output=FileAccess.open("res://docs/strong-spikes-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"floor_flight_seconds_before":0.48,"floor_flight_seconds_after":after_seconds,"horizontal_launch_speed_ratio":speed_ratio,"dig_time_seconds_before":old_intercept.seconds,"dig_time_seconds_after":new_intercept.seconds,"paired_real_defense_cases":rows.size(),"baseline_direct_points":old_points,"new_direct_points":new_points,"cases":rows},"  "))
	print("STRONG SPIKES DIAGNOSTIC: ", old_points," -> ",new_points," points from ",rows.size()," paired cases")
	assert(new_points>old_points, "Harder physical attacks should produce more points in the representative paired defense scenarios")
	assert(new_points<rows.size(), "Well-positioned defenders must retain real digs")
	print("STRONG SPIKES PASS: high-tier pace only / continuous power / unchanged soft and medium hits / real paired defenders / integrator at 30-60-120Hz")
	game.free()
	quit()

func defend(game, target: Vector3, seconds: float, fps: int) -> Dictionary:
	game.server=0
	game.rotations=[0,0]
	game.scores=[0,0]
	game.reset_rally()
	game.clock_time=0
	game.shot_serial=100
	game.attack_serial=1
	game.rally_serial=1
	game.rng.seed=20261023
	game.hitter=0
	game.setter=5
	game.ball_pos=Vector3(-3.4,game.contact_height("attack"),1.05)
	game.last_touch=0
	game.incoming_kind="spike"
	game.incoming_power=1.0
	game.test_rallies=2
	game.aim=Vector2.ZERO
	game.middle_decoy.reset()
	game.block_rosters.clear()
	game.block_orders.clear()
	game.block_jumps.clear()
	for i in 12:
		var team:=0 if i<6 else 1
		var point:=Tactics.home(i,team,0,team==game.server,false)
		game.players[i].position=point
		game.players[i].target=point
		game.players[i].velocity=Vector3.ZERO
		game.players[i].acceleration=Vector3.ZERO
		game.players[i].steering_ready=false
	game.send_to_court(0,target,seconds)
	# Isolate floor defense. Live net, recovery, movement, ball and hand-contact
	# checks remain active; block outcomes have their separate regression tests.
	game.block_checked=true
	var before: int=game.test_contacts
	var selected: int=game.receiver
	var contact_time: float=game.flight_left
	for frame in fps*3:
		game.step(1.0/fps)
		if game.test_contacts>before or game.phase=="POINT": break
	return {"point":game.phase=="POINT" and game.scores[0]>0,"dug":game.test_contacts>before,"receiver":selected,"contact_window_seconds":contact_time,"phase":game.phase}

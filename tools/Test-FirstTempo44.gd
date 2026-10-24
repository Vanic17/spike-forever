extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var prepared:=0; var safety_balls:=0
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation]; g.server=1-team; g.rng.seed=40001; g.reset_rally(); g.possession=team
			g.receiver=team*6+4; g.set_dir=1
			for index in range(team*6,team*6+6):
				if g.Tactics.libero(index,rotation,false): g.receiver=index
			g.players[g.receiver].position=g.Tactics.world(team,0,5.5)
			g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
			g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
			g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=0.3
			g.receive_ball(); g.setter_dump=false
			# Controlled good-pass scenario: CPU reception randomness is tested
			# separately; this matrix specifically verifies first-tempo preparation.
			g.pass_quality=0.95; g.input_quality=0.95
			if team==0: g.press_action("alternate")
			else: g.plan_attack(1,true)
			var middle: int=g.planned_hitter; var seen:=false
			var start: Vector3=g.players[middle].position; var distance:=0.0
			for frame in 400:
				if g.phase not in ["SET","CPU_SET"]: break
				g.step(1.0/120)
				distance=maxf(distance,g.players[middle].position.distance_to(start))
				if g.phase in ["SET","CPU_SET"] and g.players[middle].clip_name=="attack" and g.players[middle].animation_time>0 and g.flight_left>0.08: seen=true
			if g.fast_set:
				if not seen: print("FIRST TEMPO44 DIAG team=",team," R=",rotation+1," q=",g.pass_quality," sys=",g.out_of_system," clip=",g.players[middle].clip_name," distance=",distance," flight=",g.flight_left)
				assert(seen,"A reachable first tempo must show the source approach before the setter's contact")
				prepared+=1
			else:
				assert(distance>0.5,"An initially distant middle must run during the pass, retaining the existing legal high-ball fallback")
				safety_balls+=1
	assert(prepared>=8)
	# The visual first-tempo threat is independent of the eventual X command.
	g.rotations=[0,0]; g.server=1; g.reset_rally(); g.possession=0; g.setter=5
	g.phase="SET"; g.pass_quality=0.95; g.out_of_system=1; g.armed=false
	g.flight_target=g.Tactics.setter_position(0)+Vector3.UP*g.contact_height("set"); g.flight_left=1.1
	g.players[5].position=g.players[5].stance_for_contact("set",g.flight_target)
	g.plan_attack(0,false)
	var count: int=g.middle_decoy.events.size()
	for frame in 120:
		g.clock_time+=1.0/120; g.phase_time+=1.0/120; g.flight_left-=1.0/120
		g.move_players(1.0/120)
		for p in g.players: p.tick(1.0/120,false,false)
		if g.middle_decoy.events.size()>count: break
	assert(g.middle_decoy.events.size()==count+1 and not g.armed,"A good pass must start the feint before set confirmation, without adding an input or ball touch")
	print("FIRST TEMPO44 PASS quick_recipient_prepares_before_set=",prepared," safety_high_balls=",safety_balls," / six rotations mirrored / unconfirmed-set feint retained")
	FileAccess.open("res://docs/first-tempo44-report.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":12,"quality":0.95,"quick_recipient_prepares_before_set":prepared,"safety_high_balls":safety_balls,"unconfirmed_set_feint":true},"  "))
	g.free(); quit()

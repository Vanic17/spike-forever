extends SceneTree
const Access=preload("res://src/setter_access.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	if "--psa" in OS.get_cmdline_user_args(): g.Avatar.native_animation_enabled=false
	var changes:=0; var seconds_touched:=0; var failed:=0; var rows: Array=[]
	for team in 2:
		for quick in [false,true]:
			for direction in 4:
				g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.receiver=team*6+4
				g.out_of_system=1; g.pass_quality=.84; g.input_quality=.84; g.fast_set=false; g.setter_dump=false
				g.phase="SET" if team==0 else "CPU_SET"; g.armed=true
				var p=g.players[g.setter]
				p.setting_yaw=-PI/2 if team==0 else PI/2; p.rotation.y=p.setting_yaw
				p.select_variant("set","set"); p.select_variant("fast_set","fast_set")
				var point: Vector3=g.Tactics.world(team,0,2); point.y=p.contact_local("set").y
				g.ball_pos=g.Tactics.world(team,0,5); g.ball_pos.y=1.2; g.launch(point,.95)
				g.plan_attack(direction,quick)
				var origin: Vector3=g.ball_pos; var velocity: Vector3=g.ball_vel; var spin: Vector3=g.flight_spin
				Access.sync_performance(g)
				var action: String="fast_set" if g.fast_set else "set"
				var actual: Vector3=g.BallFlight.advance(origin,velocity,spin,g.flight_left)[0]
				assert(actual.distance_to(g.flight_target)<.005,"New hands must intercept the SAME flight")
				assert(absf(g.flight_target.y-p.contact_local(action).y)<.003)
				assert(g.ball_pos==origin and g.ball_vel==velocity and g.flight_spin==spin)
				changes+=1
	# A very poorly timed but physically valid second touch must still set.
	for team in 2:
		g.server=1-team; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.receiver=team*6+4
		g.phase="SET" if team==0 else "CPU_SET"; g.out_of_system=1; g.pass_quality=.8; g.input_quality=0; g.armed=true; g.setter_dump=false
		g.plan_attack(0,false); g.ball_pos=g.Tactics.world(team,0,1.8)
		g.ball_pos.y=g.players[g.setter].contact_local("set").y
		g.players[g.setter].rotation.y=g.players[g.setter].setting_yaw
		g.players[g.setter].position=g.players[g.setter].stance_for_contact("set",g.ball_pos)
		g.players[g.setter].blend_left=0; g.players[g.setter].prepare_contact("set",0)
		g.set_ball(); assert(g.phase in ["ATTACK","CPU_ATTACK"])
		seconds_touched+=1
	# Real moving receive -> set -> quick-middle construction, both sides,
	# all rotations and off-centre passes. Never replace physical hands by a score.
	for team in 2:
		for rotation in 6:
			for x in [-1.8,0.0,1.8]:
				if "--probe" in OS.get_cmdline_user_args() and (rotation!=2 or x!=-1.8): continue
				g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4
				g.rng.seed=52007; g.set_dir=1; g.armed=true; g.input_quality=.84; g.incoming_kind="spike"; g.incoming_power=.65
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.players[g.receiver].position=g.Tactics.world(team,x,5.5)
				g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
				g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
				var before: int=g.test_contacts; g.receive_ball(); g.plan_attack(1,true)
				if team==0: g.press_action("alternate")
				for frame in 800:
					if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+3: break
					if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
					g.step(1.0/120)
					if "--probe" in OS.get_cmdline_user_args() and g.phase in ["ATTACK","CPU_ATTACK"] and frame%8==0: print("TRACE52 team=",team," left=",g.flight_left," hitter=",g.hitter," root=",g.players[g.hitter].position," goal=",g.players[g.hitter].target," hands=",g.players[g.hitter].contact_world("attack")," roots=",g.players.slice(team*6,team*6+6).map(func(p): return str(p.position))," flight=",g.flight_target," source=",g.players[g.hitter].animation_time)
					if frame%4==0:
						for p in g.players: p.apply_pose(1.0/30)
				var row={"team":team,"rotation":rotation,"passer_x":x,"contacts":g.test_contacts-before,"phase":g.phase,"target":str(g.flight_target)}
				rows.append(row)
				if g.test_contacts<before+3: failed+=1; print("RALLY52 FAILURE ",row)
	var old=load("res://docs/baseline-v51/block_response.gd"); var revised=load("res://src/block_response.gd")
	var prior:=0; var current:=0; var tools:=0; var touches:=0
	var rng=RandomNumberGenerator.new(); rng.seed=52101
	for i in 10000:
		var incoming:=Vector3(rng.randf_range(-9,9),rng.randf_range(-8,1),rng.randf_range(18,38))
		var strength:=rng.randf_range(.18,1); var quality:=rng.randf_range(.60,1); var edge:=rng.randf_range(-1.25,1.25)
		var variation:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1))
		var a: Dictionary=old.solve(incoming,0,strength,quality,edge,variation)
		var b: Dictionary=revised.solve(incoming,0,strength,quality,edge,variation)
		if a.kind=="stuff_block": prior+=1
		if b.kind=="stuff_block": current+=1
		elif b.kind=="block_tool": tools+=1
		else: touches+=1
	assert(current>prior and current<prior*1.5 and tools>1000 and touches>1000)
	var dig_rows: Array=[]
	for team in 2:
		g.possession=team; g.incoming_kind="spike"; g.incoming_power=1; g.receive_offset=.25; g.rng.seed=52011
		for q in [.95,.65,.35]:
			var min_depth:=INF; var max_depth:=0.0; var max_x:=0.0
			for i in 200:
				var point: Vector3=load("res://src/shot_variation.gd").pass_target(g,g.Tactics.world(team,0,1.5),q)
				min_depth=minf(min_depth,absf(point.z)); max_depth=maxf(max_depth,absf(point.z)); max_x=maxf(max_x,absf(point.x))
			assert(max_depth-min_depth>(.2 if q>.9 else 2))
			dig_rows.append({"team":team,"quality":q,"min_depth":min_depth,"max_depth":max_depth,"max_lateral_error":max_x})
	FileAccess.open("res://docs/rally52-psa-report.json" if "--psa" in OS.get_cmdline_user_args() else "res://docs/rally52-report.json",FileAccess.WRITE).store_string(JSON.stringify({"performance_intercepts":changes,"poor_timing_sets":seconds_touched,"constructions":rows,"failed_constructions":failed,"block_contacts":10000,"old_stuffs":prior,"new_stuffs":current,"tools":tools,"soft_touches":touches,"digs":dig_rows},"  "))
	print("RALLY52 results constructions=",rows.size()-failed,"/",rows.size()," intercepts=",changes," stuff contacts=",prior," -> ",current," /10000 tools=",tools," soft=",touches)
	g.free(); quit(1 if failed else 0)

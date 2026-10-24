extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var walls:=0
	for rotation in 6:
		for wing in [-1,1]:
			g.rotations=[rotation,rotation]; g.server=1; g.reset_rally(); g.possession=1
			g.phase="CPU_ATTACK"; g.hitter=6; g.hitter_action="attack"; g.flight_target=Vector3(wing*3.4,3.3,-1); g.flight_left=0.8
			var row: Array=g.manual_wall.line(g)
			var pin: int=row[0] if wing<0 else row[2]
			var far: int=row[2] if wing<0 else row[0]
			g.phase="CPU_SET"; g.setter=11; g.planned_direction=2 if wing<0 else 0
			g.planned_hitter=g.Tactics.attacker(1,rotation,g.planned_direction,11)
			g.flight_target=Vector3(0,2.5,-1.5)
			assert(g.manual_wall.automatic_pin(g)==pin,"The pin reads the corresponding opposite wing before the set is released")
			g.setter_dump=true
			assert(g.manual_wall.automatic_pin(g)==-1,"A second-touch dump is not a set to an outside hitter")
			g.setter_dump=false
			g.phase="CPU_ATTACK"; g.flight_target=Vector3(wing*3.4,3.3,-1)
			for k in 3:
				var p=g.players[row[k]]; p.position=Vector3((k-1)*3.4,0,0.68); p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO; p.motion_lock=0
			g.manual_wall.read(g,Vector2.ZERO,0)
			assert(g.blocking_players(0).size()==2 and pin in g.blocking_players(0))
			var anchor: Vector3=g.blocking_target(pin,0)
			if wing<0: g.manual_wall.left_joined=true
			else: g.manual_wall.right_joined=true
			assert(is_equal_approx(g.blocking_target(pin,0).x,g.block_helper_x+wing*g.Tactics.BLOCK_SPACE),"The corresponding trigger can still bring the pin to the middle")
			g.manual_wall.left_joined=false; g.manual_wall.right_joined=false
			var before: int=g.block_jump_log.size()
			for frame in 120:
				g.clock_time+=1.0/60; g.phase_time+=1.0/60
				g.manual_wall.read(g,Vector2(wing,0),1.0/60)
				g.move_players(1.0/60)
				for p in g.players: p.tick(1.0/60,false,false)
			assert(g.blocking_target(pin,0)==anchor,"The automatic pin must not be dragged by the middle's stick")
			assert(g.players[pin].position.distance_to(anchor)<0.3,"The pin must physically hold its lane")
			assert(g.players[far].target.z>2.8,"Far pin drops into floor defence")
			assert(g.block_jump_log.size()==before,"Automatic placement must never trigger a jump")
			g.send_test_button(JOY_BUTTON_A)
			assert(g.block_jump_log.size()==before+2 and pin in g.manual_wall.jumped,"One Cross/A press jumps the middle and automatic pin together")
			g.manual_wall.jumped.clear(); g.block_commanded=false; g.block_jumps.clear()
			g.manual_wall.left_joined=true; g.manual_wall.right_joined=true
			assert(g.manual_wall.members(g).size()==3,"L2/R2 still form a triple wall")
			walls+=1
	# Dead-ball regrouping must never select defensive stepping or squat idles.
	g.reset_rally(); g.award(0,"TEST")
	var min_head:=INF
	var low_pose: Dictionary={}
	for frame in 180:
		g.clock_time+=1.0/60; g.move_players(1.0/60)
		for p in g.players:
			p.tick(1.0/60,false,true)
			if frame<90: continue
			assert(p.post_point and p.clip_name in ["walk","run","relaxed"],"Regrouping uses upright gait and rest")
			var head: int=p.clips[p.clip_name].names.find("Head")
			if head>=0 and p.last_pose[head].origin.y<min_head:
				min_head=p.last_pose[head].origin.y
				low_pose={"player":p.number,"clip":p.clip_name,"variant":p.variant_names.get(p.clip_name),"time":p.animation_time,"speed":p.velocity.length()}
	print("POST40 lowest head=",min_head," ",low_pose)
	assert(min_head>1.5,"Post-point poses must remain upright after contact recovery")
	var seen: Dictionary={}; var old_mean:=0.0; var new_mean:=0.0; var old_frozen:=0; var new_frozen:=0
	g.possession=1; g.receiver=6; g.incoming_power=0.93; g.flight_left=0.8
	for seed_value in 2000:
		g.rng.seed=seed_value; g.cpu_defense.prepare(g); seen[g.cpu_defense.outcome]=true
		new_mean+=0 if g.cpu_defense.frozen else g.cpu_defense.quality(0.85,0.93)
		if g.cpu_defense.frozen: new_frozen+=1
		var r:=RandomNumberGenerator.new(); r.seed=seed_value
		var timing:=clampf(1-absf(r.randf_range(-0.07,0.19)*1.53)*1.2,0.55,0.99)
		var roll:=r.randf()
		if roll<0.075: old_frozen+=1
		else: old_mean+=0.05 if roll<0.2052 else (0.35 if roll>=0.3081 and roll<0.4316 else clampf(0.85*timing-0.025-0.93*0.045,0,1))
	assert(seen.size()==7 and new_mean>old_mean+80 and new_frozen>0 and new_frozen<old_frozen,"CPU should improve moderately while preserving seven variable outcomes")
	print("MOVEMENT40 PASS walls=",walls," upright_min_head=",min_head," CPU mean=",new_mean/2000," vs v37=",old_mean/2000," frozen=",new_frozen," vs ",old_frozen," outcomes=",seen.keys())
	g.free(); quit()

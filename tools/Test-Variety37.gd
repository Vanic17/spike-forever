extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true
	var seen: Dictionary={}; var qmin:=1.0; var qmax:=0.0
	g.possession=1; g.receiver=6; g.incoming_power=0.93; g.flight_left=0.65
	for seed_value in 200:
		g.rng.seed=seed_value; g.cpu_defense.prepare(g); seen[g.cpu_defense.outcome]=true
		qmin=minf(qmin,g.cpu_defense.quality(0.85,0.93)); qmax=maxf(qmax,g.cpu_defense.quality(0.85,0.93))
	for outcome in ["clean","hesitation","shank","overpass","loose"]: assert(seen.has(outcome))
	assert(qmax-qmin>0.4)
	g.reset_rally(); g.possession=1; g.phase="CPU_RECEIVE"; g.incoming_kind="spike"; g.incoming_power=0.9; g.receiver=6
	var p=g.players[6]; p.position=Vector3(0,0,-5); p.rotation.y=0; p.prepare_contact("receive",0); g.ball_pos=p.contact_world("receive")
	g.cpu_defense.outcome="overpass"; g.cpu_defense.frozen=false
	var contacts: int=g.test_contacts; g.receive_ball()
	assert(g.test_contacts==contacts+1 and g.incoming_kind=="overpass" and g.last_touch==1)
	g.reset_rally(); g.possession=1; g.phase="CPU_RECEIVE"; g.incoming_kind="serve"; g.cpu_defense.frozen=true
	contacts=g.test_contacts; g.receive_ball(); assert(g.phase=="LOOSE" and g.test_contacts==contacts)
	g.reset_rally(); g.award(0,"TEST"); assert(not "PUNTO" in g.feedback)
	g.possession=1; g.phase="CPU_ATTACK"; g.flight_target=Vector3(3.4,3.3,-1); g.flight_left=0.6; g.hitter=6; g.hitter_action="attack"
	var row: Array=g.manual_wall.line(g); g.manual_wall.right_joined=true; g.phase_time=0.05; g.move_players(1.0/120)
	assert(g.players[row[0]].target.z<1.0)
	g.phase_time=0.3; g.move_players(1.0/120); assert(g.players[row[0]].target.z>2.8)
	print("VARIETY37 PASS: five CPU outcomes / varied contact quality / point wording / delayed short-cover transition")
	quit()

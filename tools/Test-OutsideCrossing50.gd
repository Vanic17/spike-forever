extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true; g.demo=false
	var rows: Array=[]; var failures:=0
	var db=load("res://src/league.gd").new()
	var milano: Dictionary=db.teams.filter(func(t): return t.id=="allianz-milano")[0]
	var lineup: Array=db.lineup(milano)
	print("CROSSING50 IDENTITIES OH1=",lineup[0].name," #",lineup[0].jersey_number," slot=",g.Tactics.ZONES[g.Tactics.slot(0,3)]," front=",g.Tactics.front(0,3)," OH2=",lineup[3].name," #",lineup[3].jersey_number," slot=",g.Tactics.ZONES[g.Tactics.slot(3,3)]," front=",g.Tactics.front(3,3))
	assert(lineup[0].role=="outside_hitter" and lineup[3].role=="outside_hitter")
	assert(not g.Tactics.front(0,3) and g.Tactics.front(3,3),"OH1 and OH2 are opposite in the rotation: one back row, one front row")
	for team in 2:
		for passer in [0,1,2]:
			g.rotations=[3,3]; g.server=1-team; g.rng.seed=40001; g.reset_rally(); g.possession=team
			var side:=1.0 if team==0 else -1.0
			var locations: Array=[Vector3(-3,0,6.3),Vector3(0,0,5.9),Vector3(3.8,0,6.4),Vector3(2.9,0,4.1),Vector3(0,0,1.4),Vector3(-2.3,0,1.4)]
			for i in 6:
				g.players[team*6+i].position=locations[i]*Vector3(side,1,side)
				g.players[team*6+i].velocity=Vector3.ZERO
			g.receiver=team*6+passer; g.set_dir=0
			g.ball_pos=g.players[g.receiver].contact_world("receive"); g.flight_target=g.ball_pos; g.flight_left=.65
			g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.phase_time=0
			g.incoming_kind="serve"; g.incoming_power=.75
			var runner:=team*6+3
			assert(g.Tactics.front(runner,3) and g.Tactics.slot(runner,3)==2,"Screenshot OH2 is legally front row in zone 2")
			var maximum_depth:=0.0; var stalled:=0; var run_frames:=0
			for frame in 78:
				g.clock_time+=1.0/120; g.phase_time+=1.0/120; g.flight_left-=1.0/120
				g.move_players(1.0/120)
				for p in g.players: p.tick(1.0/120,false,false)
				maximum_depth=maxf(maximum_depth,g.players[runner].position.z*side)
			g.ball_pos=g.players[g.receiver].contact_world("receive"); g.armed=true; g.input_quality=1
			var before: int=g.test_contacts
			g.receive_ball(); g.plan_attack(0,false)
			if team==0: g.press_action("action")
			assert(g.planned_hitter==runner,"Zone 4 must use the front-row OH2, not the back-row OH1")
			for frame in 1000:
				if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
				if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
				g.step(1.0/120)
				var p=g.players[runner]
				maximum_depth=maxf(maximum_depth,p.position.z*side)
				if p.travel_animation_name=="run" and p.velocity.length()>1.25: run_frames+=1
				if p.position.distance_to(p.target)>1.5 and p.velocity.length()<.1: stalled+=1
			var ok: bool=g.test_contacts==before+3 and maximum_depth<4.7 and run_frames>10
			if not ok: failures+=1
			rows.append({"team":team,"passer":passer,"contacts":g.test_contacts-before,"max_depth":maximum_depth,"stalled_frames":stalled,"run_frames":run_frames,"clip":g.players[runner].variant_names.get("attack"),"ok":ok})
			print("CROSSING50 ",rows[-1])
	FileAccess.open("res://docs/crossing50-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("CROSSING50 ","PASS" if failures==0 else "FAIL"," cases=",rows.size()," failures=",failures)
	g.free(); quit(0 if failures==0 else 1)

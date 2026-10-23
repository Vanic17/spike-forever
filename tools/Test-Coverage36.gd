extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var cases:=0
	for team in 2:
		for rotation in 6:
			for serving in 2:
				for hit_x in [-3.4,0.0,3.4]:
					for count in [0,1,2,3]:
						g.rotations=[rotation,rotation]; g.server=team if serving else 1-team; g.reset_rally()
						g.possession=1-team; g.phase="ATTACK" if team==1 else "CPU_ATTACK"
						var row: Array=g.defensive_lanes.line(g,team)
						var blockers: Array=[row[1]] if count>0 else []
						if count>=2: blockers.append(row[0] if hit_x<0 else row[2])
						if count==3: blockers.assign(row)
						var plan: Dictionary=g.defensive_coverage.plan(g,team,Vector3(hit_x,3.3,-1 if team==0 else 1),blockers)
						var lanes: Array=[]
						for index in plan:
							assert(not index in blockers)
							assert(absf(plan[index].x)<=3.3 and absf(plan[index].z)>=3.0 and absf(plan[index].z)<=7)
							if not g.Tactics.front(index,rotation): lanes.append(g.defensive_coverage.assignments[index])
							else: assert(absf(plan[index].z- (3.05 if team==0 else -3.05))<0.01)
						assert(lanes.size()==3 and lanes.has("diagonal") and lanes.has("seam") and lanes.has("line"))
						var ids: Array=plan.keys()
						for a in ids:
							for b in ids:
								if a!=b: assert(plan[a].distance_to(plan[b])>1.4,"Coverage lanes cannot overlap")
						var before: Dictionary=plan.duplicate()
						g.players[team*6].position.x+=1
						assert(before==g.defensive_coverage.plan(g,team,Vector3.ZERO,blockers),"Assignments stay stable through the flight")
						cases+=1
	# Actual movement target: off-pin and libero must not be sent to one lane.
	for destination in [1,3]:
		g.rotations=[0,0]; g.server=1; g.reset_rally(); g.possession=1; g.destination=destination
		var centre: Dictionary=g.defensive_coverage.plan(g,0,Vector3(2.4,3.3,-3),[])
		var depths: Array=[]
		for index in centre:
			if g.defensive_coverage.assignments[index] in ["line","diagonal"]: depths.append(absf(centre[index].z))
		assert(depths.size()==2 and depths.all(func(depth): return is_equal_approx(depth,5.7)),"Middle/pipe coverage must not be mistaken for a wing attack")
	g.destination=0
	g.rotations=[0,0]; g.server=1; g.reset_rally(); g.possession=1; g.phase="CPU_ATTACK"; g.hitter=6; g.hitter_action="attack"
	g.flight_target=Vector3(3.4,3.3,-1); g.flight_left=0.8
	var row: Array=g.manual_wall.line(g); g.manual_wall.right_joined=true; g.phase_time=0.3
	g.move_players(1.0/120)
	var off: int=row[0]
	print("LIVE COVER row=",row," blockers=",g.blocking_players(0)," planned=",g.defensive_coverage.targets," actual=",g.players[off].target," demo=",g.demo)
	assert(g.players[off].target.z>=2.8,"Live movement must send the free wing to short defence")
	var floor: Dictionary=g.defensive_coverage.targets.duplicate()
	g.incoming_kind="spike"; g.set_phase("RECEIVE"); g.possession=0; g.receiver=5; g.flight_target=Vector3(0,1.3,6); g.flight_left=0.3
	g.move_players(1.0/120)
	assert(g.players[off].target.z>=2.8,"The free wing must not reopen at the net before the dig")
	var live_cases:=0
	for team in 2:
		for rotation in 6:
			for hit_x in [-3.4,3.4]:
				g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=1-team
				g.phase="CPU_ATTACK" if team==0 else "ATTACK"; g.hitter=(1-team)*6; g.hitter_action="attack"
				g.flight_target=Vector3(hit_x,3.3,-1 if team==0 else 1); g.flight_left=0.6; g.block_anchor=hit_x; g.block_count=2
				if team==0:
					g.manual_wall.left_joined=hit_x<0; g.manual_wall.right_joined=hit_x>0
				for frame in 240:
					g.clock_time+=1.0/60; g.phase_time+=1.0/60; g.move_players(1.0/60)
					for p in g.players: p.tick(1.0/60,false,false)
				for index in g.defensive_coverage.targets:
					if g.players[index].position.distance_to(g.defensive_coverage.targets[index])>=0.9: print("COVER FAIL team=",team," rot=",rotation," hit=",hit_x," i=",index," pos=",g.players[index].position," assigned=",g.defensive_coverage.targets[index]," target=",g.players[index].target," velocity=",g.players[index].velocity)
					assert(g.players[index].position.distance_to(g.defensive_coverage.targets[index])<0.9,"Each floor defender must physically reach his own coverage lane")
				live_cases+=1
	print("LIVE COVERAGE36 PASS: ",live_cases," mirrored team/rotation/wing movement cases")
	print("COVERAGE36 PASS: ",cases," team/rotation/server/attack/wall plans / four floor lanes / stability / actual off-pin movement / incoming-flight preservation")
	quit()

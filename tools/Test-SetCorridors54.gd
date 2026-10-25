extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var failures: Array=[0,0]; var rows: Array=[]
	for version in 2:
		g.court_shape=load("res://docs/baseline-v53/court_shape.gd" if version==0 else "res://src/court_shape.gd").new()
		for direction in 3:
			for delay in [.05,.5,.8]:
				g.clock_time=0; g.shot_serial=0; g.planned_visual_key=""
				g.rotations=[3,3]; g.server=1; g.reset_rally(); g.possession=0; g.receiver=2; g.set_dir=0
				g.incoming_kind="spike"; g.incoming_power=.85; g.rng.seed=54006; g.test_rallies=1
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.players[2].position=Vector3(2.1,0,4); g.players[5].position=Vector3(2.8,0,6.3); g.players[4].position=Vector3(-1.3,0,4)
				g.ball_pos=g.players[2].contact_world("receive"); g.phase="RECEIVE"; g.armed=true; g.input_quality=.43; g.receive_offset=-.05
				var count: int=g.test_contacts; g.receive_ball(); assert(g.phase=="SET")
				var physical_deadline: float=g.flight_left; var elapsed:=0.0; var stalled:=0
				for frame in 500:
					if g.phase!="SET": break
					if elapsed>=delay and not g.armed: g.set_dir=direction; g.press_action("alternate")
					var previous: Vector3=g.players[g.setter].position
					g.step(1.0/120); elapsed+=1.0/120
					if g.players[g.setter].position.distance_to(previous)<.001 and g.players[g.setter].position.distance_to(g.players[g.setter].target)<.01 and g.players[g.setter].position.distance_to(g.flight_target)>1.4: stalled+=1
					if frame%4==0:
						for p in g.players: p.apply_pose(1.0/30)
				var good: bool=g.test_contacts>=count+2
				if version==1 and good:
					assert(elapsed<=physical_deadline+.025)
					assert(g.contact_log.back().gap<=.18)
				if not good: failures[version]+=1
				print("CORRIDOR54 version=",version," direction=",direction," delay=",delay," ok=",good)
				rows.append({"version":53+version,"direction":direction,"input_delay":delay,"contact":good,"elapsed":elapsed,"deadline":physical_deadline,"stalled_ticks":stalled})
	assert(failures[0]>0 and failures[1]==0,"Reproduced conflict must be fixed without changing the ball deadline")
	FileAccess.open("res://docs/corridors54-report.json",FileAccess.WRITE).store_string(JSON.stringify({"failures_before":failures[0],"failures_after":failures[1],"cases":rows},"  "))
	print("SET CORRIDORS54 PASS failures=",failures," /9 matched P4 emergency constructions")
	g.free(); quit()

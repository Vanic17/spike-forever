extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var failures:=0
	for team in 2:
		for rotation in 6:
			for q in [.35,.65,.95]:
				g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
				g.receiver=team*6+2; g.set_dir=1; g.incoming_kind="spike"; g.incoming_power=.9; g.rng.seed=54003
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.players[g.receiver].position=g.Tactics.world(team,2.1,4.0)
				g.players[team*6+5].position=g.Tactics.world(team,2.8,6.3)
				g.players[team*6+4].position=g.Tactics.world(team,-1.3,4.0)
				g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
				# Real receive -> second touch, mirrored courts and all rotations.
				g.demo=true; g.armed=true; g.input_quality=q
				var count: int=g.test_contacts; g.receive_ball(); g.demo=false
				if g.phase not in ["SET","CPU_SET"]: continue
				g.armed=true; g.input_quality=q; g.plan_attack(1,true)
				var initial={"actor":g.setter,"target":str(g.flight_target),"root":str(g.players[g.setter].position),"seconds":g.flight_left}
				for frame in 600:
					if g.phase not in ["SET","CPU_SET"]: break
					g.step(1.0/120)
					if frame%4==0:
						for p in g.players: p.apply_pose(1.0/30)
				var good: bool=g.test_contacts>=count+2
				var row={"team":team,"rotation":rotation,"q":q,"ok":good,"initial":initial,"phase":g.phase,"events":g.rally_events.slice(-4)}
				rows.append(row)
				if not good: failures+=1; print("FAIL54 ",JSON.stringify(row))
	var f=FileAccess.open("res://docs/second-touch54-report.json",FileAccess.WRITE); f.store_string(JSON.stringify(rows,"  ")); f.close()
	print("SECOND TOUCH54 ",rows.size()-failures,"/",rows.size())
	g.free(); quit(1 if failures else 0)

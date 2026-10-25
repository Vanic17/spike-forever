extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true
	g.online_session.playing=true; g.online_session.test_mode=true
	var failures:=0; var cases:=0
	for team in 2:
		for rotation in 6:
			for direction in [0,2]:
				g.rotations=[rotation,rotation]; g.server=1-team; g.rng.seed=40001; g.reset_rally(); g.possession=team; g.input_team=team
				g.receiver=team*6+4; g.set_dir=direction
				g.players[g.receiver].position=g.Tactics.world(team,0,5.5); g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
				g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
				g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=.3
				var before: int=g.test_contacts
				g.receive_ball(); g.press_action("action")
				for frame in 900:
					if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
					if g.phase in ["ATTACK","CPU_ATTACK"]: g.armed=true; g.charge=.85; g.input_quality=1
					g.step(1.0/120)
				cases+=1
				if g.test_contacts!=before+3:
					failures+=1; print("HUMAN51 FAIL ",team," ",rotation," ",direction," phase=",g.phase," contacts=",g.test_contacts-before)
	g.online_session.playing=false
	print("HUMAN51 ","PASS" if failures==0 else "FAIL"," human receive/set/attack on both teams / all rotations / cases=",cases," failures=",failures)
	g.free(); quit(0 if failures==0 else 1)

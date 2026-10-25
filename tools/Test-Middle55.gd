extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]; var failures:=0
	for team in 2:
		for rotation in 6:
			for wide in [false,true]:
				if "--probe" in OS.get_cmdline_user_args() and rotation!=1: continue
				g.rotations=[rotation,rotation]; g.server=1-team; g.rng.seed=40001; g.reset_rally(); g.possession=team
				g.receiver=team*6+4; g.set_dir=1; g.players[g.receiver].position=g.Tactics.world(team,0,5.5); g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.incoming_kind="spike"; g.incoming_power=.3
				g.flight_target=g.players[g.receiver].contact_world("receive"); g.flight_left=.6
				for tick in 72:
					g.clock_time+=1.0/120; g.phase_time+=1.0/120; g.flight_left-=1.0/120; g.move_players(1.0/120)
					for p in g.players: p.tick(1.0/120,false,false)
					if tick%4==0:
						for p in g.players: p.apply_pose(1.0/30)
				g.ball_pos=g.players[g.receiver].contact_world("receive"); g.armed=true; g.input_quality=1
				var before: int=g.test_contacts; g.receive_ball(); g.pass_quality=.95; g.input_quality=.95; g.out_of_system=1
				if team==0: g.press_action("alternate" if wide else "action")
				else: g.plan_attack(1,wide)
				var middle: int=g.planned_hitter; var origin: Vector3=g.flight_target
				var predicted: Vector3=g.RallyAI.attack_contact(g,1,middle,origin)
				var spacing:=absf(predicted.x-origin.x); var seconds:=0.0
				for frame in 1000:
					if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+3: break
					if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
					g.step(1.0/120)
					if g.test_contacts==before+2 and seconds==0: seconds=g.flight_left
					if frame%4==0:
						for p in g.players: p.apply_pose(1.0/30)
				var good: bool=g.test_contacts>=before+3
				if not good: failures+=1
				var row={"team":team,"rotation":rotation,"wide":wide,"spacing":spacing,"flight":seconds,"contacts":g.test_contacts-before,"ok":good}
				rows.append(row); if not good: print("MIDDLE55 FAIL ",row)
	for pair in range(0,rows.size(),2):
		assert(rows[pair].spacing<rows[pair+1].spacing-.3,"X must be closer to S than Square 7")
		if rows[pair].flight<.5 and rows[pair+1].flight<.5:
			assert(absf(rows[pair].flight-rows[pair+1].flight)<.035,"Ready quicks share the same tempo")
	FileAccess.open("res://docs/middle55-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("MIDDLE55 ",rows.size()-failures,"/",rows.size()); g.free(); quit(1 if failures else 0)

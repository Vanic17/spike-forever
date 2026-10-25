extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var failures:=0
	var hz:=120.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hz="): hz=float(arg.trim_prefix("--hz="))
	for power in [.4,.8,1.0]:
		assert(g.Reference.attack_seconds(power,0,true,false)==g.Reference.attack_seconds(power,0,false,false),"No back-row power penalty")
	assert(g.Reference.set_seconds(3,true,1,3,false)<g.Reference.set_seconds(3,false,1,3,false),"Quick pipe must travel on a lower, faster set")
	for team in 2:
		for rotation in 6:
			for direction in [0,2,3]:
				for quick in [false,true]:
					if "--probe" in OS.get_cmdline_user_args() and (team!=0 or rotation!=5 or direction!=3 or not quick): continue
					g.rotations=[rotation,rotation]; g.server=1-team; g.rng.seed=40001; g.shot_serial=0; g.reset_rally(); g.possession=team
					g.receiver=team*6+4; g.set_dir=direction
					g.players[g.receiver].position=g.Tactics.world(team,0,5.5); g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
					g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=.3
					var before: int=g.test_contacts
					g.receive_ball(); g.plan_attack(direction,quick)
					if team==0: g.press_action("alternate" if quick else "action")
					var runner: int=g.planned_hitter; var side:=1.0 if team==0 else -1.0
					var back: bool=not g.Tactics.front(runner,rotation)
					var takeoff:=0.0; var contact:=0.0; var run_frames:=0; var early:=0; var flight:=0.0; var measured:=false
					for frame in 900:
						if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
						if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
						if g.test_contacts==before+2 and flight==0: flight=g.flight_left
						g.step(1.0/hz)
						var p=g.players[runner]
						if p.velocity.length()>1.25 and p.travel_animation_name=="run":
							run_frames+=1
							if g.phase in ["SET","CPU_SET"]: early+=1
						if g.attack_run.flying(runner) and not measured:
							measured=true; takeoff=g.attack_run.air_start.z*side
						if g.test_contacts>=before+3: contact=p.position.z*side
					var ok: bool=g.test_contacts==before+3 and (not back or (measured and takeoff>=3.0 and contact<3.0))
					if not ok:
						failures+=1
						print("RUN50 POS ",g.players.slice(team*6,team*6+6).map(func(p): return str(p.position))," runner=",runner," actual=",g.players[runner].contact_world("attack")," ball=",g.ball_pos)
					var row={"team":team,"rotation":rotation,"direction":direction,"quick":quick,"back":back,"contacts":g.test_contacts-before,"takeoff":takeoff,"contact":contact,"run_frames":run_frames,"early_run_frames":early,"set_seconds":flight,"ok":ok}
					rows.append(row)
					if not ok or run_frames==0: print("RUN50 CASE ",row)
	FileAccess.open("res://docs/running50-report-"+str(int(hz))+".json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("RUNNING50 ","PASS" if failures==0 else "FAIL"," hz=",hz," cases=",rows.size()," failures=",failures)
	g.free(); quit(0 if failures==0 else 1)

extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var failures:=0
	var args:=OS.get_cmdline_user_args()
	var chosen_receiver:="libero"
	for arg in args:
		if arg.begins_with("--receiver="): chosen_receiver=arg.trim_prefix("--receiver=")
	for team in 2:
		for rotation in 6:
			if chosen_receiver=="opp-short" and rotation!=0: continue
			for direction in [0,1,2,3]:
				for quick in [false,true]:
					g.clock_time=0; g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
					g.rng.seed=40001; g.set_dir=direction
					var receiver: int=team*6+(4 if rotation in [0,1,5] else 1)
					if chosen_receiver=="oh1": receiver=team*6
					elif chosen_receiver=="oh2": receiver=team*6+3
					elif chosen_receiver=="opp-short": receiver=team*6+2
					g.receiver=receiver
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.phase_time=0
					g.incoming_kind="serve"; g.incoming_power=.2; g.armed=true; g.input_quality=1
					var target: Vector3=g.players[receiver].contact_world("receive")
					g.select_receive_pose(receiver,target); target=g.players[receiver].contact_world("receive")
					g.ball_pos=g.Tactics.world(1-team,0,7)+Vector3.UP*3.0
					g.launch(target,1.20 if chosen_receiver=="opp-short" else .85); g.armed=true; g.input_quality=1
					var initial: int=g.test_contacts; var chosen:=false; var hitter:=-1; var at_set:=-1.0
					var min_gap:=INF; var max_step:=0.0
					for frame in 1100:
						if g.phase in ["POINT","LOOSE"] or g.test_contacts>=initial+3: break
						if g.phase in ["SET","CPU_SET"] and not chosen:
							chosen=true
							if team==0:
								g.set_dir=direction; g.press_action("alternate" if quick else "action")
							else: g.plan_attack(direction,quick)
							hitter=g.planned_hitter
						if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
						var previous: Vector3=g.players[hitter].position if hitter>=0 else Vector3.ZERO
						g.step(1.0/120)
						if hitter>=0:
							max_step=maxf(max_step,previous.distance_to(g.players[hitter].position))
							if g.phase in ["SET","CPU_SET"]:
								for i in range(team*6,team*6+6):
									if i!=hitter: min_gap=minf(min_gap,g.players[hitter].position.distance_to(g.players[i].position))
						if frame%4==0:
							for p in g.players: p.apply_pose(1.0/30)
						if at_set<0 and g.test_contacts>=initial+2:
							var middle: int=g.Tactics.attacker(team,rotation,1,team*6+5)
							g.players[middle].apply_pose(0)
							at_set=minf(g.players[middle].current_joint("LeftFoot").y,g.players[middle].current_joint("RightFoot").y)
					var ok: bool=g.test_contacts>=initial+3 and min_gap>=g.Tactics.BODY_SPACE-.001 and max_step<=7.2/120+.025
					var row={"team":team,"rotation":rotation,"P":g.Tactics.Layout.label(rotation),"direction":direction,"quick":quick,"hitter":hitter,"contacts":g.test_contacts-initial,"middle_feet_at_set":at_set,"min_root_gap":min_gap,"max_root_step":max_step,"ok":ok,"events":g.rally_events.slice(-4) if not ok else []}
					rows.append(row)
					if not ok: failures+=1; print("TRANSITIONS62 FAIL ",JSON.stringify(row))
	var backend:="-psa" if "--psa-original" in args else ""
	FileAccess.open("res://docs/rotations62-transitions-"+chosen_receiver+backend+".json",FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"failures":failures},"  "))
	print("TRANSITIONS62 ",rows.size()-failures,"/",rows.size()," full flights from supplied reception formations")
	g.free(); quit(1 if failures else 0)

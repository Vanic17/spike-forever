extends SceneTree
## Complete incoming ball -> pass -> set -> attack, including the P6 crossing
## behind S. Readiness is measured from both displayed feet at S's real touch.
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var failures:=0; var airborne:=0; var real_airborne:=0
	for hz in [50,60,120]:
		for team in 2:
			for rotation in 6:
				for construction in ["fake","first","seven"]:
					g.clock_time=0; g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
					g.receiver=team*6+4; g.set_dir=0 if construction=="fake" else 1; g.rng.seed=40001
					g.players[g.receiver].position=g.Tactics.world(team,0,5.5)
					g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.phase_time=0
					g.incoming_kind="soft"; g.incoming_power=.2; g.armed=true; g.input_quality=1
					var target: Vector3=g.players[g.receiver].contact_world("receive")
					g.select_receive_pose(g.receiver,target); target=g.players[g.receiver].contact_world("receive")
					g.ball_pos=g.Tactics.world(1-team,0,5)+Vector3.UP*3.5
					g.launch(target,.72); g.armed=true; g.input_quality=1
					var initial: int=g.test_contacts
					var middle: int=g.Tactics.attacker(team,rotation,1,team*6+5)
					var received:=false; var measured:=false; var feet:=0.0; var at_set:=0.0; var gap:=INF
					var max_step:=0.0; var min_gap:=INF; var opening_depth:=0.0; var held_time:=0.0; var longest_hold:=0.0
					for frame in 700:
						if g.phase in ["POINT","LOOSE"] or g.test_contacts>=initial+3: break
						if g.phase in ["SET","CPU_SET"] and not received:
							received=true; opening_depth=g.players[middle].position.z*(1 if team==0 else -1)
							if team==0:
								g.set_dir=0 if construction=="fake" else 1
								g.press_action("alternate" if construction=="seven" else "action")
							else: g.plan_attack(0 if construction=="fake" else 1,construction=="seven")
						if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
						var position: Vector3=g.players[middle].position
						g.step(1.0/hz)
						max_step=maxf(max_step,position.distance_to(g.players[middle].position))
						if received and g.phase in ["SET","CPU_SET"]:
							for other in range(team*6,team*6+6):
								if other==middle: continue
								for body in g.compute_footprint_points(other): min_gap=minf(min_gap,g.players[middle].position.distance_to(body))
							if g.court_shape.setter_yields.has(middle) and position.distance_to(g.players[middle].position)<.002: held_time+=1.0/hz
							else: held_time=0
							longest_hold=maxf(longest_hold,held_time)
						if frame%maxi(1,hz/30)==0:
							for p in g.players: p.apply_pose(1.0/30)
						if not measured and g.test_contacts>=initial+2:
							measured=true; g.players[middle].apply_pose(0)
							feet=minf(g.players[middle].current_joint("LeftFoot").y,g.players[middle].current_joint("RightFoot").y)
							at_set=g.clock_time; gap=g.players[middle].position.distance_to(g.middle_decoy.target)
					var flying: bool=measured and feet>.25
					if flying: airborne+=1
					if flying and construction!="fake": real_airborne+=1
					var valid: bool=g.test_contacts==initial+3 and flying and max_step<7.2/hz+.025 and min_gap>=.975
					if not valid: failures+=1
					var row={"hz":hz,"team":team,"rotation":rotation,"construction":construction,"contacts":g.test_contacts-initial,"airborne_at_set":flying,"feet":feet,"at_set":at_set,"gap_at_set":gap,"reception_open_depth":opening_depth,"min_gap":min_gap,"max_step":max_step,"longest_cached_hold":longest_hold,"valid":valid}
					rows.append(row)
					if not valid: print("MIDDLE READY57 FAIL ",JSON.stringify(row))
	FileAccess.open("res://docs/middle-ready57-report.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"failures":failures,"airborne_at_set":airborne,"actual_airborne":real_airborne},"  "))
	print("MIDDLE READY57 ",rows.size()-failures,"/",rows.size()," full incoming constructions / airborne=",airborne," actual=",real_airborne," / 50-60-120Hz")
	g.free(); quit(1 if failures else 0)

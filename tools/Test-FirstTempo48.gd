extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var jumps:=0; var real_jumps:=0; var contacts:=0
	var probe: bool="--probe" in OS.get_cmdline_user_args()
	var smoke: bool="--smoke" in OS.get_cmdline_user_args()
	for team in 2:
		for rotation in 6:
			for quality in [.55,.75,.95]:
				if probe and (rotation!=1 or quality!=.75): continue
				if smoke and (not rotation in [0,3] or quality!=.75): continue
				for actual in [false,true]:
					g.rotations=[rotation,rotation]; g.server=1-team; g.rng.seed=40001; g.reset_rally(); g.possession=team
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.receiver=team*6+4; g.set_dir=1 if actual else 0
					g.players[g.receiver].position=g.Tactics.world(team,0,5.5)
					g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
					g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=.3
					# Include the observed incoming flight: the middle starts his
					# real preparation before the passer touches it. The separate
					# 96-contact test retains instantaneous adverse-start fixtures.
					g.flight_target=g.ball_pos; g.flight_left=.60
					for incoming in 72:
						g.clock_time+=1.0/120; g.phase_time+=1.0/120; g.flight_left-=1.0/120
						g.move_players(1.0/120)
						for p in g.players: p.tick(1.0/120,false,false)
						if incoming%4==0:
							for p in g.players: p.apply_pose(1.0/30)
					g.ball_pos=g.players[g.receiver].contact_world("receive")
					if probe: print("PROBE48 PRE team=",team," roots=",g.players.slice(team*6,team*6+6).map(func(p): return str(p.position)))
					var before: int=g.test_contacts
					g.receive_ball(); g.pass_quality=quality; g.input_quality=quality; g.out_of_system=1
					if team==0: g.press_action("alternate" if actual else "action")
					else: g.plan_attack(1 if actual else 0,actual)
					var middle: int=g.Tactics.attacker(team,rotation,1,g.setter)
					var foot:=0.0; var measured:=false; var source_time:=0.0; var variant:=""; var gap:=0.0; var release:=0.0
					for frame in 1200:
						if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+3: break
						if g.phase=="ATTACK": g.armed=true; g.charge=.75; g.input_quality=1
						g.step(1.0/120)
						if probe and frame in [0,30,60,90,120]: print("PROBE48 ",team," actual=",actual," frame=",frame," phase=",g.phase," left=",g.flight_left," p=",g.players[middle].position," target=",g.players[middle].target," task=",g.players[middle].intent.task," yield=",g.court_shape.setter_yields.get(middle)," ideal=",g.middle_decoy.target)
						if frame%4==0:
							for p in g.players: p.apply_pose(1.0/30)
						if not measured and g.test_contacts>=before+2:
							var p=g.players[middle]; p.apply_pose(0)
							foot=minf(p.current_joint("LeftFoot").y,p.current_joint("RightFoot").y)
							source_time=p.animation_time; variant=p.variant_names.get("attack",""); measured=true; release=g.flight_left
							gap=p.position.distance_to(g.middle_decoy.target)
					var jumping: bool=measured and foot>.25
					if jumping: jumps+=1
					if jumping and actual: real_jumps+=1
					if g.test_contacts==before+3: contacts+=1
					var row={"team":team,"rotation":rotation,"quality":quality,"actual":actual,"airborne_at_set":jumping,"feet_height":foot,"source_time":source_time,"variant":variant,"gap_at_set":gap,"set_flight_seconds":release,"contacts":g.test_contacts-before,"set_origin":str(g.set_origin),"out_of_system":g.out_of_system,"setter":g.setter}
					rows.append(row)
					if not jumping or g.test_contacts!=before+3: print("TEMPO48 DIAG ",row)
	if smoke or probe: DirAccess.make_dir_recursive_absolute("res://.runtime/middle48")
	FileAccess.open("res://.runtime/middle48/smoke.json" if smoke else ("res://.runtime/middle48/probe.json" if probe else "res://docs/first-tempo48-report.json"),FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"airborne_at_set":jumps,"actual_airborne":real_jumps,"three_contact_cases":contacts},"  "))
	print("FIRST TEMPO48 RESULTS airborne=",jumps,"/",rows.size()," actual=",real_jumps,"/36 contacts=",contacts)
	if smoke:
		assert(contacts==8 and jumps==8,"Quick and fake must retain pre-set takeoff and three contacts in the PSA/native smoke scenarios")
		print("FIRST TEMPO48 SMOKE PASS")
	elif not probe and not "--baseline" in OS.get_cmdline_user_args():
		assert(contacts==72,"All controlled receptions must retain three real ball contacts")
		for row in rows:
			if row.gap_at_set<.85: assert(row.airborne_at_set,"An available middle must already have BOTH feet in air when the setter contacts the ball")
		assert(jumps>=60 and real_jumps>=30,"Early takeoff must work across qualities and both teams, retaining only distant safety-ball exceptions")
		print("FIRST TEMPO48 PASS")
	g.free(); quit()

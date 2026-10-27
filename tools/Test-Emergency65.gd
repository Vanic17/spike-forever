extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var obstacle: Array=[Vector3.ZERO]
	assert(g.court_shape.clear_recovery_route(Vector3(.6,0,0),Vector3(1.5,0,0),obstacle,1.005),"An existing overlap may separate outward")
	assert(not g.court_shape.clear_recovery_route(Vector3(.6,0,0),Vector3(-1.5,0,0),obstacle,1.005),"An overlap may never cross through the body")
	var rows: Array=[]; var failures:=0; var emergencies:=0
	for native in [true,false]:
		g.Avatar.native_animation_enabled=native
		for hz in [60,120]:
			for team in 2:
				for rotation in [2,3]:
					g.clock_time=0; g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4
					g.rng.seed=52007; g.set_dir=1; g.armed=true; g.input_quality=.84; g.incoming_kind="spike"; g.incoming_power=.65
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.players[g.receiver].position=g.Tactics.world(team,1.8,5.5); g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
					g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					var before: int=g.test_contacts; var events_before: int=g.rally_events.size(); g.receive_ball(); g.plan_attack(1,true)
					if team==0: g.press_action("alternate")
					var maximum_step:=0.0; var set_seconds:=0.0; var depth:=0.0; var release: Dictionary={}
					for frame in 900:
						if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+3: break
						if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
						var hitter: int=g.planned_hitter
						var previous: Vector3=g.players[hitter].position if hitter>=0 else Vector3.ZERO
						g.step(1.0/hz)
						if hitter>=0: maximum_step=maxf(maximum_step,previous.distance_to(g.players[hitter].position))
						if g.test_contacts==before+2 and set_seconds==0:
							set_seconds=g.flight_left; depth=absf(g.flight_target.z)
							release={"motion":g.dive_motions.get(g.setter,{}).duplicate(true),"setter":g.setter,"hitter":g.hitter,"setter_root":g.players[g.setter].position,"hitter_root":g.players[g.hitter].position,"system":g.out_of_system,"source":g.players[g.setter].variant_names.get("dive",""),"events":g.rally_events.slice(-4)}
						if frame%4==0:
							for p in g.players: p.apply_pose(4.0/hz)
					var spaced:=false
					for event in g.rally_events.slice(events_before):
						if event.kind=="emergency_attack_spacing": spaced=true
					if spaced: emergencies+=1
					var good: bool=g.test_contacts>=before+3 and set_seconds<2.5 and depth<4.81
					rows.append({"native":native,"hz":hz,"team":team,"rotation":rotation,"contacts":g.test_contacts-before,"set_seconds":set_seconds,"attack_depth_m":depth,"source_save_spacing":spaced,"maximum_hitter_step_m":maximum_step,"ok":good})
					if not good: rows[-1]["release"]=release
					if not good: failures+=1; print("EMERGENCY ATTACK65 FAIL ",rows[-1])
	g.Avatar.native_animation_enabled=true
	FileAccess.open("res://docs/gameplay65-emergency.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"spaced_emergencies":emergencies,"failures":failures},"  "))
	print("EMERGENCY ATTACK65 ",rows.size()-failures,"/",rows.size()," spaced=",emergencies)
	g.free(); quit(1 if failures else 0)

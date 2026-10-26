extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]; var failures:=0
	for native in [true,false]:
		g.Avatar.native_animation_enabled=native
		for hz in [60,120]:
			g.rotations=[4,4]; g.server=0; g.reset_rally(); g.possession=1; g.receiver=10; g.set_dir=0; g.rng.seed=57002
			g.incoming_kind="spike"; g.incoming_power=.85; g.input_quality=.45; g.armed=true
			for p in g.players: p.blend_left=0; p.apply_pose(0)
			g.players[10].position=g.Tactics.world(1,1.5,5.5); g.players[11].position=g.Tactics.world(1,.5,2.2)
			g.ball_pos=g.players[10].contact_world("receive"); g.phase="CPU_RECEIVE"
			var initial: int=g.test_contacts; g.receive_ball(); assert(g.phase=="CPU_SET")
			g.armed=true; g.input_quality=.9
			var minimum:=INF; var blocked_seconds:=0.0; var maximum_step:=0.0
			for frame in 600:
				if g.phase!="CPU_SET": break
				var before: Vector3=g.players[11].position
				g.step(1.0/hz)
				maximum_step=maxf(maximum_step,before.distance_to(g.players[11].position))
				minimum=minf(minimum,g.players[10].position.distance_to(g.players[11].position))
				if before.distance_to(g.players[11].position)<.001 and g.players[11].position.distance_to(g.players[11].stance_for_contact(g.setter_action,g.flight_target))>.3: blocked_seconds+=1.0/hz
				if frame%4==0:
					for p in g.players: p.apply_pose(4.0/hz)
			var good: bool=g.test_contacts>=initial+2 and g.phase=="CPU_ATTACK" and minimum>=g.Tactics.BODY_SPACE-.001 and maximum_step<g.Reference.run_speed()*1.1/hz+.005
			rows.append({"native":native,"hz":hz,"contacts":g.test_contacts-initial,"phase":g.phase,"closest_pair_m":minimum,"maximum_root_step_m":maximum_step,"blocked_seconds":blocked_seconds,"ok":good})
			if not good: failures+=1; print("YIELD57 FAIL ",rows[-1])
	g.Avatar.native_animation_enabled=true
	FileAccess.open("res://docs/yield-routes57-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("YIELD ROUTES57 ","PASS " if failures==0 else "FAIL ",rows.size()-failures,"/",rows.size())
	g.free(); quit(1 if failures else 0)

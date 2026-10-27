extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=true
	var report:="res://docs/stats63-original-trace.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report=arg.trim_prefix("--report=")
	var rows: Array=[]
	var manual: bool="--manual" in OS.get_cmdline_user_args()
	g.demo=not manual
	for seed_value in [63001,63002]:
		g.clock_time=0; g.rng.seed=seed_value; g.rotations=[0,0]; g.server=0; g.scores=[0,0]; g.sets=[0,0]; g.reset_rally()
		for frame in 3600:
			if manual:
				if g.phase=="SERVE" and g.server==0 and not g.toss_active and not g.serve_adjusting:
					if not g.charging and g.phase_time>.3: g.press_action("action")
					elif g.charging and g.current_charge()>=.81: g.release_action()
				if g.possession==0:
					if g.phase=="RECEIVE" and not g.armed and g.receive_deadline-g.clock_time<.14: g.press_action("action")
					elif g.phase=="SET" and not g.armed:
						g.set_dir=posmod(g.test_contacts,4); g.press_action("alternate" if seed_value==63002 else "action")
					elif g.phase=="ATTACK" and not g.armed:
						if not g.charging: g.press_action("action")
						elif g.current_charge()>=.84: g.release_action()
				elif g.phase=="CPU_ATTACK" and g.flight_left<.22 and not g.block_commanded: g.press_action("action")
			g.step(1.0/120)
			if frame%4==0:
				for p in g.players: p.apply_pose(1.0/30)
			if frame%30==0:
				rows.append({"seed":seed_value,"frame":frame,"phase":g.phase,"scores":g.scores.duplicate(),"rotations":g.rotations.duplicate(),"ball":str(g.ball_pos),"velocity":str(g.ball_vel),"left":g.flight_left,"charge":g.current_charge(),"quality":g.pass_quality,"receiver":g.receiver,"setter":g.setter,"hitter":g.hitter,"rng":str(g.rng.state),"players":g.players.map(func(p): return [str(p.position),p.clip_name,p.animation_time,p.rotation.y])})
	FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify(rows))
	print("PARITY63 TRACE PASS rows=",rows.size()," contacts=",g.test_contacts)
	g.free(); quit()

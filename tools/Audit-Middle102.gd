extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("middle102" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var rows: Array=[]
	var failures: Array=[]
	Input.action_press("down")
	for rotation in 6:
		for quick in [false,true]:
			g.rotations=[rotation,rotation];g.server=1;g.reset_rally();g.possession=0;g.input_team=0;g.receiver=4;g.rng.seed=102421+rotation;g.set_dir=1
			g.players[g.receiver].position=g.Tactics.world(0,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
			g.phase="RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0;g.receive_ball()
			var row: Dictionary={"rotation":rotation,"quick":quick,"quality":g.pass_quality,"pass_target":str(g.flight_target)}
			g.press_action("alternate" if quick else "action");row.variant=g.players[g.setter].variant_names.get("set","")
			for frame in 600:
				if g.phase=="ATTACK":g.armed=true;g.charge=1;g.input_quality=1;g.aim=Vector2.DOWN
				g.step(1.0/120)
				if g.phase not in ["SET","ATTACK"]:break
			row.phase=g.phase;row.contact=str(g.ball_pos);row.target=str(g.flight_target);row.speed=g.ball_vel.length();row.velocity=str(g.ball_vel);row.power=g.last_power
			rows.append(row)
			if g.phase!="CPU_RECEIVE":failures.append(row)
			print("LIVE102 rotation=",rotation," quick=",quick," phase=",g.phase," variant=",row.variant)
	FileAccess.open("res://docs/middle102-live.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"cases":rows.size(),"errors":failures,"rows":rows},"  "))
	print("AUDIT102 ","PASS" if failures.is_empty() else "FAIL"," cases=",rows.size()," errors=",failures);quit(0 if failures.is_empty() else 1)

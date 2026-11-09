extends SceneTree
const Second=preload("res://src/setter_second96.gd")
var errors: Array=[]
var rows: Array=[]
func check(ok: bool,label: String):
	if not ok:errors.append(label);print("FAIL97 ",label)
func _initialize():call_deferred("run")
func run():
	assert("strikes96" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g)
	g.set_process(false);g.set_physics_process(false);g.started=true;g.self_test=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	await process_frame
	g.online_session.playing=true
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation];g.server=1-team;g.reset_rally();g.possession=team;g.receiver=team*6+4;g.rng.seed=97421
			g.players[g.receiver].position=g.Tactics.world(team,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
			g.phase="RECEIVE" if team==0 else "CPU_RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0
			g.receive_ball()
			rows.append({"team":team,"rotation":rotation,"q":g.pass_quality,"depth":absf(g.flight_target.z)})
			if g.pass_quality>.95:check(absf(g.flight_target.z)<.85,"tight perfect pass "+str(rows.back()))
	var live: Array=[]
	for team in 2:
		for rotation in 6:
			for direction in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
				g.rotations=[rotation,rotation];g.server=1-team;g.reset_rally();g.possession=team;g.input_team=team;g.receiver=team*6+4;g.rng.seed=97421
				g.players[g.receiver].position=g.Tactics.world(team,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
				g.phase="RECEIVE" if team==0 else "CPU_RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0
				g.receive_ball();g.aim=direction
				if not g.Tactics.front(g.setter,rotation):
					check(not Second.request(g) and not g.armed,"back-row setter cannot use triangle");continue
				var old: int=g.contact_log.size();var requested:=false
				for frame in 480:
					if not requested and g.flight_left<(.12 if "--late" in OS.get_cmdline_user_args() else .45):requested=Second.request(g)
					g.step(1.0/120)
					if g.phase not in ["SET","CPU_SET"]:break
				var touched: bool=g.contact_log.size()>old and g.contact_log.back().action=="dump"
				live.append({"team":team,"rotation":rotation,"aim":str(direction),"requested":requested,"contact":touched,"phase":g.phase})
				check(touched,"live triangle "+str(live.back()))
	# Distribution uses actual command routing; no reroll once armed.
	var onehand:=0
	g.rng.seed=97025
	for trial in 1000:
		g.rotations=[3,0];g.server=1;g.reset_rally();g.phase="SET";g.possession=0;g.input_team=0;g.setter=5;g.touches=[1,0];g.out_of_system=1;g.pass_quality=1;g.armed=false;g.set_dir=1
		var s=g.players[5];s.play("idle",1,true);s.select_variant("set","set");s.position=Vector3(1.1,0,.72);s.setting_yaw=-PI/2
		g.ball_pos=Vector3(1.1,3.8,.72);g.flight_target=Vector3(1.1,s.contact_local("set").y,.72);g.flight_left=.65;g.airborne=true;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.65,Vector3.ZERO)
		g.press_action("action")
		if s.variant_names.get("set","")=="set_first96":onehand+=1
	check(onehand>=210 and onehand<=290,"25 percent distribution "+str(onehand))
	# A late request must retain a future deadline, rather than contact at t=0.
	g.rotations=[3,0];g.possession=0;g.input_team=0;g.setter=5;g.touches=[1,0];g.phase="SET";g.armed=false;g.airborne=true;g.aim=Vector2.DOWN
	var p=g.players[5];p.setting_yaw=-PI/2;p.position=Vector3(0,0,.75);p.play("idle",1,true)
	g.ball_pos=Vector3(0,2.75,.75);g.flight_target=Vector3(0,2.53,.75);g.flight_left=.10;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.10,Vector3.ZERO);g.flight_spin=Vector3.ZERO
	check(Second.request(g),"late triangle accepted");check(g.flight_left>.04,"late triangle keeps future interception")
	var c=g.clips.dive_pancake80
	var samples: Array=[]
	for remaining in [.8,.6,.4,.25,.1,0.0]:
		var pose: Array[Transform3D]=p.normalized_pose("source:dive_pancake80",maxf(0,c.contact_time-remaining*1.15),false)
		samples.append({"remaining":remaining,"head":pose[c.names.find("Head")].origin.y,"hand":pose[c.names.find("RightHand")].origin.y})
	print("PANCAKE97 ",samples)
	check(samples[1].head>samples[4].head+.25,"pancake remains upright longer")
	FileAccess.open("res://docs/perfect-set97-tests-late.json" if "--late" in OS.get_cmdline_user_args() else "res://docs/perfect-set97-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"passes":rows,"live":live,"onehand_per_1000":onehand,"pancake":samples},"  "))
	print("PERFECT SET97 ","PASS" if errors.is_empty() else "FAIL",errors);quit(0 if errors.is_empty() else 1)

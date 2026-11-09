extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("review103" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var rows: Array=[];var failures: Array=[]
	Input.action_press("down")
	for rotation in 6:
		for direction in [0,2]:
			g.rotations=[rotation,rotation];g.server=0;g.reset_rally();g.possession=0;g.input_team=0;g.receiver=3;g.rng.seed=103421+rotation;g.set_dir=direction
			# This is a return after our serve, not a ball arriving instantly while
			# the setter is still 12 m away at his service starting position.
			for i in 12:
				var team: int=int(i/6);g.players[i].position=g.Tactics.home_for(g,i,team,rotation,team==g.server,false)
				if team==0 and g.Tactics.role_for(g,i)=="L":g.receiver=i
			g.players[g.receiver].position=g.Tactics.world(0,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
			g.phase="RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0;g.receive_ball()
			g.press_action("action")
			var hitter: int=g.planned_hitter
			var row: Dictionary={"rotation":rotation,"direction":direction,"hitter":hitter}
			for frame in 600:
				if g.phase=="ATTACK":g.armed=true;g.charge=.96;g.input_quality=1;g.aim=Vector2.DOWN if direction==0 else Vector2(1,1).normalized()
				g.step(1.0/120)
				if g.phase not in ["SET","ATTACK"]:break
			row.phase=g.phase;row.target=str(g.flight_target);row.seconds=g.flight_left;row.speed=g.ball_vel.length()
			for i in range(g.rally_events.size()-1,-1,-1):
				if g.rally_events[i].kind=="spike":row.delivery=g.rally_events[i].duplicate(true);break
			if g.phase!="CPU_RECEIVE":failures.append(row)
			if rotation==0 and hitter!=(0 if direction==0 else 2):failures.append({"P1_wrong_recipient":row})
			rows.append(row)
	Input.action_release("down")
	var file:=FileAccess.open("res://docs/review103-live.json",FileAccess.WRITE);file.store_string(JSON.stringify({"pass":failures.is_empty(),"cases":rows,"errors":failures},"\t"));file.close()
	print("AUDIT103 ","PASS" if failures.is_empty() else "FAIL"," cases=",rows.size()," errors=",failures);quit(0 if failures.is_empty() else 1)

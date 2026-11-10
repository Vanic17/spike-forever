extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("attack104" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var rows: Array=[];var errors: Array=[]
	Input.action_press("down")
	for rotation in 6:
		for direction in [0,1,2,3]:
			g.rotations=[rotation,rotation];g.server=0;g.reset_rally();g.possession=0;g.input_team=0;g.receiver=3;g.rng.seed=104421+rotation;g.set_dir=direction
			for i in 12:
				var team: int=int(i/6);g.players[i].position=g.Tactics.home_for(g,i,team,rotation,team==g.server,false)
				if team==0 and g.Tactics.role_for(g,i)=="L":g.receiver=i
			g.players[g.receiver].position=g.Tactics.world(0,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
			g.phase="RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0;g.receive_ball();g.press_action("action")
			var row: Dictionary={"rotation":rotation,"direction":direction,"hitter":g.planned_hitter};var before:=Vector3.ZERO;var trace: Array=[]
			for frame in 700:
				if g.phase=="ATTACK":
					g.armed=true;g.charge=.96;g.input_quality=1;g.aim=Vector2.DOWN if direction in [0,1] else Vector2(1,1).normalized()
					var p=g.players[g.hitter];trace.append({"seconds":g.flight_left,"position":str(p.position),"speed":p.velocity.length(),"clip":p.clip_name,"time":p.animation_time,"load":p.pin_reference_load})
				before=g.ball_pos;g.step(1.0/120)
				if g.phase not in ["SET","ATTACK"]:break
			row.phase=g.phase;row.origin=str(before);row.velocity=str(g.ball_vel);row.vertical=g.ball_vel.y;row.spin=str(g.flight_spin);row.speed=g.ball_vel.length();row.trace=trace
			for i in range(g.rally_events.size()-1,-1,-1):
				if g.rally_events[i].kind=="spike":row.delivery=g.rally_events[i].duplicate(true);break
			if g.phase!="CPU_RECEIVE":errors.append({"rotation":rotation,"direction":direction,"phase":g.phase})
			var touches: int=g.test_contacts;var score: int=g.scores[0]
			for frame in 240:
				if g.phase=="POINT" or g.test_contacts>touches:break
				g.step(1.0/120)
			row.floor_point=g.scores[0]>score;row.defended=g.test_contacts>touches;row.outcome=g.phase;row.reason=g.point_reason
			rows.append(row)
	Input.action_release("down")
	var suffix:="before" if "--baseline" in OS.get_cmdline_user_args() else "after"
	if "--psa-original" in OS.get_cmdline_user_args():suffix+="-fallback"
	var report_name:="attack105" if "--attack105" in OS.get_cmdline_user_args() else "attack104"
	var f:=FileAccess.open("res://docs/"+report_name+"-"+suffix+".json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":errors.is_empty(),"cases":rows,"errors":errors},"\t"));f.close()
	print("ATTACK104 ",suffix," ","PASS" if errors.is_empty() else "FAIL"," ",errors);quit(0 if errors.is_empty() else 1)

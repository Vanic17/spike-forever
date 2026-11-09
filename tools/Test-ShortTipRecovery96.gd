extends SceneTree
const Recovery=preload("res://src/short_tip_recovery96.gd")
const Second=preload("res://src/setter_second96.gd")
const Net=preload("res://src/net_spec94.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);print("FAIL96R ",label)
func _initialize():call_deferred("run")
func run():
	assert("strikes96" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.started=true;g.self_test=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false)
	for p in g.players:p.set_process(false);p.render_at_draw=false
	await process_frame
	var p=g.players[0];var c=g.clips.dive_pancake80
	var pose: Array[Transform3D]=p.normalized_pose("source:dive_pancake80",c.contact_time,false)
	var a: Vector3=pose[c.names.find("RightArm")].origin;var e: Vector3=pose[c.names.find("RightForeArm")].origin;var h: Vector3=pose[c.names.find("RightHand")].origin
	var extension: float=a.distance_to(h)/(a.distance_to(e)+e.distance_to(h));check(extension>.97,"pancake arm extended "+str(extension))
	var saves:=0
	for team in 2:
		g.rotations=[0,0];g.server=1;g.reset_rally();g.possession=team;g.phase="RECEIVE" if team==0 else "CPU_RECEIVE";g.input_team=team;g.incoming_short_tip96=true;g.incoming_kind="soft";g.incoming_power=.35;g.winner_team=-1;g.armed=true;g.input_quality=.9;g.late_receive=false;g.airborne=true
		var side: float=1 if team==0 else -1;var index: int=team*6;p=g.players[index]
		var landing:=Vector3(-2,.15,side*1.9)
		var offset: Vector3=c.contact_offset*p.height_scale90;landing.y=offset.y
		var yaw: float=PI if team==0 else 0
		p.position=landing-Basis(Vector3.UP,yaw)*offset;p.position.y=0;p.rotation.y=yaw;p.play("idle",1,true);p.motion_lock=0
		for other in range(team*6,team*6+6):
			if other!=index:g.players[other].position=Vector3(10,0,10)
		g.ball_pos=landing+Vector3(0,.65,side*-.12);g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,landing,.26,Vector3.ZERO);g.flight_left=.16
		var plan:=Recovery.proposal(g,index);check(not plan.is_empty(),"reachable short tip gets pancake proposal team "+str(team))
		if not plan.is_empty():
			check(Recovery.try_save(g),"pancake committed for short tip")
			check(g.players[g.receiver].variant_names.dive=="dive_pancake80","selected authored pancake")
			p.position=plan.stance;p.rotation.y=plan.yaw;p.blend_left=0;g.ball_pos=plan.point
			check(g.validate_contact(index,"dive"),"pancake physical contact team "+str(team));saves+=1
			var upper: float=p.current_joint("RightArm").distance_to(p.current_joint("RightForeArm"));var lower: float=p.current_joint("RightForeArm").distance_to(p.current_joint("RightHand"))
			check(p.current_joint("RightArm").distance_to(p.current_joint("RightHand"))/(upper+lower)>.95,"pancake arm stays extended after contact IK")
		g.incoming_short_tip96=false;check(not Recovery.eligible(g),"ordinary shots do not force pancake")
		g.incoming_short_tip96=true;g.winner_team=1-team;check(not Recovery.eligible(g),"guaranteed winner does not become automatic save")
	# A distant command is armed, then flies into the mesh instead of being rejected.
	g.possession=0;g.input_team=0;g.setter=5;g.phase="SET";g.rotations=[3,0];g.touches=[1,0];g.out_of_system=1;g.armed=false;g.airborne=true;g.aim=Vector2.RIGHT
	p=g.players[5];p.position=Vector3(0,0,4);p.setting_yaw=-PI/2;p.play("set",1,false);p.motion_lock=0
	g.ball_pos=Vector3(0,3.7,4);g.flight_target=Vector3(0,2.6,4);g.flight_left=.6;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.6,Vector3.ZERO)
	check(Second.request(g),"far-net setter can still request triangle")
	g.ball_pos=g.flight_target;p.position=p.target;p.rotation.y=PI;p.blend_left=0
	check(g.validate_contact(5,"dump"),"far-net gesture still meets the ball")
	var shot:=Second.trajectory(g);var point: Vector3=g.ball_pos;var v: Vector3=g.BallFlight.velocity_to(point,shot.target,shot.seconds,shot.spin,g.flight_gravity);var hit_net:=false
	for tick in 180:
		var next: Array=g.BallFlight.advance(point,v,shot.spin,1.0/120,g.flight_gravity)
		var crossing:=Net.crossing(point,next[0],v)
		if not crossing.is_empty():hit_net=not crossing.get("under",false);break
		point=next[0];v=next[1]
	check(hit_net,"far-net attempt hits actual mesh")
	FileAccess.open("res://docs/strokes96-short-recovery.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"pancake_extension":extension,"recoveries":saves},"  "))
	print("SHORT TIP96 ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," errors=",failures);quit(0 if failures.is_empty() else 1)

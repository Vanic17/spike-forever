extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	if not ok: failures+=1; push_error("HANDED51 FAIL "+message)
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var count:=0
	for native in [false,true]:
		g.Avatar.native_animation_enabled=native
		for side in 2:
			var p=g.players[side*6]
			p.roster_identity={"name":"Left","jersey_number":1,"appearance":{},"dominant_hand":"left","serve_preference":"float"}; p.apply_identity()
			for action in ["attack","power","float","dump"]:
				p.position=Vector3(0,0,4 if side==0 else -4); p.rotation.y=PI if side==0 else 0
				p.play(action,1,false); p.animation_time=p.clips[action].contact_time; p.blend_left=0; p.reach_weight=0
				p.apply_pose(0)
				var hand: Vector3=p.current_hand(false)
				var target: Vector3=p.contact_world(action)
				check(hand.distance_to(target)<.24,"rendered left palm contact "+str([native,side,action,hand.distance_to(target)]))
				count+=1
	for preference in ["float","jump"]:
		g.server=1; g.reset_rally(); g.started=true
		var s=g.players[g.server_index(1)]; s.roster_identity["serve_preference"]=preference
		g.phase_time=.66; g.step(.01)
		check(g.serve_type==(0 if preference=="float" else 1),"CPU serve preference "+preference)
		check(g.toss_active or g.serve_adjusting,"CPU starts selected service")
	for team in 2:
		for kind in 2:
			g.online_session.playing=true; g.server=team; g.reset_rally(); g.input_team=team; g.started=true
			var serving=g.players[g.server_index(team)]
			serving.roster_identity={"name":"Left serve","jersey_number":1,"appearance":{},"dominant_hand":"left"}; serving.apply_identity()
			g.serve_type=kind; g.serve_power=.8; var contacts: int=g.contact_log.size()
			g.begin_serve_toss()
			for frame in 700:
				if g.phase!="SERVE": break
				g.step(1.0/120)
			check(g.contact_log.size()>contacts and g.phase in ["RECEIVE","CPU_RECEIVE"],"full left-handed service "+str([team,kind]))
			g.online_session.playing=false
	g.online_session.playing=true; g.online_session.local_side=1; g.input_team=1; g.possession=1
	g.phase="CPU_SET"; g.setter=11; g.out_of_system=1; g.pass_quality=1; g.armed=false
	g.flight_target=Vector3(1,2.4,-1); g.apply_direction(Vector2(-1,0),0); g.set_camera()
	check(g.set_dir==0 and g.aim.x>.9,"guest screen-left selects own outside, world-positive X")
	check(g.camera.position.z<0 and g.display_phase()=="SET","guest front camera and own action HUD")
	for attacker in 2:
		g.rotations=[0,0]; g.server=attacker; g.reset_rally(); g.possession=attacker; g.phase="ATTACK" if attacker==0 else "CPU_ATTACK"
		g.input_team=1-attacker; g.online_session.inputs[1-attacker]={"left":1.0,"right":1.0}
		g.manual_wall.read(g,Vector2(.5,0),.1)
		var members: Array=g.manual_wall.members(g)
		check(members.size()==3 and members.all(func(index): return int(index/6)==1-attacker),"L2/R2 triple block for either human")
		g.block_commanded=false; g.jump_manual_wall()
		check(g.block_commanded and g.manual_wall.jumped.size()==3,"manual jump for both human teams")
	g.server=1; g.reset_rally(); g.started=true; g.paused=false; g.clock_time=20; g.phase="SERVE"; g.possession=1
	g.charging=true; g.charge_button="action"; g.charge_start=17
	g.online_session.apply_command(1,999,"action",false,{"direction":Vector2.ZERO},g.Timing.SERVE_CHARGE_SECONDS)
	check(absf(g.serve_power-1)<.000001,"guest released hold duration preserves displayed 100 percent")
	g.online_session.playing=false; g.input_team=0
	print("HANDED51 ","PASS" if failures==0 else "FAIL"," left contacts=",count," / four full left serves / native+PSA / both teams / CPU preferences / guest orientation / triple wall")
	FileAccess.open("res://docs/handed51-report.json",FileAccess.WRITE).store_string(JSON.stringify({"pose_contacts":count,"full_left_services":4,"both_manual_walls":true,"native_and_psa":true,"failures":failures},"  "))
	g.free(); quit(0 if failures==0 else 1)

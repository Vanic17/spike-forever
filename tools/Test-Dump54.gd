extends SceneTree
const Dump=preload("res://src/setter_dump.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for left in [false,true]:
			g.rotations=[3,3]; g.server=1-team; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.receiver=team*6+4; g.out_of_system=1
			var p=g.players[g.setter]; p.left_handed=left; p.select_variant("dump","dump_push54"); p.rotation.y=PI if team==0 else 0
			g.phase="SET" if team==0 else "CPU_SET"; g.setter_dump=true; g.armed=true; g.input_quality=1.0
			g.ball_pos=g.Tactics.world(team,1.8,.65); g.ball_pos.y=p.contact_local("dump").y
			p.position=p.stance_for_contact("dump",g.ball_pos); p.blend_left=0; p.prepare_contact("dump",0)
			assert(g.Tactics.front(g.setter,g.rotations[team]),"P4 setter is front row")
			assert(g.validate_contact(g.setter,"dump"),"Authored palm must physically meet the ball")
			print("DUMP CONTACT54 ",g.ball_pos," offset=",p.contact_local("dump")," front=",g.Tactics.front(g.setter,g.rotations[team]))
			assert(Dump.available(g,g.ball_pos),"Near-net front-row dump")
			assert(not Dump.available(g,g.ball_pos+Vector3(0,0,3 if team==0 else -3)))
			var authored: Array=p.normalized_pose("dump",p.clips.dump.contact_time,false)
			p.native_animation_enabled=false
			var fallback: Array=p.normalized_pose("dump",p.clips.dump.contact_time,false)
			p.native_animation_enabled=true
			assert(p.pose_tree.initialized and p.pose_tree.library.has_animation("dump_push54"))
			for bone in authored.size(): assert(authored[bone].origin.distance_to(fallback[bone].origin)<.002)
			for direction in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]:
				var delivery: Dictionary=Dump.trajectory(g.ball_pos,direction,team,Vector3.ZERO)
				assert(not delivery.is_empty())
				var end: Vector3=g.BallFlight.advance(g.ball_pos,delivery.velocity,Vector3.ZERO,delivery.seconds)[0]
				assert(end.distance_to(delivery.target)<.002)
			g.touches=[0,0]; g.touches[team]=1; g.aim=Vector2.ZERO; g.dump_ball()
			assert(g.possession==1-team and g.touches[team]==2 and g.phase in ["RECEIVE","CPU_RECEIVE"])
			rows.append({"team":team,"left_handed":left,"contact_height":p.contact_local("dump").y,"gap":g.max_contact_gap})
	# Real Circle command changes the hand height on the SAME incoming flight.
	g.rotations=[3,3]; g.server=1; g.reset_rally(); g.possession=0; g.setter=5; g.receiver=4; g.out_of_system=1; g.pass_quality=.95
	g.players[5].left_handed=false; g.players[5].position=Vector3(1.8,0,1.5)
	g.set_phase("SET"); g.ball_pos=Vector3(1.8,1.2,4)
	g.launch(Vector3(1.8,g.clips.set.contact_offset.y,.65),1.05)
	g.input_team=0; g.press_action("dump"); assert(g.setter_dump and g.armed,"Circle must trigger the near-net gesture")
	var before: int=g.test_contacts
	for frame in 300:
		if g.phase!="SET": break
		g.step(1.0/120)
		if frame%4==0:
			for p in g.players: p.apply_pose(1.0/30)
	assert(g.test_contacts==before+1 and g.possession==1,"Commanded dump must actually contact and cross")
	g.reset_rally(); g.possession=0; g.receiver=4; g.phase="RECEIVE"; g.incoming_kind="net"; g.touches=[2,0]; g.armed=true; g.input_quality=1
	g.players[4].blend_left=0; g.ball_pos=g.players[4].contact_world("receive")
	g.receive_ball()
	assert(g.touches[0]==3 and g.possession==1 and g.phase=="CPU_RECEIVE","Own-net rescue is the third touch, never a fourth-touch set")
	FileAccess.open("res://docs/dump54-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("DUMP54 PASS: AnimationTree and PSA, both hands/sides, 16 net-clear trajectories, two touches")
	g.free(); quit()

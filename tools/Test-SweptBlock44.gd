extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var cases:=0
	for team in 2:
		g.rotations=[0,0]; g.server=0; g.reset_rally(); g.clock_time=10
		g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.possession=team; g.last_touch=1-team; g.blocking_team=team
		g.block_time=9.75; g.block_quality=1; g.block_commanded=true; g.winner_team=-1; g.block_count=2
		var index: int=team*6+1
		if team==0: g.manual_wall.jumped.assign([index])
		else: g.block_rosters[team]=[index]
		var p=g.players[index]
		p.position=Vector3(0,0,0.68 if team==0 else -0.68); p.rotation.y=PI if team==0 else 0
		p.play("block",1,false)
		p.reach_action="block"; p.reach_weight=1
		p.reach_target=Vector3(p.contact_world("block").x,3.08,0.035 if team==0 else -0.035)
		p.prepare_contact("block",0)
		var point: Vector3=(p.current_hand(true)+p.current_hand(false))*0.5
		assert(point.y>2.43)
		var forward:=Vector3(0,0,1 if team==0 else -1)
		g.ball_pos=point+forward*0.45; g.ball_vel=forward*30+Vector3.DOWN*2; g.flight_spin=Vector3.ZERO
		g.incoming_kind="spike"; g.block_checked=false
		g.try_block(point-forward*0.45)
		assert(g.block_checked and g.last_touch==team,"The ball must hit actual hands along its swept path, even if both sampled endpoints miss")
		assert(g.ball_vel.dot(forward)<0 and g.ball_vel.y<0,"A well sealed block drives the ball into the attacker's court")
		cases+=1
		# A missed sample does not consume the only chance to detect hands.
		g.last_touch=1-team; g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.possession=team
		g.incoming_kind="spike"; g.block_checked=false
		g.ball_pos=point+Vector3(2,0,0)+forward*0.4; g.ball_vel=forward*30
		g.try_block(g.ball_pos-forward*0.8)
		assert(not g.block_checked,"A near-net miss must leave the next swept contact eligible")
		g.ball_pos=point+forward*0.4; g.ball_vel=forward*30
		g.try_block(point-forward*0.4)
		assert(g.block_checked)
		cases+=1
		g.last_touch=1-team; g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.possession=team
		g.incoming_kind="spike"; g.block_checked=false; g.block_quality=0.65
		var edge:=point; edge.x=maxf(p.current_hand(true).x,p.current_hand(false).x)+0.11
		g.ball_pos=edge+forward*0.4; g.ball_vel=forward*30
		g.try_block(edge-forward*0.4)
		assert(g.block_checked and g.last_touch==team and g.ball_vel.x>3 and g.ball_vel.dot(forward)>0,"An outer fingertip contact must allow a glancing tool off the block")
		cases+=1
	print("SWEPT BLOCK44 PASS cases=",cases," / actual skeleton hands / segment contact / miss then retry / mirrored monster and outer-finger tool")
	g.free(); quit()

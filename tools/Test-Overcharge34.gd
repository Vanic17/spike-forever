extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	assert(g.Timing.attack_risk(1.1)>g.Timing.serve_risk(1.1) and g.Timing.attack_risk(1.1,true)>g.Timing.serve_risk(1.1))
	assert(g.Timing.SERVE_CHARGE_SECONDS==0.46 and g.Timing.LATE_RECEIVE_SECONDS==0.12)
	for tip in [false,true]:
		var valid:=0; var faults:=0
		for seed_value in range(20):
			g.reset_rally(); g.rng.seed=seed_value; g.phase="ATTACK"; g.possession=0; g.hitter=0; g.hitter_action="attack"; g.attack_tip=tip; g.armed=true; g.input_quality=1; g.charge=1.1
			var p=g.players[0]; p.position=Vector3(-3,0,1.3); p.rotation.y=PI; p.prepare_contact("attack",0); g.ball_pos=p.contact_world("attack")
			g.attack_ball()
			if g.phase=="LOOSE": faults+=1
			elif g.phase=="CPU_RECEIVE": valid+=1
		assert(valid>0 and faults>0,"110 percent must produce both playable shots and sampled errors")
	for rotation in 6:
		for direction in [-3.4,3.4]:
			g.rotations=[rotation,rotation]; g.reset_rally(); g.possession=1; g.phase="CPU_ATTACK"; g.flight_target=Vector3(direction,3.3,-1)
			var row: Array=g.manual_wall.line(g); var far_pin: int=row[0] if direction>0 else row[2]; var near_pin: int=row[2] if direction>0 else row[0]
			assert(g.manual_wall.waiting(g,far_pin).z>3 and g.manual_wall.waiting(g,near_pin).z<1)
			if direction>0: g.manual_wall.left_joined=true
			else: g.manual_wall.right_joined=true
			assert(g.manual_wall.waiting(g,far_pin).z<1,"An explicitly joined blocker remains available at the net")
	print("OVERCHARGE34 PASS: sampled spike/tip errors / playable excess shots / 12 mirrored far-wing reads / manual override / unchanged serve bar")
	quit()

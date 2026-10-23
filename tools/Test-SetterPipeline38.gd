extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	var failures:=0
	var cases:=0
	for case_index in 144:
		var serial: int=[29,41,42][case_index%3]+int(case_index/3)%6*6
		var team:=int(case_index/18)%2
		var fps:=60 if int(case_index/36)%2==0 else 120
		var quality:=0.67 if case_index<72 else 0.95
		game.rotations=[int(case_index/3)%6,int(case_index/3)%6]; game.server=team; game.reset_rally(); game.possession=team
		game.rng.seed=3800+serial; game.shot_serial=serial
		var positions: Array[Vector3]=[Vector3(0,0,6.2),Vector3(-3.3,0,4.5),Vector3(3.4,0,0.7),Vector3(-3.6,0,2.4),Vector3(1.6,0,1.2),Vector3(2.6,0,4.3)]
		for i in 6:
			var p=game.players[team*6+i]; p.position=positions[i]*(1 if team==0 else -1); p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO
			p.clip_name="idle"; p.looping=true; p.steering_ready=false; p.rotation.y=PI; p.motion_lock=0
			if team==1: p.rotation.y=0
		game.receiver=team*6; game.set_dir=0; game.ball_pos=game.players[game.receiver].contact_world("receive")
		game.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE"); game.armed=true; game.receive_offset=0.3 if quality<0.8 else 0.04; game.input_quality=quality; game.incoming_kind="spike"; game.incoming_power=0.65
		var before: int=game.test_contacts
		game.receive_ball()
		if game.phase not in ["SET","CPU_SET"]:
			failures+=1
			push_error("Expected a recoverable first pass in SET for case %d"%case_index)
			continue
		var trace: Array=[]
		var initial: Vector3=game.flight_target
		var physical_gap:=INF
		var max_step:=0.0
		for frame in fps*4:
			if game.phase not in ["SET","CPU_SET"]: break
			if frame==int(fps*0.4):
				var old_ball: Vector3=game.ball_pos; var old_velocity: Vector3=game.ball_vel
				game.set_dir=1
				if team==1: game.plan_attack(1,false)
				assert(game.ball_pos==old_ball and game.ball_vel==old_velocity,"Changing the hitter must retain the live physical pass")
			if frame==int(fps*0.5) and team==0: game.press_action("action")
			var previous: Vector3=game.players[game.setter].position
			game.step(1.0/fps)
			max_step=maxf(max_step,previous.distance_to(game.players[game.setter].position))
			for i in range(team*6,team*6+6):
				if i!=game.setter: physical_gap=minf(physical_gap,game.players[i].position.distance_to(game.players[game.setter].position))
			if frame%maxi(1,int(fps/10))==0: trace.append({"t":float(frame)/fps,"p":game.players[game.setter].position,"target":game.players[game.setter].target,"left":game.flight_left,"yields":game.court_shape.setter_yields.duplicate(),"system":game.out_of_system})
		var success: bool=game.test_contacts==before+2
		cases+=1
		if not success or physical_gap<0.975 or max_step>game.Reference.run_speed()*1.11/fps:
			failures+=1; print("PIPEFAIL38 case=",case_index," serial=",serial," team=",team," fps=",fps," quality=",quality," setter=",game.setter," initial=",initial," q=",game.pass_quality," gap=",physical_gap," maxstep=",max_step," trace=",trace)
	assert(cases==144,"The matrix must execute every reception-set case")
	print("PIPELINE38 ","PASS" if failures==0 else "FAIL",": ",cases," cases / all rotations / both teams / 60-120 Hz / medium-good passes / hitter changes / physical contact, spacing and movement; failures=",failures)
	game.free(); quit(1 if failures else 0)

extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	var failures:=0
	var cases:=0
	for team in 2:
		for fps in [60,120]:
			for target_x in [-1.7,-0.9,0.0,0.7]:
				game.rotations=[3,3]
				game.server=1-team
				game.reset_rally()
				game.possession=team
				game.incoming_kind="spike"
				game.setter=team*6+5
				game.receiver=team*6+4
				game.set_phase("SET" if team==0 else "CPU_SET")
				game.pass_quality=0.64
				game.input_quality=0.95
				game.out_of_system=1
				game.armed=true
				for i in range(team*6,team*6+6):
					game.players[i].position=game.Tactics.world(team,-4+(i%3)*4,7.5+(i%2))
					game.players[i].velocity=Vector3.ZERO
					game.players[i].acceleration=Vector3.ZERO
					game.players[i].steering_ready=false
				var setter=game.players[game.setter]
				setter.position=game.Tactics.world(team,3.3,0.7)
				setter.setting_yaw=-PI/2 if team==0 else PI/2
				setter.rotation.y=PI if team==0 else 0
				setter.play("block",1.15,false)
				setter.animation_time=setter.clips.block.contact_time+0.12
				game.block_jumps[game.setter]=game.attack_serial
				var passer=game.players[game.receiver]
				passer.position=game.Tactics.world(team,1.5,1.9)
				passer.play("receive",1,false)
				passer.animation_time=passer.clips.receive.contact_time
				game.players[team*6+1].position=game.Tactics.world(team,0.2,0.8)
				var point: Vector3=game.Tactics.world(team,target_x,1.8)
				point.y=game.contact_height("set")
				game.ball_pos=game.Tactics.world(team,1.5,1.9)+Vector3.UP*1.3
				var ordinary: float=game.Reference.receive_seconds(game.pass_quality)
				var seconds: float=load("res://src/setter_access.gd").pass_seconds(game,point,ordinary)
				assert(seconds<=ordinary+0.301)
				game.launch(point,seconds)
				game.plan_attack(0,false)
				game.armed=true
				var before: int=game.test_contacts
				var trace: Array=[]
				for frame in fps*2:
					if game.phase not in ["SET","CPU_SET"]: break
					game.step(1.0/fps)
					if frame%(fps/10)==0: trace.append([setter.position,setter.target,setter.velocity,passer.position])
				
				if game.test_contacts!=before+1:
					failures+=1
					print("CROWD FAILURE ",team,"/",fps,"/",target_x," final=",setter.position," target=",setter.stance_for_contact("set",point)," yields=",game.court_shape.setter_yields," trace=",trace)
				cases+=1
	assert(failures==0,"Reachable second balls in a crowded front court must make real contact")
	for team in 2:
		var fixture=load("res://tools/Test-RecoveryTraffic.gd").prepare_case(game,team)
		var shift: Vector3=fixture.stance+game.Tactics.world(team,0,0.4)-game.players[game.receiver].position
		game.players[game.receiver].position+=shift
		game.dive_motions[game.receiver].origin+=shift
		game.dive_motions[game.receiver].stance+=shift
		game.traffic_footprints.clear()
		var target: Vector3=load("res://src/setter_access.gd").clear_target(game,fixture.point)
		assert(target.distance_to(fixture.point)>0.1,"A pass cannot require the setter to stand inside a prone teammate")
		var stance: Vector3=game.players[game.setter].stance_for_contact("set",target)
		for sample in game.court_shape.recovering_bodies(game)[game.receiver]: assert(stance.distance_to(sample)>=1.119)
		var seconds: float=load("res://src/setter_access.gd").pass_seconds(game,target,fixture.seconds)
		game.launch(target,seconds)
		game.armed=true
		var before: int=game.test_contacts
		for frame in 240:
			if game.phase not in ["SET","CPU_SET"]: break
			game.step(1.0/120)
		assert(game.test_contacts==before+1,"The cleared pass must produce a real set, without displacing the recovering body")
		cases+=1
	print("SETTER CROWD PASS: ",cases," congested second touches / both teams / 60-120Hz / planned dig arc / landed block releases root")
	game.free()
	quit()

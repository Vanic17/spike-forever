extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.demo=false
	game.started=true
	var cases: Array=[]
	for team in 2:
		for fps in [60,120]:
			var fixture:=prepare_case(game,team)
			var setter=game.players[game.setter]
			var stance: Vector3=fixture.stance
			var receive_seconds: float=fixture.seconds
			var before: int=game.test_contacts
			var minimum:=INF
			var abrupt_stalls:=0
			var prior_speed:=0.0
			var trace: Array=[]
			for frame in int(ceil(fps*(receive_seconds+0.1))):
				if game.phase not in ["SET","CPU_SET"]: break
				var previous: Vector3=setter.position
				game.step(1.0/fps)
				for obstacle in game.footprint_points(game.receiver): minimum=minf(minimum,setter.position.distance_to(obstacle))
				if prior_speed>1.0 and setter.position.distance_to(previous)<0.002: abrupt_stalls+=1
				prior_speed=setter.velocity.length()
				if frame%(fps/10)==0: trace.append({"t":float(frame)/fps,"p":setter.position,"target":setter.target,"steering":setter.steering_target,"task":setter.intent.task,"defender":game.players[game.receiver].position,"v":setter.velocity.length(),"left":game.flight_left})
			var success: bool=game.phase in ["ATTACK","CPU_ATTACK"] and game.test_contacts==before+1
			cases.append({"team":team,"fps":fps,"set_contact":success,"phase":game.phase,"footprint_gap_m":minimum,"abrupt_stalls":abrupt_stalls,"final_stance_error_m":setter.position.distance_to(stance),"trace":trace})
	var output=FileAccess.open("res://docs/recovery-traffic-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(cases,"  "))
	for result in cases:
		print("RECOVERY TRAFFIC CASE ",result.team,"/",result.fps,"Hz contact=",result.set_contact," gap=",result.footprint_gap_m," stalls=",result.abrupt_stalls," stance_error=",result.final_stance_error_m)
		assert(result.set_contact,"A prone teammate must not prevent a reachable, already scheduled second touch")
		assert(result.footprint_gap_m>=0.978,"The setter must clear the torso and legs, not only the defender's root")
		assert(result.abrupt_stalls==0,"The setter must anticipate the recovery body instead of stopping against it")
		assert(result.final_stance_error_m<0.18,"The recovery bypass must finish within the original contact deadline")
	test_extended_volume_sweep(game)
	print("RECOVERY TRAFFIC PASS: 4 real set contacts / original flight deadline / both teams at 60-120Hz / no hard stalls / extended moving volume protected")
	game.queue_free()
	quit()

func test_extended_volume_sweep(game) -> void:
	for team in 2:
		prepare_case(game,team)
		game.traffic_footprints.clear()
		var defender=game.players[game.receiver]
		defender.position=game.Tactics.world(team,0,5)
		game.players[game.setter].position=game.Tactics.world(team,-1.2,4.1)
		# The mover's root has ample room, but his extended torso would hit
		# the standing setter if collision sweeps only considered that root.
		var request: Vector3=game.Tactics.world(team,-0.4,0)
		var step: Vector3=game.collision_safe_step(game.receiver,request)
		assert(step.length()>0.15 and step.length()<0.23,"Moving recovery volume must stop before its torso hits a teammate")
		for origin in game.compute_footprint_points(game.receiver):
			for obstacle in game.compute_footprint_points(game.setter):
				assert((origin+step).distance_to(obstacle)>=0.978,"Every swept recovery footprint must preserve body clearance")

static func prepare_case(game, team: int) -> Dictionary:
	game.rotations=[0,0]
	game.server=1-team
	game.reset_rally()
	game.possession=team
	game.set_phase("SET" if team==0 else "CPU_SET")
	game.setter=team*6+5
	game.receiver=team*6+4
	game.pass_quality=0.65
	game.input_quality=0.95
	game.out_of_system=1
	game.armed=true
	game.fast_set=false
	for i in range(team*6,team*6+6):
		game.players[i].position=game.Tactics.world(team,-4+(i%3)*4,7.5+(i%2))
		game.players[i].velocity=Vector3.ZERO
		game.players[i].acceleration=Vector3.ZERO
		game.players[i].steering_ready=false
	var setter=game.players[game.setter]
	setter.setting_yaw=-PI/2 if team==0 else PI/2
	setter.rotation.y=setter.setting_yaw
	setter.position=game.Tactics.world(team,-2.5,3.0)
	var stance: Vector3=game.Tactics.world(team,0,3.0)
	var point: Vector3=stance+Basis(Vector3.UP,setter.setting_yaw)*setter.contact_local("set")
	var defender=game.players[game.receiver]
	defender.rotation.y=PI if team==0 else 0.0
	defender.dive_yaw=defender.rotation.y
	defender.position=game.Tactics.world(team,-1.0,4.45)
	var clip=defender.clips.dive
	var source_start: float=clip.contact_time+0.12
	defender.play("dive",1.15,false)
	defender.animation_time=source_start
	var source_contact: Vector3=defender.position+Basis(Vector3.UP,defender.rotation.y)*(defender.action_root_motion("dive",clip.contact_time)-defender.action_root_motion("dive",source_start))
	game.dive_motions[game.receiver]={"origin":defender.position,"stance":source_contact,"start_time":source_start,"source_time":source_start,"duration":0.001,"elapsed":0.0,"yaw":defender.rotation.y,"initial_yaw":defender.rotation.y,"action":"dive"}
	var minimum_root_route: float=defender.position.distance_to(Geometry3D.get_closest_point_to_segment(defender.position,setter.position,stance))
	assert(minimum_root_route>1.35,"Fixture must hide the threat from root-only avoidance")
	var footprint_intrudes:=false
	for obstacle in game.footprint_points(game.receiver):
		if obstacle.distance_to(Geometry3D.get_closest_point_to_segment(obstacle,setter.position,stance))<0.98: footprint_intrudes=true
		assert(obstacle.distance_to(stance)>0.98,"Final contact stance must remain free")
	assert(footprint_intrudes,"The prone torso must obstruct the approach, not its contact destination")
	game.ball_pos=point+Vector3(-0.3,0.9,0.7)
	var seconds: float=game.Reference.receive_seconds(game.pass_quality,false)
	game.launch(point,seconds)
	game.plan_attack(0,false)
	game.armed=true
	return {"stance":setter.stance_for_contact("set",point),"point":point,"seconds":seconds}

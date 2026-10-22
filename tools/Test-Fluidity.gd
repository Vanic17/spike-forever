extends SceneTree
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.demo=false
	var deceleration: Array=[]
	for fps in [30,60,120]:
		game.reset_rally()
		game.set_phase("LOOSE")
		for i in 12:
			var p=game.players[i]
			p.position=Vector3(-3.5+3.5*(i%3),0,(1.0+3.0*(i%6)/3)*(1 if i<6 else -1))
			p.target=p.position
			p.velocity=Vector3.ZERO
			p.acceleration=Vector3.ZERO
			p.steering_ready=false
		var runner=game.players[3]
		runner.position=Vector3(-3,0,8)
		runner.target=Vector3(3,0,8)
		runner.velocity=Vector3(5,0,0)
		var before: Vector3=runner.velocity
		game.clock_time+=1.0/fps
		game.move_players(1.0/fps)
		var change: float=before.distance_to(runner.velocity)
		assert(change<14.0/fps,"Changing from an urgent run to coverage must brake, not clamp existing speed in one frame")
		assert(runner.velocity.length()<=before.length()+0.00001,"A lower speed request cannot accelerate past existing momentum")
		deceleration.append({"fps":fps,"first_tick_velocity_change_m_s":change})
	# Execute actual match movement through a complete preparation window.
	# No action may sit on frame zero waiting for the scheduled ball event.
	var frozen:=0
	var prepared:=0
	for action in ["receive","set","fast_set","attack"]:
		game.reset_rally()
		game.set_phase("ATTACK" if action=="attack" else ("RECEIVE" if action=="receive" else "SET"))
		game.possession=0
		game.receiver=3
		game.setter=3
		game.hitter=3
		game.planned_hitter=0
		game.fast_set=action=="fast_set"
		game.hitter_action="attack"
		game.pass_quality=0.4
		game.flight_target=Vector3(-3,game.players[3].contact_local(action).y,5)
		var p=game.players[3]
		p.position=p.stance_for_contact(action,game.flight_target)
		for frame in 89:
			game.flight_left=(90-frame)/120.0
			game.phase_time=frame/120.0
			game.clock_time+=1.0/120.0
			game.move_players(1.0/120.0)
			if p.clip_name==action and not p.looping:
				prepared+=1
				if p.animation_time<=0.000001: frozen+=1
			for player in game.players: player.tick(1.0/120.0,false,false)
	assert(prepared>100 and frozen==0,"Actual action preparation must progress on every scheduled frame")
	var athlete=game.players[3]
	athlete.rotation.y=0
	var gaits: Array=[]
	for direction in [-1.0,1.0]:
		athlete.velocity=Vector3(direction*4,0,0)
		var gait: String=athlete.choose_gait(4,"run")
		assert(gait.begins_with("cross_"),"Fast lateral closures need real crossing steps")
		assert(athlete.clips[gait].root_motion(athlete.clips[gait].duration).dot(athlete.velocity)>0,"Crossing animation must move in the actual direction")
		athlete.velocity=Vector3(direction*1.4,0,0)
		assert(athlete.choose_gait(1.4,gait).begins_with("shuffle_"),"Small lateral adjustments must return to side steps")
		gaits.append(gait)
	athlete.prepare_contact("receive",0)
	athlete.motion_lock=0.12
	assert(athlete.recovery_speed_scale()==1.0,"A grounded pass must not impose an artificial post-touch movement pause")
	var report={"deceleration":deceleration,"preparation_frames":prepared,"frozen_preparation_frames":frozen,"crossing_gaits":gaits,"grounded_pass_free_to_cover":true}
	var output=FileAccess.open("res://docs/fluidity-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("FLUIDITY PASS: actual contact preparation / no frozen opening / gradual speed handoff at 30-60-120Hz / crossing steps and short adjustments / pass follow-through")
	game.queue_free()
	quit()

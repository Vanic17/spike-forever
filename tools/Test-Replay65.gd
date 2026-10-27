extends SceneTree
func _initialize(): call_deferred("run")
func fingerprint(g) -> Array:
	return [g.clock_time,g.phase_time,g.phase,g.ball_pos,g.ball_vel,g.flight_spin,g.rng.state,g.scores.duplicate(),g.sets.duplicate(),g.rotations.duplicate(),g.touches.duplicate(),g.test_contacts,g.attack_serial,g.shot_serial,g.players.map(func(p): return [p.transform,p.animation_time,p.clip_name,p.velocity,p.last_pose.duplicate(),p.foot_anchors.duplicate(),p.foot_planted.duplicate()])]
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var replay=g.replay; replay.set_process(false); replay.testing=true
	for p in g.players: p.apply_pose(0)
	var initial: int=g.players.size()
	for i in 90:
		g.clock_time=i/30.0; g.ball_pos=Vector3(sin(i*.1),2.0+sin(i*.05),3-i*.06)
		for p in g.players:
			p.animation_time+=.01; p.position.x+=.002; p.apply_pose(0)
		replay.capture(true)
	assert(replay.frames.size()==90 and g.players.size()==initial)
	var before:=fingerprint(g); var camera: Transform3D=g.camera.transform; var mode: int=g.camera_mode; var visual_ball: Transform3D=g.ball.transform
	assert(replay.begin())
	g.step(.1); assert(fingerprint(g)==before,"Replay must freeze simulation, RNG and contacts")
	replay.advance(.91); replay.advance(.15)
	assert(replay.state=="PLAY")
	assert(g.camera.position==preload("res://src/view_controls.gd").origin(2),"Playback camera must be lateral independently of the live mode")
	assert(g.camera_mode==mode)
	assert(g.ball.transform!=visual_ball)
	assert(g.scores==before[7] and g.rng.state==before[6])
	replay.begin_exit(); replay.advance(.91)
	assert(not replay.active and g.camera.transform==camera and g.ball.transform==visual_ball)
	assert(fingerprint(g)==before,"Every simulated field and avatar state must be restored exactly")
	for i in 12:
		var p=g.players[i]; var body=p.model_bank.body
		for bone in body.names.size():
			var idx: int=p.animation_bones[bone]; var expected: Transform3D=p.last_pose[idx]
			if bone>0: expected=p.last_pose[p.animation_bones[body.parents[bone]]].affine_inverse()*expected
			assert(p.skeleton.get_bone_pose(bone).origin.distance_to(expected.origin)<.0001)
	# Trigger selection: winning perfect attack / ace / monster only.
	for trial in [{"kind":"serve","perfect":false,"winner":0,"expect":true},{"kind":"attack","perfect":true,"winner":0,"expect":true},{"kind":"monster","perfect":false,"winner":0,"expect":true},{"kind":"attack","perfect":false,"winner":0,"expect":false},{"kind":"serve","perfect":false,"winner":1,"expect":false},{"kind":"other","perfect":true,"winner":0,"expect":false}]:
		replay.reset(); replay.frames=[{"time":0},{"time":.1},{"time":.2}]
		replay.candidate={"kind":trial.kind,"perfect":trial.perfect,"team":0}; replay.on_point(trial.winner)
		assert((not replay.pending.is_empty())==trial.expect)
	replay.reset()
	for i in 550:
		g.clock_time=10+i/30.0; replay.capture(true)
	assert(replay.frames.size()==replay.MAX_FRAMES)
	var report={"poses_recorded":replay.frames.size(),"extra_players":g.players.size()-initial,"state_rng_and_pose_restore":true,"lateral_camera":true,"six_trigger_cases":true,"mean_capture_usec":float(replay.capture_usec)/maxi(1,replay.captures)}
	FileAccess.open("res://docs/replay65-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("REPLAY65 PASS ",JSON.stringify(report)); g.free(); quit()

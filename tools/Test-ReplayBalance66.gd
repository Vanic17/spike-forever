extends SceneTree
const Old=preload("res://docs/baseline-v65/block_response.gd")
const New=preload("res://src/block_response.gd")
const Stats=preload("res://src/player_stats_gameplay.gd")
const Flight=preload("res://src/ball_flight.gd")
const Contact=preload("res://src/block_contact.gd")
const TRIALS=20000
func _initialize(): call_deferred("run")
func tally() -> Dictionary: return {"stuff_block":0,"block_touch":0,"block_tool":0}
func state(g) -> Array:
	return [g.clock_time,g.phase_time,g.phase,g.ball_pos,g.ball_vel,g.rng.state,g.scores.duplicate(),g.sets.duplicate(),g.rotations.duplicate(),g.test_contacts,g.players.map(func(p): return [p.transform,p.animation_time,p.clip_name,p.velocity,p.last_pose.duplicate()])]
func run():
	var rng:=RandomNumberGenerator.new(); rng.seed=66081
	var before:=tally(); var after:=tally(); var conversions:=0
	for sample in TRIALS:
		var defender:=sample%2; var side:=1.0 if defender==0 else -1.0
		var incoming:=Vector3(rng.randf_range(-9,9),rng.randf_range(-8,1),side*rng.randf_range(18,38))
		var strength:=rng.randf_range(.35,1); var quality:=rng.randf_range(.50,1); var edge:=rng.randf_range(-1.2,1.2)
		var variation:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1))
		var a: Dictionary=Old.solve(incoming,defender,strength,quality,edge,variation)
		var b: Dictionary=New.solve(incoming,defender,strength,quality,edge,variation)
		before[a.kind]+=1; after[b.kind]+=1
		assert(b.velocity.is_finite() and b.velocity.length()<incoming.length()*2+5)
		if a.kind=="stuff_block" and b.kind!="stuff_block":
			conversions+=1; assert(b.kind=="block_touch","Reduced monsters must become playable block touches, not extra forced tools")
		elif a.kind!="stuff_block": assert(a==b,"Other contact classes and physics remain identical")
	assert(after.stuff_block<before.stuff_block*.8 and after.stuff_block>before.stuff_block*.35)
	assert(after.block_tool==before.block_tool and before.stuff_block-after.stuff_block==conversions)
	var drop: float=100.0*(1-float(after.stuff_block)/before.stuff_block)
	# A strong sealed press retains its physical downward winner on both sides.
	for defender in 2:
		var outward: float=-1 if defender==0 else 1
		var result: Dictionary=New.solve(Vector3(.7,-4,-outward*30),defender,1,1,0,Vector3.ZERO)
		assert(result.kind=="stuff_block" and result.velocity.y<=-8.5)
		var ball:=Vector3(0,3.2,-outward*.15)
		var velocity: Vector3=Contact.pressed_velocity(result.velocity,ball,defender)
		for frame in 240:
			var next:=Flight.advance(ball,velocity,Vector3.ZERO,1.0/120)
			ball=next[0]; velocity=next[1]
			if ball.y<=.105: break
		assert(ball.z*outward>0 and absf(ball.x)<4.6 and absf(ball.z)<9.1)
	var original_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/baseline-v65/player_stats_v1.json"))
	var stats_checks: Array=[]
	for row in Stats.settings().block_stuff:
		var old_value:=0.0
		for previous in original_config.block_stuff:
			if float(previous[0])==float(row[0]): old_value=float(previous[1]); break
		assert(absf(float(row[1])-old_value*.8)<=.0051)
		stats_checks.append({"stat":row[0],"before":old_value,"after":row[1]})
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var replay=g.replay; replay.set_process(false); replay.testing=true
	for p in g.players: p.apply_pose(0)
	g.phase="ATTACK"; g.phase_time=0; g.clock_time=0
	for frame in 61:
		g.clock_time=float(frame)/30; g.ball_pos=Vector3(0,3-float(frame)*.03,1-float(frame)*.1); replay.capture(true)
	var impact: float=g.clock_time
	replay.mark_shot("attack",0,true); g.award(0,"REPLAY66 PHYSICAL TAIL")
	for frame in 160:
		g.step(1.0/120)
		if frame%4==0:
			for p in g.players: p.apply_pose(1.0/30)
		replay.advance(1.0/120)
		if replay.active: break
	assert(replay.active and replay.state=="IN")
	var tail: float=float(replay.clip[-1].time)-impact
	assert(tail>=.95 and tail<=replay.POINT_TAIL_SECONDS+.015,"A real extra second after impact must be recorded")
	var extra_visible: float=(tail-.16)/.8
	assert(extra_visible>.95 and extra_visible<1.1)
	var snapshot:=state(g); var camera: Transform3D=g.camera.transform
	g.step(.2); assert(state(g)==snapshot)
	assert(replay.TRANSITION_SECONDS>.9)
	var old_zoom_seconds: float=.9*(1-.72)
	var zoom_seconds: float=replay.TRANSITION_SECONDS*(1-.68)
	assert(zoom_seconds>old_zoom_seconds*1.25,"The final enlargement itself must slow down, not only its introduction")
	replay.advance(replay.TRANSITION_SECONDS+.01); assert(replay.state=="PLAY")
	assert(g.camera.position==preload("res://src/view_controls.gd").origin(2))
	replay.advance(.12); replay.begin_exit(); replay.advance(replay.TRANSITION_SECONDS+.01)
	assert(not replay.active and state(g)==snapshot and g.camera.transform==camera)
	var report={"contact_samples":TRIALS,"old_contacts":before,"new_contacts":after,"monster_relative_drop_pct":drop,"monsters_converted_to_playable_touches":conversions,"tools_unchanged":true,"sealed_monsters_still_score":true,"stats_curve":stats_checks,"recorded_post_point_seconds":tail,"extra_visible_replay_seconds":extra_visible,"transition_seconds":replay.TRANSITION_SECONDS,"old_zoom_seconds":old_zoom_seconds,"new_zoom_seconds":zoom_seconds,"physics_and_camera_restore":true}
	FileAccess.open("res://docs/replay66-balance-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("REPLAY BALANCE66 PASS matched contacts=",TRIALS," monsterdrop=",drop,"% tail=",tail,"s extra-visible=",extra_visible,"s zoom=",zoom_seconds,"s restore=true")
	g.free(); quit()

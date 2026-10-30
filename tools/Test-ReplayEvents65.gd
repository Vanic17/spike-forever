extends SceneTree
func _initialize(): call_deferred("run")
func simulate(g,limit: int):
	for frame in limit:
		g.step(1.0/120)
		if frame%4==0:
			for p in g.players: p.apply_pose(1.0/30)
			g.replay.capture(true)
		if g.phase=="POINT": return
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	g.replay.set_process(false); g.replay.testing=true
	var rows: Array=[]
	for floating in [false,true]:
		g.clock_time=0; g.server=0; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=65013
		g.press_action("alternate" if floating else "action"); g.charge_start=g.clock_time-g.charge_seconds("serve"); g.release_action()
		simulate(g,1200)
		assert(g.phase=="POINT" and g.scores[0]>0 and g.replay.pending.kind=="serve","Actual perfect service must generate an ace replay")
		var end_time: float=g.clock_time; g.replay.advance(g.replay.POINT_TAIL_SECONDS+.09); assert(g.replay.active)
		var length: float=float(g.replay.clip[-1].time)-float(g.replay.clip[0].time)
		assert(length<3.5 and float(g.replay.clip[0].time)>=g.replay.segment_start-.04)
		g.replay.advance(g.replay.TRANSITION_SECONDS+.01); g.replay.request_skip(); g.replay.advance(g.replay.TRANSITION_SECONDS+.01)
		assert(not g.replay.active and g.clock_time==end_time)
		rows.append({"kind":"float_ace" if floating else "jump_ace","clip_seconds":length,"score":g.scores.duplicate()})
	g.server=1; g.reset_rally(); g.possession=0; g.hitter=0; g.setter=5; g.out_of_system=1
	g.phase="ATTACK"; g.armed=true; g.charge=1; g.input_quality=1; g.hitter_action="attack"; g.replay.mark_set()
	g.ball_pos=g.Tactics.world(0,-3.4,1.05); g.ball_pos.y=g.players[0].contact_local("attack").y
	var p=g.players[0]; p.rotation.y=PI; p.position=p.stance_for_contact("attack",g.ball_pos); p.blend_left=0; p.prepare_contact("attack",0); p.apply_pose(0)
	for i in 3: g.clock_time+=.034; g.replay.capture(true)
	g.attack_ball(); simulate(g,1200)
	assert(g.phase=="POINT" and g.replay.pending.kind=="attack","Actual perfect spike must generate its replay")
	rows.append({"kind":"perfect_attack","score":g.scores.duplicate()})
	# Blocked perfect attacks still replay if the blocker deflects out.
	g.replay.reset(); g.replay.frames=[{"time":0},{"time":.1},{"time":.2}]
	g.replay.candidate={"kind":"monster","team":1,"perfect":false,"start":0}
	g.replay.last_attack={"kind":"attack","team":0,"perfect":true,"start":0}; g.replay.on_point(0)
	assert(g.replay.pending.kind=="attack")
	FileAccess.open("res://docs/replay66-events.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("REPLAY EVENTS66 PASS physical jump/float aces and perfect spike / short decisive clips / blocked-out fallback")
	g.free(); quit()

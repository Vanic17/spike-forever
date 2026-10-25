extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var cases: Array=[]; var accepted:=0
	for serial in 12:
		g.rotations=[0,0]; g.server=1; g.reset_rally(); g.possession=0; g.receiver=4; g.shot_serial=serial; g.incoming_kind="spike"
		g.players[4].position=Vector3(0,0,5.9); g.players[4].rotation.y=PI; g.players[4].blend_left=0
		g.phase="RECEIVE"; g.airborne=true; g.ball_pos=Vector3(0,2.5,5); g.ball_vel=Vector3(0,-3,0); g.flight_spin=Vector3.ZERO
		g.armed=true; g.input_quality=.8; g.receive_deadline=g.clock_time+.3
		var planned: bool=g.queue_recovery(true)
		if not planned: continue
		accepted+=1
		var initial: Dictionary=g.dive_motions[4].duplicate(); var last: float=-1; var rewind:=0.0; var before: int=g.test_contacts
		for frame in 90:
			if g.phase!="RECEIVE" or g.test_contacts>before: break
			g.step(1.0/120)
			if g.dive_motions.has(4) and g.dive_motions[4].get("committed",true):
				var time: float=g.players[4].animation_time
				if last>=0: rewind=maxf(rewind,last-time)
				last=time
			for p in g.players: p.apply_pose(1.0/120)
		assert(rewind<.025,"Dive must not finish early and rewind at ball contact")
		cases.append({"serial":serial,"variant":g.players[4].variant_names.get("dive","dive"),"start_time":initial.start_time,"seconds":initial.duration,"rewind":rewind,"contact":g.test_contacts>before})
	assert(accepted>=3)
	FileAccess.open("res://docs/dive-clock56-report.json",FileAccess.WRITE).store_string(JSON.stringify(cases,"  "))
	print("DIVE CLOCK56 PASS ",accepted," source clocks / actual hand heights / no contact rewind")
	g.free(); quit()

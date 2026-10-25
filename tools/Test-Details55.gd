extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var count:=0
	for rotation in 6:
		g.rotations=[rotation,rotation]; g.server=1; g.reset_rally(); g.possession=0
		for setter in 6:
			var index: int=g.Tactics.attacker_for(g,0,2,setter)
			assert(index>=0 and index!=setter)
			assert(g.Tactics.ROLES[index%6] in ["OH1","OH2","OPP"],"Back set must not silently become a middle quick")
			count+=1
	g.possession=0; g.rotations=[0,0]; g.setter=5; g.planned_direction=3; g.planned_hitter=3; g.phase="SET"; g.fast_set=false
	var targets: Array[Vector3]=[]
	for p in g.players: targets.append(p.position)
	g.players[3].position=Vector3(0,0,6.2); g.players[0].position=Vector3(0,0,4.7)
	g.flight_target=Vector3(1.2,2.6,1.8)
	var setter_target: Vector3=targets[5]
	g.attack_run.prepare_pipe(g,targets)
	assert(targets[5]==setter_target,"Pipe preparation must preserve second-touch priority")
	assert(g.attack_run.yielding.has(0),"Pipe support must yield BEFORE the set is released")
	for mode in 4:
		g.camera_mode=mode; g.set_camera()
		assert(g.camera.position==load("res://src/view_controls.gd").origin(mode))
	g.camera_mode=3; g.online_session.playing=true
	for side in 2:
		g.online_session.local_side=side; g.set_camera()
		assert(g.camera_mode==3 and absf(g.camera.position.y-8.1)<.01)
		assert(signf(g.camera.position.z)==(1 if side==0 else -1))
	g.online_session.playing=false
	var old=load("res://docs/baseline-v54/block_response.gd"); var current=load("res://src/block_response.gd")
	var before: Dictionary={}; var after: Dictionary={}; var random=RandomNumberGenerator.new(); random.seed=52101
	for i in 10000:
		var incoming:=Vector3(random.randf_range(-9,9),random.randf_range(-8,1),random.randf_range(18,38))
		var strength:=random.randf_range(.18,1); var quality:=random.randf_range(.6,1); var edge:=random.randf_range(-1.25,1.25)
		var variation:=Vector3(random.randf_range(-1,1),random.randf_range(-1,1),random.randf_range(-1,1))
		var a: Dictionary=old.solve(incoming,0,strength,quality,edge,variation); var b: Dictionary=current.solve(incoming,0,strength,quality,edge,variation)
		before[a.kind]=before.get(a.kind,0)+1; after[b.kind]=after.get(b.kind,0)+1
	assert(after.block_tool<before.block_tool and after.block_touch>before.block_touch and after.stuff_block>=before.stuff_block)
	FileAccess.open("res://docs/details55-report.json",FileAccess.WRITE).store_string(JSON.stringify({"back_set_recipients":count,"block_before":before,"block_after":after,"early_pipe_yield":true,"four_cameras":true,"mirrored_online_low_camera":true},"  "))
	print("DETAILS55 PASS recipients=",count," block=",before," -> ",after,"; pipe / cameras / mirrored online")
	g.free(); quit()

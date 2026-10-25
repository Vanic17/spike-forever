extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.gui_disable_input=true; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	for node in g.get_children():
		if node.get_script()==preload("res://src/start_menu.gd"): node.hide()
	g.hud.hide(); g.marker.hide(); g.camera.position=Vector3(3.2,3.4,10); g.camera.look_at(Vector3(-2,1,4.5)); g.camera.fov=37
	g.server=1; g.rotations=[0,0]; g.reset_rally(); g.possession=0; g.rng.seed=56001
	for i in 12: g.players[i].visible=i in [0,4]; g.players[i].render_at_draw=false
	for i in 6: g.players[i].position=Vector3(3.8,0,8-float(i)*.8)
	g.players[0].position=Vector3(-2,0,3.5); g.players[4].position=Vector3(-2.7,0,5.1)
	g.ball_pos=Vector3(-2,1.15,4); g.touches=[1,0]; g.set_dir=0
	load("res://src/scramble_recovery.gd").start(g,0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/recovery56-frames"))
	var count: int=g.test_contacts; var hit:=false
	for frame in 180:
		if not hit:
			g.armed=true; g.input_quality=.8; g.step(1.0/60)
			if g.test_contacts>count: hit=true
		elif g.dive_motions.has(4): g.advance_dive_body(4,1.0/60); g.players[4].tick(1.0/60,false,false)
		for p in g.players: p.apply_pose(1.0/60)
		g.ball.position=g.ball_pos
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/recovery56-frames/%03d.png"%frame)
	assert(hit); print("RECOVERY56 CAPTURE PASS"); g.free(); quit()

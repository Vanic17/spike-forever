extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("review103" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,960);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	for child in g.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	await process_frame
	var benches=g.arena_visuals.get_node("TeamBenches")
	for entry in benches.actors:
		if not entry.coach or entry.team!=0:entry.actor.hide()
	var actor=benches.actors[8].actor
	g.camera.position=actor.position+Vector3(3.5,1.9,3.6);g.camera.look_at(actor.position+Vector3(0,1.05,0));g.camera.fov=29
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/review103-coach.png")
	print("CAPTURE103 PASS");quit()

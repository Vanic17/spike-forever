extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.gui_disable_input=true; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	for node in g.get_children():
		if node.get_script()==preload("res://src/start_menu.gd"): node.hide()
	g.hud.hide(); g.marker.hide(); g.phase="RECEIVE"
	for mode in [0,3]:
		g.camera_mode=mode; g.set_camera()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/camera55-%d.png"%mode)
	print("CAMERA55 CAPTURE PASS"); g.free(); quit()

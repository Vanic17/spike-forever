extends SceneTree
func _initialize(): call_deferred("run")
func shot(name: String):
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/tutorial60-"+name+".png")
func run():
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,810); root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_physics_process(false)
	var menu
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	menu.tutorial_button.grab_focus(); await shot("home")
	g.tutorial.open(menu); g.tutorial.categories[2].grab_focus(); await shot("menu")
	g.tutorial.start_lesson("set",7); await shot("intro")
	g.tutorial.resume(); g.tutorial.coach.show(); await shot("coaching")
	print("TUTORIAL60 CAPTURE PASS"); quit()

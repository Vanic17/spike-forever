extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,720); root.content_scale_size=root.size
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	menu.clubs.match_setup()
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/match-menu49.png")
	print("MATCH MENU49 CAPTURE PASS"); quit()

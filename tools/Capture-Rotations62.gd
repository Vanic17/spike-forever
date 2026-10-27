extends SceneTree
func _initialize(): call_deferred("run")
func run():
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(960,640); root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.hide()
	g.hud.hide(); g.marker.hide()
	var overlay:=CanvasLayer.new(); root.add_child(overlay)
	var title:=Label.new(); title.position=Vector2(22,12); title.add_theme_font_size_override("font_size",26); overlay.add_child(title)
	var sheet:=Image.create(2880,1280,false,Image.FORMAT_RGBA8)
	for rotation in 6:
		g.rotations=[rotation,rotation]; g.server=1; g.reset_rally()
		g.camera.position=Vector3(0,12,17.5); g.camera.look_at(Vector3(0,.5,0)); g.camera.fov=55
		title.text=g.Tactics.Layout.label(rotation)+"  ·  RICEZIONE / RECEIVE"
		for frame in 5:
			g.move_players(.01)
			for p in g.players: p.tick(.01,false,false); p.apply_pose(0)
			await process_frame
		await RenderingServer.frame_post_draw
		var shot:=root.get_texture().get_image(); shot.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(shot,Rect2i(0,0,960,640),Vector2i(rotation%3*960,rotation/3*640))
	sheet.save_png("res://docs/rotations62-receive.png")
	print("ROTATIONS62 CAPTURE PASS six source layouts")
	g.free(); quit()

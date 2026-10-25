extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.gui_disable_input=true; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,900)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.hud.hide(); g.marker.hide()
	for node in g.get_children():
		if node.get_script()==preload("res://src/start_menu.gd"): node.hide()
	g.camera.position=Vector3(4,3.4,7); g.camera.look_at(Vector3(0,1.7,1.8)); g.camera.fov=38
	for i in 12: g.players[i].visible=i==5; g.players[i].render_at_draw=false
	var p=g.players[5]; p.position=Vector3(0,0,1.8); p.rotation.y=PI; p.left_handed=false; p.select_variant("dump","dump_push54"); p.blend_left=0
	var contact: float=p.clips.dump.contact_time
	var frames:=PackedFloat32Array([contact-.32,contact-.10,contact,contact+.13,contact+.32])
	for i in frames.size():
		p.play("dump",1.15,false); p.animation_time=frames[i]; p.blend_left=0; p.reach_weight=0; p.apply_pose(0)
		g.ball.position=p.current_hand(true)+Vector3(0,0,.08)
		if i>2: g.ball.position+=Vector3(0,-.2*(i-2),-.5*(i-2))
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/dump54-%d.png"%i)
	print("DUMP54 CAPTURE PASS"); g.free(); quit()

extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("middle102" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,960);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	for child in g.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	for p in g.players:p.hide();p.set_process(false);p.render_at_draw=false
	g.marker.hide();g.shadow.hide()
	var p=g.players[5];p.show();p.position=Vector3(0,0,2);p.rotation.y=-PI/2;p.setting_yaw=-PI/2;p.left_handed=false;p.select_variant("set","set_first96");p.play("set",1,false);p.blend_left=0;p.reach_weight=0
	g.camera.position=p.position+Vector3(-3.2,2.5,4.2);g.camera.look_at(p.position+Vector3(0,1.8,0));g.camera.fov=38
	var layer:=CanvasLayer.new();root.add_child(layer);var label:=Label.new();label.text="PRIMO TEMPO / ALZATA A UNA MANO";label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",26);layer.add_child(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/middle102/preview"))
	var clip=p.clips.set;var contact: Vector3=p.contact_world("set")
	for frame in 48:
		var t: float=clip.contact_time-.40+frame/45.0;p.animation_time=maxf(0,t);p.apply_pose(0)
		if t<clip.contact_time:g.ball_pos=contact+Vector3(0,(clip.contact_time-t)*3.5,0)
		else:g.ball_pos=contact+Vector3(-4.5,1.1,-.2)*(t-clip.contact_time)+Vector3.DOWN*4.905*pow(t-clip.contact_time,2)
		g.ball.position=g.ball_pos
		await process_frame;await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image();img.save_png("res://.runtime/middle102/preview/%04d.png"%frame)
		if frame==18:img.save_png("res://docs/middle102-onehand-contact.png")
	print("CAPTURE102 PASS frames=48");quit()

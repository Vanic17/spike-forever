extends SceneTree
const Second=preload("res://src/setter_second96.gd")
func _initialize():call_deferred("run")
func run():
	assert("strikes96" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,960);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	for child in g.get_children():
		if child is CanvasLayer:child.hide()
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	for p in g.players:p.hide();p.set_process(false);p.render_at_draw=false
	g.marker.hide();g.shadow.hide();g.ball.show()
	var layer:=CanvasLayer.new();root.add_child(layer);var label:=Label.new();label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",25);layer.add_child(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/seconds98/preview"))
	var p=g.players[5];p.show();p.left_handed=false;p.height_scale90=1;p.position=Vector3(0,0,.8);p.setting_yaw=-PI/2;p.rotation.y=p.setting_yaw
	g.camera.position=p.position+Vector3(3.4,2.5,5.8);g.camera.look_at(p.position+Vector3(0,1.75,0));g.camera.fov=41
	var index:=0
	for kind in [3,2,7]:
		var name: String={3:"dump_down96",2:"dump_back96",7:"dump_forward96"}[kind]
		p.play("idle",1,true);p.select_variant("dump",name);p.play("dump",1,false);p.blend_left=0
		var clip=p.clips.dump;p.second_contact97=clip.contact_offset-Vector3(0,.12,0)
		var contact: Vector3=p.contact_world("dump")
		g.setter=5;g.possession=0;g.setter_second96=kind;g.ball_pos=contact
		var shot:=Second.trajectory(g)
		var incoming: Vector3=contact+Vector3(.10,1.4,.35)
		var in_velocity: Vector3=g.BallFlight.velocity_to(incoming,contact,.40,Vector3.ZERO)
		var out_velocity: Vector3=g.BallFlight.velocity_to(contact,shot.target,shot.seconds,shot.spin)
		label.text="STUDIO / SECONDA %d / %s / PARALLELO ALLA RETE"%[kind,"SINISTRA" if kind==3 else "DESTRA"]
		for frame in 49:
			var time: float=-.4+frame/45.0
			p.animation_time=clip.contact_time+time*1.15;p.reach_action="dump";p.reach_target=contact;p.reach_weight=smoothstep(-.22,-.04,time)
			p.apply_pose(0)
			g.ball.position=g.BallFlight.advance(incoming,in_velocity,Vector3.ZERO,maxf(0,time+.4))[0] if time<0 else g.BallFlight.advance(contact,out_velocity,shot.spin,time)[0]
			await process_frame;await RenderingServer.frame_post_draw
			var picture:=root.get_texture().get_image();picture.save_png("res://.runtime/seconds98/preview/%04d.png"%index);index+=1
			if frame==18:picture.save_png("res://docs/setter98-%d-contact.png"%kind)
	print("CAPTURE98 PASS frames=",index);quit()

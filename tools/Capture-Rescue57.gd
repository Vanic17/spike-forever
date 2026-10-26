extends SceneTree
const Rescue=preload("res://src/contact_rescue.gd")
func _initialize(): call_deferred("run")
func run():
	root.gui_disable_input=true; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720)
	AudioServer.set_bus_mute(0,true)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	for node in g.get_children():
		if node.get_script()==preload("res://src/start_menu.gd"): node.hide()
	g.hud.hide(); g.marker.hide(); g.camera.fov=37
	var layer=CanvasLayer.new(); root.add_child(layer)
	var band=ColorRect.new(); band.color=Color(.025,.04,.065,.91); band.position=Vector2(24,18); band.size=Vector2(1232,100); layer.add_child(band)
	var title=Label.new(); title.position=Vector2(42,29); title.add_theme_font_size_override("font_size",25); title.modulate=Color("f0c46a"); layer.add_child(title)
	var note=Label.new(); note.position=Vector2(42,68); note.add_theme_font_size_override("font_size",19); layer.add_child(note)
	var footer=Label.new(); footer.position=Vector2(30,680); footer.add_theme_font_size_override("font_size",17); footer.text="TEST ISOLATO / 60 FPS · Contatto fisico e animazione di recupero · Non è un replay del filmato"; layer.add_child(footer)
	var folder="res://.runtime/rescue57-frames"; DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var report: Array=[]
	for scene in 2:
		if scene==0:
			prepare_handoff(g); title.text="01 / RECUPERO DEL COMPAGNO DISPONIBILE"
			note.text="Il compagno più vicino sta recuperando: interviene quello che ha un percorso libero."
			g.camera.position=Vector3(2.4,3.6,10.6); g.camera.look_at(Vector3(-2.1,.8,4.4))
		else:
			prepare_second(g); title.text="02 / SALVATAGGIO BASSO DEL PALLEGGIATORE"
			note.text="Palla fuori dall'altezza del bagher: tentativo basso, contatto reale e rialzata."
			g.camera.position=Vector3(3.1,3.4,9.8); g.camera.look_at(Vector3(-1,.8,3.9))
		var actor: int=g.receiver if scene==0 else g.setter
		var initial: int=g.test_contacts; var hit:=false; var touched_at:=-1; var peak_step:=0.0; var large_steps: Array=[]
		for frame in 150:
			var previous: Vector3=g.players[actor].position
			if not hit:
				g.armed=true; g.input_quality=.8; g.step(1.0/60)
				if g.test_contacts>initial: hit=true; touched_at=frame
			else:
				# Observe the source landing without running another rally. The ball
				# continues with the real post-contact velocity; it is never frozen.
				if g.dive_motions.has(actor): g.advance_dive_body(actor,1.0/60)
				for index in 12:
					var player=g.players[index]
					if index!=actor:
						player.velocity=Vector3.ZERO; player.play("ready",1,true)
					player.tick(1.0/60,false,false)
				var state: Array[Vector3]=g.BallFlight.advance(g.ball_pos,g.ball_vel,g.flight_spin,1.0/60,g.flight_gravity)
				g.ball_pos=state[0]; g.ball_vel=state[1]
				if g.ball_pos.y<.105:
					var bounced: Dictionary=g.BallContact.floor_step(g.ball_pos,g.ball_vel,1.0/60)
					g.ball_pos=bounced.position; g.ball_vel=bounced.velocity
			var moved: float=g.players[actor].position.distance_to(previous)
			peak_step=maxf(peak_step,moved)
			if moved>.15: large_steps.append({"frame":frame,"before":str(previous),"after":str(g.players[actor].position),"seconds":g.players[actor].animation_time,"motion":g.dive_motions.get(actor,{})})
			for player in g.players: player.apply_pose(1.0/60)
			g.ball.position=g.ball_pos
			await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"/%03d.png"%(scene*150+frame))
		assert(hit,"Rendered rescue must contain a real contact")
		assert(peak_step<=.121,"The landing and rise must preserve the source root-speed limit")
		report.append({"scene":scene,"actor":actor,"variant":g.players[actor].variant_names.get("dive","dive"),"hit_frame":touched_at,"max_root_step":peak_step,"source_time":g.players[actor].animation_time,"frames":150,"large_steps":large_steps})
	FileAccess.open("res://docs/rescue57-capture-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RESCUE57 CAPTURE PASS 2 isolated real contacts / 300 rendered frames / ball continues after contact")
	g.free(); quit()

func reset_players(g) -> void:
	g.server=1; g.rotations=[0,0]; g.reset_rally(); g.possession=0; g.rng.seed=56001
	for i in 12:
		g.players[i].position=g.Tactics.world(int(i/6),3.8,8-float(i%6)*.8)
		g.players[i].visible=false; g.players[i].render_at_draw=false; g.players[i].play("idle",1,true); g.players[i].blend_left=0; g.players[i].velocity=Vector3.ZERO

func prepare_handoff(g) -> void:
	reset_players(g)
	for i in [0,3,4]: g.players[i].visible=true
	g.players[0].position=Vector3(-2,0,3.5); g.players[4].position=Vector3(-2.7,0,5.1)
	g.players[3].position=Vector3(-3.2,0,3.6); g.players[3].play("recovery",1,false); g.players[3].animation_time=0; g.players[3].motion_lock=2
	g.ball_pos=Vector3(-2,1.15,4); g.touches=[1,0]; g.set_dir=0; g.set_phase("RECEIVE"); g.incoming_kind="spike"
	load("res://src/scramble_recovery.gd").start(g,0)
	assert(g.receiver==4 and g.dive_motions.has(4))

func prepare_second(g) -> void:
	reset_players(g); g.players[5].visible=true
	g.setter=5; g.receiver=0; g.touches=[1,0]; g.phase="SET"; g.armed=true; g.input_quality=.8; g.pass_quality=.38; g.setter_dump=false; g.out_of_system=-1
	var p=g.players[5]; p.position=Vector3(-1,0,4.7); p.rotation.y=PI; p.select_variant("receive","receive_step")
	g.setter_action="receive"; g.plan_attack(0,false)
	g.ball_pos=Vector3(-1,1.15,3.4); g.launch(g.ball_pos+Vector3(0,-1.045,.15),.42)
	var hit: Dictionary=g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,p.contact_local("receive").y)
	g.flight_target=hit.point; g.flight_left=hit.seconds; g.next_second_touch_read=1000
	assert(Rescue.try_second_touch(g))

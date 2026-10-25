extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,1000)
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.set_physics_process(false)
	game.started=true; game.self_test=true; game.demo=false
	game.hud.hide(); game.marker.hide()
	if game.match_audio: game.match_audio.enabled=false
	for player in game.players: player.render_at_draw=false
	var canvas=CanvasLayer.new()
	root.add_child(canvas)
	var label=Label.new()
	label.position=Vector2(30,24)
	label.add_theme_font_size_override("font_size",25)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(label)
	var fixtures=load("res://tools/Test-ContactTraffic28.gd").new()
	for team in 2:
		fixtures.prepare(game,team,"receive_pipeline")
		var before: int=game.test_contacts
		var elapsed:=0.0
		var approach_saved:=false
		var contact_saved:=false
		var recovery_saved:=false
		for frame in 210:
			if not contact_saved:
				game.step(1.0/60)
				elapsed+=1.0/60
			game.camera.position=game.Tactics.world(team,6.8,9.5)+Vector3.UP*5.0
			game.camera.look_at(game.Tactics.world(team,-0.1,2.4)+Vector3.UP*1.15)
			game.camera.fov=45
			game.ball.position=game.ball_pos
			label.text="SECONDO TOCCO / TRAFFICO A RETE / SQUADRA %d\nt=%.2fs | %s | palleggiatore %s | contatti reali +%d"%[team+1,elapsed,game.phase,game.players[game.setter].clip_name,game.test_contacts-before]
			var take:=""
			if elapsed>=0.7 and not approach_saved: approach_saved=true; take="approach"
			if game.out_of_system<0 and not recovery_saved: recovery_saved=true; take="forearm"
			if game.test_contacts>before and not contact_saved:
				contact_saved=true
				label.text+="\nCONTATTO CONFERMATO / "+str(game.contact_log.back().action)
				take="contact"
			await process_frame
			if not take.is_empty():
				await RenderingServer.frame_post_draw
				var path="res://docs/recovery52-preview-%d-%s.png"%[team,take]
				root.get_texture().get_image().save_png(path)
				print("CONTACT28 CAPTURE ",path," t=",elapsed)
			if contact_saved: break
		assert(contact_saved,"Rendered fixture must register the actual second touch")
	fixtures.free()
	game.free(); canvas.free()
	print("CONTACT28 CAPTURE PASS: mirrored live fixtures, approach, recovery selection and actual contact")
	quit()

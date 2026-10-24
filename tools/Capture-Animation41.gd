extends SceneTree
## Integrated visual proof: real skinned avatars, private AnimationTree rigs,
## source-coordinate conversion, final procedural corrections and contact IK.
## Run: Godot --path . --script tools/Capture-Animation41.gd
const Avatar = preload("res://src/avatar.gd")
const Motion = preload("res://src/motion_prototypes.gd")
var game
var gallery: GridContainer
var heading: Label
var notes: Label
var ui: Control
var metrics: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(2000, 1140)
	root.content_scale_size = Vector2i(2000, 1140)
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.started = true
	game.set_process(false)
	game.set_physics_process(false)
	game.hide()
	game.hud.hide()
	game.camera.current = false
	for athlete in game.players: athlete.set_process(false)
	Avatar.native_animation_enabled = true
	Motion.enabled = true
	make_ui()
	attack_page()
	await save("res://docs/attack41-integrated-preview.png")
	clear_page()
	dive_page()
	await save("res://docs/dive41-integrated-preview.png")
	var file := FileAccess.open("res://docs/animation41-capture-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"native_animation_tree": true, "avatar_final_ik": true, "samples": metrics}, "  "))
	print("ANIMATION41 CAPTURE PASS: native AnimationTree + skinned avatar + final IK; two comparison pages / samples=", metrics.size())
	quit()

func make_ui() -> void:
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	var background := ColorRect.new()
	background.color = Color("0c1522")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	heading = Label.new()
	heading.position = Vector2(30, 14)
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("f2d187"))
	ui.add_child(heading)
	gallery = GridContainer.new()
	gallery.columns = 5
	gallery.position = Vector2(30, 76)
	gallery.size = Vector2(1940, 964)
	gallery.add_theme_constant_override("h_separation", 15)
	gallery.add_theme_constant_override("v_separation", 20)
	ui.add_child(gallery)
	notes = Label.new()
	notes.position = Vector2(30, 1060)
	notes.add_theme_font_size_override("font_size", 19)
	notes.add_theme_color_override("font_color", Color("aec1d9"))
	ui.add_child(notes)

func attack_page() -> void:
	heading.text = "SPIKE FOREVER / SCHIACCIATA — originale sopra, nuovo gesto adattivo sotto"
	notes.text = "AnimationTree + modello completo + correzioni Avatar e IK finale. Pallone: bersaglio reale della mano.\nIl movimento fisico, gli appoggi e il tempo di contatto restano separati dalla variante visiva."
	var source = game.clips[Motion.Attack.SOURCE]
	var names := ["CARICAMENTO", "APERTURA", "CONTATTO VICINO", "CONTATTO DISTANTE", "ACCOMPAGNAMENTO"]
	var times := [source.contact_time - 0.25, source.contact_time - 0.09, source.contact_time, source.contact_time, source.contact_time + 0.32]
	for row in 2:
		for column in 5:
			var delta := Vector3.ZERO
			if column == 2: delta = Vector3(-0.10, -0.035, -0.07)
			if column == 3: delta = Vector3(0.16, 0.08, 0.12)
			make_cell("attack", Motion.Attack.SOURCE if row == 0 else "attack_adaptive41", times[column], names[column], row == 1, delta, column in [2, 3])

func dive_page() -> void:
	heading.text = "SPIKE FOREVER / DIFESA IN TUFFO — originale sopra, nuova esecuzione sotto"
	notes.text = "Sequenza completa: preparazione, estensione, contatto, assorbimento a terra e risalita sugli appoggi.\nPose renderizzate dallo stesso Avatar usato in partita; il parser PSA originale resta disponibile."
	var source = game.clips[Motion.Dive.SOURCE]
	var names := ["PREPARAZIONE", "CONTATTO", "CADUTA", "APPOGGIO / ASSORBIMENTO", "RISALITA"]
	var times := [source.contact_time * 0.4, source.contact_time, source.contact_time + 0.26, source.contact_time + 0.65, minf(source.duration - 0.04, source.contact_time + 1.58)]
	for row in 2:
		for column in 5:
			make_cell("dive", Motion.Dive.SOURCE if row == 0 else "dive_authored41", times[column], names[column], row == 1, Vector3.ZERO, column == 1)

func clear_page() -> void:
	for child in gallery.get_children():
		gallery.remove_child(child)
		child.free()

func make_cell(action: String, variant: String, time: float, title: String, authored: bool, target_delta: Vector3, contact: bool) -> void:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(376, 472)
	gallery.add_child(panel)
	var caption := Label.new()
	caption.text = ("NUOVO / " if authored else "PSA / ") + title
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_color", Color("f2d187") if authored else Color("c4d4e5"))
	panel.add_child(caption)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.custom_minimum_size = Vector2(376, 415)
	panel.add_child(view)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(376, 415)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	view.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("142336")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c8d9f0")
	env.environment.ambient_light_energy = 0.85
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -28, 0)
	light.light_energy = 1.25
	light.shadow_enabled = true
	world.add_child(light)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(5, 5)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("a9906b")
	material.roughness = 0.85
	floor.material_override = material
	world.add_child(floor)
	for index in range(-2, 3):
		for axis in 2:
			var line := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.012, 0.006, 5) if axis == 0 else Vector3(5, 0.006, 0.012)
			line.mesh = box
			line.position = Vector3(index, 0.004, 0) if axis == 0 else Vector3(0, 0.004, index)
			var line_mat := StandardMaterial3D.new()
			line_mat.albedo_color = Color("8f7c5e")
			line.material_override = line_mat
			world.add_child(line)
	var athlete = Avatar.new()
	world.add_child(athlete)
	athlete.setup(game.clips, 0, 1, game.models)
	athlete.set_process(false)
	athlete.render_at_draw = false
	athlete.select_variant(action, variant)
	athlete.play(action, 1, false)
	athlete.animation_time = time
	athlete.blend_left = 0
	athlete.indicator.hide()
	athlete.jersey_number.hide()
	Motion.enabled = authored
	var reference: Array[Transform3D] = athlete.normalized_pose("source:" + (Motion.Attack.SOURCE if action == "attack" else Motion.Dive.SOURCE), time, false)
	var hand: int = athlete.clips[action].names.find("RightHand")
	var goal: Vector3 = reference[hand].origin + target_delta + Vector3(0, 0, 0.085)
	athlete.reach_target = goal
	athlete.reach_action = action
	athlete.reach_weight = 1.0 if contact else 0.0
	athlete.look_target = goal
	athlete.apply_pose(1.0 / 60.0)
	assert(athlete.pose_tree != null and athlete.pose_tree.initialized)
	assert(athlete.pose_tree.evaluations > 0)
	if contact:
		var sphere := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.105
		ball.height = 0.21
		sphere.mesh = ball
		sphere.position = goal
		var ball_mat := StandardMaterial3D.new()
		ball_mat.albedo_color = Color("f8d058")
		sphere.material_override = ball_mat
		world.add_child(sphere)
	var camera := Camera3D.new()
	world.add_child(camera)
	if action == "attack":
		camera.position = Vector3(3.4, 2.8, 4.7)
		camera.look_at(Vector3(0, 1.60, 0.08))
		camera.fov = 43
	else:
		camera.position = Vector3(3.4, 2.45, 4.8)
		camera.look_at(Vector3(0, 0.95, 0.10))
		camera.fov = 37
	camera.current = true
	var result := Label.new()
	result.add_theme_font_size_override("font_size", 15)
	var hand_error: float = athlete.current_hand(false).distance_to(goal - Vector3(0, 0, 0.085))
	result.text = "t %.3f s" % time + ("  /  mano %.1f mm" % (hand_error * 1000) if contact else "")
	panel.add_child(result)
	metrics.append({"action": action, "variant": variant, "time_s": time, "contact": contact, "contact_error_m": hand_error if contact else null, "tree_evaluations": athlete.pose_tree.evaluations})
	Motion.enabled = true

func save(path: String) -> void:
	for frame in 7: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(path)
	assert(result == OK)
	print("ANIMATION41 SAVED ", path)

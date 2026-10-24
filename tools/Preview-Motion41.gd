extends SceneTree
## Animated A/B preview through the production Avatar/AnimationTree/IK path.
## Godot --path . --script tools/Preview-Motion41.gd
## Record: --write-movie docs/animation41-preview.avi --fixed-fps 30 --quit-after 360
## F1: next example. Space: pause. Identical extracted physical root travel on
## both sides; crossfades between examples are presentation-only.
const Avatar = preload("res://src/avatar.gd")
const Motion = preload("res://src/motion_prototypes.gd")
var game
var actors: Array = []
var balls: Array[MeshInstance3D] = []
var cameras: Array[Camera3D] = []
var curtain: ColorRect
var title: Label
var details: Label
var stage := 0
var clock := 0.0
var preview_paused := false
var frames := 0
var checked_frames := 0
var last_space := false
var last_f1 := false
var ready := false

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 960)
	root.content_scale_size = root.size
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.started = true
	game.set_process(false)
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.hide()
	game.hud.hide()
	game.camera.current = false
	for athlete in game.players: athlete.set_process(false)
	Avatar.native_animation_enabled = true
	Motion.enabled = true
	build_preview()
	begin_stage(0)
	ready = true

func build_preview() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var ui := Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("0c1522")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	title = Label.new()
	title.position = Vector2(24, 12)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("f2d187"))
	ui.add_child(title)
	for side in 2:
		var label := Label.new()
		label.position = Vector2(24 + side * 800, 56)
		label.text = "ORIGINALE PSA / AnimationTree" if side == 0 else "NUOVO GESTO / AnimationTree + adattamento"
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("c4d4e5") if side == 0 else Color("f2d187"))
		ui.add_child(label)
		var container := SubViewportContainer.new()
		container.position = Vector2(side * 800, 94)
		container.size = Vector2(795, 780)
		container.stretch = true
		ui.add_child(container)
		var view := SubViewport.new()
		view.size = Vector2i(795, 780)
		view.own_world_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		view.msaa_3d = Viewport.MSAA_4X
		container.add_child(view)
		var world := Node3D.new()
		view.add_child(world)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("142336")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("c8d9f0")
		environment.environment.ambient_light_energy = 0.85
		world.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-55, -28, 0)
		light.light_energy = 1.25
		light.shadow_enabled = true
		world.add_child(light)
		var floor := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(14, 14)
		floor.mesh = plane
		floor.material_override = material(Color("a9906b"))
		world.add_child(floor)
		for index in range(-7, 8):
			for axis in 2:
				var line := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.012, 0.006, 14) if axis == 0 else Vector3(14, 0.006, 0.012)
				line.mesh = box
				line.position = Vector3(index, 0.004, 0) if axis == 0 else Vector3(0, 0.004, index)
				line.material_override = material(Color("8f7c5e"))
				world.add_child(line)
		var athlete = Avatar.new()
		world.add_child(athlete)
		athlete.setup(game.clips, 0, 1, game.models)
		athlete.set_process(false)
		athlete.render_at_draw = false
		athlete.indicator.hide()
		athlete.jersey_number.hide()
		actors.append(athlete)
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.105
		sphere.height = 0.21
		ball.mesh = sphere
		ball.material_override = material(Color("f8d058"))
		world.add_child(ball)
		balls.append(ball)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.fov = 43
		camera.current = true
		cameras.append(camera)
	curtain = ColorRect.new()
	curtain.color = Color(0.047, 0.082, 0.133, 1)
	curtain.position = Vector2(0, 94)
	curtain.size = Vector2(1600, 780)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(curtain)
	details = Label.new()
	details.position = Vector2(24, 892)
	details.add_theme_font_size_override("font_size", 20)
	details.add_theme_color_override("font_color", Color("aec1d9"))
	ui.add_child(details)

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

func begin_stage(next: int) -> void:
	stage = posmod(next, 3)
	clock = 0
	var action := "dive" if stage == 2 else "attack"
	var source: String = Motion.Dive.SOURCE if stage == 2 else Motion.Attack.SOURCE
	for side in 2:
		var athlete = actors[side]
		athlete.reach_weight = 0
		athlete.select_variant(action, source if side == 0 else ("dive_authored41" if stage == 2 else "attack_adaptive41"))
		athlete.play(action, 1, false)
		athlete.blend_left = 0
		athlete.foot_planted = [false, false]
		athlete.foot_weights = [0.0, 0.0]
	title.text = "SPIKE FOREVER / " + ["SCHIACCIATA — palla vicina", "SCHIACCIATA — palla distante", "TUFFO — estensione, contatto, caduta e risalita"][stage]
	print("MOTION41 PREVIEW stage=", stage, " source=", source)
	render_frame(0.0, 0.0)

func _process(delta: float) -> bool:
	if not ready: return false
	frames += 1
	var space := Input.is_physical_key_pressed(KEY_SPACE)
	var f1 := Input.is_physical_key_pressed(KEY_F1)
	if space and not last_space: preview_paused = not preview_paused
	if f1 and not last_f1: begin_stage(stage + 1)
	last_space = space
	last_f1 = f1
	var dt := minf(delta, 0.05)
	if not preview_paused: clock += dt
	var source = game.clips[Motion.Dive.SOURCE if stage == 2 else Motion.Attack.SOURCE]
	if clock > source.duration + 0.55:
		begin_stage(stage + 1)
		source = game.clips[Motion.Dive.SOURCE if stage == 2 else Motion.Attack.SOURCE]
	render_frame(minf(clock, source.duration), 0.0 if preview_paused else dt)
	curtain.color.a = maxf(1.0 - smoothstep(0.0, 0.18, clock), smoothstep(source.duration + 0.35, source.duration + 0.55, clock))
	details.text = ("PAUSA / " if preview_paused else "") + "t %.2f s / F1: esempio successivo / Spazio: pausa\nRoot fisico identico su entrambi; supporti, contatto, tempo e IK del gioco originale." % minf(clock, source.duration)
	return false

func render_frame(time: float, dt: float) -> void:
	var action := "dive" if stage == 2 else "attack"
	var source = game.clips[Motion.Dive.SOURCE if stage == 2 else Motion.Attack.SOURCE]
	var root_travel: Vector3 = source.root_motion(time)
	var contact_root: Vector3 = source.root_motion(source.contact_time)
	var reference: Array[Transform3D] = Motion.normalized(source, source.contact_time)
	var hand: int = source.names.find("RightHand")
	var goal: Vector3 = contact_root + reference[hand].origin + Vector3(0, 0, 0.085)
	if stage == 0: goal += Vector3(-0.10, -0.035, -0.07)
	if stage == 1: goal += Vector3(0.16, 0.08, 0.12)
	var ball_point := goal
	if time < source.contact_time:
		var until: float = source.contact_time - time
		ball_point += (Vector3(0.2, 2.5, 1.25) if action == "attack" else Vector3(0.12, 0.25, 2.2)) * clampf(until / 0.42, 0, 1)
	else:
		var after: float = time - source.contact_time
		ball_point += (Vector3(0.5, -1.9, 4.0) if action == "attack" else Vector3(0.1, 1.8, -2.2)) * clampf(after / 0.38, 0, 1)
	for side in 2:
		var athlete = actors[side]
		Motion.enabled = side == 1
		athlete.position = root_travel
		athlete.animation_time = time
		athlete.contact_scheduled = true
		athlete.reach_action = action
		athlete.reach_target = goal
		athlete.reach_weight = smoothstep(source.contact_time - 0.21, source.contact_time - 0.025, time) * (1.0 - smoothstep(source.contact_time + 0.02, source.contact_time + 0.16, time))
		athlete.look_target = ball_point
		athlete.tick(dt, false, true)
		assert(athlete.pose_tree != null and athlete.pose_tree.initialized)
		for bone in athlete.last_pose: assert(bone.origin.is_finite())
		balls[side].position = ball_point
		var eye := Vector3(4.0, 2.8, 5.4) if action == "attack" else Vector3(3.9, 2.2, 5.2)
		cameras[side].position = root_travel + eye
		cameras[side].look_at(root_travel + Vector3(0, 1.5 if action == "attack" else 0.85, 0.1))
	assert(actors[0].position.distance_to(actors[1].position) < 0.000001)
	Motion.enabled = true
	checked_frames += 1

func _finalize() -> void:
	if checked_frames > 0:
		print("MOTION41 ANIMATED PREVIEW PASS: frames=", frames, " validated=", checked_frames, " / same physical root / native Tree / final Avatar IK / no non-finite bone positions")

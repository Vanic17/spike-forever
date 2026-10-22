extends Node3D

const PSA = preload("res://src/psa.gd")
const Avatar = preload("res://src/avatar.gd")
const Timing = preload("res://src/timing.gd")
const HUD = preload("res://src/hud.gd")
const PSK = preload("res://src/psk.gd")
const G := 9.81
const BASE := [Vector3(-3, 0, 1.8), Vector3(0, 0, 1.4), Vector3(3, 0, 1.8), Vector3(3, 0, 6.1), Vector3(0, 0, 6.5), Vector3(-3, 0, 6.1)]
var clips: Dictionary = {}
var models: Dictionary = {}
var players: Array = []
var ball: MeshInstance3D
var shadow: MeshInstance3D
var marker: MeshInstance3D
var camera: Camera3D
var hud: Control
var timing = Timing.new()
var rng := RandomNumberGenerator.new()
var phase := "SERVE"
var phase_time := 0.0
var clock_time := 0.0
var server := 0
var possession := 0
var scores := [0, 0]
var sets := [0, 0]
var rotations := [0, 0]
var touches := [0, 0]
var selected := 3
var receiver := 0
var hitter := 0
var setter := 1
var destination := 0
var committed_destination := 0
var ball_pos := Vector3.ZERO
var ball_vel := Vector3.ZERO
var flight_target := Vector3.ZERO
var flight_left := 0.0
var airborne := false
var last_touch := 0
var charge := 0.0
var charging := false
var charge_start := 0.0
var armed := false
var input_quality := 0.0
var pass_quality := 0.8
var set_quality := 1.0
var fast_set := false
var serve_type := 0
var aim := Vector2(0, -1)
var set_dir := 0
var cue_left := 0.0
var prediction := false
var prediction_given := false
var block_count := 1
var block_time := -100.0
var block_quality := 0.0
var block_checked := false
var block_hand := 0.0
var feedback := "BENVENUTO IN CAMPO"
var feedback_left := 4.0
var point_reason := ""
var started := false
var paused := false
var demo := false
var debug_visible := false
var difficulty := 1
var camera_mode := 0
var gallery := false
var gallery_index := 0
var self_test := false
var test_points := 0
var test_contacts := 0
var test_rallies := 0
var max_rally := 0
var status := ""
var synth: AudioStreamPlayer

func _ready() -> void:
	rng.seed = 194260
	setup_inputs()
	for name in ["idle", "run", "receive", "set", "fast_set", "attack", "block", "float", "power", "serve_idle"]:
		if "--fallback-test" in OS.get_cmdline_user_args(): continue
		var clip = PSA.new()
		if clip.load_file("res://assets/active/" + name + ".psa"):
			clip.load_hierarchy("res://assets/active/skeleton.psk")
			clip.detect_contact(name)
			clips[name] = clip
			print("ANIMATION ", name, ": ", clip.frames, " frames / ", clip.names.size(), " bones / ", clip.duration, "s")
	if not clips.is_empty():
		if not clips.has("idle"): clips["idle"] = clips.values()[0]
		for name in ["run", "receive", "set", "fast_set", "attack", "block", "float", "power", "serve_idle"]:
			if not clips.has(name): clips[name] = clips.idle
	var body = PSK.new()
	if not "--fallback-test" in OS.get_cmdline_user_args() and body.load_file("res://assets/active/body.psk"):
		models["body"] = body
		for name in ["cloth", "head"]:
			var model = PSK.new()
			if model.load_file("res://assets/active/" + name + ".psk", body.names): models[name] = model
	build_arena()
	for team in 2:
		for i in 6:
			var player = Avatar.new()
			add_child(player)
			player.setup(clips, team, i + 1, models)
			player.rotation.y = PI if team == 0 else 0.0
			players.append(player)
	hud = Control.new()
	hud.set_script(HUD)
	hud.game = self
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	synth = AudioStreamPlayer.new()
	add_child(synth)
	reset_rally()
	self_test = "--self-test" in OS.get_cmdline_user_args() or "--fallback-test" in OS.get_cmdline_user_args()
	if self_test:
		if "--self-test" in OS.get_cmdline_user_args(): run_tests()
		else:
			assert(clips.is_empty() and models.is_empty() and players.size() == 12)
			print("FALLBACK TEST: no source animations or meshes; procedural athletes active")
		started = true
		demo = true
		for i in 240000:
			step(1.0 / 120.0)
			if test_points >= 16 or clock_time > 1999: break
		print("SIMULATION points=", test_points, " contacts=", test_contacts, " longest_rally=", max_rally, " clock=", clock_time)
		get_tree().quit(0 if test_points >= 16 and test_contacts > 35 and max_rally >= 6 else 1)
	if "--preview" in OS.get_cmdline_user_args():
		started = true
		demo = true

func setup_inputs() -> void:
	var bindings := {"action": [KEY_SPACE, JOY_BUTTON_X], "fast": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER], "serve_type": [KEY_TAB, JOY_BUTTON_Y], "start": [KEY_ENTER, JOY_BUTTON_START]}
	var config := ConfigFile.new()
	config.load("res://controls.cfg")
	for action in bindings:
		InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = int(config.get_value(action, "key", bindings[action][0]))
		InputMap.action_add_event(action, key)
		var joy := InputEventJoypadButton.new()
		joy.device = -1
		joy.button_index = int(config.get_value(action, "button", bindings[action][1]))
		InputMap.action_add_event(action, joy)
	for pair in [["left", KEY_A], ["right", KEY_D], ["up", KEY_W], ["down", KEY_S]]:
		InputMap.add_action(pair[0])
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)

func mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mat(color)
	add_child(node)
	return node

func build_arena() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101e2d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b2c6dc")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -30, 0)
	light.light_energy = 0.85
	light.shadow_enabled = true
	add_child(light)
	box(Vector3(0, -0.18, 0), Vector3(26, 0.3, 32), Color("103b48"))
	box(Vector3(0, -0.015, 0), Vector3(9, 0.04, 18), Color("ae794e"))
	for x in range(-4, 5):
		box(Vector3(x, 0.009, 0), Vector3(0.012, 0.008, 18), Color("c38b5e"))
	for x in [-4.5, 4.5]:
		box(Vector3(x, 0.025, 0), Vector3(0.06, 0.015, 18.08), Color.WHITE)
	for z in [-9, -3, 0, 3, 9]:
		box(Vector3(0, 0.025, z), Vector3(9.05, 0.015, 0.06), Color.WHITE)
	for x in [-5.25, 5.25]:
		box(Vector3(x, 1.4, 0), Vector3(0.13, 2.8, 0.13), Color("31bcd0"))
		box(Vector3(x, 0.7, 0), Vector3(0.36, 1.4, 0.36), Color("15394c"))
	for y in range(12):
		box(Vector3(0, 1.43 + y * 0.085, 0), Vector3(10.5, 0.012, 0.012), Color("49616a"))
	for i in range(106):
		box(Vector3(-5.25 + i * 0.1, 1.9, 0), Vector3(0.008, 0.95, 0.008), Color("49616a"))
	box(Vector3(0, 2.43, 0), Vector3(10.5, 0.075, 0.04), Color.WHITE)
	for x in [-4.6, 4.6]:
		for i in 6:
			box(Vector3(x, 2.48 + i * 0.12, 0), Vector3(0.035, 0.12, 0.035), Color("ef584c") if i % 2 else Color.WHITE)
	for side in [-1, 1]:
		for row in 4:
			box(Vector3(side * (8.7 + row * 0.8), row * 0.48 + 0.2, 0), Vector3(0.8, 0.45, 24), Color("172d42"))
			for seat in 26:
				box(Vector3(side * (8.7 + row * 0.8), row * 0.48 + 0.64, seat * 0.86 - 11), Vector3(0.38, 0.46, 0.44), Color("315269") if (seat + row) % 3 else Color("e09b6e"))
		box(Vector3(side * 6.4, 0.42, 0), Vector3(0.16, 0.85, 22), Color("101e2f"))
		for z in [-7, 0, 7]:
			var brand := Label3D.new()
			brand.text = "SPIKE / FOREVER"
			brand.position = Vector3(side * 6.25, 0.6, z)
			brand.rotation.y = -side * PI / 2
			brand.font_size = 54
			brand.pixel_size = 0.01
			brand.modulate = Color("33cddd")
			add_child(brand)
	ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.105
	sphere.height = 0.21
	sphere.radial_segments = 24
	sphere.rings = 12
	ball.mesh = sphere
	ball.material_override = mat(Color("ffe6a0"))
	add_child(ball)
	shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.17
	disc.bottom_radius = 0.17
	disc.height = 0.006
	shadow.mesh = disc
	shadow.material_override = mat(Color("6b6c60"))
	add_child(shadow)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.39
	marker.mesh = ring
	marker.material_override = mat(Color("ffe39c"), true)
	add_child(marker)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 25
	add_child(camera)
	set_camera()

func set_camera() -> void:
	camera.position = Vector3(16, 18, 24) if camera_mode == 0 else Vector3(0, 22, 24)
	camera.look_at(Vector3(0, 0, 0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if started: paused = not paused
			KEY_F1: debug_visible = not debug_visible
			KEY_F2: demo = not demo
			KEY_F3:
				gallery = not gallery
				started = true
				gallery_index = 0
				if gallery: show_clip()
				else: reset_rally()
			KEY_F5: difficulty = (difficulty + 1) % 3
			KEY_C:
				camera_mode = 1 - camera_mode
				set_camera()
			KEY_R:
				scores = [0, 0]
				sets = [0, 0]
				rotations = [0, 0]
				reset_rally()
			KEY_RIGHT:
				if gallery:
					gallery_index = (gallery_index + 1) % clips.size()
					show_clip()
			KEY_LEFT:
				if gallery:
					gallery_index = posmod(gallery_index - 1, clips.size())
					show_clip()
	if event.is_action_pressed("start"):
		if not started:
			started = true
		else:
			paused = not paused
	if event.is_action_pressed("serve_type") and phase == "SERVE" and not charging:
		serve_type = 1 - serve_type
	if not started or paused or gallery:
		return
	if event.is_action_pressed("action"):
		press_action()
	if event.is_action_released("action"):
		release_action()

func show_clip() -> void:
	if clips.is_empty():
		gallery = false
		notice("ANIMAZIONI ASSENTI · GIOCATORI PROVVISORI")
		return
	var name: String = clips.keys()[gallery_index]
	for p in players:
		p.play(name, 1.0, true)

func pad() -> int:
	var ids := Input.get_connected_joypads()
	return ids[0] if not ids.is_empty() else -1

func stick(right: bool) -> Vector2:
	var result := Vector2.ZERO
	var id := pad()
	if id >= 0:
		result = Vector2(Input.get_joy_axis(id, JOY_AXIS_RIGHT_X if right else JOY_AXIS_LEFT_X), Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y if right else JOY_AXIS_LEFT_Y))
		if result.length() < 0.22: result = Vector2.ZERO
	if right:
		var key := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
		if key != Vector2.ZERO: result = key
	else:
		result += Input.get_vector("left", "right", "up", "down")
	return result.limit_length()

func read_controls() -> void:
	var direction := stick(true)
	if direction.length() > 0.3:
		var angle := roundf(direction.angle() / (PI / 4)) * PI / 4
		aim = Vector2.from_angle(angle)
		if absf(direction.x) > absf(direction.y):
			set_dir = 0 if direction.x < 0 else 2
		else:
			set_dir = 1 if direction.y < 0 else 3
		if phase == "CPU_ATTACK" and cue_left > 0 and not prediction_given:
			prediction_given = true
			prediction = set_dir == committed_destination and committed_destination != 3
			block_count = Timing.blockers(prediction, fast_set, set_quality, committed_destination == 3)
			notice("LETTURA CORRETTA · MURO A DUE" if prediction else "LETTURA ERRATA · MURO SINGOLO", 1.1)
		if clock_time - block_time < 0.65: block_hand = direction.x
	if phase == "SET": fast_set = Input.is_action_pressed("fast")

func press_action() -> void:
	if phase == "SERVE" and server == 0 and not charging:
		charging = true
		charge_start = clock_time
		players[selected].play("float" if serve_type == 0 else "power")
	elif phase == "ATTACK" and not armed:
		charging = true
		charge_start = clock_time
	elif phase in ["RECEIVE", "SET"] and not armed:
		armed = true
		input_quality = timing.quality(flight_left, fast_set if phase == "SET" else false, pass_quality, difficulty_scale())
		show_quality(input_quality, flight_left)
	elif phase == "CPU_ATTACK" and clock_time - block_time > 0.9:
		block_time = clock_time
		block_quality = timing.quality(flight_left - 0.12, fast_set, 0.6, difficulty_scale())
		for i in block_count:
			players[i].play("block", maxf(1.0, clips.block.contact_time / 0.22) if clips.has("block") else 2.0)
		show_quality(block_quality, flight_left - 0.12)

func release_action() -> void:
	if not charging: return
	charge = clampf((clock_time - charge_start) / (1.05 if phase == "SERVE" else 0.75), 0, 1.5)
	charging = false
	if phase == "SERVE" and server == 0:
		if charge > 1.00001:
			award(1, "FALLO DI SERVIZIO · SOVRACCARICO")
		else:
			input_quality = timing.quality((clock_time - charge_start) - 0.92, false, 1, difficulty_scale())
			serve_ball(0, charge)
	elif phase == "ATTACK" and not armed:
		armed = true
		input_quality = timing.quality(flight_left, false, pass_quality, difficulty_scale())
		show_quality(input_quality, flight_left)

func difficulty_scale() -> float:
	return [1.55, 1.0, 0.72][difficulty]

func notice(message: String, seconds: float = 1.5) -> void:
	feedback = message
	feedback_left = seconds

func show_quality(q: float, remaining: float) -> void:
	notice("PERFETTO" if q > 0.97 else ("BUONO" if q > 0.75 else ("ANTICIPO" if remaining > 0 else "RITARDO")))

func set_phase(value: String) -> void:
	phase = value
	phase_time = 0
	armed = false
	input_quality = 0
	charging = false
	charge = 0

func reset_rally() -> void:
	airborne = false
	possession = server
	last_touch = server
	touches = [0, 0]
	for i in 12:
		var p = players[i]
		p.motion_lock = 0
		var base: Vector3 = BASE[posmod(i % 6 - rotations[i / 6], 6)]
		base.z *= 1 if i < 6 else -1
		p.position = base
		p.target = base
		p.play("idle", 1, true)
	selected = server_index(0)
	var serving = players[server_index(server)]
	serving.position = Vector3(3, 0, 9.7 * (1 if server == 0 else -1))
	serving.target = serving.position
	serving.play("serve_idle", 1, true)
	ball_pos = serving.position + Vector3(0, 1.3, -0.35 if server == 0 else 0.35)
	ball_vel = Vector3.ZERO
	set_phase("SERVE")
	block_time = -100
	block_checked = false
	marker.visible = false

func server_index(team: int) -> int:
	return team * 6 + posmod(3 + rotations[team], 6)

func nearest(team: int, point: Vector3, exclude: int = -1) -> int:
	var best := team * 6
	var dist := INF
	for i in range(team * 6, team * 6 + 6):
		if i == exclude: continue
		var d: float = Vector2(players[i].position.x - point.x, players[i].position.z - point.z).length()
		if d < dist:
			dist = d
			best = i
	return best

func launch(target: Vector3, seconds: float) -> void:
	flight_target = target
	flight_left = seconds
	ball_vel = (target - ball_pos) / seconds + Vector3(0, G * seconds * 0.5, 0)
	airborne = true
	marker.position = Vector3(target.x, 0.04, target.z)
	marker.visible = true
	beep(460, 0.035)

func serve_ball(team: int, power: float) -> void:
	last_touch = team
	possession = 1 - team
	var s := 1.0 if possession == 0 else -1.0
	var target := Vector3(clampf(aim.x * 2.8, -3.8, 3.8), 1.05, s * (5.2 + aim.y * 1.5))
	if team == 1: target.x = rng.randf_range(-3.1, 3.1)
	var contact_quality := input_quality if team == 0 and not demo else 0.92
	var dispersion := 2.2 * (1.0 - contact_quality)
	target.x += rng.randf_range(-dispersion, dispersion)
	target.z += rng.randf_range(-dispersion, dispersion)
	players[server_index(team)].prepare_contact("float" if serve_type == 0 else "power", 0)
	receiver = nearest(possession, target)
	players[receiver].target = Vector3(target.x, 0, target.z)
	selected = receiver if possession == 0 else 1
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	launch(target, (1.65 if serve_type == 0 else 1.30) + (1.0 - power) * 0.5)

func reachable(index: int, point: Vector3, reach: float = 1.4) -> bool:
	return Vector2(players[index].position.x - point.x, players[index].position.z - point.z).length() < reach

func receive_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.22), false, 0.6, 1.0)
	if not reachable(receiver, ball_pos) or (possession == 0 and not armed) or q < 0.16:
		miss_contact()
		return
	if possession == 1 and phase != "CPU_RECEIVE":
		q *= 0.95
	pass_quality = q
	register_touch(receiver)
	players[receiver].prepare_contact("receive", 0)
	var s := 1 if possession == 0 else -1
	var dispersion := (1 - q) * 2.6
	var target := Vector3(rng.randf_range(-dispersion, dispersion), 2.15, s * (1.5 + rng.randf_range(0, dispersion)))
	setter = nearest(possession, target, receiver)
	players[setter].target = Vector3(target.x, 0, target.z)
	selected = setter if possession == 0 else 1
	fast_set = false
	set_phase("SET" if possession == 0 else "CPU_SET")
	launch(target, 1.5 + (1.0 - q) * 0.55)

func set_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.15), fast_set, pass_quality, 1.0)
	if not reachable(setter, ball_pos) or (possession == 0 and not armed) or q < 0.12:
		miss_contact()
		return
	if possession == 1:
		set_dir = rng.randi_range(0, 3)
		fast_set = rng.randf() < 0.35 and pass_quality > 0.75
	if fast_set and pass_quality < 0.45:
		fast_set = false
		notice("RICEZIONE DIFFICILE · ALTA DI EMERGENZA")
	set_quality = q
	destination = set_dir
	committed_destination = destination
	register_touch(setter)
	players[setter].prepare_contact("fast_set" if fast_set else "set", 0)
	var s := 1.0 if possession == 0 else -1.0
	var x: float = [-3.4, 0.0, 3.4, 0.0][destination]
	var z := s * (3.5 if destination == 3 else 1.05)
	var target := Vector3(x + rng.randf_range(-1, 1) * (1 - q) * 0.8, 3.05, z)
	hitter = nearest(possession, target, setter)
	players[hitter].target = Vector3(target.x, 0, target.z)
	selected = hitter if possession == 0 else nearest(0, Vector3(x, 0, 0.6))
	var flight := 0.95 if fast_set else 1.45 + (1 - q) * 1.6
	block_count = Timing.blockers(false, fast_set, q, destination == 3)
	if possession == 0:
		var cpu_correct := rng.randf() < 0.52
		block_count = Timing.blockers(cpu_correct, fast_set, q, destination == 3)
	prediction = false
	prediction_given = false
	cue_left = timing.cue_duration_fast if fast_set else timing.cue_duration_normal
	block_time = -100
	block_quality = 0
	block_checked = false
	block_hand = 0
	set_phase("ATTACK" if possession == 0 else "CPU_ATTACK")
	launch(target, flight)
	notice((["BANDA · ZONA 4", "CENTRO · ZONA 3", "OPPOSTO · ZONA 2", "PIPE · ZONA 6"][destination]) + (" / VELOCE" if fast_set else " / ALTA"), 0.8)

func attack_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.17), false, pass_quality, 1.0)
	if not reachable(hitter, ball_pos) or (possession == 0 and not armed) or q < 0.12:
		miss_contact()
		return
	var attacker := possession
	register_touch(hitter)
	players[hitter].prepare_contact("attack", 0)
	last_touch = attacker
	var power := clampf(charge, 0, 1) if attacker == 0 else rng.randf_range(0.25, 0.9)
	var precision := Timing.precision(power)
	var spread := (1.0 - precision + (1.0 - q) * 0.8) * 3.0
	var s := -1.0 if attacker == 0 else 1.0
	var target := Vector3(clampf(ball_pos.x * 0.35 + aim.x * 3.0, -3.9, 3.9), 1.0, s * (5.6 + aim.y * 1.6))
	if attacker == 1: target.x = rng.randf_range(-3.8, 3.8)
	target += Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread, spread))
	# The net's geometry also checks the resulting ballistic arc, including pipe attacks.
	possession = 1 - attacker
	touches[possession] = 0
	receiver = nearest(possession, target)
	players[receiver].target = Vector3(target.x, 0, target.z)
	selected = receiver if possession == 0 else selected
	var saved_block_time := block_time
	var saved_block_quality := block_quality
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	charge = power
	block_time = saved_block_time
	block_quality = saved_block_quality
	launch(target, 1.05 - power * 0.25)
	block_checked = false
	if attacker == 0:
		block_time = clock_time - rng.randf_range(0.05, 0.4)
		block_quality = rng.randf_range(0.45, 1)
		for i in block_count:
			players[6 + i].prepare_contact("block", 0.1)

func register_touch(index: int) -> void:
	touches[possession] += 1
	last_touch = possession
	test_contacts += 1
	test_rallies += 1
	max_rally = maxi(max_rally, test_rallies)
	if touches[possession] > 3:
		award(1 - possession, "QUATTRO TOCCHI")
	players[index].motion_lock = 0.12

func miss_contact() -> void:
	if self_test:
		print("MISS ", phase, " ball=", ball_pos, " receiver=", players[receiver].position, " setter=", players[setter].position, " armed=", armed, " quality=", input_quality)
	# No magnetic rescue: let gravity carry the missed ball to the floor.
	phase = "LOOSE"
	flight_left = 100
	marker.visible = false
	notice("PALLA NON RAGGIUNTA", 0.8)

func award(team: int, reason: String) -> void:
	if phase == "POINT": return
	if self_test: print("POINT ", team, " ", reason, " phase=", phase, " ball=", ball_pos)
	scores[team] += 1
	if server != team: rotations[team] = posmod(rotations[team] + 1, 6)
	server = team
	point_reason = reason
	notice("PUNTO " + ("AURORA" if team == 0 else "EMBER"), 2.0)
	if scores[team] >= 25 and scores[team] - scores[1 - team] >= 2:
		sets[team] += 1
		scores = [0, 0]
		point_reason = "SET " + ("AURORA" if team == 0 else "EMBER")
		if sets[team] >= 3:
			point_reason = "VITTORIA " + ("AURORA" if team == 0 else "EMBER") + " · R PER NUOVA PARTITA"
			paused = true
	set_phase("POINT")
	airborne = false
	marker.visible = false
	test_points += 1
	test_rallies = 0
	beep(720, 0.11)

func _physics_process(dt: float) -> void:
	if self_test:
		return
	else:
		step(dt)

func _process(_dt: float) -> void:
	if "--preview" in OS.get_cmdline_user_args() and clock_time > 5.5:
		get_viewport().get_texture().get_image().save_png("res://docs/preview.png")
		get_tree().quit()

func step(dt: float) -> void:
	if gallery:
		for p in players: p.tick(dt, false)
		return
	if not started or paused: return
	clock_time += dt
	phase_time += dt
	feedback_left -= dt
	cue_left = maxf(0, cue_left - dt)
	read_controls()
	if demo:
		demo_input()
	move_players(dt)
	if phase == "SERVE":
		var serving = players[server_index(server)]
		if charging or server == 1 or demo:
			var elapsed := clock_time - charge_start if charging else maxf(0, phase_time - 0.3)
			ball_pos = serving.position + Vector3(0, 1.3 + 4.2 * elapsed - 1.7 * elapsed * elapsed, -0.2 if server == 0 else 0.2)
			serving.prepare_contact("float" if serve_type == 0 else "power", maxf(0, 1.05 - elapsed))
		else:
			ball_pos = serving.position + Vector3(0, 1.3, -0.3 if server == 0 else 0.3)
		if server == 1 and phase_time > 1.4:
			serve_type = rng.randi_range(0, 1)
			serve_ball(1, rng.randf_range(0.5, 0.95))
	elif phase == "POINT":
		if phase_time > 2.0: reset_rally()
	elif airborne:
		var old := ball_pos
		ball_pos += ball_vel * dt + Vector3(0, -0.5 * G * dt * dt, 0)
		ball_vel.y -= G * dt
		flight_left -= dt
		if serve_type == 0 and phase in ["RECEIVE", "CPU_RECEIVE"] and test_rallies == 0:
			# Small, deterministic float perturbation, shared with intercept guidance.
			ball_vel.x += sin(clock_time * 19.0) * dt * 0.5
		if old.z * ball_pos.z < 0:
			var fraction := absf(old.z) / maxf(absf(old.z - ball_pos.z), 0.001)
			var net_y := lerpf(old.y, ball_pos.y, fraction)
			if net_y < 2.48 and absf(ball_pos.x) < 4.65:
				award(1 - last_touch, "RETE")
			elif not block_checked and test_rallies > 1:
				try_block()
		if phase != "POINT" and ball_pos.y <= 0.105:
			var inside := absf(ball_pos.x) <= 4.605 and absf(ball_pos.z) <= 9.105
			var floor_team := 0 if ball_pos.z > 0 else 1
			award(1 - floor_team if inside else 1 - last_touch, "PALLA A TERRA" if inside else "FUORI")
		elif phase != "POINT" and flight_left <= 0:
			var late_window := possession == 0 and phase in ["RECEIVE", "SET", "ATTACK"] and not armed and flight_left > -0.14
			if not late_window:
				match phase:
					"RECEIVE", "CPU_RECEIVE": receive_ball()
					"SET", "CPU_SET": set_ball()
					"ATTACK", "CPU_ATTACK": attack_ball()
	ball.position = ball_pos
	ball.rotation += Vector3(1.2, 0.7, 2.5) * dt
	shadow.position = Vector3(ball_pos.x, 0.034, ball_pos.z)
	shadow.scale = Vector3.ONE * (1.0 + maxf(ball_pos.y, 0) * 0.06)
	if not self_test:
		for i in 12: players[i].tick(dt, i == selected)

func try_block() -> void:
	block_checked = true
	var defender := 1 - last_touch
	var good_jump := clock_time - block_time > 0.08 and clock_time - block_time < 0.85
	var near := false
	for i in range(defender * 6, defender * 6 + mini(block_count, 3)):
		if absf(players[i].position.x + block_hand * 0.3 - ball_pos.x) < 0.7 and absf(players[i].position.z) < 1.8:
			near = true
	if good_jump and near and ball_pos.y < 3.6 and block_quality > 0.55:
		if rng.randf() < block_quality * (0.3 + block_count * 0.12):
			ball_vel.z *= -0.6
			ball_vel.y = -1.4
			last_touch = defender
			possession = 1 - defender
			touches[possession] = 0 # block is not one of the three team contacts
			# Predict a reachable dig on the actual deflected trajectory; do not relaunch it.
			var height := maxf(0, ball_pos.y - 1.05)
			var intercept_time := (ball_vel.y + sqrt(ball_vel.y * ball_vel.y + 2 * G * height)) / G
			flight_left = maxf(0.05, intercept_time)
			flight_target = ball_pos + ball_vel * flight_left + Vector3(0, -0.5 * G * flight_left * flight_left, 0)
			receiver = nearest(possession, flight_target)
			players[receiver].target = Vector3(flight_target.x, 0, flight_target.z)
			selected = receiver if possession == 0 else selected
			phase = "RECEIVE" if possession == 0 else "CPU_RECEIVE"
			armed = false
			input_quality = 0
			marker.position = Vector3(flight_target.x, 0.04, flight_target.z)
			marker.visible = true
			notice("MURO! · TOCCO A RETE", 1.0)
			beep(300, 0.05)

func move_players(dt: float) -> void:
	for i in 12:
		var p = players[i]
		p.motion_lock = maxf(0, p.motion_lock - dt)
		var side := 1.0 if i < 6 else -1.0
		if phase in ["CPU_ATTACK", "ATTACK"] and int(i / 6) != possession and i % 6 < block_count:
			var spread := (float(i % 6) - (block_count - 1) * 0.5) * 0.7
			p.target = Vector3(flight_target.x + spread, 0, side * 0.65)
			if possession == 0 and flight_left < 0.55:
				p.prepare_contact("block", flight_left + 0.12)
		elif i != receiver and i != setter and i != hitter and phase != "SERVE":
			var base: Vector3 = BASE[posmod(i % 6 - rotations[i / 6], 6)]
			base.z *= side
			p.target = base
		var movement: Vector3 = p.target - p.position
		movement.y = 0
		if movement.length() > 0.08 and p.motion_lock <= 0:
			p.position += movement.limit_length(5.8 * dt)
			if p.clip_name == "idle": p.play("run", 1.25, true)
		elif p.clip_name == "run": p.play("idle", 1, true)
		if i == selected and not demo:
			var input := stick(false)
			p.position += Vector3(input.x, 0, input.y) * dt * 4.5
		p.position.x = clampf(p.position.x, -5.7, 5.7)
		p.position.z = clampf(p.position.z, 0.25, 10.5) if i < 6 else clampf(p.position.z, -10.5, -0.25)
		if phase in ["ATTACK", "CPU_ATTACK"] and i == hitter and flight_left < 0.8:
			p.prepare_contact("attack", flight_left)
		elif phase in ["SET", "CPU_SET"] and i == setter and flight_left < 0.6:
			p.prepare_contact("fast_set" if fast_set else "set", flight_left)
		elif phase in ["RECEIVE", "CPU_RECEIVE"] and i == receiver and flight_left < 0.5:
			p.prepare_contact("receive", flight_left)

func demo_input() -> void:
	if phase == "SERVE" and server == 0 and phase_time > 1.25: serve_ball(0, 0.75)
	if phase in ["RECEIVE", "SET", "ATTACK"] and flight_left < 0.06 and not armed:
		if phase == "SET":
			set_dir = int(clock_time) % 4
			fast_set = int(clock_time) % 3 == 0
		armed = true
		input_quality = timing.quality(rng.randfn(0, 0.20), phase == "SET" and fast_set, pass_quality, 1.0)
		charge = 0.65
	if phase == "CPU_ATTACK":
		prediction = true
		block_count = Timing.blockers(true, fast_set, set_quality, committed_destination == 3)
		if flight_left < 0.12:
			block_time = clock_time
			block_quality = 0.9

func beep(hz: float, seconds: float) -> void:
	if self_test or synth == null: return
	var data := PackedByteArray()
	var count := int(22050 * seconds)
	data.resize(count * 2)
	for i in count:
		var value := sin(float(i) / 22050 * hz * TAU) * 1700 * (1.0 - float(i) / count)
		data.encode_s16(i * 2, int(value))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = data
	synth.stream = wav
	synth.play()

func run_tests() -> void:
	assert(clips.size() == 10, "Every selected source animation must load")
	var button := InputEventJoypadButton.new()
	button.device = 9
	button.button_index = JOY_BUTTON_X
	button.pressed = true
	assert(InputMap.event_is_action(button, "action"), "Xbox X / PS Square must map across controller IDs")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	assert(InputMap.event_is_action(key, "action"))
	var inspect_pose: Array[Transform3D] = clips.idle.pose(0.0, true)
	for bone in ["Hips", "Head", "LeftArm", "LeftForeArm", "LeftHand", "LeftUpLeg", "LeftLeg", "LeftFoot"]:
		var idx: int = clips.idle.names.find(bone)
		print("POSE ", bone, " index=", idx, " p=", inspect_pose[idx].origin if idx >= 0 else Vector3.ZERO)
	for clip in clips.values():
		assert(clip.frames > 0 and clip.names.size() == 145)
		var pose: Array[Transform3D] = clip.pose(clip.duration * 0.5, false)
		for transform in pose:
			assert(transform.origin.is_finite() and transform.basis.is_finite())
	assert(inspect_pose[clips.idle.names.find("Head")].origin.z > 100)
	assert(inspect_pose[clips.idle.names.find("LeftFoot")].origin.z < 35)
	assert(models.size() == 3 and models.body.triangle_count > 1000)
	assert(is_equal_approx(Timing.precision(0), 1.0))
	assert(is_equal_approx(Timing.precision(1), 0.7))
	assert(is_equal_approx(Timing.precision(0.5), 0.85))
	assert(Timing.blockers(true, false, 1, false) == 2)
	assert(Timing.blockers(false, true, 1, false) == 1)
	assert(Timing.blockers(true, false, 0.8, false) == 3)
	assert(Timing.blockers(false, false, 1, true) == 1)
	assert(timing.quality(0) > timing.quality(0.3))
	assert(timing.quality(0.3) > timing.quality(0.7))
	for direction in 4:
		var normal_time := 0.0
		for quick in [false, true]:
			possession = 0
			phase = "SET"
			setter = 1
			players[setter].position = Vector3(0, 0, 1.5)
			ball_pos = Vector3(0, 2.15, 1.5)
			armed = true
			input_quality = 1.0
			pass_quality = 1.0
			fast_set = quick
			set_dir = direction
			set_ball()
			assert(phase == "ATTACK")
			assert(absf(flight_target.x - [-3.4, 0.0, 3.4, 0.0][direction]) < 0.01)
			if quick: assert(flight_left < normal_time)
			else: normal_time = flight_left
			if direction == 3: assert(flight_target.z > 3.0)
	# Exercise contextual inputs and the actual serve fault/scoring branch.
	phase = "RECEIVE"
	armed = false
	flight_left = 0.02
	press_action()
	assert(armed and input_quality > 0.9)
	phase = "SERVE"
	server = 0
	charging = true
	charge_start = clock_time - 1.06
	var before: int = scores[1]
	release_action()
	assert(scores[1] == before + 1 and phase == "POINT")
	scores = [0, 0]
	rotations = [0, 0]
	server = 0
	test_points = 0
	test_contacts = 0
	test_rallies = 0
	max_rally = 0
	rng.seed = 194260
	reset_rally()
	print("SELF TEST PASS: source meshes, animation hierarchy, four set zones, fast variants, pipe, contextual input, overcharge scoring, precision, timing, block formations")

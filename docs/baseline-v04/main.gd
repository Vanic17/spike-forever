extends Node3D

const PSA = preload("res://src/psa.gd")
const Avatar = preload("res://src/avatar.gd")
const Arena = preload("res://src/arena.gd")
const MatchAudio = preload("res://src/match_audio.gd")
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
var match_audio: Node
var toss_active := false
var serve_pending := false
var serve_power := 0.0
var toss_origin := Vector3.ZERO
var toss_velocity := Vector3.ZERO
var toss_elapsed := 0.0
const TOSS_TIME := 1.12
var contact_log: Array[Dictionary] = []
var max_contact_gap := 0.0
var camera_focus := Vector3(0, 1.25, -0.7)
var travel := PackedFloat32Array([0,0,0,0,0,0,0,0,0,0,0,0])
var locked_cursor := 0.5
var block_rosters: Dictionary = {}
var dead_ball_bounces := 0
var point_formation: Array[Vector3] = []

func _ready() -> void:
	rng.seed = 194260
	setup_inputs()
	for name in ["idle", "relaxed", "ready", "walk", "backwalk", "backpedal", "run", "run_right", "shuffle_left", "shuffle_right", "receive", "set", "fast_set", "attack", "block", "float", "power", "serve_idle"]:
		if "--fallback-test" in OS.get_cmdline_user_args(): continue
		var clip = PSA.new()
		if clip.load_file("res://assets/active/" + name + ".psa"):
			clip.load_hierarchy("res://assets/active/skeleton.psk")
			clip.detect_contact(name)
			clips[name] = clip
			print("ANIMATION ", name, ": ", clip.frames, " frames / ", clip.names.size(), " bones / ", clip.duration, "s / contact ", clip.contact_offset)
	if not clips.is_empty():
		if not clips.has("idle"): clips["idle"] = clips.values()[0]
		for name in ["run", "receive", "set", "fast_set", "attack", "block", "float", "power", "serve_idle"]:
			if not clips.has(name): clips[name] = clips.idle
	var body = PSK.new()
	if not "--fallback-test" in OS.get_cmdline_user_args() and body.load_file("res://assets/active/body.psk"):
		models["body"] = body
		for name in ["cloth", "head", "hair", "eyes", "shoes"]:
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
	match_audio = MatchAudio.new()
	match_audio.enabled = not ("--self-test" in OS.get_cmdline_user_args() or "--fallback-test" in OS.get_cmdline_user_args())
	add_child(match_audio)
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
		print("SIMULATION points=", test_points, " contacts=", test_contacts, " longest_rally=", max_rally, " clock=", clock_time, " max_hand_gap=", max_contact_gap)
		print("PLAYER TRAVEL METRES ", travel)
		var report := {"points":test_points, "contacts":test_contacts, "longest_rally":max_rally, "maximum_hand_ball_gap_m":max_contact_gap, "travel_metres":Array(travel), "contact_events":contact_log}
		var report_path := "res://docs/revision-contact-report.json" if "--self-test" in OS.get_cmdline_user_args() else "res://docs/fallback-contact-report.json"
		var report_file := FileAccess.open(report_path, FileAccess.WRITE)
		if report_file: report_file.store_string(JSON.stringify(report, "  "))
		assert(max_contact_gap <= 0.18)
		for distance in travel: assert(distance > 1.0, "Every athlete must participate in coverage")
		get_tree().quit(0 if test_points >= 16 and test_contacts > 35 and max_rally >= 6 else 1)
	if "--preview" in OS.get_cmdline_user_args() or "--demo-capture" in OS.get_cmdline_user_args():
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

func build_arena() -> void:
	var arena = Arena.new()
	add_child(arena)
	ball = arena.ball
	shadow = arena.shadow
	marker = arena.marker
	camera = arena.camera
	set_camera()

func set_camera() -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 48 if camera_mode == 0 else 50
	camera.position = Vector3(0, 9.8, 18.4) if camera_mode == 0 else Vector3(0, 11.5, 23.0)
	camera_focus = Vector3(0, 0.7, -0.5)
	camera.look_at(camera_focus)

func update_camera(dt: float) -> void:
	var origin := Vector3(0, 9.8, 18.4) if camera_mode == 0 else Vector3(0, 11.5, 23.0)
	var focus := Vector3(clampf(ball_pos.x * 0.11, -0.5, 0.5), 0.7 + maxf(0, ball_pos.y - 3.2) * 0.04, -0.5)
	camera_focus = camera_focus.lerp(focus, 1.0 - exp(-2.5 * dt))
	camera.position = camera.position.lerp(origin + Vector3(clampf(ball_pos.x * 0.08, -0.35, 0.35), 0, 0), 1.0 - exp(-1.6 * dt))
	camera.look_at(camera_focus)

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
	if event.is_action_pressed("serve_type") and phase == "SERVE" and not toss_active:
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
		if not toss_active: begin_serve_toss()
	elif phase == "ATTACK" and not armed:
		charging = true
		charge_start = clock_time
	elif phase in ["RECEIVE", "SET"] and not armed:
		armed = true
		locked_cursor = timing.cursor(flight_left, fast_set if phase == "SET" else false, pass_quality)
		input_quality = timing.quality(flight_left, fast_set if phase == "SET" else false, pass_quality, difficulty_scale())
		show_quality(input_quality, flight_left)
	elif phase == "CPU_ATTACK" and clock_time - block_time > 0.9:
		block_time = clock_time
		locked_cursor = timing.cursor(flight_left - 0.12, fast_set, 0.6)
		block_quality = timing.quality(flight_left - 0.12, fast_set, 0.6, difficulty_scale())
		for i in block_count:
			var blocker: int = blocking_players(0)[i]
			players[blocker].prepare_contact("block", 0.22)
		show_quality(block_quality, flight_left - 0.12)

func release_action() -> void:
	if not charging: return
	charge = clampf((clock_time - charge_start) / (1.05 if phase == "SERVE" else 0.75), 0, 1.5)
	charging = false
	if phase == "SERVE" and server == 0:
		if charge > 1.00001:
			award(1, "FALLO DI SERVIZIO · SOVRACCARICO")
		else:
			input_quality = timing.quality((clock_time - charge_start) - 1.02, false, 1, difficulty_scale())
			locked_cursor = timing.cursor((clock_time - charge_start) - 1.02)
			serve_power = charge
			serve_pending = true
	elif phase == "ATTACK" and not armed:
		armed = true
		locked_cursor = timing.cursor(flight_left)
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
	toss_active = false
	serve_pending = false
	for i in 12:
		var p = players[i]
		p.motion_lock = 0
		var base: Vector3 = BASE[posmod(i % 6 - rotations[i / 6], 6)]
		base.z *= 1 if i < 6 else -1
		p.position = base
		p.target = base
		p.velocity = Vector3.ZERO
		p.acceleration = Vector3.ZERO
		p.steering_ready = false
		p.foot_planted = [false, false]
		p.play("idle", 1, true)
	selected = server_index(0)
	var serving = players[server_index(server)]
	serving.position = Vector3(3, 0, 9.7 * (1 if server == 0 else -1))
	serving.target = serving.position
	serving.play("serve_idle", 1, true)
	serving.prepare_contact("serve_idle", 0)
	serving.play("serve_idle", 1, true)
	serving.tick(0, false)
	ball_pos = serving.current_hand(true) + Vector3(0, 0.11, 0)
	ball_vel = Vector3.ZERO
	set_phase("SERVE")
	block_time = -100
	block_checked = false
	block_rosters.clear()
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

func attacking_player(team: int, point: Vector3, pipe: bool, exclude: int) -> int:
	var best := -1
	var distance := INF
	for i in range(team * 6, team * 6 + 6):
		var front_row := posmod(i % 6 - rotations[team], 6) < 3
		if i == exclude or front_row == pipe: continue
		var candidate: float = players[i].position.distance_to(point)
		if candidate < distance:
			distance = candidate
			best = i
	return best if best >= 0 else nearest(team, point, exclude)

func launch(target: Vector3, seconds: float) -> void:
	flight_target = target
	flight_left = seconds
	ball_vel = (target - ball_pos) / seconds + Vector3(0, G * seconds * 0.5, 0)
	airborne = true
	marker.position = Vector3(target.x, 0.04, target.z)
	marker.visible = true

func contact_height(action: String) -> float:
	return clips[action].contact_offset.y if clips.has(action) else players[0].contact_local(action).y

func begin_serve_toss() -> void:
	charging = server == 0
	charge_start = clock_time
	toss_active = true
	serve_pending = false
	toss_elapsed = 0
	toss_origin = ball_pos
	var action := "float" if serve_type == 0 else "power"
	var point: Vector3 = players[server_index(server)].contact_world(action)
	toss_velocity = (point - toss_origin) / TOSS_TIME + Vector3(0, G * TOSS_TIME * 0.5, 0)
	players[server_index(server)].prepare_contact(action, TOSS_TIME)

func validate_contact(index: int, action: String) -> bool:
	var player = players[index]
	if player.contact_world(action).distance_to(ball_pos) > 0.35: return false
	player.reach_target = ball_pos
	player.reach_weight = 1
	player.reach_action = action
	player.prepare_contact(action, 0)
	var actual: Vector3 = player.current_hand(false)
	if action in ["receive", "set", "fast_set", "block"]:
		actual = (actual + player.current_hand(true)) * 0.5 + Vector3(0, 0.07 if action != "block" else 0.0, 0)
	var distance := actual.distance_to(ball_pos)
	if not player.skeleton: distance = player.contact_world(action).distance_to(ball_pos)
	if distance > 0.18: return false
	max_contact_gap = maxf(max_contact_gap, distance)
	contact_log.append({"action":action, "player":index, "gap":distance, "ball":ball_pos, "hands":actual, "time":clock_time})
	if contact_log.size() > 2048: contact_log.pop_front()
	if match_audio: match_audio.contact("serve" if action in ["float", "power"] else ("set" if action == "fast_set" else action), ball_pos, 0.7)
	return true

func serve_ball(team: int, power: float) -> void:
	last_touch = team
	possession = 1 - team
	var s := 1.0 if possession == 0 else -1.0
	var target := Vector3(clampf(aim.x * 2.8, -3.8, 3.8), 1.05, s * (5.2 + aim.y * 1.5))
	target.y = contact_height("receive")
	if team == 1: target.x = rng.randf_range(-3.1, 3.1)
	var contact_quality := input_quality if team == 0 and not demo else 0.92
	var dispersion := 2.2 * (1.0 - contact_quality)
	target.x += rng.randf_range(-dispersion, dispersion)
	target.z += rng.randf_range(-dispersion, dispersion)
	if not validate_contact(server_index(team), "float" if serve_type == 0 else "power"):
		award(1 - team, "SERVIZIO · CONTATTO MANCATO")
		return
	toss_active = false
	receiver = nearest(possession, target)
	players[receiver].target = players[receiver].stance_for_contact("receive", target)
	selected = receiver if possession == 0 else 1
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	launch(target, (1.12 if serve_type == 0 else 0.90) + (1.0 - power) * 0.30)

func reachable(index: int, point: Vector3, reach: float = 1.4) -> bool:
	return Vector2(players[index].position.x - point.x, players[index].position.z - point.z).length() < reach

func receive_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.22), false, 0.6, 1.0)
	if (possession == 0 and not armed) or q < 0.16 or not validate_contact(receiver, "receive"):
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
	target.y = contact_height("set")
	setter = nearest(possession, target, receiver)
	players[setter].target = players[setter].stance_for_contact("set", target)
	selected = setter if possession == 0 else 1
	fast_set = false
	set_phase("SET" if possession == 0 else "CPU_SET")
	launch(target, 1.05 + (1.0 - q) * 0.45)

func set_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.15), fast_set, pass_quality, 1.0)
	if (possession == 0 and not armed) or q < 0.12 or not validate_contact(setter, "fast_set" if fast_set else "set"):
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
	target.y = contact_height("attack")
	hitter = attacking_player(possession, target, destination == 3, setter)
	players[hitter].target = players[hitter].stance_for_contact("attack", target)
	selected = hitter if possession == 0 else nearest(0, Vector3(x, 0, 0.6))
	var flight := 0.62 if fast_set else 1.02 + (1 - q) * 1.25
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
	block_rosters.clear()
	if possession == 1: selected = blocking_players(0)[0]
	notice((["BANDA · ZONA 4", "CENTRO · ZONA 3", "OPPOSTO · ZONA 2", "PIPE · ZONA 6"][destination]) + (" / VELOCE" if fast_set else " / ALTA"), 0.8)

func attack_ball() -> void:
	var q := input_quality if possession == 0 else timing.quality(rng.randfn(0, 0.17), false, pass_quality, 1.0)
	if (possession == 0 and not armed) or q < 0.12 or not validate_contact(hitter, "attack"):
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
	target.y = contact_height("receive")
	if attacker == 1: target.x = rng.randf_range(-3.8, 3.8)
	target += Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread, spread))
	# The net's geometry also checks the resulting ballistic arc, including pipe attacks.
	possession = 1 - attacker
	touches[possession] = 0
	receiver = nearest(possession, target)
	players[receiver].target = players[receiver].stance_for_contact("receive", target)
	selected = receiver if possession == 0 else selected
	var saved_block_time := block_time
	var saved_block_quality := block_quality
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	charge = power
	block_time = saved_block_time
	block_quality = saved_block_quality
	launch(target, 0.62 - power * 0.20)
	block_checked = false
	if attacker == 0:
		block_time = clock_time - rng.randf_range(0.05, 0.4)
		block_quality = rng.randf_range(0.45, 1)
		for i in block_count:
			players[blocking_players(1)[i]].prepare_contact("block", 0.1)

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
	var missing_input := possession == 0 and not armed
	var poor_timing := possession == 0 and armed and input_quality < 0.16
	# No magnetic rescue: let gravity carry the missed ball to the floor.
	phase = "LOOSE"
	flight_left = 100
	marker.visible = false
	notice("PREMI QUADRATO PER COLPIRE" if missing_input else ("TIMING ERRATO" if poor_timing else "PALLA FUORI PORTATA"), 1.1)

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
	# A whistle ends scoring and contacts, not the physical trajectory.
	airborne = true
	ball_pos.y = maxf(0.105, ball_pos.y)
	if reason == "RETE": ball_vel.z *= -0.22
	point_formation.clear()
	for i in 12:
		var side := 1.0 if i < 6 else -1.0
		var centre := Vector3(-0.7 if i < 6 else 0.7, 0, side * 3.3)
		var angle := float(i % 6) * TAU / 6
		point_formation.append(centre + Vector3(cos(angle), 0, sin(angle)) * 1.2)
	marker.visible = false
	test_points += 1
	test_rallies = 0
	if match_audio:
		match_audio.contact("cheer", Vector3(0, 2, -15), 0.6)

func _physics_process(dt: float) -> void:
	if self_test:
		return
	else:
		step(dt)

func _process(_dt: float) -> void:
	if camera and not self_test: update_camera(_dt)
	if "--preview" in OS.get_cmdline_user_args() and clock_time > 5.5:
		get_viewport().get_texture().get_image().save_png("res://docs/preview.png")
		get_tree().quit()

func step(dt: float) -> void:
	# Substep to the exact contact event; never validate an overshot ball.
	if airborne and flight_left > 0.00001 and flight_left < dt and phase != "POINT":
		var contact_dt := flight_left
		step(contact_dt)
		step(dt - contact_dt)
		return
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
		if toss_active:
			toss_elapsed = minf(TOSS_TIME, toss_elapsed + dt)
			ball_pos = toss_origin + toss_velocity * toss_elapsed + Vector3(0, -0.5 * G * toss_elapsed * toss_elapsed, 0)
			serving.prepare_contact("float" if serve_type == 0 else "power", TOSS_TIME - toss_elapsed)
			if server == 1 and toss_elapsed > 0.98:
				serve_pending = true
				serve_power = 0.75
			if toss_elapsed >= TOSS_TIME:
				if serve_pending: serve_ball(server, serve_power)
				else: award(1 - server, "FALLO · RILASCIO OLTRE IL LIMITE")
		else:
			ball_pos = serving.current_hand(true) + Vector3(0, 0.11, 0)
		if server == 1 and phase_time > 0.65 and not toss_active:
			serve_type = rng.randi_range(0, 1)
			begin_serve_toss()
	elif phase == "POINT":
		step_dead_ball(dt)
		if phase_time > 4.5: reset_rally()
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
		elif phase != "POINT" and flight_left <= 0.00001:
			if true:
				match phase:
					"RECEIVE", "CPU_RECEIVE": receive_ball()
					"SET", "CPU_SET": set_ball()
					"ATTACK", "CPU_ATTACK": attack_ball()
	ball.position = ball_pos
	ball.rotation += Vector3(1.2, 0.7, 2.5) * dt
	shadow.position = Vector3(ball_pos.x, 0.034, ball_pos.z)
	shadow.scale = Vector3.ONE * (1.0 + maxf(ball_pos.y, 0) * 0.06)
	for i in 12: players[i].tick(dt, i == selected, not self_test)

func step_dead_ball(dt: float) -> void:
	# Short substeps retain bounce height even after a hard downward spike.
	var remaining := dt
	while remaining > 0.000001:
		var h := minf(remaining, 1.0 / 240.0)
		remaining -= h
		ball_pos += ball_vel * h + Vector3(0, -0.5 * G * h * h, 0)
		ball_vel.y -= G * h
		if ball_pos.y < 0.105:
			ball_pos.y = 0.105
			if ball_vel.y < -0.65:
				var impact := -ball_vel.y
				ball_vel.y = impact * 0.76
				ball_vel.x *= 0.88
				ball_vel.z *= 0.88
				dead_ball_bounces += 1
				if match_audio: match_audio.contact("bounce", ball_pos, clampf(impact / 12.0, 0.15, 0.9))
			else:
				ball_vel.y = 0
				ball_vel.x = move_toward(ball_vel.x, 0, h * 1.6)
				ball_vel.z = move_toward(ball_vel.z, 0, h * 1.6)
		ball_vel.x *= exp(-0.06 * h)
		ball_vel.z *= exp(-0.06 * h)

func try_block() -> void:
	block_checked = true
	var defender := 1 - last_touch
	var good_jump := clock_time - block_time > 0.08 and clock_time - block_time < 0.85
	var near := false
	for i in blocking_players(defender):
		var player = players[i]
		if player.clip_name != "block": continue
		player.apply_pose(0)
		var left: Vector3 = player.current_hand(true)
		var right: Vector3 = player.current_hand(false)
		var nearest_point := Geometry3D.get_closest_point_to_segment(ball_pos, left, right)
		if nearest_point.distance_to(ball_pos) < 0.32: near = true
	if good_jump and near and block_quality > 0.4:
		if true:
			ball_vel.z *= -0.6
			ball_vel.y = -1.4
			last_touch = defender
			possession = 1 - defender
			touches[possession] = 0 # block is not one of the three team contacts
			# Predict a reachable dig on the actual deflected trajectory; do not relaunch it.
			var height := maxf(0, ball_pos.y - contact_height("receive"))
			var intercept_time := (ball_vel.y + sqrt(ball_vel.y * ball_vel.y + 2 * G * height)) / G
			flight_left = maxf(0.05, intercept_time)
			flight_target = ball_pos + ball_vel * flight_left + Vector3(0, -0.5 * G * flight_left * flight_left, 0)
			receiver = nearest(possession, flight_target)
			players[receiver].target = players[receiver].stance_for_contact("receive", flight_target)
			selected = receiver if possession == 0 else selected
			phase = "RECEIVE" if possession == 0 else "CPU_RECEIVE"
			armed = false
			input_quality = 0
			marker.position = Vector3(flight_target.x, 0.04, flight_target.z)
			marker.visible = true
			notice("MURO! · TOCCO A RETE", 1.0)
			if match_audio: match_audio.contact("block", ball_pos, 0.85)

func blocking_players(team: int) -> Array[int]:
	if block_rosters.has(team):
		var result: Array[int] = []
		for i in mini(block_count, block_rosters[team].size()): result.append(block_rosters[team][i])
		return result
	var candidates: Array[int] = []
	for i in range(team * 6, team * 6 + 6):
		var zone := posmod(i % 6 - rotations[team], 6)
		if zone < 3: candidates.append(i)
	candidates.sort_custom(func(a, b): return players[a].position.distance_to(Vector3(flight_target.x, 0, 0)) < players[b].position.distance_to(Vector3(flight_target.x, 0, 0)))
	block_rosters[team] = candidates.duplicate()
	candidates.resize(mini(block_count, candidates.size()))
	return candidates

func move_players(dt: float) -> void:
	var action_actor := -1
	var action := ""
	match phase:
		"RECEIVE", "CPU_RECEIVE":
			action_actor = receiver
			action = "receive"
		"SET", "CPU_SET":
			action_actor = setter
			action = "fast_set" if fast_set else "set"
		"ATTACK", "CPU_ATTACK":
			action_actor = hitter
			action = "attack"
	var blockers: Array = blocking_players(1 - possession) if phase in ["ATTACK", "CPU_ATTACK"] else []
	for i in 12:
		var p = players[i]
		p.reach_weight = maxf(0, p.reach_weight - dt * 5)
		p.motion_lock = maxf(0, p.motion_lock - dt)
		var side := 1.0 if i < 6 else -1.0
		var zone := posmod(i % 6 - rotations[int(i / 6)], 6)
		var base: Vector3 = BASE[zone]
		base.z *= side
		var team := int(i / 6)
		if i == action_actor:
			# Solving the stance from the source hand event aligns animation and flight.
			p.target = p.stance_for_contact(action, flight_target)
		elif i in blockers:
			var slot := blockers.find(i)
			var spread := (float(slot) - (blockers.size() - 1) * 0.5) * 0.65
			p.target = Vector3(clampf(flight_target.x + spread, -4.0, 4.0), 0, side * 0.48)
			if team == 1 and flight_left < 0.6: p.prepare_contact("block", flight_left + 0.14)
		elif phase == "SERVE":
			if i != server_index(server): p.target = base + Vector3(0.15 * ball_pos.x if team != server else 0, 0, 0)
		elif phase not in ["POINT", "LOOSE"]:
			p.target = tactical_target(i, zone, team, side)
		elif phase == "POINT" and point_formation.size() == 12:
			p.target = point_formation[i]
		# Teammates react at different rates and keep a stable position instead
		# of chasing every centimetre of a continuously moving tactical marker.
		var urgent := i == action_actor or i in blockers
		if not p.steering_ready:
			p.steering_target = p.position
			p.steering_ready = true
		if urgent:
			p.steering_target = p.target
		elif p.steering_target.distance_to(p.target) > 0.22:
			p.steering_target = p.steering_target.lerp(p.target, 1.0 - exp(-dt * (5.5 + float(i % 4))))
		var movement: Vector3 = p.steering_target - p.position
		movement.y = 0
		var max_speed := 7.2 if urgent else (1.6 if phase == "POINT" else 4.0)
		var arrival_speed := movement.length() * 2.5
		if urgent: arrival_speed = movement.length() / maxf(0.055, flight_left - 0.12)
		if urgent: arrival_speed = minf(arrival_speed, sqrt(2.0 * 22.0 * movement.length()) * 0.72)
		var desired := movement.normalized() * minf(max_speed, arrival_speed)
		if movement.length() < (0.045 if urgent else 0.18): desired = Vector3.ZERO
		# Mild separation prevents two athletes occupying the same contact space.
		if i != action_actor:
			for j in range(team * 6, team * 6 + 6):
				if i == j: continue
				var delta: Vector3 = p.position - players[j].position
				delta.y = 0
				if delta.length() < 0.75 and delta.length() > 0.01: desired += delta.normalized() * (0.75 - delta.length()) * 3.0
		if i == selected and not demo:
			var input := stick(false)
			desired += Vector3(input.x, 0, input.y) * 5.5
		if phase == "SERVE" and i == server_index(server): desired = Vector3.ZERO
		if p.motion_lock > 0: desired *= 0.35
		var wanted_accel: Vector3 = ((desired.limit_length(max_speed) - p.velocity) / (0.055 if urgent else 0.12)).limit_length(28.0 if urgent else 12.0)
		p.acceleration = wanted_accel if urgent else p.acceleration.move_toward(wanted_accel, 70.0 * dt)
		p.velocity = (p.velocity + p.acceleration * dt).limit_length(max_speed)
		if desired.length() < 0.01 and p.velocity.length() < 0.10:
			p.velocity = Vector3.ZERO
			p.acceleration = Vector3.ZERO
		p.position += p.velocity * dt
		travel[i] += p.velocity.length() * dt
		p.position.x = clampf(p.position.x, -5.7, 5.7)
		p.position.z = clampf(p.position.z, 0.25, 10.5) if i < 6 else clampf(p.position.z, -10.5, -0.25)
		var facing := PI if team == 0 else 0.0
		if phase != "SERVE" and i != action_actor and not i in blockers:
			var look: Vector3 = ball_pos - p.position
			if phase == "POINT": look = Vector3(0, 0, side * 3.3) - p.position
			facing = atan2(look.x, look.z)
			# Sprint facing the route, then open the shoulders to the ball on braking.
			if p.velocity.length() > 2.6 and movement.length() > 0.9:
				facing = atan2(p.velocity.x, p.velocity.z)
		var turn := wrapf(facing - p.rotation.y, -PI, PI)
		p.rotation.y += clampf(turn * 8.0, -7.0 if urgent else -3.8, 7.0 if urgent else 3.8) * dt
		p.look_target = Vector3(0, 1.7, side * 3.3) if phase == "POINT" else ball_pos
		p.ready_stance = (team == possession and phase in ["RECEIVE", "CPU_RECEIVE"] and (zone >= 3 or i == receiver)) or (team != possession and phase in ["ATTACK", "CPU_ATTACK"])
		if phase == "SERVE": p.ready_stance = team != server and zone >= 3
		# Wings waiting to approach and setters waiting to penetrate stand tall;
		# only passers and floor defenders stay in the low defensive posture.
		p.relaxed_stance = not p.ready_stance and i != action_actor and not i in blockers
		p.locomotion(p.velocity.length(), dt)
		if i == action_actor and flight_left < (0.60 if action == "attack" else 0.38):
			p.prepare_contact(action, flight_left)
			p.reach_action = action
			p.reach_target = flight_target
			p.reach_weight = 1.0 - smoothstep(0.04, 0.22, flight_left)
		p.hand_adjust = block_hand if team == 0 and clock_time - block_time < 0.7 else 0
		if p.velocity.length() > 1.8 and p.step_cooldown <= 0 and not self_test:
			if match_audio: match_audio.contact("step", p.position, 0.35)
			p.step_cooldown = 0.32 + float(i % 3) * 0.025

func tactical_target(index: int, zone: int, team: int, side: float) -> Vector3:
	var own_ball := team == possession
	var receiving := phase in ["RECEIVE", "CPU_RECEIVE"]
	var setting := phase in ["SET", "CPU_SET"]
	var attacking := phase in ["ATTACK", "CPU_ATTACK"]
	var lane: float = [-3.0, 0.0, 3.0, 3.1, 0.0, -3.1][zone]
	if own_ball:
		if receiving or setting:
			# Setter penetrates; wings open outside the court before approaching.
			var designated_setter := team * 6 + posmod(1 + rotations[team], 6)
			if index == designated_setter and index != receiver:
				return Vector3(0.45, 0, side * 1.6)
			if zone < 3:
				return Vector3(lane * 1.25, 0, side * (2.8 if zone == 1 else 3.5))
			# Non-receivers cover the pass and prepare a back-row option.
			return Vector3(lane + clampf(flight_target.x * 0.18, -0.5, 0.5), 0, side * (4.6 if setting else 5.8))
		if attacking:
			# Two close cover players, remaining players in deeper staggered cover.
			var close_cover := zone < 3 or index == setter
			return Vector3(clampf(lerpf(lane, flight_target.x, 0.42 if close_cover else 0.18), -4.1, 4.1), 0, side * (2.7 if close_cover else 5.4))
	else:
		if attacking:
			# Floor defence covers line and diagonal behind the committed block.
			var attack_x := flight_target.x
			if zone < 3:
				return Vector3(lane, 0, side * 3.3)
			var shift := clampf(attack_x * 0.22, -0.75, 0.75)
			return Vector3(clampf(lane + shift, -4.0, 4.0), 0, side * (7.2 if zone == 4 else 5.8))
		# Read the pass with front row at the net, back row in defensive lanes.
		return Vector3(lane + clampf(ball_pos.x * 0.14, -0.5, 0.5), 0, side * (0.85 if zone < 3 else 6.0))
	return Vector3(lane, 0, side * 5.0)

func demo_input() -> void:
	if phase == "SERVE" and server == 0:
		if phase_time > 0.45 and not toss_active: begin_serve_toss()
		if charging and toss_elapsed > 0.98: release_action()
	if phase in ["RECEIVE", "SET", "ATTACK"] and flight_left < 0.06 and not armed:
		if phase == "SET":
			set_dir = int(clock_time) % 4
			fast_set = int(clock_time) % 3 == 0
		armed = true
		locked_cursor = timing.cursor(flight_left, phase == "SET" and fast_set, pass_quality)
		input_quality = timing.quality(rng.randfn(0, 0.20), phase == "SET" and fast_set, pass_quality, 1.0)
		charge = 0.65
	if phase == "CPU_ATTACK":
		prediction = true
		block_count = Timing.blockers(true, fast_set, set_quality, committed_destination == 3)
		if flight_left < 0.14 and clock_time - block_time > 0.9:
			press_action()
			block_quality = 0.9

func run_tests() -> void:
	assert(clips.size() == 18, "Every selected source animation must load")
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
	assert(models.size() == 6 and models.body.triangle_count > 1000)
	assert(is_equal_approx(Timing.precision(0), 1.0))
	assert(is_equal_approx(Timing.precision(1), 0.7))
	assert(is_equal_approx(Timing.precision(0.5), 0.85))
	assert(Timing.blockers(true, false, 1, false) == 2)
	assert(Timing.blockers(false, true, 1, false) == 1)
	assert(Timing.blockers(true, false, 0.8, false) == 3)
	assert(Timing.blockers(false, false, 1, true) == 1)
	assert(timing.quality(0) > timing.quality(0.3))
	assert(timing.quality(1.0 / timing.cursor_speed) > 0.99, "Every visible green crossing must be accepted")
	for direction in 4:
		var normal_time := 0.0
		for quick in [false, true]:
			possession = 0
			phase = "SET"
			setter = 1
			ball_pos = Vector3(0, contact_height("fast_set" if quick else "set"), 1.5)
			players[setter].position = players[setter].stance_for_contact("fast_set" if quick else "set", ball_pos)
			players[setter].rotation.y = PI
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
	test_manual_reception()
	test_bounce_and_animation()
	scores = [0, 0]
	rotations = [0, 0]
	server = 0
	test_points = 0
	test_contacts = 0
	test_rallies = 0
	max_rally = 0
	max_contact_gap = 0
	contact_log.clear()
	rng.seed = 194260
	reset_rally()
	print("SELF TEST PASS: source meshes, animation hierarchy, four set zones, fast variants, pipe, contextual input, overcharge scoring, precision, timing, block formations")

func test_manual_reception() -> void:
	# Regression uses the same event handler as a real controller, not demo_input.
	for fps in [30, 60, 120]:
		for early in [true, false]:
			reset_rally()
			started = true
			demo = false
			paused = false
			possession = 0
			receiver = 4
			selected = receiver
			last_touch = 1
			set_phase("RECEIVE")
			var target := Vector3(0, contact_height("receive"), 5.2)
			players[receiver].position = players[receiver].stance_for_contact("receive", target)
			players[receiver].rotation.y = PI
			ball_pos = Vector3(0, 3.2, -5)
			serve_type = 1
			launch(target, 1.0 / timing.cursor_speed)
			var event := InputEventJoypadButton.new()
			event.device = 9
			event.button_index = JOY_BUTTON_X
			event.pressed = true
			var sent := false
			for frame in 180:
				if not sent and (early or flight_left <= 0.04):
					_unhandled_input(event)
					assert(armed and input_quality > 0.9, "Square must buffer a visible green confirmation")
					sent = true
				step(1.0 / fps)
				if phase != "RECEIVE": break
			assert(phase == "SET", "Manual Square reception must physically return the ball at every tested frame rate")
			assert(pass_quality > 0.9)
	# A button does not rescue an athlete outside physical reach.
	ball_pos = Vector3(5.5, contact_height("receive"), 9)
	players[receiver].position = Vector3(-4, 0, 2)
	assert(not validate_contact(receiver, "receive"))
	print("MANUAL INPUT PASS: Square through event handler, early green and near contact, 30/60/120 Hz; unreachable ball rejected")

func test_bounce_and_animation() -> void:
	var original_enabled: bool = match_audio.enabled
	match_audio.enabled = false
	var ending_heights: Array[float] = []
	for fps in [30, 60, 120]:
		ball_pos = Vector3(0, 3, 4)
		ball_vel = Vector3(2, -4, 1)
		var before_bounces := dead_ball_bounces
		var before_scores := scores.duplicate()
		for frame in fps * 3: step_dead_ball(1.0 / fps)
		assert(dead_ball_bounces - before_bounces >= 2, "Dead ball must continue bouncing after the whistle")
		assert(scores == before_scores and ball_pos.x > 2.0 and ball_pos.y >= 0.105)
		ending_heights.append(ball_pos.y)
	assert(absf(ending_heights.max() - ending_heights.min()) < 0.025, "Bounce must remain stable across frame rates")
	var p = players[0]
	# Exercise the rendered rig: locomotion, transition, feet IK and landing.
	for frame in 150:
		p.velocity = Vector3(2, 0, -2) if frame < 70 else Vector3.ZERO
		p.position += p.velocity / 60.0
		p.look_target = Vector3(1, 3, -3)
		p.locomotion(p.velocity.length(), 1.0 / 60.0)
		p.tick(1.0 / 60.0, false, true)
		for transform in p.last_pose: assert(transform.origin.is_finite() and transform.basis.is_finite())
	assert(p.foot_corrections > 0, "Foot planting must execute on the actual skinned athlete")
	# A local-space blend must preserve limb lengths when directions change.
	var clip = clips.run
	var a: Array[Transform3D] = clip.pose(0, false)
	var b: Array[Transform3D] = clip.pose(clip.duration * 0.5, false)
	var blended: Array[Transform3D] = p.blend_hierarchy(a, b, 0.5, clip.parents)
	for bone in ["LeftLeg", "RightLeg", "LeftForeArm", "RightForeArm"]:
		var index: int = clip.names.find(bone)
		var parent: int = clip.parents[index]
		var expected: float = (a[index].origin.distance_to(a[parent].origin) + b[index].origin.distance_to(b[parent].origin)) * 0.5
		assert(absf(blended[index].origin.distance_to(blended[parent].origin) - expected) < 0.05, "Blending must preserve limb length")
	p.prepare_contact("attack", 0)
	for frame in 24:
		p.locomotion(0, 1.0 / 60.0)
		p.tick(1.0 / 60.0, false, true)
	assert(p.clip_name == "attack", "Attack must retain its landing instead of cutting straight to idle")
	match_audio.enabled = original_enabled
	print("MOTION PASS: local limb lengths, planted feet, head tracking, full attack landing; post-point bouncing at 30/60/120 Hz")

func _exit_tree() -> void:
	var assets = preload("res://src/source_assets.gd")
	assets.textures.clear()
	assets.files.clear()
	assets.scenes.clear()

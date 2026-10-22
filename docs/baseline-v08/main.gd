extends Node3D

const PSA = preload("res://src/psa.gd")
const Avatar = preload("res://src/avatar.gd")
const Arena = preload("res://src/arena.gd")
const MatchAudio = preload("res://src/match_audio.gd")
const Timing = preload("res://src/timing.gd")
const HUD = preload("res://src/hud.gd")
const PSK = preload("res://src/psk.gd")
const Tactics = preload("res://src/tactics.gd")
const BallFlight = preload("res://src/ball_flight.gd")
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
var charge_button := "action"
var setter_dump := false
var late_receive := false
var receive_deadline := 0.0
var block_helper_x := 0.0
var last_power := 0.0
var last_precision := 1.0
var last_serve_fault := ""
var block_rosters: Dictionary = {}
var dead_ball_bounces := 0
var point_formation: Array[Vector3] = []
var block_orders: Dictionary = {}
var block_anchor := 0.0
var minimum_player_gap := INF
var minimum_block_gap := INF
var collision_stops := 0
var passing_sides: Dictionary = {}
var blocking_team := -1
var attack_serial := 0
var block_commanded := false
var block_jumps: Dictionary = {}
var block_jump_log: Array[Dictionary] = []
var planned_direction := 0
var planned_fast := false
var planned_hitter := -1
var play_log: Array[Dictionary] = []
var flight_spin := Vector3.ZERO
var net_contacts := 0
var last_ai_direction := -1
var support_travel := PackedFloat32Array([0,0,0,0,0,0,0,0,0,0,0,0])

func _ready() -> void:
	rng.seed = 194260
	setup_inputs()
	for name in ["idle", "relaxed", "ready", "block_ready", "walk", "backwalk", "backpedal", "run", "run_right", "shuffle_left", "shuffle_right", "receive", "recovery", "dump", "set", "fast_set", "attack", "block", "float", "power", "serve_idle"]:
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
	if "--controls-test" in OS.get_cmdline_user_args():
		self_test = true
		test_charge_and_context_controls()
		test_manual_reception()
		get_tree().quit()
		return
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
		var jump_keys: Dictionary = {}
		for event in block_jump_log:
			var key := str(event.attack_id) + ":" + str(event.player)
			assert(not jump_keys.has(key), "One block takeoff per athlete per attack")
			jump_keys[key] = true
		var report := {"points":test_points, "contacts":test_contacts, "longest_rally":max_rally, "maximum_hand_ball_gap_m":max_contact_gap, "minimum_player_spacing_m":minimum_player_gap, "minimum_block_spacing_m":minimum_block_gap, "collision_avoidances":collision_stops, "travel_metres":Array(travel), "support_travel_metres":Array(support_travel), "contact_events":contact_log, "planned_attacks":play_log, "block_jump_events":block_jump_log, "duplicate_block_jumps":0, "net_contacts":net_contacts}
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
	var bindings := {"action": [KEY_SPACE, JOY_BUTTON_A], "alternate": [KEY_Q, JOY_BUTTON_X], "dump": [KEY_E, JOY_BUTTON_B], "start": [KEY_ENTER, JOY_BUTTON_START]}
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
	if phase == "SERVE" and server == 0:
		origin = Vector3(0, 11.2, 25.0 + maxf(0, players[server_index(0)].position.z - 10.0) * 0.8)
		focus.z = 0.6
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
	if not started or paused or gallery:
		return
	if event.is_action_pressed("action") or event.is_action_pressed("alternate") or event.is_action_pressed("dump"):
		read_controls() # Include a stick flick delivered in the same input frame.
	if event.is_action_pressed("action"):
		press_action()
	if event.is_action_pressed("alternate"):
		press_action("alternate")
	if event.is_action_pressed("dump"):
		press_action("dump")
	if event.is_action_released(charge_button):
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
		if phase == "CPU_ATTACK" and not block_commanded:
			block_helper_x = [-3.4, 0.0, 3.4, 0.0][set_dir]
		if clock_time - block_time < 0.65: block_hand = direction.x
	if phase == "SET" and not armed and not demo:
		plan_attack(set_dir, fast_set)

func press_action(button: String = "action") -> void:
	if phase == "SERVE" and server == 0 and not charging and not toss_active and button != "dump":
		serve_type = 0 if button == "alternate" else 1
		charge_button = button
		charging = true
		charge_start = clock_time
		players[server_index(server)].prepare_contact("float" if serve_type == 0 else "power", TOSS_TIME)
	elif phase == "ATTACK" and not armed and not charging and button == "action":
		charge_button = button
		charging = true
		charge_start = clock_time
	elif phase == "RECEIVE" and not armed and button == "action":
		var remaining := receive_deadline - clock_time
		if remaining < -Timing.LATE_RECEIVE_SECONDS: return
		input_quality = timing.quality(remaining, difficulty_scale())
		if remaining < 0:
			var recovery := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("recovery"))
			if recovery.is_empty() or recovery.seconds > 0.18 or recovery.seconds < 0: return
			late_receive = true
			flight_target = recovery.point
			flight_left = maxf(0.001, recovery.seconds)
		armed = true
		notice(("RECUPERO · " if late_receive else "RICEZIONE · ") + "%d%%" % roundi(input_quality * 100), 0.9)
	elif phase == "SET" and not armed:
		setter_dump = button == "dump"
		plan_attack(set_dir, button == "alternate")
		var contact := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("dump" if setter_dump else ("fast_set" if fast_set else "set")))
		if not contact.is_empty():
			flight_target = contact.point
			flight_left = maxf(0.001, contact.seconds)
		armed = true
		input_quality = pass_quality
		notice("COLPO DI SECONDA" if setter_dump else ("ALZATA VELOCE" if fast_set else "ALZATA NORMALE"), 0.8)
	elif phase == "CPU_ATTACK" and not block_commanded and button == "action":
		block_commanded = true
		block_time = clock_time
		block_quality = 1.0
		for blocker in blocking_players(0):
			if can_jump_block(blocker, 0):
				request_block_jump(blocker, 0.22)

func release_action() -> void:
	if not charging: return
	charge = current_charge()
	charging = false
	if phase == "SERVE" and server == 0:
		input_quality = 1.0
		serve_power = charge
		begin_serve_toss()
	elif phase == "ATTACK" and not armed:
		armed = true
		input_quality = 1.0

func current_charge() -> float:
	if not charging: return charge
	return maxf(0, (clock_time - charge_start) / (Timing.SERVE_CHARGE_SECONDS if phase == "SERVE" else Timing.ATTACK_CHARGE_SECONDS))

func difficulty_scale() -> float:
	return [1.55, 1.0, 0.72][difficulty]

func notice(message: String, seconds: float = 1.5) -> void:
	feedback = message
	feedback_left = seconds

func set_phase(value: String) -> void:
	phase = value
	phase_time = 0
	armed = false
	input_quality = 0
	charging = false
	charge = 0
	setter_dump = false
	late_receive = false

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
		var base: Vector3 = Tactics.serve_position(i, int(i / 6), rotations[int(i / 6)])
		p.position = base
		p.target = base
		p.velocity = Vector3.ZERO
		p.rotation.y = PI if i < 6 else 0.0
		p.acceleration = Vector3.ZERO
		p.steering_ready = false
		p.foot_planted = [false, false]
		p.set_libero(Tactics.libero(i, rotations[int(i / 6)], int(i / 6) == server))
		p.play("idle", 1, true)
	selected = server_index(0)
	var serving = players[server_index(server)]
	serving.position = Tactics.world(server, 3, 9.7)
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
	block_orders.clear()
	passing_sides.clear()
	blocking_team = -1
	block_commanded = false
	block_jumps.clear()
	planned_hitter = -1
	marker.visible = false

func server_index(team: int) -> int:
	return Tactics.server(team, rotations[team])

func choose_receiver(team: int, point: Vector3, serve_receive: bool = false) -> int:
	var best := -1
	var score := INF
	for i in range(team * 6, team * 6 + 6):
		var r := Tactics.role(i, rotations[team], team == server)
		var stance: Vector3 = players[i].stance_for_contact("receive", point)
		var cost: float = players[i].position.distance_to(stance)
		if serve_receive: cost += 2.8 if r == "S" else (0.0 if r == "L" or r.begins_with("OH") else 1.4)
		if players[i].clip_name == "block" and not players[i].looping: cost += 4.0
		if cost < score:
			score = cost
			best = i
	return best

func choose_setter(team: int, point: Vector3, available: float) -> int:
	var designated := team * 6 + 5
	var stance: Vector3 = players[designated].stance_for_contact("set", point)
	if designated != receiver and players[designated].position.distance_to(stance) < available * 6.5: return designated
	var backup := -1
	var distance := INF
	for i in range(team * 6, team * 6 + 6):
		if i == receiver or Tactics.libero(i, rotations[team], team == server): continue
		var candidate: float = players[i].position.distance_to(point)
		if candidate < distance:
			distance = candidate
			backup = i
	if not self_test: notice("ALZATA DI EMERGENZA", 0.8)
	return backup

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
		var front_row := Tactics.front(i, rotations[team])
		if Tactics.libero(i, rotations[team], team == server): continue
		if i == exclude or front_row == pipe: continue
		var candidate: float = players[i].position.distance_to(point)
		if candidate < distance:
			distance = candidate
			best = i
	return best if best >= 0 else nearest(team, point, exclude)

func launch(target: Vector3, seconds: float) -> void:
	flight_target = target
	flight_left = seconds
	var direction := signf(target.z - ball_pos.z)
	if phase in ["RECEIVE", "CPU_RECEIVE"]:
		flight_spin = Vector3(direction * (0.3 if test_rallies == 0 and serve_type == 0 else 20.0), aim.x * 2.0, 0.5)
	else:
		flight_spin = Vector3(0.3, 0.6, -0.2)
	ball_vel = BallFlight.velocity_to(ball_pos, target, seconds, flight_spin)
	airborne = true
	if phase == "RECEIVE": receive_deadline = clock_time + seconds
	marker.position = Vector3(target.x, 0.04, target.z)
	marker.visible = true

func contact_height(action: String) -> float:
	return clips[action].contact_offset.y if clips.has(action) else players[0].contact_local(action).y

func begin_serve_toss() -> void:
	charging = false
	toss_active = true
	serve_pending = true
	toss_elapsed = 0
	toss_origin = ball_pos
	var action := "float" if serve_type == 0 else "power"
	var point: Vector3 = players[server_index(server)].contact_world(action)
	toss_velocity = (point - toss_origin) / TOSS_TIME + Vector3(0, G * TOSS_TIME * 0.5, 0)
	players[server_index(server)].prepare_contact(action, TOSS_TIME)

func validate_contact(index: int, action: String) -> bool:
	var player = players[index]
	if player.contact_world(action).distance_to(ball_pos) > (0.55 if action == "recovery" else 0.35): return false
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
	contact_log.append({"action":action, "player":index, "role":Tactics.role(index, rotations[int(index / 6)], int(index / 6) == server), "rotation":rotations[int(index / 6)], "gap":distance, "ball":ball_pos, "hands":actual, "time":clock_time})
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
	last_power = power
	last_serve_fault = ""
	if power > 1.0 and rng.randf() < Timing.serve_risk(power):
		last_serve_fault = "NET" if rng.randf() < 0.5 else "OUT"
		if last_serve_fault == "NET":
			fault_flight(Vector3(target.x, 1.5, -0.2 if team == 0 else 0.2), 0.66)
		else:
			fault_flight(Vector3(target.x, 0.105, s * (11.0 + minf(power - 1, 2) * 4)), 1.0)
		return
	receiver = choose_receiver(possession, target, true)
	players[receiver].target = players[receiver].stance_for_contact("receive", target)
	selected = receiver if possession == 0 else 1
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	launch(target, (1.12 if serve_type == 0 else 0.90) + (1.0 - clampf(power, 0, 1)) * 0.30)

func fault_flight(target: Vector3, seconds: float) -> void:
	# A bad charge produces a real trajectory. The point is awarded on contact
	# with the floor, preserving net collisions and post-point bounces.
	set_phase("LOOSE")
	launch(target, seconds)
	flight_left = 100
	marker.visible = false
	notice("SOVRACCARICO", 0.8)

func reachable(index: int, point: Vector3, reach: float = 1.4) -> bool:
	return Vector2(players[index].position.x - point.x, players[index].position.z - point.z).length() < reach

func receive_ball() -> void:
	var action := "recovery" if late_receive else "receive"
	var q := input_quality if possession == 0 else timing.quality(absf(rng.randfn(0, 0.13)))
	if (possession == 0 and not armed) or q < 0.04 or not validate_contact(receiver, action):
		miss_contact()
		return
	if possession == 1 and phase != "CPU_RECEIVE":
		q *= 0.95
	pass_quality = q
	register_touch(receiver)
	players[receiver].prepare_contact(action, 0)
	var s := 1 if possession == 0 else -1
	var dispersion := (1 - q) * 2.6
	var target := Vector3(rng.randf_range(-dispersion, dispersion), 2.15, s * (1.5 + rng.randf_range(0, dispersion)))
	target.y = contact_height("set")
	setter = choose_setter(possession, target, 1.05 + (1.0 - q) * 0.45)
	players[setter].target = players[setter].stance_for_contact("set", target)
	selected = setter if possession == 0 else 1
	fast_set = false
	set_phase("SET" if possession == 0 else "CPU_SET")
	launch(target, 1.05 + (1.0 - q) * 0.45)
	if possession == 1:
		choose_cpu_play()
	else:
		if demo: set_dir = int(clock_time) % 4
		plan_attack(set_dir, int(clock_time) % 3 == 0 if demo else false)

func choose_cpu_play() -> void:
	var choice := 0
	var best_score := -INF
	for direction in 4:
		var candidate := Tactics.attacker(possession, rotations[possession], direction, setter)
		if candidate < 0: continue
		var x: float = [-3.4,0.0,3.4,0.0][direction] * (-1 if possession == 1 else 1)
		var depth := 1.05 if Tactics.front(candidate, rotations[possession]) else 3.65
		var point := Vector3(x, 0, depth * (-1 if possession == 1 else 1))
		var score := 1.0 + rng.randf_range(-0.45, 0.45)
		if direction == 1: score += pass_quality * 0.65 - (1.5 if pass_quality < 0.75 else 0.0)
		if direction == 3: score += 0.4 if pass_quality > 0.85 else -0.8
		if direction == last_ai_direction: score -= 0.80
		score -= players[candidate].position.distance_to(point) * 0.13
		for defender in range((1 - possession) * 6, (1 - possession) * 6 + 6):
			if Tactics.front(defender, rotations[1 - possession]) and absf(players[defender].position.x - x) < 1.5: score -= 0.35
		if score > best_score:
			best_score = score
			choice = direction
	var quick := pass_quality > 0.85 and absf(flight_target.z) < 2.8 and rng.randf() < 0.45
	last_ai_direction = choice
	plan_attack(choice, quick)

func plan_attack(direction: int, quick: bool) -> void:
	planned_direction = direction
	planned_fast = quick and pass_quality >= 0.45
	fast_set = planned_fast
	planned_hitter = Tactics.attacker(possession, rotations[possession], planned_direction, setter)
	if planned_hitter < 0:
		for alternative in [0, 2, 1, 3]:
			var candidate := Tactics.attacker(possession, rotations[possession], alternative, setter)
			if candidate >= 0:
				planned_direction = alternative
				planned_hitter = candidate
				planned_fast = false
				fast_set = false
				break

func set_ball() -> void:
	if setter_dump:
		dump_ball()
		return
	# Resolve the same planned play used during preparation, including its pose.
	if planned_hitter < 0: plan_attack(set_dir, fast_set)
	fast_set = planned_fast
	var q := input_quality if possession == 0 else clampf(pass_quality * rng.randf_range(0.95, 1.0), 0, 1)
	if (possession == 0 and not armed) or q < 0.12 or not validate_contact(setter, "fast_set" if fast_set else "set"):
		miss_contact()
		return
	if fast_set and pass_quality < 0.45:
		fast_set = false
		notice("RICEZIONE DIFFICILE · ALTA DI EMERGENZA")
	set_quality = q
	destination = planned_direction
	committed_destination = destination
	register_touch(setter)
	players[setter].prepare_contact("fast_set" if fast_set else "set", 0)
	var s := 1.0 if possession == 0 else -1.0
	var x: float = [-3.4, 0.0, 3.4, 0.0][destination] * s
	hitter = planned_hitter
	if hitter < 0:
		miss_contact()
		return
	var back_attack := not Tactics.front(hitter, rotations[possession])
	var z := s * (3.65 if back_attack else 1.05)
	var target := Vector3(x + rng.randf_range(-1, 1) * (1 - q) * 0.8, 3.05, z)
	target.y = contact_height("attack")
	players[hitter].target = players[hitter].stance_for_contact("attack", target)
	selected = hitter if possession == 0 else nearest(0, Vector3(x, 0, 0.6))
	var approach_distance: float = players[hitter].position.distance_to(players[hitter].target)
	var approach_time := approach_distance / 5.4 + 0.26
	var flight := maxf(0.62 if fast_set else 1.02 + (1 - q) * 1.25, approach_time)
	if fast_set and flight > 1.1:
		# A rushed but unreachable quick is converted before launch, never rerouted
		# to a random nearby player after the ball has left the setter's hands.
		flight = maxf(1.18, flight)
		fast_set = false
		if not self_test: notice("ALTA DI SICUREZZA", 0.8)
	block_count = Timing.blockers(false, fast_set, q, destination == 3)
	if possession == 0:
		var cpu_correct := rng.randf() < 0.52
		block_count = Timing.blockers(cpu_correct, fast_set, q, destination == 3)
	block_time = -100
	block_quality = 0
	block_checked = false
	block_hand = 0
	attack_serial += 1
	block_commanded = false
	block_jumps.clear()
	set_phase("ATTACK" if possession == 0 else "CPU_ATTACK")
	launch(target, flight)
	block_rosters.clear()
	block_orders.clear()
	block_anchor = target.x
	block_helper_x = 0.0
	if possession == 1: block_count = 2
	blocking_team = 1 - possession
	play_log.append({"attack_id":attack_serial, "setter":setter, "hitter":hitter, "role":Tactics.ROLES[hitter % 6], "direction":destination, "target":target, "quick":fast_set, "flight_s":flight, "time":clock_time})
	if possession == 1: selected = blocking_players(0)[1]
	notice(("#%d · " % players[hitter].number) + (["BANDA · ZONA 4", "CENTRO · ZONA 3", "OPPOSTO · ZONA 2", "PIPE · ZONA 6"][destination]) + (" / VELOCE" if fast_set else " / ALTA"), 0.8)

func dump_ball() -> void:
	var attacker := possession
	if not armed or not validate_contact(setter, "dump"):
		miss_contact()
		return
	register_touch(setter)
	# Back-row setters may dump only below the top of the net in the front zone.
	if not Tactics.front(setter, rotations[attacker]) and absf(players[setter].position.z) < 3.0 and ball_pos.y > 2.43:
		award(1 - attacker, "ATTACCO IRREGOLARE DI SECONDA LINEA")
		return
	var side := -1.0 if attacker == 0 else 1.0
	var landing := Vector3(aim.x * 2.9, 0.105, side * (2.3 if aim.y >= 0 else 5.5))
	send_to_court(attacker, landing, 0.83)
	notice("COLPO DI SECONDA", 0.9)

func attack_ball() -> void:
	if possession == 0 and charging: release_action()
	var q := input_quality if possession == 0 else 1.0
	if (possession == 0 and not armed) or q < 0.12 or not validate_contact(hitter, "attack"):
		miss_contact()
		return
	var attacker := possession
	register_touch(hitter)
	players[hitter].prepare_contact("attack", 0)
	last_touch = attacker
	var requested_power := charge if attacker == 0 else rng.randf_range(0.25, 0.9)
	var power := clampf(requested_power, 0, 1)
	var precision := Timing.precision(power)
	last_power = requested_power
	last_precision = precision
	var spread := (1.0 - precision) * 3.0
	var s := -1.0 if attacker == 0 else 1.0
	# The eight stick sectors select floor targets, not an airborne point which
	# would continue past the chosen corner when no defender touches the ball.
	var target := Vector3(signf(aim.x) * 3.85 if absf(aim.x) > 0.3 else 0.0, 0.105, s * (8.0 if aim.y < -0.3 else (2.0 if aim.y > 0.3 else 5.0)))
	if attacker == 1: target.x = rng.randf_range(-3.8, 3.8)
	target += Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread, spread))
	if requested_power > 1.00001:
		target.z = s * (10.8 + minf(requested_power - 1, 2) * 4)
		fault_flight(target, 0.62)
		return
	send_to_court(attacker, target, 0.72 - power * 0.24)

func send_to_court(attacker: int, landing: Vector3, seconds: float) -> void:
	# The net's geometry also checks the resulting ballistic arc, including pipe attacks.
	possession = 1 - attacker
	touches[possession] = 0
	var saved_block_time := block_time
	var saved_block_quality := block_quality
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	block_time = saved_block_time
	block_quality = saved_block_quality
	launch(landing, seconds)
	var intercept := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("receive"))
	if not intercept.is_empty():
		flight_target = intercept.point
		flight_left = intercept.seconds
		if phase == "RECEIVE": receive_deadline = clock_time + flight_left
	receiver = choose_receiver(possession, flight_target)
	players[receiver].target = players[receiver].stance_for_contact("receive", flight_target)
	selected = receiver if possession == 0 else selected
	marker.position = Vector3(landing.x, 0.04, landing.z)
	block_checked = false
	if attacker == 0:
		block_quality = rng.randf_range(0.45, 1)

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
	notice("COLPO NON COMANDATO" if missing_input else ("TIMING ERRATO" if poor_timing else "PALLA FUORI PORTATA"), 1.1)

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
			if toss_elapsed >= TOSS_TIME:
				if serve_pending: serve_ball(server, serve_power)
		else:
			if charging: serving.prepare_contact("float" if serve_type == 0 else "power", TOSS_TIME)
			ball_pos = serving.current_hand(true) + Vector3(0, 0.11, 0)
		if server == 1 and phase_time > 0.65 and not toss_active:
			serve_type = rng.randi_range(0, 1)
			serve_power = 0.75
			begin_serve_toss()
	elif phase == "POINT":
		step_dead_ball(dt)
		if phase_time > 4.5: reset_rally()
	elif airborne:
		var old := ball_pos
		var state := BallFlight.advance(ball_pos, ball_vel, flight_spin, dt)
		ball_pos = state[0]
		ball_vel = state[1]
		flight_left -= dt
		if old.z * ball_pos.z < 0:
			var fraction := absf(old.z) / maxf(absf(old.z - ball_pos.z), 0.001)
			var net_y := lerpf(old.y, ball_pos.y, fraction)
			if net_y < 2.535 and absf(ball_pos.x) < 4.65:
				ball_pos = old.lerp(ball_pos, fraction)
				ball_pos.z = signf(old.z) * 0.106
				ball_vel.z *= -0.20
				ball_vel.y *= 0.65
				flight_spin *= 0.45
				net_contacts += 1
				phase = "LOOSE"
				flight_left = 100
				marker.visible = false
				if match_audio: match_audio.contact("block", ball_pos, 0.35)
			elif not block_checked and test_rallies > 1:
				try_block()
		if phase != "POINT" and ball_pos.y <= 0.105:
			var inside := absf(ball_pos.x) <= 4.605 and absf(ball_pos.z) <= 9.105
			var floor_team := 0 if ball_pos.z > 0 else 1
			award(1 - floor_team if inside else 1 - last_touch, "PALLA A TERRA" if inside else "FUORI")
		elif phase != "POINT" and flight_left <= 0.00001:
			if true:
				match phase:
					"RECEIVE", "CPU_RECEIVE":
						if phase == "RECEIVE" and not armed and clock_time < receive_deadline + Timing.LATE_RECEIVE_SECONDS:
							pass # Small explicit late-input window; never auto-save.
						else: receive_ball()
					"SET", "CPU_SET": set_ball()
					"ATTACK", "CPU_ATTACK": attack_ball()
	ball.position = ball_pos
	ball.rotation += flight_spin * dt
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
				flight_spin *= 0.76
				dead_ball_bounces += 1
				if match_audio: match_audio.contact("bounce", ball_pos, clampf(impact / 12.0, 0.15, 0.9))
			else:
				ball_vel.y = 0
				ball_vel.x = move_toward(ball_vel.x, 0, h * 1.6)
				ball_vel.z = move_toward(ball_vel.z, 0, h * 1.6)
				flight_spin = flight_spin.lerp(Vector3.UP.cross(Vector3(ball_vel.x, 0, ball_vel.z)) / 0.105, 1.0 - exp(-h * 3.0))
		ball_vel.x *= exp(-0.06 * h)
		ball_vel.z *= exp(-0.06 * h)
		flight_spin *= exp(-0.20 * h)

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
		if nearest_point.distance_to(ball_pos) < 0.20: near = true
	if good_jump and near:
		if true:
			var normal := Vector3(block_hand * 0.22 if defender == 0 else 0.0, 0.12, -1.0 if defender == 0 else 1.0).normalized()
			var incoming := ball_vel
			var closing := ball_vel.dot(normal)
			if closing < 0: ball_vel -= normal * closing * (1.20 + block_quality * 0.20)
			ball_vel *= 0.82
			flight_spin = flight_spin * 0.45 + normal.cross(incoming) * 0.35
			last_touch = defender
			possession = 1 - defender
			touches[possession] = 0 # block is not one of the three team contacts
			# Predict a reachable dig on the actual deflected trajectory; do not relaunch it.
			var interception := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("receive"))
			if interception.is_empty():
				phase = "LOOSE"
				return
			flight_left = maxf(0.05, interception.seconds)
			flight_target = interception.point
			receiver = choose_receiver(possession, flight_target)
			players[receiver].target = players[receiver].stance_for_contact("receive", flight_target)
			selected = receiver if possession == 0 else selected
			set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
			if possession == 0: receive_deadline = clock_time + flight_left
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
		if Tactics.front(i, rotations[team]): candidates.append(i)
	# Lead wing closes its own pin; middle joins, far wing only for a triple.
	candidates.sort_custom(func(a, b): return absf(Tactics.home(a, team, rotations[team], team == server, false).x - block_anchor) < absf(Tactics.home(b, team, rotations[team], team == server, false).x - block_anchor))
	if candidates.size() == 3 and not Tactics.ROLES[candidates[0] % 6].begins_with("MB"):
		for k in range(1, 3):
			if Tactics.ROLES[candidates[k] % 6].begins_with("MB"):
				var middle: int = candidates[k]
				candidates.remove_at(k)
				candidates.insert(1, middle)
				break
	block_rosters[team] = candidates.duplicate()
	var order: Array[int] = candidates.duplicate()
	order.sort_custom(func(a, b): return players[a].position.x < players[b].position.x)
	block_orders[team] = order
	candidates.resize(mini(block_count, candidates.size()))
	return candidates

func blocking_target(index: int, team: int) -> Vector3:
	var active := blocking_players(team)
	var order: Array[int] = []
	for i in block_orders[team]:
		if i in active: order.append(i)
	var target := Tactics.block_target(index, order, block_anchor, team)
	if team == 0 and not demo and active.size() == 2 and index == active[1]:
		var lead: Vector3 = Tactics.block_target(active[0], order, block_anchor, team)
		target.x = clampf(block_helper_x, -4.1, 4.1)
		if absf(target.x - lead.x) < 0.90:
			target.x = lead.x + (0.90 if lead.x < 0 else -0.90)
	return target

func can_jump_block(index: int, team: int) -> bool:
	if players[index].position.distance_to(blocking_target(index, team)) > 0.32: return false
	for other in blocking_players(team):
		if other == index: continue
		if absf(players[other].position.x - players[index].position.x) < 0.78 and absf(players[other].position.z) < 1.45: return false
	return true

func request_block_jump(index: int, contact_in: float) -> bool:
	if phase not in ["ATTACK", "CPU_ATTACK"]: return false
	if block_jumps.get(index, -1) == attack_serial: return false
	var p = players[index]
	if p.clip_name == "block" and not p.looping and p.clips.has("block") and p.animation_time < p.clips.block.contact_time + 0.58: return false
	block_jumps[index] = attack_serial
	block_jump_log.append({"attack_id":attack_serial, "player":index, "time":clock_time, "contact_in":contact_in})
	p.target = p.position
	p.steering_target = p.position
	p.velocity = Vector3.ZERO
	p.acceleration = Vector3.ZERO
	p.prepare_contact("block", contact_in)
	return true

func move_players(dt: float) -> void:
	var action_actor := -1
	var action := ""
	match phase:
		"RECEIVE", "CPU_RECEIVE":
			action_actor = receiver
			action = "recovery" if late_receive else "receive"
		"SET", "CPU_SET":
			action_actor = setter
			action = "dump" if setter_dump else ("fast_set" if fast_set else "set")
		"ATTACK", "CPU_ATTACK":
			action_actor = hitter
			action = "attack"
	var blockers: Array = blocking_players(1 - possession) if phase in ["ATTACK", "CPU_ATTACK"] else []
	if blockers.is_empty() and blocking_team >= 0 and clock_time - block_time < 0.58 and phase in ["RECEIVE", "CPU_RECEIVE"]:
		blockers = blocking_players(blocking_team)
		blockers.erase(action_actor)
	for i in 12:
		var p = players[i]
		p.reach_weight = maxf(0, p.reach_weight - dt * 5)
		p.motion_lock = maxf(0, p.motion_lock - dt)
		var side := 1.0 if i < 6 else -1.0
		var zone := Tactics.slot(i, rotations[int(i / 6)])
		var base: Vector3 = Tactics.serve_position(i, int(i / 6), rotations[int(i / 6)])
		var team := int(i / 6)
		var serving_player := phase == "SERVE" and i == server_index(server)
		var depth_limit := 12.5 if serving_player else 10.5
		var preparing_hitter := phase in ["SET", "CPU_SET"] and i == planned_hitter
		var urgent := i == action_actor or i in blockers or preparing_hitter
		var assignment := "contact" if i == action_actor else ("approach" if preparing_hitter else ("block" if i in blockers else ("recover" if phase == "POINT" else "cover")))
		var yield_target := Vector3.ZERO
		var yielding := false
		if i != action_actor and not i in blockers and action_actor >= 0 and int(action_actor / 6) == team:
			var contact_stance: Vector3 = players[action_actor].stance_for_contact(action, flight_target)
			var corridor := Geometry3D.get_closest_point_to_segment(p.position, players[action_actor].position, contact_stance)
			var escape: Vector3 = p.position - corridor
			escape.y = 0
			if escape.length() < (1.35 if p.intent.task == "yield" else 1.05):
				if escape.length() < 0.1: escape = Vector3(1 if i % 2 == 0 else -1, 0, 0.4)
				yield_target = p.position + escape.normalized() * maxf(0.35, 1.35 - escape.length())
				yielding = true
				assignment = "yield"
		if not p.steering_ready:
			p.intent.reset(p.position)
			p.steering_ready = true
		p.intent.observe(phase + ":" + str(attack_serial), Tactics.role(i, rotations[team], team == server), assignment, clock_time)
		var chase_distance: float = p.position.distance_to(flight_target)
		p.effort = clampf(chase_distance / maxf(0.3, flight_left * 5.4), 0, 1.5) if airborne else 0.0
		p.visual_context = "quick" if fast_set and phase in ["SET", "CPU_SET", "ATTACK", "CPU_ATTACK"] else ("emergency" if (phase in ["SET", "CPU_SET"] and pass_quality < 0.65) or (i == action_actor and p.effort > 1.0) else "normal")
		if i == action_actor:
			# Solving the stance from the source hand event aligns animation and flight.
			p.target = p.stance_for_contact(action, flight_target)
		elif i in blockers:
			p.target = blocking_target(i, team)
			# Travel laterally behind the net lane, then step in beside the lead.
			if absf(p.position.x - p.target.x) > 0.8: p.target.z = side * 1.20
			if phase == "ATTACK" and team == 1 and flight_left < 0.34 and can_jump_block(i, team):
				if request_block_jump(i, flight_left + 0.08):
					if block_time < 0: block_time = clock_time
					block_quality = 0.85
			if block_jumps.get(i, -1) == attack_serial and p.clip_name == "block" and not p.looping:
				p.target = p.steering_target
		elif phase == "SERVE":
			if i != server_index(server): p.target = base + Vector3(0.15 * ball_pos.x if team != server else 0, 0, 0)
		elif phase not in ["POINT", "LOOSE"]:
			p.target = tactical_target(i, zone, team, side)
		elif phase == "POINT" and point_formation.size() == 12:
			p.target = point_formation[i]
		if yielding: p.target = yield_target
		if preparing_hitter:
			var setter_stance: Vector3 = players[action_actor].stance_for_contact(action, flight_target)
			var opening: Vector3 = p.target - setter_stance
			if opening.length() < 1.1:
				if opening.length() < 0.01: opening = Vector3(0,0,side)
				p.target = setter_stance + opening.normalized() * 1.1
		# Each athlete perceives the same cue on an individual schedule. Direct
		# contact assistance remains immediate; support and reading are staggered.
		p.steering_target = p.intent.perceive(p.target, clock_time, dt)
		var movement: Vector3 = p.steering_target - p.position
		movement.y = 0
		var max_speed: float = 7.2 if urgent else (1.6 if phase == "POINT" else p.intent.support_speed(p.visual_context == "emergency"))
		var arrival_speed := movement.length() * 2.5
		if urgent: arrival_speed = movement.length() / maxf(0.055, flight_left - 0.12)
		if preparing_hitter: arrival_speed = movement.length() * 3.5
		if urgent: arrival_speed = minf(arrival_speed, sqrt(2.0 * 22.0 * movement.length()) * 0.72)
		var desired := movement.normalized() * minf(max_speed, arrival_speed)
		if movement.length() < (0.045 if urgent else p.intent.settle_distance()): desired = Vector3.ZERO
		desired = avoid_teammates(i, desired, movement, max_speed)
		# Mild separation prevents two athletes occupying the same contact space.
		if i != action_actor:
			for j in range(team * 6, team * 6 + 6):
				if i == j: continue
				var delta: Vector3 = p.position - players[j].position
				delta.y = 0
				if delta.length() < 0.75 and delta.length() > 0.01: desired += delta.normalized() * (0.75 - delta.length()) * 3.0
		if i == selected and not demo and phase != "SERVE":
			var input := stick(false)
			desired += Vector3(input.x, 0, input.y) * 5.5
		if serving_player:
			desired = Vector3.ZERO
			if server == 0 and not demo and not charging and not toss_active:
				var service_input := stick(false)
				desired = Vector3(service_input.x, 0, service_input.y) * 3.5
			p.target = p.position
			if charging or toss_active:
				p.velocity = Vector3.ZERO
				p.acceleration = Vector3.ZERO
		if p.motion_lock > 0: desired *= 0.35
		if block_jumps.get(i, -1) == attack_serial and p.clip_name == "block" and not p.looping: desired = Vector3.ZERO
		var wanted_accel: Vector3 = ((desired.limit_length(max_speed) - p.velocity) / (0.055 if urgent else p.intent.response_time())).limit_length(28.0 if urgent else 9.5 + p.intent.individuality * 3.5)
		p.acceleration = wanted_accel if i == action_actor else p.acceleration.move_toward(wanted_accel, (150.0 if urgent else 50.0 + p.intent.individuality * 35.0) * dt)
		p.velocity = (p.velocity + p.acceleration * dt).limit_length(max_speed)
		if desired.length() < 0.01 and p.velocity.length() < 0.10:
			p.velocity = Vector3.ZERO
			p.acceleration = Vector3.ZERO
		var safe_step: Vector3 = p.velocity * dt
		for projection in 3:
			var bounded: Vector3 = p.position + safe_step
			bounded.x = clampf(bounded.x, -5.7, 5.7)
			bounded.z = clampf(bounded.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(bounded.z, -depth_limit, -9.3 if serving_player else -0.25)
			safe_step = collision_safe_step(i, bounded - p.position)
		var endpoint: Vector3 = p.position + safe_step
		endpoint.x = clampf(endpoint.x, -5.7, 5.7)
		endpoint.z = clampf(endpoint.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(endpoint.z, -depth_limit, -9.3 if serving_player else -0.25)
		safe_step = endpoint - p.position
		for other in range(team * 6, team * 6 + 6):
			if other != i and endpoint.distance_to(players[other].position) < Tactics.BODY_SPACE - 0.0001:
				safe_step = Vector3.ZERO
		p.position += safe_step
		if safe_step.length() + 0.00001 < p.velocity.length() * dt:
			p.velocity = safe_step / maxf(dt, 0.00001)
			p.acceleration = Vector3.ZERO
		travel[i] += p.velocity.length() * dt
		if i != action_actor and not i in blockers and phase not in ["SERVE", "POINT", "LOOSE"]: support_travel[i] += p.velocity.length() * dt
		p.position.x = clampf(p.position.x, -5.7, 5.7)
		p.position.z = clampf(p.position.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(p.position.z, -depth_limit, -9.3 if serving_player else -0.25)
		var facing := PI if team == 0 else 0.0
		if phase != "SERVE" and i != action_actor and not i in blockers:
			var look: Vector3 = ball_pos - p.position
			if phase == "POINT": look = Vector3(0, 0, side * 3.3) - p.position
			facing = atan2(look.x, look.z)
			# Sprint facing the route, then open the shoulders to the ball on braking.
			if p.velocity.length() > 2.6 and movement.length() > 0.9:
				facing = atan2(p.velocity.x, p.velocity.z)
			if clock_time < p.intent.react_at: facing = p.rotation.y
		var turn := wrapf(facing - p.rotation.y, -PI, PI)
		var turn_speed: float = 7.0 if urgent else 3.1 + p.intent.individuality * 0.8
		p.rotation.y += clampf(turn * (8.0 if urgent else 5.0 + p.intent.individuality * 2.0), -turn_speed, turn_speed) * dt
		p.look_target = Vector3(0, 1.7, side * 3.3) if phase == "POINT" else ball_pos
		p.ready_stance = (team == possession and phase in ["RECEIVE", "CPU_RECEIVE"] and (zone >= 3 or i == receiver)) or (team != possession and phase in ["ATTACK", "CPU_ATTACK"])
		p.block_ready_stance = team != possession and zone < 3 and phase in ["RECEIVE", "CPU_RECEIVE", "SET", "CPU_SET", "ATTACK", "CPU_ATTACK"]
		if phase == "SERVE": p.ready_stance = team != server and zone >= 3
		# Wings waiting to approach and setters waiting to penetrate stand tall;
		# only passers and floor defenders stay in the low defensive posture.
		p.relaxed_stance = not p.ready_stance and i != action_actor and not i in blockers
		p.locomotion(p.velocity.length(), dt)
		var preparation_lead := (0.51 if fast_set else 0.68) if action == "attack" else 0.38
		preparation_lead += p.intent.individuality * 0.055 + (0.04 if p.visual_context == "emergency" else 0.0)
		if i == action_actor and flight_left < preparation_lead:
			p.prepare_contact(action, flight_left)
			p.reach_action = action
			p.reach_target = flight_target
			p.reach_weight = 1.0 - smoothstep(0.04, 0.22, flight_left)
		p.hand_adjust = block_hand if team == 0 and clock_time - block_time < 0.7 else 0
		if p.velocity.length() > 1.8 and p.step_cooldown <= 0 and not self_test:
			if match_audio: match_audio.contact("step", p.position, 0.35)
			p.step_cooldown = 0.32 + float(i % 3) * 0.025
	for team in 2:
		for a in range(team * 6, team * 6 + 6):
			for b in range(a + 1, team * 6 + 6):
				var distance: float = players[a].position.distance_to(players[b].position)
				minimum_player_gap = minf(minimum_player_gap, distance)
				if a in blockers and b in blockers: minimum_block_gap = minf(minimum_block_gap, distance)

func collision_safe_step(index: int, movement: Vector3) -> Vector3:
	var origin: Vector3 = players[index].position
	var allowed := 1.0
	var original_length := movement.length()
	# First find a sliding direction. Re-projecting against a second neighbour
	# can reintroduce a collision with the first, so sweep only AFTER this pass.
	for iteration in 3:
		for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
			if j == index: continue
			var delta: Vector3 = origin - players[j].position
			delta.y = 0
			if delta.length() < Tactics.BODY_SPACE + 0.04 and delta.length() > 0.001:
				var normal := delta.normalized()
				var inward := movement.dot(normal)
				if inward < 0: movement -= normal * inward
	for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
		if j == index: continue
		var delta: Vector3 = origin - players[j].position
		delta.y = 0
		var approaching := delta.dot(movement)
		if approaching >= 0 or movement.length_squared() < 0.0000001: continue
		var c := delta.length_squared() - Tactics.BODY_SPACE * Tactics.BODY_SPACE
		if c < 0:
			allowed = 0
			continue
		var discriminant := approaching * approaching - movement.length_squared() * c
		if discriminant >= 0:
			var t := (-approaching - sqrt(discriminant)) / movement.length_squared()
			if t >= 0 and t < allowed: allowed = maxf(0, t - 0.001)
	if allowed < 1.0 or movement.length() + 0.00001 < original_length: collision_stops += 1
	return movement * allowed

func avoid_teammates(index: int, desired: Vector3, route: Vector3, max_speed: float) -> Vector3:
	if route.length() < 0.20: return desired
	var forward := route.normalized()
	var tangent := Vector3(forward.z, 0, -forward.x)
	var lookahead := minf(route.length(), 2.0)
	for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
		if j == index: continue
		var relative: Vector3 = players[j].position - players[index].position
		relative.y = 0
		var ahead := relative.dot(forward)
		var lateral := relative.dot(tangent)
		var key := str(index) + ":" + str(j)
		if ahead < -0.15 or ahead > lookahead or absf(lateral) > 1.05:
			passing_sides.erase(key)
			continue
		if not passing_sides.has(key): passing_sides[key] = -1.0 if lateral > 0.08 else 1.0
		var threat := (1.0 - absf(lateral) / 1.05) * (1.0 - maxf(0, ahead) / 2.4)
		desired += tangent * float(passing_sides[key]) * max_speed * threat * 1.4
	return desired.limit_length(max_speed)

func tactical_target(index: int, zone: int, team: int, side: float) -> Vector3:
	var own_ball := team == possession
	var receiving := phase in ["RECEIVE", "CPU_RECEIVE"]
	var setting := phase in ["SET", "CPU_SET"]
	var attacking := phase in ["ATTACK", "CPU_ATTACK"]
	var r := Tactics.role(index, rotations[team], team == server)
	var home: Vector3 = Tactics.home(index, team, rotations[team], team == server, own_ball)
	var local_ball_x := ball_pos.x * side
	if own_ball and receiving:
		if r == "S": return home
		# Keep defensive balance until the dig, open a corridor around the passer.
		if zone < 3:
			home.z = side * 2.5
			home.x += clampf((flight_target.x - home.x) * 0.10, -0.4, 0.4)
		else:
			home.x += clampf(flight_target.x * 0.16, -0.65, 0.65)
			home.z += side * clampf((absf(flight_target.z) - 5.2) * 0.24, -0.55, 0.55)
		return home
	if own_ball and setting:
		var individual_time: float = maxf(0, phase_time - players[index].intent.delay)
		var approach_duration := 0.56 if fast_set else 0.85
		var progress := smoothstep(0, approach_duration, individual_time)
		var selected_option := index == planned_hitter
		if r == "S": return home
		if r == "L": return Tactics.world(team, -2.3 + local_ball_x * 0.12, 4.9)
		if r.begins_with("MB") and zone < 3:
			return Tactics.world(team, -0.25, lerpf(3.3, 2.9 if selected_option else 3.15, progress))
		if r.begins_with("OH") and zone < 3:
			return Tactics.world(team, -3.85, lerpf(3.9, 2.9 if selected_option else 3.4, progress))
		if r.begins_with("OH"):
			return Tactics.world(team, 0.15, lerpf(6.4, 4.8 if selected_option else 5.8, progress))
		if r == "OPP":
			return Tactics.world(team, 3.8 if zone < 3 else 3.0, lerpf(3.9 if zone < 3 else 6.0, (2.9 if zone < 3 else 4.8) if selected_option else (3.4 if zone < 3 else 5.5), progress))
		return home
	if own_ball and attacking:
		var attack_x := flight_target.x * side
		if r == "S": return Tactics.world(team, 1.3 + attack_x * 0.10, 2.25)
		if r == "L": return Tactics.world(team, -2.35 + attack_x * 0.14, 4.75)
		if r.begins_with("MB"): return Tactics.world(team, attack_x * 0.24, 2.85)
		if r.begins_with("OH") and zone < 3: return Tactics.world(team, -2.55 + attack_x * 0.14, 3.25)
		if r.begins_with("OH"): return Tactics.world(team, attack_x * 0.22, 5.85)
		return Tactics.world(team, 2.85 + attack_x * 0.10, 4.35 if zone >= 3 else 3.35)
	if not own_ball and attacking:
		if zone < 3:
			# Non-blocking wing drops to cover tips, never into the block lane.
			home.z = side * 3.1
		else:
			home.x += clampf(block_anchor * 0.20, -0.65, 0.65)
			home.z += side * (0.45 if r.begins_with("OH") else -0.25)
	elif not own_ball:
		# Read the setter/pass and adjust depth before the opponent hits.
		home.x += clampf(ball_pos.x * 0.16, -0.55, 0.55)
		if zone >= 3: home.z += side * (0.35 if setting else -0.20)
	return home

func demo_input() -> void:
	if phase == "SERVE" and server == 0:
		if phase_time > 0.45 and not toss_active and not charging:
			press_action("alternate" if int(clock_time) % 2 == 0 else "action")
		if charging and current_charge() >= 0.85: release_action()
	if phase == "RECEIVE" and flight_left < 0.04 and not armed: press_action()
	if phase == "SET" and not armed:
		press_action("alternate" if planned_fast else "action")
	if phase == "ATTACK" and not armed:
		if not charging and flight_left <= 0.55: press_action()
		if charging and (current_charge() >= 0.65 or flight_left <= 0.01): release_action()
	if phase == "CPU_ATTACK":
		block_count = Timing.blockers(true, fast_set, set_quality, committed_destination == 3)
		if flight_left < 0.22 and not block_commanded:
			press_action()
			block_quality = 0.9

func run_tests() -> void:
	assert(clips.size() == 21, "Every selected source animation must load")
	var button := InputEventJoypadButton.new()
	button.device = 9
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	assert(InputMap.event_is_action(button, "action"), "Xbox A / PS Cross must map across controller IDs")
	button.button_index = JOY_BUTTON_X
	assert(InputMap.event_is_action(button, "alternate"))
	button.button_index = JOY_BUTTON_B
	assert(InputMap.event_is_action(button, "dump"))
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
	assert(is_equal_approx(Timing.precision(0.5), 1.0))
	assert(is_equal_approx(Timing.precision(0.9), 0.8))
	assert(Timing.blockers(true, false, 1, false) == 2)
	assert(Timing.blockers(false, true, 1, false) == 1)
	assert(Timing.blockers(true, false, 0.8, false) == 3)
	assert(Timing.blockers(false, false, 1, true) == 1)
	assert(timing.quality(0) > timing.quality(0.3))
	assert(timing.quality(0.8) == 0, "Early presses must never become perfect again")
	assert(timing.quality(0.20) < timing.quality(0.08))
	assert(timing.quality(-0.03) > timing.quality(-0.09))
	for direction in 4:
		var normal_time := 0.0
		for quick in [false, true]:
			touches = [0, 0]
			rotations = [0, 0]
			possession = 0
			phase = "SET"
			setter = 5
			ball_pos = Vector3(0, contact_height("fast_set" if quick else "set"), 1.5)
			players[setter].position = players[setter].stance_for_contact("fast_set" if quick else "set", ball_pos)
			players[setter].rotation.y = PI
			armed = true
			input_quality = 1.0
			pass_quality = 1.0
			fast_set = quick
			set_dir = direction
			plan_attack(direction, quick)
			var landing := Vector3([-3.4, 0.0, 3.4, 0.0][direction], contact_height("attack"), 3.65 if direction == 3 else 1.05)
			players[planned_hitter].position = players[planned_hitter].stance_for_contact("attack", landing)
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
	receive_deadline = clock_time + flight_left
	press_action()
	assert(armed and input_quality > 0.9)
	test_charge_and_context_controls()
	test_manual_reception()
	test_bounce_and_animation()
	test_tactical_spacing()
	test_planned_attacks_and_jump_lifecycle()
	scores = [0, 0]
	rotations = [0, 0]
	server = 0
	test_points = 0
	test_contacts = 0
	test_rallies = 0
	max_rally = 0
	max_contact_gap = 0
	minimum_player_gap = INF
	minimum_block_gap = INF
	collision_stops = 0
	contact_log.clear()
	play_log.clear()
	block_jump_log.clear()
	support_travel.fill(0)
	rng.seed = 194260
	reset_rally()
	print("SELF TEST PASS: source meshes, four set zones, contextual Cross/Square/Circle, charge and real fault flights, arrival accuracy, block formations")

func test_planned_attacks_and_jump_lifecycle() -> void:
	var plays := 0
	for team in 2:
		for rotation in 6:
			for direction in 4:
				rotations = [rotation, rotation]
				server = team
				reset_rally()
				possession = team
				setter = team * 6 + 5
				phase = "SET" if team == 0 else "CPU_SET"
				fast_set = false
				pass_quality = 1
				armed = true
				input_quality = 1
				ball_pos = Tactics.world(team, 1.15, 1.5)
				ball_pos.y = contact_height("set")
				players[setter].position = players[setter].stance_for_contact("set", ball_pos)
				plan_attack(direction, false)
				var committed := planned_hitter
				set_ball()
				assert(hitter == committed and destination == direction)
				assert(hitter == Tactics.attacker(team, rotation, direction, setter))
				assert(not Tactics.libero(hitter, rotation, team == server))
				assert(absf(flight_target.x * (1 if team == 0 else -1) - [-3.4,0.0,3.4,0.0][direction]) < 0.81)
				if not Tactics.front(hitter, rotation): assert(absf(flight_target.z) > 3.0)
				var predicted := BallFlight.advance(ball_pos, ball_vel, flight_spin, flight_left)
				assert(predicted[0].distance_to(flight_target) < 0.01, "Spin-aware prediction must meet the planned hitter")
				plays += 1
	rotations = [0, 0]
	server = 0
	reset_rally()
	possession = 0
	phase = "ATTACK"
	block_count = 2
	block_anchor = 0
	blocking_team = 1
	attack_serial += 1
	var active := blocking_players(1)
	var before := block_jump_log.size()
	for i in active:
		players[i].position = blocking_target(i, 1)
		assert(request_block_jump(i, 0.12))
		assert(not request_block_jump(i, 0.12))
	phase = "CPU_RECEIVE"
	receiver = 9
	flight_target = Vector3(0, contact_height("receive"), -6)
	for frame in 90:
		flight_left = 0.42 - frame / 120.0
		clock_time += 1.0 / 120.0
		move_players(1.0 / 120.0)
		for i in active:
			var prior: float = players[i].animation_time
			players[i].tick(1.0 / 120.0, false, false)
			if players[i].clip_name == "block": assert(players[i].animation_time >= prior)
			assert(not request_block_jump(i, 0.12), "Next receive deadline must not restart the block")
	assert(block_jump_log.size() - before == active.size())
	for fps in [30,60,120]:
		var origin := Vector3(1,3.2,1)
		var target := Vector3(-2,1.2,-6)
		var spin := Vector3(-20,3,1)
		var velocity := BallFlight.velocity_to(origin, target, 0.8, spin)
		for frame in int(0.8 * fps):
			var state := BallFlight.advance(origin, velocity, spin, 1.0 / fps)
			origin = state[0]
			velocity = state[1]
		assert(origin.distance_to(target) < 0.01)
	# A real net collision changes motion, rather than freezing/scoring the ball.
	server = 0
	reset_rally()
	phase = "CPU_RECEIVE"
	possession = 1
	last_touch = 0
	test_rallies = 0
	ball_pos = Vector3(0, 1.6, 0.12)
	ball_vel = Vector3(0, 0, -15)
	flight_spin = Vector3.ZERO
	flight_left = 0.3
	airborne = true
	var before_net := net_contacts
	var prior_score := scores.duplicate()
	step(1.0 / 60.0)
	assert(net_contacts == before_net + 1 and phase == "LOOSE")
	assert(ball_vel.z > 0 and scores == prior_score)
	# Exercise collision against the actual animated hands, with no ball snap.
	reset_rally()
	phase = "ATTACK"
	possession = 0
	last_touch = 0
	block_anchor = 0
	block_count = 1
	blocking_team = 1
	attack_serial += 1
	var blocker: int = blocking_players(1)[0]
	players[blocker].position = blocking_target(blocker, 1)
	assert(request_block_jump(blocker, 0))
	ball_pos = (players[blocker].current_hand(true) + players[blocker].current_hand(false)) * 0.5
	var hit_position := ball_pos
	ball_vel = Vector3(0, -1, -15)
	flight_spin = Vector3(-15, 0, 0)
	block_time = clock_time - 0.2
	block_quality = 0.7
	try_block()
	assert(last_touch == 1 and ball_vel.z > 0 and ball_pos.distance_to(hit_position) < 0.0001)
	assert(flight_spin.is_finite() and flight_target.is_finite())
	print("PLAY LIFECYCLE PASS: ", plays, " role-specific planned sets / one takeoff per attack / no animation rewind after dig / shared spin prediction 30,60,120 Hz")
	print("BALL COLLISION PASS: real animated hands / deterministic rebound / spin transfer / net deflection without premature score")

func test_tactical_spacing() -> void:
	var scenarios := 0
	var smallest := INF
	for team in 2:
		for rotation in 6:
			rotations = [rotation, rotation]
			assert(Tactics.slot(server_index(team), rotation) == 3)
			assert(Tactics.slot(team * 6 + 5, rotation) == posmod(5 + rotation, 6))
			var front_count := 0
			for i in range(team * 6, team * 6 + 6):
				if Tactics.front(i, rotation): front_count += 1
				assert(Tactics.serve_position(i, team, rotation).distance_to(Tactics.serve_position(i % 6 + (1 - team) * 6, 1 - team, rotation) * -1) < 0.001)
			assert(front_count == 3)
			for direction in 4:
				var attacker := Tactics.attacker(team, rotation, direction, team * 6 + 5)
				assert(attacker >= 0 and not Tactics.libero(attacker, rotation, false))
				if direction < 2: assert(Tactics.front(attacker, rotation))
				if direction == 3: assert(not Tactics.front(attacker, rotation))
			for attack_x in [-4.3, 0.0, 4.3]:
				for count in [1, 2, 3]:
					server = 1 - team
					reset_rally()
					possession = 1 - team
					set_phase("ATTACK" if possession == 0 else "CPU_ATTACK")
					destination = 0
					hitter = Tactics.attacker(possession, rotation, 0, possession * 6 + 5)
					flight_target = Vector3(attack_x, contact_height("attack"), -1.05 if team == 0 else 1.05)
					block_anchor = attack_x
					block_count = count
					blocking_team = team
					var active := blocking_players(team)
					assert(active.size() == count)
					for i in active:
						assert(Tactics.front(i, rotation) and not Tactics.libero(i, rotation, team == server))
						for j in active:
							if j != i: assert(blocking_target(i, team).distance_to(blocking_target(j, team)) > 0.89)
					for frame in 150:
						flight_left = maxf(0.01, 1.25 - frame / 120.0)
						move_players(1.0 / 120.0)
						for a in active:
							for b in active:
								if a == b: continue
								var distance: float = players[a].position.distance_to(players[b].position)
								smallest = minf(smallest, distance)
								assert(distance >= 0.775, "Blockers must never intersect while travelling or jumping")
					scenarios += 1
	print("TACTICS PASS: ", scenarios, " blocking scenarios / six rotations / both teams / minimum blocker spacing=", smallest, " / stable setter, legal attackers, mirrored zones")

func send_test_button(button: int, pressed: bool = true) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 9
	event.button_index = button
	event.pressed = pressed
	_unhandled_input(event)

func test_charge_and_context_controls() -> void:
	started = true
	demo = false
	paused = false
	server = 0
	reset_rally()
	var serving: int = server_index(0)
	var original: Vector3 = players[serving].position
	Input.action_press("down")
	for frame in 120: step(1.0 / 120.0)
	Input.action_release("down")
	assert(players[serving].position.z > original.z + 0.8 and players[serving].position.z <= 12.5, "The human server must be able to back up")
	Input.action_press("up")
	for frame in 180: step(1.0 / 120.0)
	Input.action_release("up")
	assert(players[serving].position.z >= 9.3, "Pre-serve movement must stay behind the end line")
	for fps in [30, 60, 120]:
		for button in [JOY_BUTTON_A, JOY_BUTTON_X]:
			reset_rally()
			send_test_button(button)
			assert(charging and not toss_active)
			assert(serve_type == (1 if button == JOY_BUTTON_A else 0))
			var before: Array = scores.duplicate()
			for frame in int(2.0 * fps): step(1.0 / fps)
			assert(phase == "SERVE" and charging and current_charge() > 1.8)
			assert(scores == before, "Holding beyond max must not end the point or stop the bar")
			# Test the exact max with the actual release event.
			charge_start = clock_time - Timing.SERVE_CHARGE_SECONDS
			send_test_button(button, false)
			assert(toss_active and not charging and is_equal_approx(serve_power, 1.0))
			for frame in int(1.3 * fps):
				step(1.0 / fps)
				if phase != "SERVE": break
			assert(phase == "CPU_RECEIVE" and last_serve_fault.is_empty(), "Both max-power serve animations must contact the ball")
	# Guaranteed excess risk still travels physically and scores only on landing.
	var faults: Dictionary = {}
	for attempt in 12:
		server = 0
		reset_rally()
		send_test_button(JOY_BUTTON_A)
		charge_start = clock_time - Timing.SERVE_CHARGE_SECONDS * 1.5
		send_test_button(JOY_BUTTON_A, false)
		var before: int = scores[1]
		for frame in 140: step(1.0 / 120.0)
		assert(not last_serve_fault.is_empty() and scores[1] == before)
		faults[last_serve_fault] = true
		for frame in 240:
			step(1.0 / 120.0)
			if phase == "POINT": break
		assert(phase == "POINT" and scores[1] == before + 1)
	assert(faults.has("NET") and faults.has("OUT"))
	assert(Timing.serve_risk(1.0) == 0 and Timing.serve_risk(1.1) < Timing.serve_risk(1.3))
	# Normal, quick and second ball use the real contextual buttons.
	for button in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_B]:
		for direction in 4:
			reset_rally()
			possession = 0
			setter = 5
			pass_quality = 1.0
			set_dir = direction
			set_phase("SET")
			var action := "dump" if button == JOY_BUTTON_B else ("fast_set" if button == JOY_BUTTON_X else "set")
			var target := Vector3(0, contact_height(action), 1.5)
			players[setter].position = players[setter].stance_for_contact(action, target)
			ball_pos = Vector3(0, contact_height("receive"), 5.2)
			launch(target, 1.0)
			plan_attack(direction, button == JOY_BUTTON_X)
			var hit_target := Vector3([-3.4,0.0,3.4,0.0][direction],contact_height("attack"),3.65 if not Tactics.front(planned_hitter,rotations[0]) else 1.05)
			players[planned_hitter].position = players[planned_hitter].stance_for_contact("attack", hit_target)
			send_test_button(button)
			assert(armed and setter_dump == (button == JOY_BUTTON_B))
			for frame in 160:
				step(1.0 / 120.0)
				if phase != "SET": break
			assert(phase == ("CPU_RECEIVE" if button == JOY_BUTTON_B else "ATTACK"), "Every set command must complete its intended real contact")
			if button != JOY_BUTTON_B:
				assert(destination == direction and fast_set == (button == JOY_BUTTON_X))
	# Attack tap, 90%, 100%, and overcharge: no extra release-timing penalty.
	for requested in [0.02, 0.9, 1.0, 1.2, -1.0]:
		reset_rally()
		possession = 0
		hitter = 0
		set_phase("ATTACK")
		var target := Vector3(-3.4, contact_height("attack"), 1.05)
		players[hitter].position = players[hitter].stance_for_contact("attack", target)
		ball_pos = Vector3(0,contact_height("set"),1.5)
		aim = Vector2(-1,-1).normalized()
		launch(target, 1.3)
		send_test_button(JOY_BUTTON_A)
		send_test_button(JOY_BUTTON_X, false)
		assert(charging, "Releasing Square must not end a Cross charge")
		if requested >= 0:
			charge_start = clock_time - requested * Timing.ATTACK_CHARGE_SECONDS
			send_test_button(JOY_BUTTON_A, false)
			assert(armed and is_equal_approx(charge, requested) and input_quality == 1)
		for frame in 160:
			step(1.0 / 120.0)
			if phase != "ATTACK": break
		assert(is_equal_approx(last_power, requested) if requested >= 0 else last_power > 1.0, "Still-held attack must use the real charge at contact")
		if requested > 1 or requested < 0:
			assert(phase == "LOOSE" and absf(flight_target.z) > 9.105)
		else:
			assert(phase == "CPU_RECEIVE" and is_equal_approx(last_precision, Timing.precision(requested)))
			if requested < 0.1:
				var landing := BallFlight.intercept(ball_pos, ball_vel, flight_spin, 0.105)
				assert(landing.point.distance_to(Vector3(-3.85,0.105,-8)) < 0.03, "A tap must land at the selected corner")
	# The auxiliary blocker is continuously directed by the stick, with safe slots.
	reset_rally()
	set_phase("CPU_ATTACK")
	possession = 1
	attack_serial += 1
	block_count = 2
	block_anchor = -3.4
	var active := blocking_players(0)
	block_helper_x = 3.4
	var right := blocking_target(active[1],0)
	block_helper_x = -3.4
	var left := blocking_target(active[1],0)
	assert(right.x - left.x > 3.0)
	assert(left.distance_to(blocking_target(active[0],0)) >= 0.89)
	for i in active: players[i].position = blocking_target(i,0)
	send_test_button(JOY_BUTTON_A)
	var jump_count := block_jump_log.size()
	send_test_button(JOY_BUTTON_A)
	assert(block_commanded and block_jump_log.size() == jump_count)
	reset_rally()
	print("CONTROL SYSTEM PASS: Cross/Square serve; unbounded charge; max and excess; 12 set commands; dump; attack tap/90/100/excess; auxiliary block and single jump; 30/60/120 Hz")

func test_manual_reception() -> void:
	for fps in [30, 60, 120]:
		for mode in ["early", "perfect", "late", "none"]:
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
			launch(target, 0.85)
			send_test_button(JOY_BUTTON_X)
			assert(not armed, "Square must not act as reception after the remap")
			var sent := false
			var threshold := 0.22 if mode == "early" else (-0.025 if mode == "late" else 0.025)
			for frame in 180:
				if mode != "none" and not sent and receive_deadline - clock_time <= threshold:
					send_test_button(JOY_BUTTON_A)
					assert(armed, "Cross reception must accept the arrival or late window")
					if mode == "early": assert(input_quality > 0.4 and input_quality < 0.8)
					if mode == "perfect": assert(input_quality > 0.97)
					if mode == "late": assert(late_receive and input_quality < 0.8)
					sent = true
				step(1.0 / fps)
				if phase != "RECEIVE": break
			if mode == "none":
				assert(phase == "LOOSE" or phase == "POINT", "No input must never auto-save")
			else:
				assert(phase == "SET", "Manual Cross reception must physically return the ball at every frame rate")
				if mode == "perfect":
					assert(pass_quality > 0.97 and absf(flight_target.x) < 0.08 and absf(flight_target.z - 1.5) < 0.08, "Perfect reception must target central zone 3")
				if mode == "late":
					assert(contact_log.back().action == "recovery")
	ball_pos = Vector3(5.5, contact_height("receive"), 9)
	players[receiver].position = Vector3(-4, 0, 2)
	assert(not validate_contact(receiver, "receive"))
	print("MANUAL INPUT PASS: Cross arrival accuracy, early/near/late/no input, central zone 3 and source recovery, 30/60/120 Hz; unreachable ball rejected")

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

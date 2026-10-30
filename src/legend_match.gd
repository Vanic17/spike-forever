extends Node
## Diventa un mito owns its rally, input and scoring. The standard match motor
## never advances while this node is active. Only eleven athletes have AI.
signal match_finished(result: Dictionary)

const Tactics = preload("res://src/tactics.gd")
const Flight = preload("res://src/ball_flight.gd")
const Contact = preload("res://src/ball_contact.gd")
const Net = preload("res://src/net_dynamics.gd")
const Kits = preload("res://src/club_kits.gd")
const G := 9.81
const BALL_RADIUS := 0.105
const NET_HEIGHT := 2.43
const INPUT_DEADZONE := 0.18

var game
var active := false
var controlled_index := 0
var manual_available := true
var role := "OH"
var difficulty := 1
var config: Dictionary = {}
var random := RandomNumberGenerator.new()
var move_input := Vector2.ZERO
var aim_input := Vector2.ZERO
var sprint_input := 0.0
var keys: Dictionary = {}
var buttons: Dictionary = {}
var velocities: Array[Vector3] = []
var jump_speeds: Array[float] = []
var heights: Array[float] = []
var cooldowns: Array[float] = []
var dive_left: Array[float] = []
var visual_offsets: Array[float] = []
var shot_stage := "serve"
var actor := -1
var last_actor := -1
var last_team := 0
var live := false
var service_toss := false
var service_clock := 0.0
var serve_clock := 0.0
var point_clock := 0.0
var flight_clock := 0.0
var flight_duration := 0.0
var prediction := Vector3.ZERO
var contact_height := 1.15
var predicted_left := 0.0
var manual_charge := 0.0
var manual_kind := ""
var swing_left := 0.0
var swing_kind := ""
var swing_power := 0.0
var requested_set := false
var suggestion := ""
var set_scores: Array = []
var first_server := 0
var set_number := 0
var point_total := 0
var contact_log: Array[Dictionary] = []
var performance: Dictionary = {}
var spin := Vector3.ZERO
var ai_read_clock := 0.0
var finished_sent := false
var point_last_hitter := -1
var jump_origin: Array[Vector3] = []
var contact_points: Array[Vector3] = []
var energy := 100.0
var last_attack_setter := -1
var last_blocker := -1
var travel_during_rally := 0.0
var saved_game: Dictionary = {}

func start(options: Dictionary) -> bool:
	if game == null or game.players.size() != 12: return false
	stop()
	config = options.duplicate(true)
	difficulty = clampi(int(config.get("options",{}).get("difficulty",1)),0,2)
	saved_game = {"use_player_stats":game.use_player_stats,"match_best_of":game.match_best_of,"match_points":game.match_points}
	var manager = game.get("match_management")
	if is_instance_valid(manager):
		saved_game["manager_active"] = manager.active
		manager.active = false
	role = normalize_role(str(config.get("role", config.get("player", {}).get("role", "OH"))))
	controlled_index = {"OH":0,"MB":1,"OPP":2,"S":5,"L":4}.get(role, 0)
	random.seed = int(config.get("seed", 720194260))
	velocities.clear(); jump_speeds.clear(); heights.clear(); cooldowns.clear(); dive_left.clear(); visual_offsets.clear(); jump_origin.clear(); contact_points.clear()
	for i in 12:
		velocities.append(Vector3.ZERO); jump_speeds.append(0.0); heights.append(0.0); cooldowns.append(0.0); dive_left.append(0.0); visual_offsets.append(0.0); jump_origin.append(Vector3.ZERO)
		contact_points.append(Vector3.ZERO)
		var p = game.players[i]
		if p.visual_root != null: visual_offsets[i] = p.visual_root.position.y
	var lineups: Array = [config.get("club_lineup", []), config.get("opponent_lineup", [])]
	for team in 2:
		var club: Dictionary = config.get("club" if team == 0 else "opponent", {})
		var variant := "home" if str(club.get("id", "")) == str(config.get("home_club_id", "")) else "away"
		var kit := Kits.selection(str(club.get("id", "")), variant)
		var libero_kit := Kits.selection(str(club.get("id", "")), variant, true)
		for slot in 6:
			var p = game.players[team * 6 + slot]
			if not kit.is_empty(): p.kit_identity = kit; p.libero_kit = libero_kit
			if lineups[team].size() >= 6:
				var identity: Dictionary = lineups[team][slot]
				var libero: Dictionary = lineups[team][6] if lineups[team].size() > 6 else {}
				assign_identity(p, identity, libero)
	var player: Dictionary = config.get("player", {})
	if not player.is_empty():
		var p = game.players[controlled_index]
		assign_identity(p, p.roster_identity if role == "L" else player, player if role == "L" else p.libero_identity)
	game.use_player_stats = true
	game.started = true; game.paused = false; game.demo = false; game.match_finished = false
	game.scores = [0, 0]; game.sets = [0, 0]; game.rotations = [0, 0]; game.touches = [0, 0]
	game.match_best_of = 3 if int(config.get("best_of", 5)) == 3 else 5
	game.match_points = clampi(int(config.get("points", 25)), 1, 25)
	game.team_names = [str(config.get("club", {}).get("short_name", config.get("club", {}).get("name", "LA TUA SQUADRA"))), str(config.get("opponent", {}).get("short_name", config.get("opponent", {}).get("name", "AVVERSARI")))]
	if game.has_method("set_home_club") and not str(config.get("home_club_id", "")).is_empty(): game.set_home_club(str(config.home_club_id), 0)
	game.home_team = 0 if str(config.get("club", {}).get("id", "")) == str(config.get("home_club_id", "")) else 1
	game.clock_time = 0.0; game.test_contacts = 0; game.test_points = 0; game.test_rallies = 0
	game.contact_log.clear(); game.max_contact_gap = 0.0
	set_scores.clear(); contact_log.clear(); point_total = 0; set_number = 0; finished_sent = false
	performance = {"contacts":0,"touches":0,"serves":0,"attacks":0,"kills":0,"blocks":0,"block_touches":0,"digs":0,"receptions":0,"sets":0,"assists":0,"aces":0,"errors":0,"misses":0,"points":0,"team_points":0,"distance_m":0.0,"jumps":0,"requests":0,"quality_sum":0.0,"minutes":0.0}
	energy = 100.0
	first_server = clampi(int(config.get("first_server", 0)), 0, 1)
	game.server = first_server
	active = true
	reset_rally()
	notice("DIVENTA UN MITO · LS MUOVE · RS MIRA · R1/RB SALTO MANUALE", 5.0)
	return true

func assign_identity(p, person: Dictionary, libero: Dictionary) -> void:
	if p.skeleton != null:
		p.set_roster_identity(person, libero, p.kit_identity, p.libero_kit)
	else:
		# Headless/capsule avatars do not own a skinned appearance rig.
		p.roster_identity = person; p.libero_identity = libero
		p.left_handed = person.get("dominant_hand", "right") == "left"

static func normalize_role(value: String) -> String:
	match value.to_upper():
		"S", "SETTER", "PALLEGGIATORE": return "S"
		"MB", "MB1", "MB2", "MIDDLE_BLOCKER", "CENTRALE": return "MB"
		"OPP", "OPPOSITE", "OPPOSTO": return "OPP"
		"L", "LIBERO": return "L"
	return "OH"

func stop() -> void:
	if active and game != null:
		for i in mini(12, game.players.size()):
			var p = game.players[i]
			p.position.y = 0.0
			p.velocity = Vector3.ZERO
			p.reach_weight = 0.0
			p.contact_scheduled = false
			if p.visual_root != null and i < visual_offsets.size(): p.visual_root.position.y = visual_offsets[i]
		for field in ["use_player_stats", "match_best_of", "match_points"]:
			if saved_game.has(field): game.set(field, saved_game[field])
		var manager = game.get("match_management")
		if is_instance_valid(manager) and saved_game.has("manager_active"): manager.active = saved_game.manager_active
	saved_game.clear()
	active = false; live = false; service_toss = false
	move_input = Vector2.ZERO; aim_input = Vector2.ZERO; sprint_input = 0.0
	keys.clear(); buttons.clear(); manual_kind = ""; swing_left = 0.0

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X: move_input.x = event.axis_value
			JOY_AXIS_LEFT_Y: move_input.y = event.axis_value
			JOY_AXIS_RIGHT_X: aim_input.x = event.axis_value
			JOY_AXIS_RIGHT_Y: aim_input.y = event.axis_value
			JOY_AXIS_TRIGGER_LEFT: sprint_input = maxf(0.0, event.axis_value)
			JOY_AXIS_TRIGGER_RIGHT:
				if event.axis_value > 0.55 and not buttons.get("trigger_dive", false): dive()
				buttons["trigger_dive"] = event.axis_value > 0.55
		return true
	if event is InputEventJoypadButton:
		if event.button_index in [JOY_BUTTON_START, JOY_BUTTON_BACK]: return false
		var command: String = {JOY_BUTTON_A:"action",JOY_BUTTON_X:"alternate",JOY_BUTTON_B:"dump",JOY_BUTTON_RIGHT_SHOULDER:"jump",JOY_BUTTON_LEFT_SHOULDER:"request"}.get(event.button_index, "")
		if not command.is_empty():
			if event.pressed: press(command)
			else: release(command)
		return true
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code in [KEY_ESCAPE, KEY_ENTER, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F11]: return false
		if event.echo: return true
		keys[code] = event.pressed
		var command: String = {KEY_SPACE:"action",KEY_Q:"alternate",KEY_E:"dump",KEY_R:"jump",KEY_F:"request",KEY_C:"dive"}.get(code, "")
		if not command.is_empty():
			if event.pressed: press(command)
			else: release(command)
		return true
	return false

func press(kind: String) -> void:
	if not active or game.paused or game.match_finished or not manual_available: return
	if kind == "jump": jump(); return
	if kind == "dive": dive(); return
	if kind == "request":
		requested_set = true; performance.requests += 1
		suggestion = "RAGGIUNGI " + ("IL CENTRO RETE" if role == "MB" else ("ZONA PALLEGGIO" if role == "S" else ("LA DIFESA DI SECONDA LINEA" if role == "L" else "IL TUO CORRIDOIO D'ATTACCO")))
		notice(suggestion + " · R1/RB SALTA, X/A COLPISCI", 3.0)
		return
	if kind not in ["action", "alternate", "dump"]: return
	buttons[kind] = true
	manual_kind = kind; manual_charge = 0.0
	game.charging = true; game.charge_start = game.clock_time; game.charge = 0.0
	if game.phase == "SERVE" and service_index(game.server) == controlled_index and not service_toss:
		begin_toss()
	elif kind == "dump" and game.ball_pos.y < 1.0 and flat_gap(controlled_index, game.ball_pos) > 0.85:
		dive()
	var action := manual_action(kind)
	var p = game.players[controlled_index]
	if not (action in ["attack", "power", "block"] and heights[controlled_index] < 0.10) and (p.clip_name != action or p.looping): p.play(action, 1.0, false)

func release(kind: String) -> void:
	buttons[kind] = false
	if not active or kind not in ["action", "alternate", "dump"] or manual_kind != kind: return
	game.charging = false
	if game.paused:
		manual_kind = ""; swing_left = 0.0
		return
	swing_kind = kind; swing_power = clampf(manual_charge / charge_seconds(), 0.10, 1.35)
	game.last_power = swing_power
	manual_kind = ""; swing_left = 0.22
	if attempt_manual(kind, swing_power): swing_left = 0.0

func charge_seconds() -> float:
	var key := "battuta" if game.phase == "SERVE" else ("palleggio" if shot_stage == "set" else "schiacciata")
	return lerpf(0.95, 0.60, rating(controlled_index, key) / 99.0)

func jump() -> bool:
	if not active or not manual_available or game.paused or game.match_finished or heights[controlled_index] > 0.015 or jump_speeds[controlled_index] > 0.0 or dive_left[controlled_index] > 0.0: return false
	var p = game.players[controlled_index]
	jump_speeds[controlled_index] = jump_speed(controlled_index)
	jump_origin[controlled_index] = p.position
	performance.jumps += 1
	energy = maxf(0.0, energy - 2.8)
	var block: bool = absf(p.position.z) < 1.4 and game.possession != 0
	var action := "block" if block else ("power" if game.phase == "SERVE" else "attack")
	p.play(action, 1.0, false)
	p.prepare_contact(action, jump_speeds[controlled_index] / G)
	notice("SALTO MANUALE · " + ("MANI A MURO" if block else "RILASCIA X/A PER COLPIRE"), 0.8)
	return true

func dive() -> bool:
	if not active or not manual_available or game.paused or game.match_finished or heights[controlled_index] > 0.1 or dive_left[controlled_index] > 0.0: return false
	var direction := movement_vector()
	if direction.length() < 0.1:
		direction = game.ball_pos - game.players[controlled_index].position; direction.y = 0
	if direction.length() < 0.1: direction = Vector3(0, 0, -1)
	dive_left[controlled_index] = 0.72
	velocities[controlled_index] = direction.normalized() * 7.6
	var p = game.players[controlled_index]
	p.dive_yaw = atan2(direction.x, direction.z)
	p.play("dive", 1.0, false)
	return true

func reset_rally() -> void:
	# A libero is exchanged for its original middle in front row and while
	# that middle serves. The avatar index stays fixed; AI owns the middle.
	manual_available = role != "L" or Tactics.libero(controlled_index, game.rotations[0], game.server == 0)
	game.phase = "SERVE"; game.phase_time = 0.0; game.possession = 1 - game.server
	game.touches = [0, 0]; game.selected = controlled_index; game.airborne = false
	game.ball_vel = Vector3.ZERO; game.incoming_kind = "serve"; game.charging = false
	shot_stage = "serve"; actor = service_index(game.server); last_actor = -1; last_team = game.server
	serve_clock = 0.0; service_clock = 0.0; point_clock = 0.0; service_toss = false; live = false
	manual_kind = ""; manual_charge = 0.0; swing_left = 0.0; requested_set = false; point_last_hitter = -1
	last_blocker = -1; last_attack_setter = -1; travel_during_rally = 0.0
	game.test_rallies = 0
	for i in 12:
		var team := int(i / 6)
		var p = game.players[i]
		var point: Vector3 = Tactics.serve_position(i, team, game.rotations[team], team == game.server)
		if i == actor: point = Tactics.world(team, 2.4, 10.0)
		if role == "L" and is_manual(i): point = Vector3(-1.5, 0, 5.8)
		p.position = point; p.target = point; p.velocity = Vector3.ZERO
		p.rotation.y = PI if team == 0 else 0.0
		p.reach_weight = 0.0; p.contact_scheduled = false; p.motion_lock = 0.0
		p.post_point = false; p.ready_stance = true; p.block_ready_stance = false
		# The athlete's identity remains fixed, including a middle in back row.
		var libero_now: bool = (i != controlled_index and not (team == 0 and role == "L") and Tactics.libero(i, game.rotations[team], team == game.server)) or (is_manual(i) and role == "L")
		var changed: bool = p.libero_active != libero_now
		p.libero_active = libero_now
		if changed and p.skeleton != null: p.apply_identity()
		p.play("serve_idle" if i == actor else "ready", 1.0, true)
		velocities[i] = Vector3.ZERO; heights[i] = 0.0; jump_speeds[i] = 0.0; cooldowns[i] = 0.0; dive_left[i] = 0.0
	game.ball_pos = hand_point(actor, "serve_idle")
	game.receiver = nearest_receiver(1 - game.server, Tactics.world(1 - game.server, 0, 5.5))
	game.setter = (1 - game.server) * 6 + 5
	game.hitter = (1 - game.server) * 6
	game.flight_left = 0.0
	update_visuals(0.0)
	if not manual_available: notice("IN PANCHINA · IL CENTRALE GIOCA LA PRIMA LINEA E IL SERVIZIO", 5.0)

func service_index(team: int) -> int:
	return Tactics.server(team, game.rotations[team])

func is_manual(index: int) -> bool:
	return index == controlled_index and manual_available

func step(dt: float) -> void:
	if not active or not game.started or game.paused: return
	var remaining := clampf(dt, 0.0, 0.25)
	while remaining > 0.000001 and active and game.started and not game.paused:
		var part := minf(remaining, 1.0 / 120.0)
		remaining -= part
		advance(part)
	if active: update_visuals(dt)

func advance(dt: float) -> void:
	game.clock_time += dt; game.phase_time += dt
	if manual_available: performance.minutes = minf(360.0, performance.minutes + dt / 60.0)
	else: energy = minf(100.0, energy + dt * 3.0)
	game.feedback_left = maxf(0.0, game.feedback_left - dt)
	if game.phase == "POINT":
		point_clock += dt
		move_players(dt, true)
		if game.ball_pos.y > BALL_RADIUS:
			var state := Flight.advance(game.ball_pos, game.ball_vel, spin, dt)
			game.ball_pos = state[0]; game.ball_vel = state[1]
			if game.ball_pos.y <= BALL_RADIUS: game.ball_pos.y = BALL_RADIUS; game.ball_vel = Vector3.ZERO
		if point_clock > 1.7 and not game.match_finished: reset_rally()
		return
	if not manual_kind.is_empty():
		manual_charge += dt; game.charge = clampf(manual_charge / charge_seconds(), 0.0, 1.35)
	move_players(dt)
	if game.phase == "SERVE":
		serve_clock += dt
		if not service_toss:
			game.ball_pos = hand_point(actor, "serve_idle")
			if not is_manual(actor) and serve_clock > 0.85: begin_toss()
			elif is_manual(actor) and serve_clock > 8.0: award(1 - game.server, "OTTO SECONDI AL SERVIZIO")
			return
		service_clock += dt
		var state := Flight.advance(game.ball_pos, game.ball_vel, Vector3.ZERO, dt)
		game.ball_pos = state[0]; game.ball_vel = state[1]
		if not is_manual(actor):
			if service_clock > 0.22 and heights[actor] < 0.01 and jump_speeds[actor] == 0.0:
				jump_speeds[actor] = jump_speed(actor); jump_origin[actor] = game.players[actor].position
				game.players[actor].play("power", 1.0, false)
			if service_clock > 0.40 and service_clock < 0.92 and physical_gap(actor, "power") < 0.62: serve_ball(actor, ai_quality(), false)
		elif swing_left > 0.0:
			swing_left -= dt
			if attempt_manual(swing_kind, swing_power): swing_left = 0.0
		if game.phase == "SERVE" and game.ball_pos.y <= BALL_RADIUS: award(1 - game.server, "SERVIZIO NON COLPITO")
		return
	if not live: return
	flight_clock += dt; predicted_left = maxf(0.0, predicted_left - dt)
	game.flight_left = predicted_left
	var previous: Vector3 = game.ball_pos
	var state := Flight.advance(game.ball_pos, game.ball_vel, spin, dt)
	game.ball_pos = state[0]; game.ball_vel = state[1]
	if swing_left > 0.0:
		swing_left -= dt
		if attempt_manual(swing_kind, swing_power): swing_left = 0.0
	if game.phase == "POINT": return
	try_block(previous)
	if game.phase == "POINT": return
	if previous.z * game.ball_pos.z < 0.0:
		var fraction := absf(previous.z) / maxf(0.001, absf(previous.z - game.ball_pos.z))
		var crossing := previous.lerp(game.ball_pos, fraction)
		if absf(crossing.x) > 4.605: award(1 - last_team, "FUORI ANTENNA"); return
		if crossing.y < NET_HEIGHT + BALL_RADIUS:
			game.ball_pos = crossing
			var tape := crossing.y >= NET_HEIGHT and absf(game.ball_vel.z) > 4.0
			game.ball_pos.z = -signf(previous.z) * BALL_RADIUS if tape else signf(previous.z) * BALL_RADIUS
			var dynamic_net = game.get("dynamic_net")
			if is_instance_valid(dynamic_net): dynamic_net.impact(crossing, game.ball_vel)
			game.ball_vel = Net.response(game.ball_vel, crossing.y)
			spin *= 0.4
			if not tape:
				if game.incoming_kind == "serve": award(1 - last_team, "BATTUTA IN RETE"); return
				game.possession = last_team; shot_stage = "receive"
				read_flight()
	if game.ball_pos.y <= BALL_RADIUS:
		var inside := absf(game.ball_pos.x) <= 4.605 and absf(game.ball_pos.z) <= 9.105
		var floor_team := 0 if game.ball_pos.z >= 0.0 else 1
		award(1 - floor_team if inside else 1 - last_team, "PALLA A TERRA" if inside else "FUORI")
		return
	if game.ball_pos.y > 12.0 or absf(game.ball_pos.x) > 18.0 or absf(game.ball_pos.z) > 23.0 or flight_clock > 8.0:
		award(1 - last_team, "FUORI"); return
	try_ai_contact(previous)

func begin_toss() -> void:
	if service_toss or game.phase != "SERVE": return
	service_toss = true; service_clock = 0.0; game.airborne = true
	game.ball_pos = hand_point(actor, "serve_idle")
	game.ball_vel = Vector3(0, 6.0, 0)
	game.players[actor].play("float" if is_manual(actor) and manual_kind == "alternate" else "power", 1.0, false)
	if is_manual(actor): notice("LANCIO · R1/RB SALTA · RILASCIA X/A O QUADRATO/X", 1.5)

func serve_ball(index: int, power: float, floating: bool) -> void:
	var target := aimed_target(1 - int(index / 6), true)
	var skill := rating(index, "battuta")
	var error := lerpf(1.25, 0.25, skill / 99.0) + maxf(0.0, power - 1.0) * 6.0
	if not is_manual(index): target = Tactics.world(1 - int(index / 6), random.randf_range(-3.4, 3.4), random.randf_range(4.5, 8.1)) + Vector3(0, BALL_RADIUS, 0)
	target += Vector3(random.randfn(0.0, error * 0.28), 0, random.randfn(0.0, error * 0.3))
	var seconds := lerpf(2.05, 1.35, clampf(power, 0.0, 1.0)) + (0.2 if floating else 0.0)
	seconds/=maxf(1.0,power)
	register_contact(index, "float" if floating else "power", power)
	if is_manual(index): performance.serves += 1
	game.touches = [0, 0]; game.incoming_kind = "serve"
	shot_stage = "receive"; game.possession = 1 - int(index / 6); service_toss = false
	launch(target, seconds)

func manual_action(kind: String) -> String:
	if game.phase == "SERVE": return "float" if kind == "alternate" else "power"
	if dive_left.size() > controlled_index and dive_left[controlled_index] > 0.0: return "dive"
	if kind == "dump": return "dump" if shot_stage == "set" and game.ball_pos.y > 1.75 else "recovery"
	if shot_stage == "set": return "set"
	if shot_stage == "attack" and heights[controlled_index] > 0.12: return "attack"
	return "receive"

func attempt_manual(kind: String, power: float) -> bool:
	if not active or not manual_available or game.paused or game.phase == "POINT" or cooldowns[controlled_index] > 0.0: return false
	var i := controlled_index
	if game.phase == "SERVE":
		if actor != i or not service_toss: return false
		var floating := kind == "alternate"
		if not floating and heights[i] < 0.20: return false
		var action := "float" if floating else "power"
		if physical_gap(i, action) > 0.64: return false
		if absf(game.players[i].position.x) > 4.5 or game.players[i].position.z < 9.10:
			performance.errors += 1; award(1, "FALLO DI PIEDE"); return false
		serve_ball(i, power, floating); return true
	if not live or game.possession != 0 or game.ball_pos.z < -0.15 or last_actor == i: return false
	var action := manual_action(kind)
	var radius := 0.72 if action in ["receive", "recovery", "dive"] else 0.57
	if physical_gap(i, action) > radius: return false
	if action == "attack" and heights[i] < 0.12: return false
	if role == "L" and action in ["attack", "dump"] and game.ball_pos.y > NET_HEIGHT:
		performance.errors += 1; award(1, "ATTACCO DEL LIBERO SOPRA RETE"); return false
	if action == "attack" and not is_front(i) and absf(jump_origin[i].z) < 3.0:
		performance.errors += 1; award(1, "ATTACCO DI SECONDA LINEA DENTRO I TRE METRI"); return false
	play_contact(i, action, clampf(power, 0.1, 1.35), kind == "alternate", kind == "dump")
	return true

func physical_gap(index: int, action: String) -> float:
	return hand_point(index, action).distance_to(game.ball_pos)

func flat_gap(index: int, point: Vector3) -> float:
	var p: Vector3 = game.players[index].position
	return Vector2(p.x - point.x, p.z - point.z).length()

func hand_point(index: int, action: String) -> Vector3:
	var p: Vector3 = game.players[index].position
	var direction := -1.0 if index < 6 else 1.0
	var height: float = {"serve_idle":1.25,"receive":1.10,"recovery":0.62,"dive":0.48,"set":2.12,"dump":2.15,"attack":2.24,"power":2.24,"float":2.12,"block":2.32}.get(action, 1.1)
	# Contact is bounded by body reach, not by a planned ball destination.
	return p + Vector3(0.0, height, direction * (0.52 if action == "dive" else 0.34))

func rating(index: int, key: String) -> float:
	var p = game.players[index]
	var identity: Dictionary = p.libero_identity if p.libero_active else p.roster_identity
	var value := float(identity.get("ratings", {}).get(key, 65.0))
	var cap := float(identity.get("cap_real", identity.get("capreal", 99.0)))
	return clampf(minf(value, cap), 1.0, 99.0)

func jump_speed(index: int) -> float:
	var identity: Dictionary = game.players[index].roster_identity
	var jump_cm := float(identity.get("jump_cm", 0.0))
	if jump_cm > 0.0: return sqrt(2.0 * G * clampf(jump_cm / 100.0, 0.4, 1.05))
	return lerpf(3.9, 4.8, rating(index, "schiacciata") / 99.0)

func movement_vector() -> Vector3:
	var stick := move_input
	var keyboard := Vector2(float(keys.get(KEY_D, false)) - float(keys.get(KEY_A, false)), float(keys.get(KEY_S, false)) - float(keys.get(KEY_W, false)))
	if keyboard.length_squared() > 0.0: stick = keyboard
	if stick.length() <= INPUT_DEADZONE: return Vector3.ZERO
	stick = stick.limit_length(1.0)
	var camera = game.get("camera")
	if is_instance_valid(camera):
		var right: Vector3 = camera.global_basis.x; right.y = 0.0
		var back: Vector3 = camera.global_basis.z; back.y = 0.0
		return (right.normalized() * stick.x + back.normalized() * stick.y).limit_length(1.0)
	return Vector3(stick.x, 0, stick.y)

func move_players(dt: float, dead: bool = false) -> void:
	for i in 12:
		cooldowns[i] = maxf(0.0, cooldowns[i] - dt)
		dive_left[i] = maxf(0.0, dive_left[i] - dt)
		var p = game.players[i]
		var previous: Vector3 = velocities[i]
		if is_manual(i):
			var direction := movement_vector()
			var sprint: float = maxf(sprint_input, 1.0 if keys.get(KEY_SHIFT, false) else 0.0)
			var effort := clampf(sprint, 0, 1) * direction.length()
			energy = clampf(energy + dt * (1.8 if effort < 0.2 else -4.0), 0.0, 100.0)
			var speed := lerpf(4.2, lerpf(4.9, 6.5, energy / 100.0), clampf(sprint, 0, 1))
			if heights[i] > 0.0: speed *= 0.68
			if dive_left[i] > 0.0: velocities[i] = velocities[i].move_toward(Vector3.ZERO, dt * 7.0)
			else: velocities[i] = velocities[i].move_toward(direction * speed, dt * (14.0 if direction.length() > 0.0 else 19.0))
		else:
			var target := ai_target(i, dead)
			p.target = target
			var delta: Vector3 = target - p.position; delta.y = 0.0
			var max_speed := 5.5
			var desired := delta.normalized() * minf(max_speed, delta.length() * 6.0)
			if heights[i] > 0.0: desired *= 0.55
			# AI yields to the user. It cannot drag the controlled root away.
			for j in range(int(i / 6) * 6, int(i / 6) * 6 + 6):
				if j == i: continue
				var gap: Vector3 = p.position - game.players[j].position; gap.y = 0
				if gap.length() < 0.75 and gap.length() > 0.01: desired += gap.normalized() * (0.75 - gap.length()) * 8.0
			velocities[i] = velocities[i].move_toward(desired.limit_length(max_speed), dt * 13.0)
			if live and i == actor and shot_stage == "attack" and predicted_left < 0.42 and heights[i] < 0.01 and jump_speeds[i] == 0.0 and flat_gap(i, prediction) < 1.3:
				jump_speeds[i] = jump_speed(i); jump_origin[i] = p.position; p.play("attack", 1.0, false); p.prepare_contact("attack", predicted_left)
			if live and int(i / 6) != game.possession and is_front(i) and shot_stage == "attack" and predicted_left < 0.12 and heights[i] < 0.01 and absf(p.position.x - game.ball_pos.x) < 1.2 and absf(p.position.z) < 1.3:
				jump_speeds[i] = jump_speed(i); jump_origin[i] = p.position; p.play("block", 1.0, false); p.prepare_contact("block", jump_speeds[i] / G)
		var movement: Vector3 = velocities[i] * dt
		p.position.x = clampf(p.position.x + movement.x, -7.2, 7.2)
		var side := 1.0 if i < 6 else -1.0
		p.position.z = clampf(p.position.z * side + movement.z * side, 0.35, 12.5) * side
		if is_manual(i):
			var distance := Vector2(movement.x, movement.z).length()
			performance.distance_m += distance; travel_during_rally += distance
		if jump_speeds[i] != 0.0 or heights[i] > 0.0:
			heights[i] = maxf(0.0, heights[i] + jump_speeds[i] * dt - 0.5 * G * dt * dt)
			jump_speeds[i] -= G * dt
			if heights[i] <= 0.0: jump_speeds[i] = 0.0
		p.position.y = heights[i]
		p.velocity = velocities[i]; p.acceleration = (velocities[i] - previous) / maxf(dt, 0.001)
		p.look_target = game.ball_pos; p.ready_stance = not dead; p.post_point = dead
		p.block_ready_stance = live and int(i / 6) != game.possession and is_front(i) and absf(p.position.z) < 1.4
		p.locomotion(velocities[i].length(), dt)

func is_front(index: int) -> bool:
	if is_manual(index) and role == "L": return false
	return Tactics.front(index, game.rotations[int(index / 6)])

func ai_target(index: int, dead: bool) -> Vector3:
	var team := int(index / 6)
	var point: Vector3 = Tactics.home(index, team, game.rotations[team], team == game.server, game.possession == team)
	if dead: return point
	if game.phase == "SERVE":
		if index == actor: return game.players[index].position
		return Tactics.serve_position(index, team, game.rotations[team], team == game.server)
	if index == actor:
		return prediction - Vector3(0.0, prediction.y, -0.34 if team == 0 else 0.34)
	if team == game.possession:
		if shot_stage == "receive" and index % 6 == 5: return Tactics.setter_position(team)
		# Cover a user who cannot reach the ball, without moving that athlete.
		if is_manual(actor) and index == backup_actor() and flat_gap(controlled_index, prediction) > predicted_left * 4.2 + 0.8:
			return prediction - Vector3(0.0, prediction.y, -0.34 if team == 0 else 0.34)
		if shot_stage in ["receive", "set"] and not is_libero(index) and index % 6 != 5:
			return attack_lane(index)
		point.x = lerpf(point.x, game.ball_pos.x, 0.10)
	else:
		if is_front(index) and shot_stage == "attack":
			point.x = clampf(prediction.x + (index % 3 - 1) * 0.8, -4.1, 4.1)
			point.z = 0.72 if team == 0 else -0.72
		else: point.x = clampf(point.x + game.ball_pos.x * 0.12, -4.1, 4.1)
	return point

func attack_lane(index: int) -> Vector3:
	var team := int(index / 6)
	var front := is_front(index)
	var r: String = Tactics.ROLES[index % 6]
	if is_manual(index): r = role
	var x := 0.0
	if r.begins_with("OH"): x = -3.3 if front else -1.0
	elif r == "OPP": x = 3.3
	elif r == "S": x = 1.2
	return Tactics.world(team, x, 1.45 if front else 3.65)

func is_libero(index: int) -> bool:
	return (is_manual(index) and role == "L") or (index != controlled_index and game.players[index].libero_active)

func backup_actor() -> int:
	var best := -1; var cost := INF
	for i in range(game.possession * 6, game.possession * 6 + 6):
		if is_manual(i) or i == last_actor: continue
		var value := flat_gap(i, prediction)
		if value < cost: cost = value; best = i
	return best

func nearest_receiver(team: int, point: Vector3) -> int:
	var best := team * 6; var cost := INF
	for i in range(team * 6, team * 6 + 6):
		if i == last_actor and int(last_actor / 6) == team: continue
		var value := flat_gap(i, point)
		if i % 6 == 5: value += 1.2
		if is_libero(i): value -= 0.6
		if value < cost: cost = value; best = i
	return best

func choose_setter(team: int) -> int:
	var setter := team * 6 + 5
	if setter != last_actor: return setter
	var best := -1; var cost := INF
	for i in range(team * 6, team * 6 + 6):
		if i == last_actor: continue
		var value := flat_gap(i, prediction) - rating(i, "palleggio") * 0.012
		if value < cost: best = i; cost = value
	return best

func choose_hitter(team: int) -> int:
	var choices: Array[int] = []
	for i in range(team * 6, team * 6 + 6):
		if i == last_actor or is_libero(i) or i % 6 == 5: continue
		if is_front(i): choices.append(i)
	var human_option: bool = team == 0 and manual_available and role not in ["L", "S"] and last_actor != controlled_index
	if human_option:
		# A called ball has priority, but ordinary rallies involve the other
		# attackers too. Sets keep a fixed court destination, never follow LS.
		if requested_set: return controlled_index
		if controlled_index not in choices: choices.append(controlled_index)
		if random.randf() < 0.48: return controlled_index
	if choices.is_empty():
		for i in range(team * 6, team * 6 + 6):
			if i != last_actor and not is_libero(i): choices.append(i)
	return choices[random.randi_range(0, choices.size() - 1)] if not choices.is_empty() else team * 6

func launch(target: Vector3, seconds: float) -> void:
	spin = Vector3(random.randf_range(-3.0, 3.0), 0.0, 0.0)
	game.ball_vel = Flight.velocity_to(game.ball_pos, target, seconds, spin)
	game.flight_target = target; flight_duration = seconds; flight_clock = 0.0
	game.airborne = true; live = true; game.phase_time = 0.0
	read_flight()

func read_flight() -> void:
	contact_height = 1.10 if shot_stage == "receive" else (2.12 if shot_stage == "set" else 2.95)
	var interception := Flight.intercept(game.ball_pos, game.ball_vel, spin, contact_height)
	prediction = interception.get("point", game.flight_target)
	predicted_left = float(interception.get("seconds", 1.5))
	if shot_stage == "receive": actor = nearest_receiver(game.possession, prediction); game.receiver = actor
	elif shot_stage == "set": actor = choose_setter(game.possession); game.setter = actor
	elif shot_stage == "attack": game.hitter = actor
	game.flight_left = predicted_left
	game.phase = ("CPU_" if game.possession == 1 else "") + {"receive":"RECEIVE","set":"SET","attack":"ATTACK"}.get(shot_stage, "RECEIVE")

func try_ai_contact(previous: Vector3) -> void:
	if not live or game.ball_pos.y < 0.24: return
	var action: String = {"receive":"receive","set":"set","attack":"attack"}.get(shot_stage, "receive")
	if game.ball_vel.y > 0.5: return
	var order: Array[int] = [actor]
	for i in range(game.possession * 6, game.possession * 6 + 6):
		if i != actor: order.append(i)
	for i in order:
		if i < 0 or is_manual(i) or i == last_actor or cooldowns[i] > 0.0: continue
		if int(i / 6) != game.possession: continue
		if game.ball_pos.z * (1.0 if i < 6 else -1.0) < 0.0: continue
		var selected_action: String = action
		if action == "attack" and (heights[i] < 0.15 or is_libero(i)): selected_action = "receive"
		if action == "set" and game.ball_pos.y < 1.55: selected_action = "receive"
		var hand := hand_point(i, selected_action)
		var gap := distance_to_segment(hand, previous, game.ball_pos)
		if gap > (0.59 if selected_action in ["attack", "set"] else 0.67): continue
		# Unassigned teammates only take genuine emergency contacts.
		if i != actor and (game.ball_pos.y > 1.50 or selected_action == "attack"): continue
		if action == "attack" and selected_action == "attack" and not is_front(i) and absf(jump_origin[i].z) < 3.0: continue
		play_contact(i, selected_action, ai_quality(), random.randf() < 0.12, false)
		return

func ai_quality() -> float:
	# Difficulty changes the opponents' execution, never the user's reach,
	# input timing or manually commanded movement.
	var side: int=game.server if game.phase=="SERVE" else game.possession
	if side==0: return random.randf_range(.62,.96)
	return random.randf_range([.52,.62,.73][difficulty],[.87,.96,.99][difficulty])

static func distance_to_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
	var line := b - a
	var amount := clampf((point - a).dot(line) / maxf(line.length_squared(), 0.00001), 0, 1)
	return point.distance_to(a + line * amount)

func play_contact(index: int, action: String, power: float, soft: bool, dump: bool) -> void:
	var team := int(index / 6)
	var old_stage := shot_stage
	var skill_key := "ricezione" if old_stage == "receive" and game.incoming_kind == "serve" else ("difesa" if old_stage == "receive" else ("palleggio" if old_stage == "set" else "schiacciata"))
	var quality := clampf(0.35 + rating(index, skill_key) / 150.0 - physical_gap(index, action) * 0.35 - maxf(0, power - 1.0) * 0.55, 0.1, 1.0)
	register_contact(index, action, quality)
	game.touches[team] += 1
	if game.touches[team] > 3: award(1 - team, "QUATTRO TOCCHI"); return
	if old_stage == "receive":
		shot_stage = "set"; game.possession = team
		var target := Tactics.setter_position(team) + Vector3(0.0, 2.12, 0.0)
		var spread := (1.0 - quality) * 1.5
		target += Vector3(random.randfn(0, spread), 0, random.randfn(0, spread * 0.7))
		launch(target, 1.45 + (1.0 - quality) * 0.25)
	elif old_stage == "set" and not dump:
		last_attack_setter = index
		shot_stage = "attack"; game.possession = team
		actor = choose_hitter(team); game.hitter = actor
		var target := attack_lane(actor) + Vector3(0.0, 2.95, 0.0)
		var spread := (1.0 - quality) * 0.7
		target += Vector3(random.randfn(0, spread), 0, random.randfn(0, spread * 0.5))
		# A manual setter directs the set with RS without changing LS movement.
		if is_manual(index) and current_aim().length() > 0.2:
			var direction := current_aim()
			target.x = clampf(direction.x * 3.8, -4.0, 4.0)
			target.z = (1.35 if direction.y < 0.3 else 3.65) * (1.0 if team == 0 else -1.0)
			actor = nearest_hitter(team, target); game.hitter = actor
		requested_set = false
		var seconds := 1.35 if not (Tactics.ROLES[actor % 6].begins_with("MB") and is_front(actor)) else 1.0
		# The AI has to run the entire approach; this is deliberately hittable.
		seconds = maxf(seconds, flat_gap(actor, target) / 4.4 + 0.42) if not is_manual(actor) else seconds
		launch(target, seconds)
	else:
		shot_stage = "receive"; game.possession = 1 - team
		var target := aimed_target(1 - team, false) if is_manual(index) else ai_attack_target(1 - team)
		var seconds := lerpf(1.30, 0.83, clampf(power, 0, 1))
		seconds/=maxf(1.0,power)
		if soft or dump or action in ["receive", "recovery", "dive"]:
			seconds = 1.7 if action in ["receive", "recovery", "dive"] else 1.3
			if soft or dump: target.z = (2.0 + absf(current_aim().y) * 2.4) * (1.0 if 1 - team == 0 else -1.0)
		var spread := (1.0 - quality) * 0.9 + maxf(0.0, power - 1.0) * 6.0
		target += Vector3(random.randfn(0, spread * 0.5), 0, random.randfn(0, spread * 0.45))
		game.incoming_kind = "soft" if soft or dump else "spike"
		point_last_hitter = index if action == "attack" else -1
		last_blocker = -1
		game.touches[1 - team] = 0
		launch(target, seconds)

func nearest_hitter(team: int, target: Vector3) -> int:
	var best := -1; var cost := INF
	for i in range(team * 6, team * 6 + 6):
		if i == last_actor or is_libero(i): continue
		var value := flat_gap(i, target)
		if value < cost: best = i; cost = value
	return best if best >= 0 else team * 6

func current_aim() -> Vector2:
	var direction := aim_input
	var keyboard := Vector2(float(keys.get(KEY_RIGHT, false)) - float(keys.get(KEY_LEFT, false)), float(keys.get(KEY_DOWN, false)) - float(keys.get(KEY_UP, false)))
	if keyboard.length_squared() > 0.0: direction = keyboard
	return direction.limit_length(1.0) if direction.length() > INPUT_DEADZONE else Vector2.ZERO

func aimed_target(team: int, serve: bool) -> Vector3:
	var direction := current_aim()
	var depth := clampf(6.2 - direction.y * 2.5, 2.0, 8.8)
	if serve: depth = clampf(6.0 - direction.y * 2.3, 3.5, 8.5)
	return Tactics.world(team, -direction.x * 4.0 if team == 1 else direction.x * 4.0, depth) + Vector3(0, BALL_RADIUS, 0)

func ai_attack_target(team: int) -> Vector3:
	var x := random.randf_range(-3.6, 3.6)
	var depth := random.randf_range(4.0, 8.0)
	return Tactics.world(team, x, depth) + Vector3(0, BALL_RADIUS, 0)

func try_block(previous: Vector3) -> void:
	if not live or shot_stage != "receive" or game.incoming_kind == "serve" or absf(game.ball_pos.z) > 1.0: return
	var team: int = game.possession
	for i in range(team * 6, team * 6 + 6):
		if not is_front(i) or is_libero(i) or heights[i] < 0.2 or cooldowns[i] > 0.0: continue
		var hands := hand_point(i, "block")
		if hands.y < NET_HEIGHT or absf(hands.z) > 0.95: continue
		if distance_to_segment(hands, previous, game.ball_pos) > 0.43: continue
		var skill:=rating(i,"muro")/99.0
		register_contact(i, "block", clampf(.35+skill*.55,0,1))
		last_blocker = i; point_last_hitter = -1
		game.touches[team] = 0
		game.possession = 1 - team
		var solid: bool=random.randf()<.20+skill*.55
		var lateral:=lerpf(1.8,.6,skill)
		var depth:=random.randf_range(.8,2.3) if solid else random.randf_range(1.8,4.8)
		var target := Tactics.world(1 - team, clampf(game.ball_pos.x + random.randf_range(-lateral, lateral), -4.1, 4.1), depth) + Vector3(0, BALL_RADIUS, 0)
		game.incoming_kind = "block"; shot_stage = "receive"
		launch(target, random.randf_range(.42,.66) if solid else random.randf_range(.72,1.12))
		return

func register_contact(index: int, action: String, quality: float) -> void:
	var gap := physical_gap(index, action)
	var entry := {"player":index,"team":int(index / 6),"action":action,"gap":gap,"ball":game.ball_pos,"root":game.players[index].position,"time":game.clock_time,"manual":is_manual(index)}
	contact_log.append(entry); game.contact_log.append(entry)
	game.max_contact_gap = maxf(game.max_contact_gap, gap)
	game.test_contacts += 1; game.test_rallies += 1
	last_actor = index; last_team = int(index / 6)
	game.last_touch = last_team
	cooldowns[index] = 0.24
	var p = game.players[index]
	p.play(action, 1.0, false)
	# Arm IK is bounded by Avatar; it follows only a validated nearby ball.
	p.reach_target = game.ball_pos; p.reach_action = action; p.reach_weight = 1.0
	p.prepare_contact(action, 0.0)
	contact_points[index] = game.ball_pos
	p.reach_target = game.ball_pos + Vector3.UP * source_lift(p)
	p.apply_pose(0.0)
	var audio = game.get("match_audio")
	if is_instance_valid(audio): audio.contact(action, game.ball_pos, clampf(quality, 0.2, 1.0))
	if is_manual(index):
		performance.contacts += 1; performance.touches += 1; performance.quality_sum += quality
		if action == "attack": performance.attacks += 1
		elif action == "block": performance.block_touches += 1
		elif action in ["set", "fast_set"]: performance.sets += 1
		elif action in ["receive", "recovery", "dive"]:
			if game.incoming_kind == "serve": performance.receptions += 1
			else: performance.digs += 1
		notice({"receive":"BAGHER","set":"ALZATA","attack":"ATTACCO","block":"TOCCO A MURO","dive":"DIFESA IN TUFFO","recovery":"RECUPERO","dump":"SECONDA","float":"BATTUTA FLOAT","power":"BATTUTA IN SALTO"}.get(action, "TOCCO") + " · %.0f%%" % (quality * 100.0), 1.0)

func award(team: int, reason: String) -> void:
	if not active or game.phase == "POINT" or game.match_finished: return
	team = clampi(team, 0, 1)
	game.scores[team] += 1
	point_total += 1; game.test_points += 1
	if game.server != team: game.rotations[team] = posmod(game.rotations[team] + 1, 6)
	game.server = team; game.point_reason = reason
	if team == 0:
		performance.team_points += 1
		if manual_available and last_blocker == controlled_index and last_actor == controlled_index: performance.blocks += 1
		elif manual_available and point_last_hitter == controlled_index and last_actor == controlled_index: performance.kills += 1
		elif manual_available and game.incoming_kind == "serve" and last_actor == controlled_index: performance.aces += 1
		if manual_available and point_last_hitter >= 0 and last_actor == point_last_hitter and last_attack_setter == controlled_index:
			performance.assists = mini(performance.sets, performance.assists + 1)
	elif is_manual(last_actor) and reason in ["FUORI", "QUATTRO TOCCHI", "FUORI ANTENNA"]: performance.errors += 1
	performance.points = performance.kills + performance.aces + performance.blocks
	var target: int = 15 if game.sets[0] + game.sets[1] == game.match_best_of - 1 else game.match_points
	if game.scores[team] >= target and game.scores[team] - game.scores[1 - team] >= 2:
		set_scores.append(game.scores.duplicate())
		game.sets[team] += 1; set_number += 1
		game.scores = [0, 0]
		game.point_reason = "SET " + game.team_names[team]
		if game.sets[team] >= int(game.match_best_of / 2) + 1:
			game.match_finished = true
			game.winner_team = team
			game.point_reason = "VITTORIA " + game.team_names[team]
		else:
			# Service alternates between sets, including the deciding set.
			game.server = posmod(first_server + set_number, 2)
			game.rotations = [0, 0]
	game.phase = "POINT"; game.phase_time = 0.0; point_clock = 0.0; live = false
	game.charging = false; manual_kind = ""; swing_left = 0.0
	notice(game.point_reason, 2.0)
	var audio = game.get("match_audio")
	if is_instance_valid(audio): audio.point_event(team == game.home_team)
	if game.match_finished and not finished_sent:
		finished_sent = true
		var away: bool = not str(config.get("home_club_id", "")).is_empty() and str(config.get("club", {}).get("id", "")) != str(config.get("home_club_id", ""))
		var ordered_sets: Array = [game.sets[1], game.sets[0]] if away else game.sets.duplicate()
		var ordered_scores: Array = []
		for score in set_scores: ordered_scores.append([score[1], score[0]] if away else score.duplicate())
		var result := {"winner":1 - team if away else team,"winner_team":1 - team if away else team,"won":team == 0,"sets":ordered_sets,"set_scores":ordered_scores,"score_order":"home_away","fixture_id":str(config.get("fixture_id", "")),"performance":performance.duplicate(true),"points_played":point_total,"mode":"legend_manual","role":role,"player_id":str(config.get("player", {}).get("id", "")),"duration":game.clock_time}
		match_finished.emit(result)

func hud_state() -> Dictionary:
	if game == null or not active: return {"active":false}
	var name: String = str(config.get("player", {}).get("name", "IL TUO GIOCATORE"))
	var context: String = {"serve":"BATTUTA MANUALE","receive":"RICEZIONE / DIFESA","set":"SECONDO TOCCO / ALZATA","attack":"ATTACCO / COPERTURA"}.get(shot_stage, "IN CAMPO")
	if game.phase == "POINT": context = game.point_reason
	elif game.possession != 0 and shot_stage != "serve": context = "MURO / DIFESA"
	if not manual_available: context = "IN PANCHINA · ATTENDI IL RIENTRO IN SECONDA LINEA"
	return {"active":true,"manual":true,"manual_available":manual_available,"player_name":name,"name":name,"role":role,"controlled_index":controlled_index,"team":0,"energy":energy,"power":game.charge,"charging":game.charging,"context":context,"feedback":game.feedback,"feedback_left":game.feedback_left,"stage":shot_stage,"requested_set":requested_set,"jumping":manual_available and heights[controlled_index] > 0.03,"height":heights[controlled_index],"can_jump":manual_available and heights[controlled_index] < 0.015 and dive_left[controlled_index] <= 0.0,"aim":current_aim(),"suggestion":suggestion,"performance":performance.duplicate(),"controls":"LS MUOVI · RS MIRA · R1/RB SALTA · X/A CARICA/RILASCIA · QUADRATO/X FLOAT/TIP · CERCHIO/B SECONDA/RECUPERO · L1/LB CHIAMA · L2/LT SPRINT · R2/RT TUFFO","keyboard":"WASD MUOVI · FRECCE MIRA · R SALTA · SPAZIO CARICA/RILASCIA · Q FLOAT/TIP · E SECONDA/RECUPERO · F CHIAMA · SHIFT SPRINT · C TUFFO"}

func notice(message: String, seconds: float = 1.5) -> void:
	game.feedback = message; game.feedback_left = seconds
	if game.has_method("notice"): game.notice(message, seconds)

func update_visuals(dt: float) -> void:
	var ball = game.get("ball")
	if is_instance_valid(ball):
		ball.position = game.ball_pos
		ball.quaternion = Contact.spin_rotation(ball.quaternion, spin, dt)
	var shadow = game.get("shadow")
	if is_instance_valid(shadow): shadow.position = Vector3(game.ball_pos.x, 0.034, game.ball_pos.z); shadow.scale = Vector3.ONE * (1.0 + maxf(0.0, game.ball_pos.y) * 0.06)
	var marker = game.get("marker")
	if is_instance_valid(marker): marker.visible = false
	for i in 12:
		var p = game.players[i]
		if p.reach_weight > 0.0: p.reach_target = contact_points[i] + Vector3.UP * source_lift(p)
		p.tick(dt, is_manual(i), true)
		# Source clips contain their own vertical jump. Remove that translation
		# so only the explicit physics takeoff controls actual/visible height.
		if p.visual_root != null: p.visual_root.position.y = visual_offsets[i] - source_lift(p)
		if p.reach_weight > 0.0: p.reach_weight = maxf(0.0, p.reach_weight - dt * 2.5)

func source_lift(p) -> float:
	if p.last_pose.is_empty() or not p.clips.has("idle") or p.clip_name not in ["attack", "block", "power", "float", "set", "fast_set", "dump"]: return 0.0
	var left: int = p.clips.idle.names.find("LeftFoot")
	var right: int = p.clips.idle.names.find("RightFoot")
	if left < 0 or right < 0: return 0.0
	return maxf(0.0, minf(p.last_pose[left].origin.y, p.last_pose[right].origin.y) - 0.09)

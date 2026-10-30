extends SceneTree
## Run: tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Test-LegendManual72.gd
## Real avatars and league identities, with a small render-free host for the isolated manual engine.
const Avatar = preload("res://src/avatar.gd")
const League = preload("res://src/league.gd")
const Rotation = preload("res://src/rotation_model.gd")

class MatchHost extends Node3D:
	var players: Array = []
	var clips: Dictionary = {}
	var models: Dictionary = {}
	var ball: MeshInstance3D
	var shadow: MeshInstance3D
	var marker: MeshInstance3D
	var camera: Camera3D
	var hud: Control
	var dynamic_net = null
	var match_audio = null
	var arena_visuals = null
	var match_management = null
	var replay = null
	var substitution_scene = null
	var tutorial = null
	var preferences = null
	var phase := "SERVE"
	var phase_time := 0.0
	var clock_time := 0.0
	var server := 0
	var possession := 0
	var scores := [0, 0]
	var sets := [0, 0]
	var rotations := [0, 0]
	var touches := [0, 0]
	var team_names := ["HOME", "AWAY"]
	var match_best_of := 5
	var match_points := 25
	var match_finished := false
	var winner_team := -1
	var selected := 0
	var receiver := 0
	var setter := 5
	var hitter := 0
	var destination := 0
	var ball_pos := Vector3.ZERO
	var ball_vel := Vector3.ZERO
	var flight_spin := Vector3.ZERO
	var flight_target := Vector3.ZERO
	var flight_gravity := 9.81
	var flight_left := 0.0
	var airborne := false
	var last_touch := 0
	var incoming_kind := "serve"
	var incoming_power := 0.7
	var charging := false
	var charge := 0.0
	var charge_start := 0.0
	var last_power := 0.0
	var armed := false
	var aim := Vector2(0, -1)
	var block_time := -100.0
	var feedback := ""
	var feedback_left := 0.0
	var receive_feedback := ""
	var receive_feedback_left := 0.0
	var point_reason := ""
	var started := false
	var paused := false
	var demo := false
	var gallery := false
	var self_test := true
	var use_player_stats := false
	var home_club_id := ""
	var home_team := 0
	var input_team := 0
	var rally_serial := 0
	var shot_serial := 0
	var test_points := 0
	var test_contacts := 0
	var test_rallies := 0
	var max_rally := 0
	var max_contact_gap := 0.0
	var contact_log: Array[Dictionary] = []
	var rally_events: Array[Dictionary] = []
	var play_log: Array[Dictionary] = []
	var match_condition: Array = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
	var rng := RandomNumberGenerator.new()

	func notice(message: String, seconds: float = 1.5) -> void:
		feedback = message
		feedback_left = seconds

	func server_index(team: int) -> int:
		for index in range(team * 6, team * 6 + 6):
			if Rotation.slot(index, rotations[team]) == 3: return index
		return team * 6

	func set_home_club(club_id: String, side: int = 0) -> void:
		home_club_id = club_id
		home_team = side

	func log_rally_event(kind: String, details: Dictionary = {}) -> void:
		var record := details.duplicate(true)
		record.kind = kind
		rally_events.append(record)

var game: MatchHost
var legend
var league
var failures: Array[String] = []
var checks := 0
var finished: Array[Dictionary] = []
var report: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("LEGEND MANUAL 72: " + message)

func make_game() -> void:
	game = MatchHost.new()
	root.add_child(game)
	game.ball = MeshInstance3D.new()
	game.shadow = MeshInstance3D.new()
	game.marker = MeshInstance3D.new()
	game.add_child(game.ball)
	game.add_child(game.shadow)
	game.add_child(game.marker)
	for index in 12:
		var avatar = Avatar.new()
		game.add_child(avatar)
		avatar.setup({}, int(index / 6), index % 6 + 1, {})
		game.players.append(avatar)
	legend = load("res://src/legend_match.gd").new()
	legend.game = game
	game.add_child(legend)
	legend.match_finished.connect(func(result: Dictionary): finished.append(result.duplicate(true)))

func config(role: String = "OH", best_of: int = 3) -> Dictionary:
	var home: Dictionary = league.teams[0]
	var away: Dictionary = league.teams[1]
	var lineup: Array = league.lineup(home).duplicate(true)
	var mapping := {"OH":0, "MB":1, "OPP":2, "S":5, "L":6}
	var person: Dictionary = lineup[mapping[role]].duplicate(true)
	person.id = "legend-test-" + role
	person.name = "Manual Test " + role
	return {"player":person, "role":role, "club":home, "opponent":away,
		"home_club_id":home.id, "club_lineup":lineup,
		"opponent_lineup":league.lineup(away).duplicate(true), "teams":league.teams,
		"best_of":best_of, "points":25, "seed":72001}

func tick(seconds: float) -> void:
	for frame in int(ceil(seconds * 120.0)):
		legend.step(1.0 / 120.0)

func restart(role: String = "OH", best_of: int = 3) -> void:
	legend.stop()
	finished.clear()
	check(legend.start(config(role, best_of)), "start accepts valid " + role + " configuration")

func test_roles_and_rng() -> void:
	var expected := {"S":5, "MB":1, "OH":0, "OPP":2, "L":4}
	for role in expected:
		game.rng.seed = 72072
		var original_rng_state := game.rng.state
		restart(role)
		check(legend.active, role + " starts active")
		check(legend.controlled_index == expected[role], role + " has its fixed player index")
		check(game.players.size() == 12, role + " retains twelve athletes")
		check(game.use_player_stats, role + " uses active player ratings")
		check(game.rng.state == original_rng_state, role + " leaves the other modes' RNG untouched")
		var selected: int = legend.controlled_index
		var origin: Vector3 = game.players[selected].position
		tick(0.25)
		check(legend.controlled_index == selected, role + " does not switch selected athlete during play")
		check(game.players[selected].position.distance_to(origin) < 0.001, role + " never runs or jumps without input")
	report.roles = expected

func test_motion_and_jump() -> void:
	restart()
	var avatar = game.players[legend.controlled_index]
	var origin: Vector3 = avatar.position
	legend.move_input = Vector2(1, 0)
	legend.aim_input = Vector2(-1, -0.4)
	legend.step(1.0 / 120.0)
	var first_speed: float = Vector2(avatar.velocity.x, avatar.velocity.z).length()
	check(first_speed > 0.0 and first_speed < 3.0, "movement accelerates continuously from rest")
	tick(0.27)
	var running_speed: float = Vector2(avatar.velocity.x, avatar.velocity.z).length()
	check(avatar.position.x > origin.x + 0.15, "left stick directly moves the controlled athlete")
	check(running_speed > first_speed + 0.4, "movement builds speed over successive frames")
	check(absf(avatar.position.z - origin.z) < 0.05, "right-stick aim does not steer movement")
	legend.move_input = Vector2.ZERO
	legend.step(1.0 / 120.0)
	var braking_speed: float = Vector2(avatar.velocity.x, avatar.velocity.z).length()
	check(braking_speed > 0 and braking_speed < running_speed, "releasing movement brakes over time")
	tick(0.5)
	check(Vector2(avatar.velocity.x, avatar.velocity.z).length() < 0.05, "braking reaches a stationary stance")
	check(absf(avatar.position.y) < 0.01, "movement alone never initiates a jump")
	check(legend.jump(), "manual jump is accepted while grounded")
	tick(0.12)
	check(avatar.position.y > 0.15, "manual jump changes the player's physical height")
	check(not legend.jump(), "airborne player cannot double jump")
	tick(1.0)
	check(absf(avatar.position.y) < 0.015, "manual jump lands on the floor")
	report.motion = {"first_speed":first_speed, "running_speed":running_speed, "braking_speed":braking_speed}

func test_set_distribution() -> void:
	restart("OH")
	legend.last_actor=5
	var counts: Dictionary={}
	for trial in 200:
		var hitter: int=legend.choose_hitter(0)
		counts[hitter]=int(counts.get(hitter,0))+1
	check(int(counts.get(0,0))>35 and counts.size()>1,"ordinary AI sets involve the created player and other attackers")
	legend.requested_set=true
	for trial in 20: check(legend.choose_hitter(0)==0,"an explicit L1/LB request prioritizes the manual athlete")
	report.set_distribution=counts
	game.phase="RECEIVE"; game.possession=1
	var difficulty_means: Array=[]
	for level in 3:
		legend.difficulty=level; legend.random.seed=720122
		var total:=0.0
		for trial in 200: total+=legend.ai_quality()
		difficulty_means.append(total/200)
	check(difficulty_means[0]<difficulty_means[1] and difficulty_means[1]<difficulty_means[2],"difficulty affects opponent execution in the manual match")
	report.difficulty_means=difficulty_means

func test_block_rating_and_overcharge() -> void:
	restart("OH")
	var counts: Array=[]
	for skill in [30,95]:
		legend.random.seed=720440; var solid:=0
		game.players[0].roster_identity.ratings.muro=skill
		for trial in 200:
			game.players[0].position=Vector3(0,.8,.55); legend.heights[0]=.8; legend.cooldowns[0]=0
			game.phase="RECEIVE"; game.possession=0; game.incoming_kind="spike"
			legend.live=true; legend.shot_stage="receive"; legend.last_actor=6
			game.ball_pos=legend.hand_point(0,"block"); game.ball_vel=Vector3(0,-1,8)
			legend.try_block(game.ball_pos-Vector3(0,0,.1))
			if legend.flight_duration<.68: solid+=1
		counts.append(solid)
	check(counts[1]>counts[0]+30,"improving the block attribute produces more strong returns at the same physical contact")
	var speeds: Array=[]
	for power in [1.0,1.1]:
		restart("OH"); game.players[0].position=Vector3(2.4,.8,10)
		game.ball_pos=legend.hand_point(0,"power"); legend.serve_ball(0,power,false)
		speeds.append(legend.flight_duration)
	check(speeds[1]<speeds[0]*.92,"110 percent serve power remains physically faster than 100 percent")
	report.block_attribute={"low":counts[0],"high":counts[1]}
	report.overcharge_serve_seconds=speeds

func test_service_takeoff() -> void:
	var cases: Array=[{"takeoff":9.4,"contact":8.8,"height":.8,"float":false,"legal":true},{"takeoff":8.8,"contact":9.4,"height":.8,"float":false,"legal":false},{"takeoff":9.4,"contact":8.8,"height":0.0,"float":true,"legal":false}]
	for sample in cases:
		restart("OH"); game.phase="SERVE"; game.server=0
		legend.actor=0; legend.service_toss=true
		legend.jump_origin[0]=Vector3(1.2,0,sample.takeoff); legend.heights[0]=sample.height
		game.players[0].position=Vector3(1.2,sample.height,sample.contact)
		game.ball_pos=legend.hand_point(0,"float" if sample.float else "power")
		var hit: bool=legend.attempt_manual("alternate" if sample.float else "action",.85)
		check(hit==sample.legal,"service judges the last ground contact, including a legal forward jump")
		if not sample.legal: check(game.phase=="POINT" and game.point_reason=="FALLO DI PIEDE","illegal takeoff and standing inside the court remain foot faults")
	report.service_takeoff=true

func test_input_and_gap() -> void:
	restart()
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.82
	check(legend.handle_input(motion), "left stick input belongs to manual mode")
	check(legend.move_input.x > 0.7, "left stick input updates continuous movement")
	motion = InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = -0.74
	legend.handle_input(motion)
	check(legend.aim_input.x < -0.6 and legend.move_input.x > 0.7, "the two sticks remain independent")
	legend.move_input = Vector2.ZERO
	var start_button := InputEventJoypadButton.new()
	start_button.button_index = JOY_BUTTON_START
	start_button.pressed = true
	check(not legend.handle_input(start_button), "pause remains owned by the existing main flow")
	var avatar = game.players[legend.controlled_index]
	game.phase = "RECEIVE"
	game.possession = 0
	legend.live = true; legend.shot_stage = "receive"; legend.last_actor = 6
	game.ball_pos = avatar.position + Vector3(3.5, 1.15, 0)
	game.ball_vel = Vector3(1, -1, 2)
	var before: Vector3 = game.ball_pos
	var velocity_before: Vector3 = game.ball_vel
	check(not legend.attempt_manual("action", 0.7), "a manual action fails when the ball is physically distant")
	check(game.ball_pos.is_equal_approx(before) and game.ball_vel.is_equal_approx(velocity_before), "a failed distant action cannot teleport or redirect the ball")
	var jump_button := InputEventJoypadButton.new()
	jump_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	jump_button.pressed = true
	check(legend.handle_input(jump_button), "RB/R1 is consumed by manual jumping")
	tick(0.1)
	check(avatar.position.y > 0.1, "RB/R1 initiates a physical jump")
	legend.press("action")
	game.paused = true
	motion = InputEventJoypadMotion.new(); motion.axis = JOY_AXIS_LEFT_X; motion.axis_value = 0
	legend.handle_input(motion)
	legend.release("action")
	check(legend.move_input == Vector2.ZERO and not game.charging and legend.manual_kind == "", "paused stick and button releases clear held input without triggering actions")
	game.paused = false
	report.physical_gap = true

func test_ai_rallies() -> void:
	restart("L")
	var crossings := 0
	var previous_z: float = game.ball_pos.z
	var starting_points: int = game.test_points
	var starting_contacts: int = game.test_contacts
	var seen_phases: Dictionary = {}
	for frame in 18000:
		if not legend.active or game.match_finished: break
		# The test driver only supplies a real user's service input when that fixed player serves.
		if game.phase == "SERVE" and game.server == 0 and game.server_index(0) == legend.controlled_index:
			if frame % 120 == 5: legend.press("action")
			if frame % 120 == 70: legend.release("action")
		legend.step(1.0 / 120.0)
		if previous_z * game.ball_pos.z < 0: crossings += 1
		previous_z = game.ball_pos.z
		seen_phases[game.phase] = true
	var points: int = game.test_points - starting_points
	var contacts: int = game.test_contacts - starting_contacts
	check(crossings >= 5, "AI teammates and opponents produce repeated real net crossings")
	check(points >= 3, "AI rallies reach physical point outcomes")
	check(contacts >= 12, "the eleven autonomous players continue contacting the ball")
	check(game.max_contact_gap < 1.0, "recorded contacts stay within a physical player's reach")
	check(legend.controlled_index == 4, "autonomous rallies never take control of another athlete")
	report.ai = {"crossings":crossings, "points":points, "contacts":contacts, "phases":seen_phases.keys(), "max_contact_gap":game.max_contact_gap}
	var actions: Dictionary = {}
	for contact in legend.contact_log: actions[contact.action] = actions.get(contact.action, 0) + 1
	report.ai.actions = actions
	check(actions.get("set", 0) >= 3 and actions.get("attack", 0) >= 3, "AI rallies include actual setting and attacking contacts")

func prepare_manual(stage: String, kind: String, position: Vector3) -> Vector3:
	game.phase = {"receive":"RECEIVE", "set":"SET", "attack":"ATTACK"}[stage]
	game.possession = 0; game.touches = [0, 0]
	legend.live = true; legend.shot_stage = stage; legend.actor = legend.controlled_index
	legend.last_actor = 6; legend.last_team = 1
	var avatar = game.players[legend.controlled_index]
	avatar.position = position
	game.ball_pos = legend.hand_point(legend.controlled_index, kind)
	game.ball_vel = Vector3(0, -1, 0)
	return game.ball_pos

func test_manual_contacts() -> void:
	restart("OH")
	var original := prepare_manual("receive", "receive", Vector3(0, 0, 5.5))
	check(legend.attempt_manual("action", 0.65), "a nearby manually commanded forearm pass succeeds")
	check(game.ball_pos.is_equal_approx(original), "a successful pass redirects velocity without snapping ball position")
	check(legend.shot_stage == "set" and game.ball_vel.y > 0, "manual reception launches a genuine high pass")
	restart("S")
	prepare_manual("set", "set", Vector3(1.2, 0, 1.0))
	check(legend.attempt_manual("action", 0.7), "manual setter can make the second contact")
	check(legend.performance.sets == 1 and legend.shot_stage == "attack", "manual setting creates a real attack trajectory and measured stat")
	restart("OH")
	game.players[0].position = Vector3(-3.3, 0, 1.4)
	check(legend.jump(), "attack requires an explicit player takeoff")
	tick(0.24)
	var height: float = game.players[0].position.y
	prepare_manual("attack", "attack", Vector3(-3.3, height, 1.4))
	legend.aim_input = Vector2(0.9, -0.4)
	check(legend.attempt_manual("alternate", 0.65), "manual airborne player can direct a tip with the alternate button")
	check(legend.performance.attacks == 1 and legend.shot_stage == "receive", "manual airborne contact sends the ball toward real opponent defense")
	check(not game.match_finished and game.phase != "POINT", "a well charged manual shot never forces an instant point")
	restart("S")
	legend.press("alternate")
	tick(0.20)
	check(absf(game.players[5].position.y) < 0.001, "float service does not jump the athlete automatically")
	legend.release("alternate")
	check(game.phase == "CPU_RECEIVE" and legend.performance.serves == 1, "manual ground float service contacts its physical toss")
	restart("S")
	legend.press("action")
	tick(0.18)
	legend.jump()
	tick(0.24)
	legend.release("action")
	check(game.phase == "CPU_RECEIVE" and legend.performance.serves == 1, "manual R1 jump plus release can hit a power serve")
	restart("OH")
	game.players[0].position = Vector3(0, 0, 0.55)
	game.possession = 1
	legend.jump()
	tick(0.25)
	game.phase = "RECEIVE"; game.possession = 0; game.incoming_kind = "spike"
	legend.live = true; legend.shot_stage = "receive"; legend.last_actor = 6
	game.ball_pos = legend.hand_point(0, "block")
	game.ball_vel = Vector3(0, -1, 8)
	legend.try_block(game.ball_pos - Vector3(0, 0, 0.1))
	check(legend.performance.block_touches == 1 and legend.last_actor == 0, "a manual jump blocks only when raised hands physically meet the ball")
	restart("OH")
	game.players[0].position = Vector3(0, 0, 0.55)
	game.phase = "RECEIVE"; game.possession = 0; game.incoming_kind = "spike"
	legend.live = true; legend.shot_stage = "receive"; legend.last_actor = 6
	game.ball_pos = Vector3(0, 3.15, 0.15); game.ball_vel = Vector3(0, -1, 8)
	legend.try_block(game.ball_pos - Vector3(0, 0, 0.1))
	check(legend.last_actor == 6, "standing near the net cannot produce an automatic block or jump")
	var grounded: Vector3 = game.players[0].position
	legend.press("action")
	tick(0.10)
	check(absf(game.players[0].position.y - grounded.y) < 0.001, "holding an action never jumps the controlled root")
	report.manual_contacts = true

func test_full_physical_match() -> void:
	restart("L", 3)
	for frame in 160000:
		if game.match_finished: break
		legend.step(1.0 / 120.0)
	check(game.match_finished and finished.size() == 1, "an entire best of three completes from ball physics and AI without scoring shortcuts")
	check(game.test_points >= 50 and game.test_contacts >= 100, "the complete match includes regulation scores and repeated real contacts")
	check(legend.controlled_index == 4, "a full match never switches the fixed libero identity")
	check(not (legend.manual_available and legend.service_index(0) == 4), "the controlled libero never becomes the server")
	if finished.size() == 1:
		check(finished[0].performance.has("minutes") and finished[0].performance.has("serves"), "completed physical match supplies career performance schema")
	report.full_match = {"finished":game.match_finished, "points":game.test_points, "contacts":game.test_contacts, "sets":game.sets, "seconds":game.clock_time}

func test_libero_exchanges() -> void:
	restart("L")
	var original_middle: String = config("L").club_lineup[4].id
	for rotation in 6:
		game.server = 0; game.rotations[0] = rotation
		legend.reset_rally()
		var available: bool = Rotation.libero(4, rotation, true)
		check(legend.manual_available == available, "libero availability respects front row and service in rotation " + str(rotation))
		check(game.players[4].roster_identity.id == original_middle and game.players[4].libero_identity.id == "legend-test-L", "libero exchange preserves distinct original middle and custom player identities")
		check(game.players[4].libero_active == available, "the court avatar wears the correct identity for each libero exchange")
		if not available:
			check(not legend.jump() and not legend.dive(), "benched libero cannot command the AI middle's jump or dive")
			legend.press("action")
			check(legend.manual_kind == "" and "PANCHINA" in legend.hud_state().context, "bench state suppresses manual action and explains the waiting period")
	game.server = 1; game.rotations[0] = 5
	legend.reset_rally()
	check(legend.manual_available, "libero can enter the back-row Z1 when the opponent serves")
	report.libero_exchanges = true

func direct_point(team: int) -> void:
	# Scoring assertions do not bypass the rally test above; each starts a fresh dead-ball interval.
	game.phase = "RECEIVE"
	legend.award(team, "TEST SCORING")

func test_scoring_and_match() -> void:
	restart("S", 3)
	game.server = 0
	game.rotations = [0, 0]
	direct_point(1)
	check(game.scores == [0, 1] and game.server == 1, "sideout transfers service and awards one point")
	check(game.rotations == [0, 1], "only a sideout winner rotates")
	direct_point(1)
	check(game.rotations == [0, 1], "retained service does not rotate again")
	game.scores = [24, 24]
	direct_point(0)
	check(game.sets == [0, 0], "24-all requires a two-point lead")
	direct_point(0)
	check(game.sets == [1, 0], "a regulation set closes at 26-24")
	game.scores = [24, 0]
	direct_point(0)
	check(game.match_finished and finished.size() == 1, "best of three ends after the second set victory exactly once")
	if finished.size() == 1:
		check(finished[0].has("set_scores") and finished[0].has("performance"), "match result includes set scores and the player's performance")
		check(finished[0].get("sets", []) == [2, 0], "match result preserves final set totals")
	restart("L", 5)
	game.sets = [2, 2]
	game.scores = [14, 14]
	direct_point(1)
	check(not game.match_finished, "deciding fifth set requires a two-point margin at 15")
	direct_point(1)
	check(game.match_finished and game.sets == [2, 3], "deciding fifth set closes at 16-14")
	check(finished.size() == 1, "deciding-set result signal is emitted exactly once")
	legend.stop(); finished.clear()
	var away_options := config("S", 3)
	away_options.home_club_id = away_options.opponent.id
	away_options.fixture_id = "legend-away-order"
	check(legend.start(away_options), "away fixture starts with club kept on input team zero")
	game.scores = [24, 10]; direct_point(0)
	game.scores = [24, 11]; direct_point(0)
	check(finished.size() == 1 and finished[0].sets == [0, 2], "away fixture reports sets in home-away order")
	check(finished[0].set_scores == [[10, 25], [11, 25]] and finished[0].won, "away score conversion preserves the user's win and set scores")
	check(finished[0].fixture_id == "legend-away-order" and finished[0].score_order == "home_away", "career result identifies fixture and explicit score order")
	check(game.home_team == 1, "away fixture branding identifies home side correctly")
	report.scoring = {"sideout":true, "deuce_25":true, "best_of_three":true, "tie_break_15":true, "best_of_five":true}

func run() -> void:
	league = League.new()
	make_game()
	test_roles_and_rng()
	test_motion_and_jump()
	test_set_distribution()
	test_block_rating_and_overcharge()
	test_service_takeoff()
	test_input_and_gap()
	test_ai_rallies()
	test_manual_contacts()
	test_full_physical_match()
	test_libero_exchanges()
	test_scoring_and_match()
	legend.stop()
	check(not legend.active, "stop releases the manual mode")
	report.checks = checks
	report.failures = failures
	FileAccess.open("res://docs/legend72-manual.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND_MANUAL72 ", JSON.stringify(report))
	game.free()
	quit(0 if failures.is_empty() else 1)

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
const BallContact = preload("res://src/ball_contact.gd")
const Reference = preload("res://src/reference_style.gd")
const RallyAI = preload("res://src/rally_ai.gd")
const CourtShape = preload("res://src/court_shape.gd")
const MiddleDecoy = preload("res://src/middle_decoy.gd")
const AnimationVariety = preload("res://src/animation_variety.gd")
var rotation_context=preload("res://src/rotation_context.gd").new()
var rally_lanes=preload("res://src/rally_lanes.gd").new()
var contact_navigation=preload("res://src/contact_navigation.gd").new()
var next_second_touch_read:=0.0
var attack_buffer_start:=-1.0
var attack_buffer_power:=-1.0
var winner_team:=-1
var attack_tip:=false
var overpass_attack_team:=-1
var receive_offset:=0.0
var receive_feedback:=""
var receive_feedback_left:=0.0
var dynamic_net
var arena_visuals: Node3D
var serve_fault_sequence:=0
var planned_visual_key:=""
const G := 9.81
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
var team_names := ["AURORA","EMBER"]
var match_best_of:=5
var match_points:=25
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
var serve_motion_active := false
var serve_motion_player := -1
var serve_motion_action := "power"
var serve_motion_origin := Vector3.ZERO
var serve_motion_time := 0.0
var serve_motion_start_time := 0.0
var serve_toss_duration := TOSS_TIME
var serve_motion_yaw := 0.0
var serve_windup_left := 0.0
var dive_motions: Dictionary = {}
var contact_log: Array[Dictionary] = []
var max_contact_gap := 0.0
var camera_focus := Vector3(0, 1.25, -0.7)
var travel := PackedFloat32Array([0,0,0,0,0,0,0,0,0,0,0,0])
var charge_button := "action"
var setter_dump := false
var late_receive := false
var recovery_action := "receive"
var receive_deadline := 0.0
var block_helper_x := 0.0
var manual_wall=preload("res://src/manual_wall.gd").new()
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
var set_origin := Vector3.ZERO
var court_shape = CourtShape.new()
var middle_decoy=MiddleDecoy.new()
var movement_snapshot: Array[Dictionary]=[]
var traffic_blockers: Array = []
var defensive_lanes=preload("res://src/defensive_lanes.gd").new()
var cpu_defense=preload("res://src/cpu_defense.gd").new()
var defensive_coverage=preload("res://src/defensive_coverage.gd").new()
var traffic_footprints: Array = []
var play_log: Array[Dictionary] = []
var flight_spin := Vector3.ZERO
var flight_gravity := G
var incoming_kind := "serve"
var incoming_power := 0.75
var incoming_out := false
var out_of_system := 1
var setter_action := "set"
var hitter_action := "attack"
var rally_serial := 0
var shot_serial := 0
var last_shots: Array = [-1,-1]
var rally_events: Array[Dictionary] = []
var scramble_ready := PackedFloat32Array([0,0,0,0,0,0,0,0,0,0,0,0])
var net_contacts := 0
var last_ai_direction := -1
var support_travel := PackedFloat32Array([0,0,0,0,0,0,0,0,0,0,0,0])

func _ready() -> void:
	rng.seed = 194260
	setup_inputs()
	var audio_controls=preload("res://src/global_audio.gd").new()
	audio_controls.game=self
	add_child(audio_controls)
	for name in preload("res://src/psa_animation_library.gd").CLIPS:
		if "--fallback-test" in OS.get_cmdline_user_args(): continue
		var clip = PSA.new()
		if clip.load_file("res://assets/active/" + name + ".psa"):
			clip.load_hierarchy("res://assets/active/skeleton.psk")
			clip.detect_contact(name)
			clips[name] = clip
			print("ANIMATION ", name, ": ", clip.frames, " frames / ", clip.names.size(), " bones / ", clip.duration, "s / contact ", clip.contact_offset)
	if not clips.is_empty():
		for i in 7:
			var name:="attack_tip_"+str(i)
			var tip=PSA.new()
			if tip.load_file("res://assets/active/"+name+".psa"):
				tip.load_hierarchy("res://assets/active/skeleton.psk"); tip.detect_contact("attack"); clips[name]=tip
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
	var rotation_overlay=preload("res://src/rotation_overlay.gd").new()
	rotation_overlay.game=self
	canvas.add_child(rotation_overlay)
	rotation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	self_test = "--self-test" in OS.get_cmdline_user_args() or "--fallback-test" in OS.get_cmdline_user_args() or "--rally-test" in OS.get_cmdline_user_args()
	if not self_test:
		var start_menu=preload("res://src/start_menu.gd").new()
		start_menu.game=self
		add_child(start_menu)
	if self_test:
		if "--self-test" in OS.get_cmdline_user_args(): run_tests()
		elif "--fallback-test" in OS.get_cmdline_user_args():
			assert(clips.is_empty() and models.is_empty() and players.size() == 12)
			print("FALLBACK TEST: no source animations or meshes; procedural athletes active")
		started = true
		demo = true
		var target_points := 64 if "--reference-stress" in OS.get_cmdline_user_args() else 16
		for i in 240000:
			step(1.0 / 120.0)
			if test_points >= target_points or clock_time > 1999: break
		print("SIMULATION points=", test_points, " contacts=", test_contacts, " longest_rally=", max_rally, " clock=", clock_time, " max_hand_gap=", max_contact_gap)
		print("PLAYER TRAVEL METRES ", travel)
		var jump_keys: Dictionary = {}
		for event in block_jump_log:
			var key := str(event.attack_id) + ":" + str(event.player)
			assert(not jump_keys.has(key), "One block takeoff per athlete per attack")
			jump_keys[key] = true
		var report := {"points":test_points, "contacts":test_contacts, "longest_rally":max_rally, "maximum_hand_ball_gap_m":max_contact_gap, "minimum_player_spacing_m":minimum_player_gap, "minimum_block_spacing_m":minimum_block_gap, "collision_avoidances":collision_stops, "travel_metres":Array(travel), "support_travel_metres":Array(support_travel), "contact_events":contact_log, "planned_attacks":play_log, "block_jump_events":block_jump_log, "duplicate_block_jumps":0, "net_contacts":net_contacts, "rally_events":rally_events, "reference_sha256":Reference.data.assembly_sha256}
		var report_path := "res://docs/fallback-contact-report.json" if "--fallback-test" in OS.get_cmdline_user_args() else "res://docs/revision-contact-report.json"
		if "--reference-stress" in OS.get_cmdline_user_args(): report_path = "res://docs/reference-stress-report.json"
		var report_file := FileAccess.open(report_path, FileAccess.WRITE)
		if report_file: report_file.store_string(JSON.stringify(report, "  "))
		assert(max_contact_gap <= 0.18)
		for distance in travel: assert(distance > 1.0, "Every athlete must participate in coverage")
		get_tree().quit(0 if test_points >= target_points and test_contacts > 35 and max_rally >= 6 else 1)
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
		var axis:=InputEventJoypadMotion.new()
		axis.device=-1
		axis.axis=JOY_AXIS_LEFT_X if pair[0] in ["left","right"] else JOY_AXIS_LEFT_Y
		axis.axis_value=-1.0 if pair[0] in ["left","up"] else 1.0
		InputMap.action_set_deadzone(pair[0],0.22)
		if not InputMap.action_has_event(pair[0],axis): InputMap.action_add_event(pair[0],axis)
	for binding in [["block_left",KEY_Z,JOY_AXIS_TRIGGER_LEFT],["block_right",KEY_B,JOY_AXIS_TRIGGER_RIGHT]]:
		InputMap.add_action(binding[0],0.20)
		var key:=InputEventKey.new()
		key.physical_keycode=binding[1]
		InputMap.action_add_event(binding[0],key)
		var trigger:=InputEventJoypadMotion.new()
		trigger.device=-1
		trigger.axis=binding[2]
		trigger.axis_value=1.0
		InputMap.action_add_event(binding[0],trigger)

func build_arena() -> void:
	var arena = Arena.new()
	arena_visuals=arena
	add_child(arena)
	dynamic_net=arena.dynamic_net
	ball = arena.ball
	shadow = arena.shadow
	marker = arena.marker
	camera = arena.camera
	set_camera()

func set_camera() -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 48 if camera_mode == 0 else (40 if camera_mode==2 else 50)
	camera.position = preload("res://src/view_controls.gd").origin(camera_mode)
	camera_focus = Vector3(0,0.7,0) if camera_mode==2 else Vector3(0, 0.7, -0.5)
	camera.look_at(camera_focus)

func update_camera(dt: float) -> void:
	var origin := preload("res://src/view_controls.gd").origin(camera_mode)
	if camera_mode==2:
		var tv_focus:=Vector3(0,0.7+maxf(0,ball_pos.y-3.2)*0.04,clampf(ball_pos.z*0.06,-0.45,0.45))
		if phase=="SERVE": tv_focus.z=clampf(ball_pos.z*0.15,-1.2,1.2)
		camera_focus=camera_focus.lerp(tv_focus,1.0-exp(-2.5*dt))
		camera.position=camera.position.lerp(origin,1.0-exp(-1.6*dt))
		camera.look_at(camera_focus)
		return
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
			KEY_F6:
				Avatar.native_animation_enabled = not Avatar.native_animation_enabled
				notice("ANIMAZIONI: " + ("ANIMATIONTREE" if Avatar.native_animation_enabled else "PSA ORIGINALE"), 2.5)
			KEY_F3:
				gallery = not gallery
				started = true
				gallery_index = 0
				if gallery: show_clip()
				else: reset_rally()
			KEY_F5: difficulty = (difficulty + 1) % 3
			KEY_C:
				camera_mode = (camera_mode + 1) % 3
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
			return
		else:
			paused = not paused
	if event is InputEventJoypadButton and event.button_index==JOY_BUTTON_Y and event.pressed and started:
		camera_mode=(camera_mode+1)%3
		set_camera()
	if not started or paused or gallery:
		return
	if event.is_action_pressed("action") or event.is_action_pressed("alternate") or event.is_action_pressed("dump"):
		read_controls(0) # Sample triggers without integrating movement twice.
	if event.is_action_pressed("action"):
		press_action()
	if event.is_action_pressed("alternate"):
		press_action("alternate")
	if event.is_action_pressed("dump"):
		press_action("dump")
	if phase=="SET" and attack_buffer_start>=0 and event.is_action_released("action"):
		attack_buffer_power=maxf(0,(clock_time-attack_buffer_start)/Timing.ATTACK_CHARGE_SECONDS)
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

func stick(_right: bool = false) -> Vector2:
	# The left stick is exclusively tactical aim; every athlete moves by AI.
	var result := Input.get_vector("left", "right", "up", "down")
	var id := pad()
	if id >= 0:
		var axes := Vector2(Input.get_joy_axis(id, JOY_AXIS_LEFT_X), Input.get_joy_axis(id, JOY_AXIS_LEFT_Y))
		if axes.length() >= 0.22: result = axes
	var arrows := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
	if arrows != Vector2.ZERO: result = arrows
	return result.limit_length()

func read_controls(dt: float = 1.0/120.0) -> void:
	var direction := preload("res://src/view_controls.gd").court_direction(stick(),camera_mode)
	if human_wall(): manual_wall.read(self,direction,dt)
	if direction.length() > 0.3:
		var angle := roundf(direction.angle() / (PI / 4)) * PI / 4
		aim = direction.limit_length() if phase=="SERVE" else Vector2.from_angle(angle)
		if absf(direction.x) > absf(direction.y):
			set_dir = 0 if direction.x < 0 else 2
		else:
			set_dir = 1 if direction.y < 0 else 3
		if clock_time - block_time < 0.65: block_hand = direction.x
	if phase == "SET" and not armed and not demo:
		plan_attack(set_dir, fast_set)

func press_action(button: String = "action") -> void:
	if phase=="ATTACK" and hitter_action=="attack" and button=="alternate" and not armed:
		if charging: return
		attack_tip=true; charging=true; charge_button="alternate"; charge_start=clock_time; charge=0; input_quality=1.0
		players[hitter].select_variant("attack",preload("res://src/shot_variation.gd").tip_variant(aim,shot_serial))
		hitter_action="attack"
		var intercept:=BallFlight.intercept(ball_pos,ball_vel,flight_spin,players[hitter].contact_local("attack").y,flight_gravity)
		if not intercept.is_empty(): flight_target=intercept.point; flight_left=maxf(0.001,intercept.seconds)
		notice("PALLONETTO · COLPO DI POLSO",0.9)
		return
	if phase=="SET" and armed and button=="action":
		attack_buffer_start=clock_time; attack_buffer_power=-1.0
		return
	if phase == "SERVE" and server == 0 and not charging and not toss_active and button != "dump":
		serve_type = 0 if button == "alternate" else 1
		charge_button = button
		charging = true
		charge_start = clock_time
		players[server_index(server)].play("serve_idle", 1.0, true)
	elif phase == "ATTACK" and not armed and not charging and button == "action":
		charge_button = button
		charging = true
		charge_start = clock_time
	elif phase == "RECEIVE" and not armed and button == "action":
		var remaining := receive_deadline - clock_time
		receive_offset=remaining
		if remaining < -Timing.LATE_RECEIVE_SECONDS: return
		input_quality = minf(lerpf(1.0,Reference.receive_quality(ball_pos.distance_to(players[receiver].contact_world("receive")), difficulty_scale()),0.825),timing.quality(remaining,difficulty_scale())) if remaining >= 0 else timing.quality(remaining, difficulty_scale())
		if remaining < 0:
			var recovery := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("recovery"), flight_gravity)
			if recovery.is_empty() or recovery.seconds > 0.18 or recovery.seconds < 0: return
			late_receive = true
			recovery_action = "recovery"
			flight_target = recovery.point
			flight_left = maxf(0.001, recovery.seconds)
		armed = true
		receive_feedback=preload("res://src/shot_variation.gd").reception_label(remaining)+" · %d%%"%roundi(input_quality*100)
		receive_feedback_left=2.4
		notice(receive_feedback,1.4)
	elif phase == "SET" and not armed:
		setter_dump = button == "dump"
		plan_attack(set_dir, button == "alternate")
		setter_action = "dump" if setter_dump else ("receive" if out_of_system < 0 else ("fast_set" if fast_set else "set"))
		# Normal and quick are choices of delivery, not a new interception
		# deadline. Only a genuinely different contact (dump/bump) changes height.
		var height: float=players[setter].contact_local(setter_action).y
		if setter_action in ["set","fast_set"]: height=flight_target.y
		var contact := BallFlight.intercept(ball_pos, ball_vel, flight_spin, height, flight_gravity)
		if not contact.is_empty():
			flight_target = contact.point
			flight_left = maxf(0.001, contact.seconds)
		armed = true
		input_quality = pass_quality
		notice("COLPO DI SECONDA" if setter_dump else ("ALZATA VELOCE" if fast_set else "ALZATA NORMALE"), 0.8)
	elif (human_wall() or phase=="CPU_ATTACK") and not block_commanded and button == "action":
		block_commanded = true
		block_time = clock_time
		block_quality = 1.0
		if human_wall(): manual_wall.jumped=manual_wall.members(self)
		var accepted_jump:=false
		for blocker in blocking_players(0):
			if can_jump_block(blocker, 0):
				accepted_jump=request_block_jump(blocker, 0.22) or accepted_jump
		if not accepted_jump:
			block_commanded=false
			manual_wall.jumped.clear()

func release_action() -> void:
	if phase=="SET" and attack_buffer_start>=0:
		attack_buffer_power=maxf(0,(clock_time-attack_buffer_start)/Timing.ATTACK_CHARGE_SECONDS)
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
	if value in ["RECEIVE","CPU_RECEIVE"]: receive_offset=0.0
	if value=="CPU_RECEIVE" and phase!="CPU_RECEIVE":
		manual_wall.reset()
		block_commanded=false
		block_helper_x=0
		block_rosters.erase(0)
		block_orders.erase(0)
	phase = value
	phase_time = 0
	armed = false
	input_quality = 0
	charging = false
	charge = 0
	setter_dump = false
	late_receive = false
	recovery_action = "receive"

func reset_rally() -> void:
	cpu_defense.reset()
	overpass_attack_team=-1
	attack_tip=false
	attack_buffer_start=-1.0; attack_buffer_power=-1.0; winner_team=-1
	contact_navigation.reset()
	next_second_touch_read=0.0
	rally_lanes.reset(rotations,server)
	planned_visual_key=""
	rotation_context.reset()
	defensive_lanes.reset()
	defensive_coverage.reset()
	manual_wall.reset()
	rally_serial += 1
	test_rallies = 0
	incoming_kind = "serve"
	incoming_out = false
	out_of_system = 1
	setter_action = "set"
	hitter_action = "attack"
	scramble_ready.fill(0)
	airborne = false
	possession = server
	last_touch = server
	touches = [0, 0]
	toss_active = false
	serve_pending = false
	serve_motion_active = false
	serve_motion_player = -1
	serve_windup_left = 0
	dive_motions.clear()
	for i in 12:
		var p = players[i]
		p.motion_lock = 0
		p.setting_yaw = PI if i<6 else 0.0
		p.play("idle", 1, true)
		for action in ["receive","set","fast_set","attack","dive"]: p.select_variant(action)
		var base: Vector3 = Tactics.serve_position(i, int(i / 6), rotations[int(i / 6)], int(i / 6) == server)
		p.position = base
		p.target = base
		p.velocity = Vector3.ZERO
		p.rotation.y = PI if i < 6 else 0.0
		p.acceleration = Vector3.ZERO
		p.steering_ready = false
		p.foot_planted = [false, false]
		p.set_libero(Tactics.libero(i, rotations[int(i / 6)], int(i / 6) == server))
		p.tick(0,false,false)
	selected = server_index(0)
	var serving = players[server_index(server)]
	# The source stadium's first platform begins at depth 12.6 m. Keep both
	# feet in the clear free zone and use the final approach steps of each clip.
	serving.position.z = (1.0 if server == 0 else -1.0) * 11.9
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
	traffic_blockers.clear()
	block_helper_x=0
	planned_hitter = -1
	set_origin = Vector3.ZERO
	court_shape.reset()
	middle_decoy.reset()
	marker.visible = false
	log_rally_event("formation", {"server":server,"rotation":rotations.duplicate()})

func log_rally_event(kind: String, details: Dictionary = {}) -> void:
	var event := {"kind":kind,"time":clock_time,"rally":rally_serial,"team":possession}
	event.merge(details,true)
	rally_events.append(event)
	if rally_events.size() > 4096: rally_events.pop_front()

func server_index(team: int) -> int:
	return Tactics.server(team, rotations[team])

func choose_receiver(team: int, point: Vector3, serve_receive: bool = false) -> int:
	var best := -1
	var score := INF
	for i in range(team * 6, team * 6 + 6):
		var r := Tactics.role(i, rotations[team], team == server)
		var stance: Vector3 = players[i].stance_for_contact("receive", point)
		var cost: float = players[i].position.distance_to(stance)
		if player_recovery_seconds(i) > maxf(0.05, flight_left - 0.2): cost += 50.0
		if serve_receive:
			if r == "S": cost += 30.0
			elif r.begins_with("MB"): cost += 6.0
			elif r == "OPP" and not Tactics.front(i,rotations[team]): cost += 10.0
		if players[i].clip_name == "block" and not players[i].looping: cost += 4.0
		var p = players[i]
		if p.clips.has(p.clip_name) and not p.looping:
			if p.clip_name in ["attack","float","power"] and p.animation_time<p.clips[p.clip_name].contact_time+0.55: cost += 10.0
			if p.clip_name in ["dive","recovery"] and p.animation_time<p.clips[p.clip_name].contact_time+0.65: cost += 8.0
		if cost < score:
			score = cost
			best = i
	return best

func choose_setter(team: int, point: Vector3, available: float) -> int:
	var designated := team * 6 + 5
	var stance: Vector3 = players[designated].stance_for_contact("set", point)
	if designated != receiver and player_recovery_seconds(designated) < maxf(0.01, available - 0.2) and players[designated].position.distance_to(stance) < minf(5.26,available * 4.8): return designated
	var backup := -1
	var distance := INF
	for i in range(team * 6, team * 6 + 6):
		if i == receiver: continue
		var candidate: float = players[i].position.distance_to(point)
		if player_recovery_seconds(i) > maxf(0.05, available - 0.2): candidate += 50.0
		if Tactics.libero(i,rotations[team],team==server): candidate -= 1.0
		if Tactics.front(i,rotations[team]): candidate += 1.0
		if candidate < distance:
			distance = candidate
			backup = i
	if not self_test: notice("ALZATA DI EMERGENZA", 0.8)
	return backup

func player_recovery_seconds(index: int) -> float:
	if dive_motions.has(index):
		var motion: Dictionary = dive_motions[index]
		return maxf(0, (players[index].clips[motion.action].recovery_end - motion.source_time) / 1.15)
	var player = players[index]
	if player.clip_name in ["dive", "recovery"] and not player.looping: return player.contact_recovery_remaining()
	if serve_motion_active and index == serve_motion_player: return maxf(0, (clips[serve_motion_action].recovery_end - serve_motion_time) / 1.15)
	return 0.0

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
	shot_serial += 1
	flight_gravity = G
	flight_target = target
	flight_left = seconds
	var direction := signf(target.z - ball_pos.z)
	if phase in ["RECEIVE", "CPU_RECEIVE"]:
		flight_spin = Vector3(direction * (0.3 if test_rallies == 0 and serve_type == 0 else 20.0), aim.x * 2.0, 0.5)
	else:
		flight_spin = Vector3(0.3, 0.6, -0.2)
	ball_vel = BallFlight.velocity_to(ball_pos, target, seconds, flight_spin, flight_gravity)
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
	var action := "float" if serve_type == 0 else "power"
	var player = players[server_index(server)]
	serve_motion_active = clips.has(action)
	serve_motion_player = server_index(server)
	serve_motion_action = action
	serve_motion_origin = player.position
	serve_motion_start_time = serve_start_time(action)
	serve_motion_time = serve_motion_start_time
	serve_motion_yaw = player.rotation.y
	player.power_transfer_from=player.global_transform.affine_inverse()*(ball_pos-Vector3.UP*0.105)
	player.power_transfer_start=serve_motion_start_time
	var preparation: float = (clips[action].contact_time - serve_motion_start_time) / 1.15 if clips.has(action) else TOSS_TIME
	serve_toss_duration = (clips[action].contact_time-maxf(serve_motion_start_time,clips[action].toss_release_time))/1.15 if clips.has(action) else TOSS_TIME
	serve_windup_left = maxf(0, preparation - serve_toss_duration)
	player.prepare_contact(action, preparation)
	if serve_windup_left <= 0: release_serve_toss()

func serve_start_time(action: String) -> float:
	if not clips.has(action): return 0.0
	var clip = clips[action]
	var takeoff_depth: float = clip.root_motion(clip.takeoff_time).z
	for frame in clip.frames:
		var source_time: float = float(frame) / clip.fps
		if source_time >= clip.takeoff_time: break
		if takeoff_depth - clip.root_motion(source_time).z <= 2.5: return source_time
	return 0.0

func release_serve_toss() -> void:
	var player = players[serve_motion_player]
	player.apply_pose(0)
	toss_origin = player.current_hand(serve_motion_action=="float")+Vector3(0,0.105,0)
	ball_pos = toss_origin
	var point: Vector3 = player.contact_world(serve_motion_action)
	if serve_motion_active:
		point = serve_motion_origin + Basis(Vector3.UP, serve_motion_yaw) * (player.action_root_motion(serve_motion_action, clips[serve_motion_action].contact_time) - player.action_root_motion(serve_motion_action, serve_motion_start_time) + player.contact_local(serve_motion_action))
	toss_velocity = (point - toss_origin) / serve_toss_duration + Vector3(0, G * serve_toss_duration * 0.5, 0)

func validate_contact(index: int, action: String) -> bool:
	var player = players[index]
	if player.contact_world(action).distance_to(ball_pos) > (0.55 if action in ["recovery","dive"] else 0.35): return false
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
	contact_log.append({"action":action,"variant":player.variant_names.get(action,action), "player":index, "role":Tactics.role(index, rotations[int(index / 6)], int(index / 6) == server), "rotation":rotations[int(index / 6)], "gap":distance, "ball":ball_pos, "hands":actual, "time":clock_time})
	if contact_log.size() > 2048: contact_log.pop_front()
	if match_audio:
		var sound := "serve" if action in ["float","power"] else ("receive" if action in ["receive","recovery","dive"] else ("set" if action in ["set","fast_set","dump"] else action))
		match_audio.contact(sound,ball_pos,0.7)
	return true

func serve_ball(team: int, power: float) -> void:
	var layout: Dictionary=rotation_context.capture(self,team)
	log_rally_event("service_foot_snapshot",layout)
	last_touch = team
	possession = 1 - team
	var s := 1.0 if possession == 0 else -1.0
	var target := serve_aim_target(team,aim)
	target.y = contact_height("receive")
	if team == 1:
		target.x = rng.randf_range(-3.3, 3.3)
		target.z = s*rng.randf_range(5.2,8.0)
	var contact_quality := input_quality if team == 0 and not demo else 0.92
	var dispersion := 2.2 * (1.0 - contact_quality)
	target.x += rng.randf_range(-dispersion, dispersion)
	target.z += rng.randf_range(-dispersion, dispersion)
	if not validate_contact(server_index(team), "float" if serve_type == 0 else "power"):
		award(1 - team, "SERVIZIO · CONTATTO MANCATO")
		return
	if not layout.legal:
		award(team,"FALLO DI POSIZIONE IN RICEZIONE")
		return
	toss_active = false
	last_power = power
	incoming_power = power
	incoming_kind = "serve"
	last_serve_fault = ""
	if power > 1.0 and rng.randf() < Timing.serve_risk(power):
		last_serve_fault = "NET" if serve_fault_sequence%2==0 else "OUT"
		serve_fault_sequence+=1
		if last_serve_fault == "NET":
			fault_flight(Vector3(clampf(target.x,-3.8,3.8),rng.randf_range(1.1,1.8),-0.15 if team == 0 else 0.15), 0.58/power)
		else:
			var outside:=Vector3(target.x,0.105,s*(11.0+minf(power-1,2)*4))
			fault_flight(outside,preload("res://src/winning_shot.gd").flight_seconds(self,outside,0.90/power))
		return
	receiver = choose_receiver(possession, target, true)
	select_receive_pose(receiver,target)
	players[receiver].target = players[receiver].stance_for_contact("receive", target)
	selected = receiver if possession == 0 else 1
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	var seconds := Reference.serve_seconds(power,serve_type==0)
	winner_team=team if Timing.winning_power(power) else -1
	# Every power band uses the same legal floor trajectory. Gold changes
	# the defensive outcome, never the flight model or its speed profile.
	target.y=0.105; target.x=clampf(target.x,-3.8,3.8); target.z=s*clampf(absf(target.z)+minf(power,1.0)*(0.85 if serve_type==0 else 1.4),4.5,8.8)
	# Calibrate the full-power arc once, then retain the charge curve on
	# either side of gold. A clearance minimum must not flatten all powers.
	var full_seconds:=Reference.serve_seconds(1.0,serve_type==0)
	seconds=preload("res://src/winning_shot.gd").flight_seconds(self,target,full_seconds,2.60 if serve_type==0 else 2.54)*seconds/full_seconds
	launch(target,seconds)
	var contact:=BallFlight.intercept(ball_pos,ball_vel,flight_spin,contact_height("receive"),flight_gravity)
	if not contact.is_empty(): flight_target=contact.point; flight_left=contact.seconds; receive_deadline=clock_time+flight_left
	cpu_defense.prepare(self)
	log_rally_event("float_serve" if serve_type==0 else "power_serve",{"seconds":seconds,"power":power})

func serve_aim_target(team: int, direction: Vector2) -> Vector3:
	# Screen-left/right stay world-left/right from every service position.
	# Stick up sends the ball deeper, down shorter; target is court-relative,
	# never an angle added to the server's current lateral position.
	var side:=1.0 if team==1 else -1.0
	return Vector3(clampf(direction.x,-1,1)*3.4,contact_height("receive"),side*(6.0-clampf(direction.y,-1,1)*1.5))

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
	if winner_team>=0:
		preload("res://src/winning_shot.gd").failed_save(self)
		return
	attack_buffer_start=-1.0; attack_buffer_power=-1.0
	if possession==1 and cpu_defense.frozen and incoming_kind in ["serve","spike","soft"]:
		log_rally_event("cpu_hesitation"); miss_contact(); return
	if possession == 0 and not armed:
		miss_contact()
		return
	if incoming_out and possession == 1:
		log_rally_event("leave_out")
		miss_contact()
		return
	var action := recovery_action if late_receive else "receive"
	if not validate_contact(receiver, action):
		if not late_receive and queue_recovery():
			return
		miss_contact()
		return
	var q := RallyAI.reception_quality(self,input_quality)
	if possession==1 and incoming_kind in ["serve","spike","soft"]: q=cpu_defense.quality(q,incoming_power)
	if incoming_kind=="shank" and touches[possession]==1:
		setter=receiver; pass_quality=maxf(q,0.25); input_quality=pass_quality; out_of_system=-1
		players[setter].select_variant("receive",action)
		phase="SET" if possession==0 else "CPU_SET"; armed=true; setter_dump=false; plan_attack(set_dir,false)
		set_ball(); return
	if possession==0 and receive_offset>0.90:
		pass_quality=q; register_touch(receiver)
		var over:=Vector3(clampf(ball_pos.x+rng.randf_range(-0.7,0.7),-4.1,4.1),0.105,-rng.randf_range(1.0,4.0))
		incoming_kind="overpass"; incoming_power=0.18
		send_to_court(0,over,1.4); log_rally_event("mistimed_overpass",{"offset":receive_offset}); return
	pass_quality = q
	register_touch(receiver)
	if phase=="POINT": return
	if possession==1 and cpu_defense.outcome=="overpass" and incoming_kind in ["serve","spike","soft"]:
		var over:=Vector3(rng.randf_range(-2.8,2.8),0.105,rng.randf_range(1.2,4.5))
		incoming_kind="overpass"; incoming_power=0.18; send_to_court(1,over,1.8); log_rally_event("cpu_overpass"); return
	if possession==1 and block_time<clock_time-0.6:
		# A new opposing construction must not inherit an earlier block latch.
		block_commanded=false
		manual_wall.jumped.clear()
		block_jumps.clear()
	players[receiver].prepare_contact(action,0)
	if action in ["dive","recovery"]: players[receiver].motion_lock = players[receiver].contact_recovery_remaining()
	log_rally_event("dig" if incoming_kind=="spike" else "reception",{"quality":q,"receiver":receiver,"incoming":incoming_kind,"recovery":late_receive})
	var side := 1.0 if possession == 0 else -1.0
	if q < 0.08:
		if touches[possession]==1 and rng.randf()<0.60:
			preload("res://src/scramble_recovery.gd").start(self,receiver)
			return
		fault_flight(Vector3(ball_pos.x+signf(rng.randf_range(-1,1))*rng.randf_range(4,7),0.105,side*rng.randf_range(10,13)),0.9)
		log_rally_event("shank")
		return
	if q<0.38 and touches[possession]==1 and incoming_kind=="spike" and rng.randf()<0.25:
		preload("res://src/scramble_recovery.gd").start(self,receiver); return
	if q < 0.50 and incoming_power > 0.68 and incoming_kind in ["serve","spike"] and rng.randf() < (0.50-q)*incoming_power*0.75:
		var attacker := possession
		incoming_kind = "overpass"
		incoming_power = 0.18
		var target := Tactics.world(1-attacker,rng.randf_range(-2.3,2.3),rng.randf_range(2.5,5.5))
		target.y = 0.105
		send_to_court(attacker,target,1.15)
		log_rally_event("overpass")
		return
	var dispersion := (1-q)*lerpf(2.6,6.0,clampf(inverse_lerp(0.65,0.1,q),0,1))
	var target := Vector3(rng.randf_range(-dispersion,dispersion),contact_height("set"),side*(1.5+rng.randf_range(0,dispersion)))
	target=preload("res://src/shot_variation.gd").pass_target(self,target,q)
	target=preload("res://src/setter_access.gd").clear_target(self,target)
	var seconds := Reference.receive_seconds(q,q<0.5)
	seconds=preload("res://src/setter_access.gd").pass_seconds(self,target,seconds)
	setter = choose_setter(possession,target,seconds)
	players[setter].setting_yaw = -PI/2 if possession==0 else PI/2
	out_of_system = RallyAI.system_quality(target,Tactics.ROLES[setter%6]=="S")
	if q < 0.32: out_of_system = -1
	setter_action = "receive" if out_of_system < 0 else "set"
	target.y = contact_height(setter_action)
	players[setter].target = players[setter].stance_for_contact(setter_action,target)
	selected = setter if possession == 0 else 1
	fast_set = false
	set_phase("SET" if possession == 0 else "CPU_SET")
	launch(target,seconds)
	if out_of_system < 1: log_rally_event("out_of_system",{"setter":setter,"quality":q,"target":target})
	if possession == 1:
		choose_cpu_play()
	else:
		if demo: set_dir = int(clock_time) % 4
		plan_attack(set_dir,int(clock_time)%3==0 if demo else false)
	# Finalize the first pass against the selected performance before any
	# movement tick. The generic set height can differ from the actual hands.
	var actual_action: String="dump" if setter_dump else ("receive" if out_of_system<0 else ("fast_set" if fast_set else "set"))
	var actual_target: Vector3=flight_target
	actual_target.y=players[setter].contact_local(actual_action).y
	# Reserve the feet of the selected athlete AND selected performance,
	# not the generic setter pose used before the recipient was chosen.
	actual_target=preload("res://src/setter_access.gd").clear_target(self,actual_target,setter,actual_action)
	flight_left=maxf(flight_left,preload("res://src/setter_access.gd").pass_seconds(self,actual_target,seconds,setter,actual_action))
	flight_target=actual_target
	ball_vel=BallFlight.velocity_to(ball_pos,actual_target,flight_left,flight_spin,flight_gravity)
	players[setter].target=players[setter].stance_for_contact(actual_action,actual_target)

func queue_recovery(anticipate: bool = false) -> bool:
	var action := "dive" if anticipate else "recovery"
	var recovery := BallFlight.intercept(ball_pos,ball_vel,flight_spin,contact_height(action),flight_gravity)
	if recovery.is_empty() or recovery.seconds <= 0.005 or recovery.seconds > (0.45 if anticipate else 0.18): return false
	var player = players[receiver]
	player.select_variant("dive",AnimationVariety.diving(player.global_basis.inverse()*(recovery.point-player.position),incoming_kind,shot_serial))
	var toward: Vector3 = recovery.point-player.position
	player.dive_yaw = atan2(toward.x,toward.z)-atan2(player.contact_local("dive").x,player.contact_local("dive").z)
	# A forward dive cannot rotate an upright body through a half-turn in the
	# last few frames. A ball already behind the defender uses the late save.
	if anticipate and absf(wrapf(player.dive_yaw-player.rotation.y,-PI,PI)) > deg_to_rad(110): return false
	var stance: Vector3 = player.stance_for_contact(action,recovery.point)
	if player.position.distance_to(stance) > recovery.seconds*(7.2 if anticipate else 4.8)+0.52: return false
	if anticipate and clips.has(action):
		var source_start := maxf(0, player.clips[action].contact_time - recovery.seconds * 1.15)
		dive_motions[receiver] = {"origin":player.position,"stance":stance,"start_time":source_start,"source_time":source_start,"duration":recovery.seconds,"elapsed":0.0,"yaw":player.dive_yaw,"initial_yaw":player.rotation.y,"action":action}
		player.prepare_contact(action, recovery.seconds)
	late_receive = true
	recovery_action = action
	flight_target = recovery.point
	flight_left = recovery.seconds
	input_quality *= 0.78
	log_rally_event("emergency_reach",{"receiver":receiver,"seconds":flight_left})
	return true

func choose_cpu_play() -> void:
	if pass_quality > 0.65 and absf(flight_target.z)<2.6 and rng.randf()<0.10:
		setter_dump = true
		setter_action = "dump"
		var dump_contact := BallFlight.intercept(ball_pos,ball_vel,flight_spin,contact_height("dump"),flight_gravity)
		if not dump_contact.is_empty():
			flight_target = dump_contact.point
			flight_left = dump_contact.seconds
	var choice := 0
	var best_score := -INF
	for direction in 4:
		var candidate := Tactics.attacker_for(self,possession,direction,setter)
		if candidate < 0: continue
		var point := RallyAI.attack_contact(self,direction,candidate,flight_target)
		var x: float = point.x
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
	planned_fast = quick and pass_quality >= 0.45 and out_of_system == 1
	fast_set = planned_fast
	planned_hitter = Tactics.attacker_for(self,possession,planned_direction,setter)
	if planned_hitter < 0:
		for alternative in [0, 2, 1, 3]:
			var candidate := Tactics.attacker_for(self,possession,alternative,setter)
			if candidate >= 0:
				planned_direction = alternative
				planned_hitter = candidate
				planned_fast = false
				fast_set = false
				break
	# Choose a performance once for this play. Re-reading the setter's speed
	# every frame used to change contact offsets again during final braking.
	var visual_key:=str([shot_serial,setter,planned_hitter,planned_direction])
	if visual_key!=planned_visual_key:
		planned_visual_key=visual_key
		if planned_hitter>=0:
			players[planned_hitter].select_variant("attack",AnimationVariety.attack(planned_direction,pass_quality,shot_serial))
		players[setter].select_variant("set",AnimationVariety.setting(planned_direction==2,players[setter].velocity.length(),pass_quality,shot_serial))
		players[setter].select_variant("fast_set",AnimationVariety.fast_setting(planned_direction==2,players[setter].velocity.length(),pass_quality,shot_serial,players[setter].variant_names.get("set","set")))

func select_receive_pose(index: int, point: Vector3) -> void:
	var player=players[index]
	var local: Vector3 = Basis(Vector3.UP,PI if index<6 else 0).inverse()*(point-player.position)
	var variant := AnimationVariety.receive(local,player.velocity.length(),incoming_kind,shot_serial)
	player.select_variant("receive",variant)

func set_ball() -> void:
	overpass_attack_team=-1
	attack_tip=false
	if setter_dump:
		dump_ball()
		return
	# Resolve the same planned play used during preparation, including its pose.
	if planned_hitter < 0: plan_attack(set_dir, fast_set)
	fast_set = planned_fast
	var q := input_quality if possession == 0 else clampf(pass_quality * rng.randf_range(0.95, 1.0), 0, 1)
	var contact_action := "receive" if out_of_system < 0 else ("fast_set" if fast_set else "set")
	if (possession == 0 and not armed) or q < 0.06 or not validate_contact(setter, contact_action):
		miss_contact()
		return
	if fast_set and pass_quality < 0.45:
		fast_set = false
		notice("RICEZIONE DIFFICILE · ALTA DI EMERGENZA")
	set_quality = q
	destination = planned_direction
	committed_destination = destination
	register_touch(setter)
	if phase=="POINT": return
	players[setter].prepare_contact(contact_action, 0)
	var s := 1.0 if possession == 0 else -1.0
	set_origin = ball_pos
	hitter = planned_hitter
	if hitter < 0:
		miss_contact()
		return
	var target := RallyAI.attack_contact(self,destination,hitter,set_origin)
	hitter_action = "receive" if out_of_system < 0 and (q < 0.22 or absf(ball_pos.z)>8.0 or absf(ball_pos.x)>5.7) else "attack"
	if hitter_action == "receive": target.z = s*4.6
	target.x += rng.randf_range(-1, 1) * (1 - q) * 0.8
	target.y = contact_height(hitter_action)
	players[hitter].target = players[hitter].stance_for_contact(hitter_action, target)
	selected = hitter if possession == 0 else nearest(0, Vector3(target.x, 0, 0.6))
	var approach_distance: float = players[hitter].position.distance_to(players[hitter].target)
	var approach_time := maxf(approach_distance / 5.4 + 0.26,preload("res://src/approach_planner.gd").seconds(players[hitter],players[hitter].target,Reference.run_speed()*1.10))
	if destination==1 and fast_set and approach_distance<0.65:
		# A middle already planted in his quick lane does not need a second
		# generic .38s plant after preparing during reception and the first pass.
		approach_time=maxf(0.30,approach_time-0.30)
	var flight := maxf(Reference.set_seconds(destination,fast_set,q,ball_pos.distance_to(target),out_of_system<0),approach_time)
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
	var early_wall := possession==1 and block_commanded and phase=="CPU_SET"
	if not early_wall:
		block_time = -100
		block_quality = 0
	block_checked = false
	block_hand = 0
	attack_serial += 1
	if not early_wall:
		block_commanded = false
		block_jumps.clear()
	set_phase("ATTACK" if possession == 0 else "CPU_ATTACK")
	if possession==0 and attack_buffer_start>=0 and clock_time-attack_buffer_start<1.5:
		if attack_buffer_power>=0: armed=true; charge=attack_buffer_power; input_quality=1.0
		else: charging=true; charge_button="action"; charge_start=attack_buffer_start
	attack_buffer_start=-1.0; attack_buffer_power=-1.0
	launch(target, flight)
	if not early_wall and not (possession==1 and not demo):
		block_rosters.clear()
		block_orders.clear()
	block_anchor = target.x*0.88
	if possession == 1: block_count = manual_wall.members(self).size() if human_wall() else 2
	if hitter_action == "receive": block_count = 0
	blocking_team = 1 - possession
	play_log.append({"attack_id":attack_serial, "setter":setter, "hitter":hitter, "role":Tactics.ROLES[hitter % 6], "direction":destination, "target":target, "quick":fast_set, "flight_s":flight, "time":clock_time})
	log_rally_event("free_ball_preparation" if hitter_action=="receive" else ("quick_set" if fast_set else ("emergency_set" if out_of_system<0 else "high_set")),{"hitter":hitter,"setter":setter,"direction":destination,"seconds":flight,"system":out_of_system})
	if possession == 1: selected = manual_wall.line(self)[1] if human_wall() else (blocking_players(0)[1] if block_count>=2 else nearest(0,Vector3(0,0,5)))
	notice((players[hitter].role_label()+" · ") + (["ZONA 4", "ZONA 3", "ZONA 2", "PIPE · ZONA 6"][destination]) + (" / VELOCE" if fast_set else " / ALTA"), 0.8)

func dump_ball() -> void:
	var attacker := possession
	if (possession==0 and not armed) or not validate_contact(setter, "dump"):
		miss_contact()
		return
	register_touch(setter)
	if phase=="POINT": return
	# Back-row setters may dump only below the top of the net in the front zone.
	if not Tactics.front(setter, rotations[attacker]) and absf(players[setter].position.z) < 3.0 and ball_pos.y > 2.43:
		award(1 - attacker, "ATTACCO IRREGOLARE DI SECONDA LINEA")
		return
	var side := -1.0 if attacker == 0 else 1.0
	var landing := Vector3(aim.x * 2.9, 0.105, side * (2.3 if aim.y >= 0 else 5.5))
	incoming_kind = "dump"
	incoming_power = 0.35
	send_to_court(attacker, landing, 0.83)
	log_rally_event("setter_dump")
	notice("COLPO DI SECONDA", 0.9)

func attack_ball() -> void:
	if possession == 0 and charging: release_action()
	var q := input_quality if possession == 0 else 1.0
	if (possession == 0 and not armed) or q < 0.12 or not validate_contact(hitter, hitter_action):
		miss_contact()
		return
	var attacker := possession
	register_touch(hitter)
	if phase=="POINT": return
	players[hitter].prepare_contact(hitter_action, 0)
	last_touch = attacker
	var automatic_overpass:=overpass_attack_team==attacker
	var requested_power := 1.0 if automatic_overpass else (charge if attacker == 0 else rng.randf_range(0.55, 0.97))
	var power := clampf(requested_power, 0, 1)
	if out_of_system<0: power*=0.72
	var precision := Timing.precision(power)
	last_power = requested_power
	last_precision = precision
	var spread := (1.0 - precision) * 3.0
	var s := -1.0 if attacker == 0 else 1.0
	# The eight stick sectors select floor targets, not an airborne point which
	# would continue past the chosen corner when no defender touches the ball.
	var target := Vector3(signf(aim.x) * 3.85 if absf(aim.x) > 0.3 else 0.0, 0.105, s * (8.0 if aim.y < -0.3 else (3.3 if aim.y > 0.3 else 5.0)))
	var soft := power < 0.18
	if attacker == 1 or demo:
		var choice := RallyAI.attack_choice(self,attacker,power)
		target = choice.target
		soft = choice.soft
		power = choice.power
	if automatic_overpass:
		# A reachable overpass is a committed first-touch kill. Keep the
		# authored contact, normal full-power trajectory and physical scoring.
		soft=false
		power=1.0
		attack_tip=false
		target.z=s*maxf(5.0,absf(target.z))
	target += Vector3(rng.randf_range(-minf(spread,0.8),minf(spread,0.8)),0,rng.randf_range(-minf(spread,0.65),minf(spread,0.65)))
	target+=Vector3(rng.randf_range(-0.18,0.18),0,rng.randf_range(-0.22,0.22))
	target.x=clampf(target.x,-4.25,4.25); target.z=s*clampf(absf(target.z),2.8,8.8)
	winner_team=attacker if Timing.winning_power(requested_power) and hitter_action=="attack" else -1
	if requested_power > 1.00001 and rng.randf()<Timing.attack_risk(requested_power,attack_tip):
		target.z = s * (10.8 + minf(requested_power - 1, 2) * 4)
		fault_flight(target, Reference.attack_seconds(1.0,0.0,false,false)/requested_power)
		return
	incoming_kind = "free" if hitter_action=="receive" else ("soft" if soft else "spike")
	incoming_power = power
	var back_row := not Tactics.front(hitter,rotations[attacker])
	var angle := clampf((9.0-absf(target.z))/8.0,0,1)
	var seconds := Reference.attack_seconds(power,angle,back_row,soft)
	var full_seconds:=Reference.attack_seconds(1.0,angle,back_row,false)
	seconds=preload("res://src/winning_shot.gd").flight_seconds(self,target,full_seconds)*seconds/full_seconds
	if attack_tip:
		incoming_kind="soft"; incoming_power=lerpf(0.12,0.65,power)
		seconds=preload("res://src/winning_shot.gd").flight_seconds(self,target,0.70)*(1.35-0.35*power)
	if hitter_action == "receive": seconds = 1.4
	elif requested_power>1.0: seconds/=requested_power
	send_to_court(attacker,target,seconds)
	if automatic_overpass: log_rally_event("overpass_kill",{"hitter":hitter,"power":requested_power,"seconds":seconds})
	overpass_attack_team=-1
	log_rally_event(incoming_kind,{"power":power,"seconds":seconds,"target":target})

func send_to_court(attacker: int, landing: Vector3, seconds: float) -> void:
	if attacker==0:
		manual_wall.reset()
		block_commanded=false
		block_jumps.clear()
	# The net's geometry also checks the resulting ballistic arc, including pipe attacks.
	possession = 1 - attacker
	touches[possession] = 0
	var saved_block_time := block_time
	var saved_block_quality := block_quality
	set_phase("RECEIVE" if possession == 0 else "CPU_RECEIVE")
	block_time = saved_block_time
	block_quality = saved_block_quality
	if incoming_kind in ["free","overpass"]:
		# A returned pass needs genuine flight time to rise under normal gravity.
		# Never manufacture the arc by changing gravity for this shot.
		if incoming_kind == "overpass": seconds = maxf(seconds, 1.8)
	launch(landing,seconds)
	incoming_out = absf(landing.x)>4.605 or absf(landing.z)>9.105
	var intercept := BallFlight.intercept(ball_pos, ball_vel, flight_spin, contact_height("receive"),flight_gravity)
	if not intercept.is_empty():
		flight_target = intercept.point
		flight_left = intercept.seconds
		if phase == "RECEIVE": receive_deadline = clock_time + flight_left
	receiver = choose_receiver(possession, flight_target)
	select_receive_pose(receiver,flight_target)
	cpu_defense.prepare(self)
	players[receiver].target = players[receiver].stance_for_contact("receive", flight_target)
	selected = receiver if possession == 0 else selected
	marker.position = Vector3(landing.x, 0.04, landing.z)
	block_checked = false
	if attacker == 0:
		block_quality = rng.randf_range(0.45, 1)
	if incoming_kind == "overpass": prepare_overpass_attack()

func prepare_overpass_attack() -> bool:
	var contact := BallFlight.intercept(ball_pos,ball_vel,flight_spin,contact_height("attack"),flight_gravity)
	if contact.is_empty() or contact.seconds<0.25 or signf(contact.point.z)!=(1.0 if possession==0 else -1.0) or absf(contact.point.z)>3.0: return false
	var best := -1
	var distance := INF
	for i in range(possession*6,possession*6+6):
		if not Tactics.front(i,rotations[possession]): continue
		var stance: Vector3 = players[i].stance_for_contact("attack",contact.point)
		var gap: float = players[i].position.distance_to(stance)
		if gap<distance:
			distance = gap
			best = i
	if best<0 or distance>contact.seconds*4.8-0.3: return false
	hitter = best
	hitter_action = "attack"
	set_phase("ATTACK" if possession==0 else "CPU_ATTACK")
	overpass_attack_team=possession
	attack_tip=false
	out_of_system=1
	armed=true
	input_quality=1.0
	charge=1.0
	flight_target = contact.point
	flight_left = contact.seconds
	attack_serial += 1
	block_rosters.clear()
	block_orders.clear()
	block_jumps.clear()
	block_count = 2
	block_commanded = false
	block_time = -100
	block_anchor = contact.point.x
	blocking_team = 1-possession
	selected = hitter if possession==0 else (manual_wall.line(self)[1] if human_wall() else blocking_players(0)[1])
	log_rally_event("overpass_attack",{"hitter":hitter,"target":flight_target})
	return true

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
	var target_points:=15 if match_best_of>1 and sets[0]+sets[1]==match_best_of-1 else match_points
	if scores[team] >= target_points and scores[team] - scores[1 - team] >= 2:
		sets[team] += 1
		scores = [0, 0]
		point_reason = "SET " + team_names[team]
		if sets[team] >= int(match_best_of/2)+1:
			point_reason = "VITTORIA " + team_names[team] + " · R PER NUOVA PARTITA"
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
		match_audio.point_event(team==0)
	if team==0 and is_instance_valid(arena_visuals) and arena_visuals.has_method("crowd_react"): arena_visuals.crowd_react()

func _physics_process(dt: float) -> void:
	if self_test:
		return
	else:
		step(dt)

func _process(_dt: float) -> void:
	if match_audio and match_audio.has_method("update_match_state"): match_audio.update_match_state(started,phase,paused and phase!="POINT")
	if camera and not self_test: update_camera(_dt)
	if "--preview" in OS.get_cmdline_user_args() and clock_time > 5.5:
		get_viewport().get_texture().get_image().save_png("res://docs/preview.png")
		get_tree().quit()

func step(dt: float) -> void:
	# Substep to the exact contact event; never validate an overshot ball.
	if phase == "SERVE" and toss_active:
		var service_left := serve_windup_left + serve_toss_duration - toss_elapsed
		if serve_windup_left>0.00001: service_left=serve_windup_left
		if service_left > 0.00001 and service_left < dt:
			step(service_left)
			step(dt - service_left)
			return
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
	receive_feedback_left=maxf(0,receive_feedback_left-dt)
	read_controls(dt)
	if demo:
		demo_input()
	if phase in ["SET","CPU_SET"] and (possession==1 or armed):
		preload("res://src/setter_access.gd").try_low_contact(self)
	if phase in ["RECEIVE","CPU_RECEIVE"] and not late_receive and flight_left>0.001 and flight_left<0.42 and (possession==1 or armed):
		var stance: Vector3 = players[receiver].stance_for_contact("receive",flight_target)
		if players[receiver].position.distance_to(stance)>flight_left*Reference.run_speed()+0.12: queue_recovery(true)
	move_players(dt)
	if phase == "SERVE":
		var serving = players[server_index(server)]
		if toss_active:
			var toss_dt := dt
			if serve_windup_left > 0:
				toss_dt = maxf(0, dt - serve_windup_left)
				serve_windup_left = maxf(0, serve_windup_left - dt)
				serving.prepare_contact(serve_motion_action, serve_windup_left + serve_toss_duration)
				serving.apply_pose(0)
				ball_pos = serving.current_hand(serve_motion_action=="float") + Vector3(0, 0.11, 0)
				if serve_windup_left <= 0: release_serve_toss()
			if serve_windup_left <= 0:
				toss_elapsed = minf(serve_toss_duration, toss_elapsed + toss_dt)
				ball_pos = toss_origin + toss_velocity * toss_elapsed + Vector3(0, -0.5 * G * toss_elapsed * toss_elapsed, 0)
				serving.prepare_contact(serve_motion_action, serve_toss_duration - toss_elapsed)
				if toss_elapsed >= serve_toss_duration:
					if serve_pending: serve_ball(server, serve_power)
		else:
			ball_pos = serving.current_hand(true) + Vector3(0, 0.11, 0)
		if server == 1 and phase_time > 0.65 and not toss_active:
			serve_type = rng.randi_range(0, 1)
			serve_power = rng.randf_range(0.55,1.08)
			begin_serve_toss()
	elif phase == "POINT":
		step_dead_ball(dt)
		if phase_time > 4.5: reset_rally()
	elif airborne:
		var old := ball_pos
		var state := BallFlight.advance(ball_pos, ball_vel, flight_spin, dt,flight_gravity)
		ball_pos = state[0]
		ball_vel = state[1]
		flight_left -= dt
		if old.z * ball_pos.z < 0:
			var fraction := absf(old.z) / maxf(absf(old.z - ball_pos.z), 0.001)
			var net_y := lerpf(old.y, ball_pos.y, fraction)
			if net_y < 2.535 and absf(ball_pos.x) < 4.65:
				ball_pos = old.lerp(ball_pos, fraction)
				var tape_over := net_y >= 2.43 and absf(ball_vel.z)>4.0
				ball_pos.z = -signf(old.z)*0.106 if tape_over else signf(old.z)*0.106
				if is_instance_valid(dynamic_net): dynamic_net.impact(ball_pos,ball_vel)
				ball_vel=preload("res://src/net_dynamics.gd").response(ball_vel,net_y)
				flight_spin *= 0.45
				net_contacts += 1
				log_rally_event("net_tape_over" if tape_over else "net_rebound")
				if incoming_kind=="serve" and not tape_over:
					phase = "LOOSE"
					flight_left = 100
					marker.visible = false
				else: resume_deflection("net")
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
	ball.quaternion = BallContact.spin_rotation(ball.quaternion, flight_spin, dt)
	shadow.position = Vector3(ball_pos.x, 0.034, ball_pos.z)
	shadow.scale = Vector3.ONE * (1.0 + maxf(ball_pos.y, 0) * 0.06)
	for i in 12: players[i].tick(dt, i == selected, not self_test)

func step_dead_ball(dt: float) -> void:
	# Short substeps retain bounce height even after a hard downward spike.
	var remaining := dt
	while remaining > 0.000001:
		var h := minf(remaining, 1.0 / 240.0)
		remaining -= h
		var state := BallContact.floor_step(ball_pos,ball_vel,h)
		ball_pos = state.position
		ball_vel = state.velocity
		for impact in state.impacts:
			flight_spin *= 0.76
			dead_ball_bounces += 1
			if match_audio: match_audio.contact("bounce", ball_pos, clampf(impact / 12.0, 0.15, 0.9))
		if is_zero_approx(ball_vel.y) and ball_pos.y<=0.1051:
			flight_spin = flight_spin.lerp(Vector3.UP.cross(Vector3(ball_vel.x, 0, ball_vel.z)) / 0.105, 1.0 - exp(-h * 3.0))
		ball_vel.x *= exp(-0.06 * h)
		ball_vel.z *= exp(-0.06 * h)
		flight_spin *= exp(-0.20 * h)

func try_block() -> void:
	block_checked = true
	var defender := 1 - last_touch
	var good_jump := clock_time - block_time > 0.08 and clock_time - block_time < 0.85
	var near := false
	var strength := 0.0
	var contact_side:=0.0
	for i in blocking_players(defender):
		var player = players[i]
		if player.clip_name != "block": continue
		player.apply_pose(0)
		var left: Vector3 = player.current_hand(true)
		var right: Vector3 = player.current_hand(false)
		var nearest_point := Geometry3D.get_closest_point_to_segment(ball_pos, left, right)
		var gap := nearest_point.distance_to(ball_pos)
		for arm in ["Left","Right"]:
			var hand: Vector3 = player.current_joint(arm+"Hand")
			var elbow: Vector3 = player.current_joint(arm+"ForeArm")
			var forearm := Geometry3D.get_closest_point_to_segment(ball_pos,hand,elbow)
			if forearm.y>2.53: gap = minf(gap,forearm.distance_to(ball_pos))
		if "--trace-block" in OS.get_cmdline_user_args(): print("BLOCK a=",attack_serial," dt=",clock_time-block_time," ball=",ball_pos," player=",i," root=",player.position," left=",left," right=",right," elbow=",player.current_joint("RightForeArm")," gap=",gap)
		if gap < 0.20:
			near = true
			if strength<clampf(1.0-gap/0.24,0.18,1.0): contact_side=clampf((ball_pos.x-nearest_point.x)*5.0,-0.65,0.65)
			strength = maxf(strength,clampf(1.0-gap/0.24,0.18,1.0))
	if good_jump and near:
		if winner_team>=0:
			var side:=1.0 if defender==0 else -1.0
			var landing:=Vector3(clampf(ball_pos.x,-3.9,3.9),0.105,side*2.0)
			ball_vel=BallFlight.velocity_to(ball_pos,landing,0.26,flight_spin,flight_gravity)
			last_touch=defender; phase="LOOSE"; flight_left=100
			log_rally_event("winning_shot_block_break",{"defender":defender})
			if match_audio: match_audio.contact("block",ball_pos,0.9)
			return
		if true:
			var normal := Vector3(contact_side+(block_hand*0.22 if defender==0 else 0.0),lerpf(0.03,0.22,1.0-strength),-1.0 if defender == 0 else 1.0).normalized()
			var incoming := ball_vel
			var closing := ball_vel.dot(normal)
			if closing < 0: ball_vel -= normal * closing * (0.45 + strength * (0.75 + block_quality * 0.20))
			ball_vel *= 0.82
			ball_vel.y += (1-strength)*1.8
			flight_spin = flight_spin * 0.45 + normal.cross(incoming) * 0.35
			last_touch = defender
			resume_deflection("block" if strength>0.55 else "tip")
			log_rally_event("stuff_block" if strength>0.55 else "block_touch",{"strength":strength,"blocking_team":defender})
			notice("MURO! · TOCCO A RETE", 1.0)
			if match_audio: match_audio.contact("block", ball_pos, 0.85)

func resume_deflection(kind: String) -> void:
	# Continue from current position and velocity; both a stuffed block and a
	# light touch can stay live on whichever side the real rebound reaches.
	flight_gravity = G
	var interception := BallFlight.intercept(ball_pos,ball_vel,flight_spin,contact_height("receive"),flight_gravity)
	if interception.is_empty() or interception.seconds<0.025 or absf(interception.point.x)>7.0 or absf(interception.point.z)>12.0:
		phase = "LOOSE"
		flight_left = 100
		marker.visible = false
		return
	possession = 0 if interception.point.z>0 else 1
	touches[possession] = 0 if kind in ["block","tip"] else touches[possession]
	set_phase("RECEIVE" if possession==0 else "CPU_RECEIVE")
	incoming_kind = kind
	incoming_power = clampf(ball_vel.length()/35.0,0,1)
	incoming_out = false
	flight_target = interception.point
	flight_left = interception.seconds
	receive_deadline = clock_time+flight_left
	receiver = choose_receiver(possession,flight_target)
	select_receive_pose(receiver,flight_target)
	selected = receiver if possession==0 else selected
	marker.position = Vector3(flight_target.x,0.04,flight_target.z)
	marker.visible = true
	var reaction: Array = Reference.data.reaction.tape if kind=="net" else Reference.data.reaction.block
	scramble_ready[receiver] = clock_time+rng.randf_range(reaction[0],reaction[1])

func human_wall() -> bool:
	return not demo and phase in ["CPU_RECEIVE","CPU_SET","CPU_ATTACK"]

func manual_wall_active() -> bool:
	# The opponent's hit immediately switches to our RECEIVE phase. Preserve
	# the actual chosen hands through that flight and the contact at the net.
	return human_wall() or (not demo and blocking_team==0 and not manual_wall.jumped.is_empty() and clock_time-block_time<0.85)

func choose_block_lane(direction: Vector2) -> void:
	if human_wall(): manual_wall.read(self,direction,1.0/120.0)

func wall_attack_id() -> int:
	return attack_serial+1 if phase in ["CPU_RECEIVE","CPU_SET"] else attack_serial

func blocking_players(team: int) -> Array[int]:
	if team==0 and manual_wall_active(): return manual_wall.members(self)
	var count := block_count
	if block_rosters.has(team):
		var result: Array[int] = []
		for i in mini(count, block_rosters[team].size()): result.append(block_rosters[team][i])
		return result
	var candidates: Array[int] = []
	for i in range(team * 6, team * 6 + 6):
		if Tactics.front(i, rotations[team]): candidates.append(i)
	# Lead wing closes its own pin; middle joins, far wing only for a triple.
	var lane := block_anchor
	candidates.sort_custom(func(a, b): return absf(players[a].position.x - lane) < absf(players[b].position.x - lane))
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
	candidates.resize(mini(count, candidates.size()))
	return candidates

func blocking_target(index: int, team: int) -> Vector3:
	if team==0 and manual_wall_active(): return manual_wall.target(self,index)
	var active := blocking_players(team)
	var order: Array[int] = []
	for i in block_orders[team]:
		if i in active: order.append(i)
	return Tactics.block_target(index,order,block_helper_x if team==0 and human_wall() else block_anchor,team)

func can_jump_block(index: int, team: int) -> bool:
	if team==0 and human_wall():
		return true # Manual jump timing also applies while still closing the wall.
	elif players[index].position.distance_to(blocking_target(index, team)) > 0.14: return false
	for other in blocking_players(team):
		if other == index: continue
		if absf(players[other].position.x - players[index].position.x) < 0.78 and absf(players[other].position.z) < 1.45: return false
	return true

func manual_wall_route(index: int, destination: Vector3) -> Vector3:
	destination.z=0.68
	return manual_wall.route(self,index,destination)

func waiting_wall_target(index: int) -> Vector3:
	return manual_wall.waiting(self,index)

func request_block_jump(index: int, contact_in: float) -> bool:
	if phase not in ["ATTACK", "CPU_ATTACK","CPU_SET","CPU_RECEIVE"]: return false
	var jump_id := wall_attack_id() if index<6 else attack_serial
	if block_jumps.get(index, -1) == jump_id: return false
	var p = players[index]
	if p.clip_name == "block" and not p.looping and p.clips.has("block") and p.animation_time < p.clips.block.recovery_end: return false
	block_jumps[index] = jump_id
	block_jump_log.append({"attack_id":jump_id, "player":index, "time":clock_time, "contact_in":contact_in})
	p.target = p.position
	p.steering_target = p.position
	p.select_variant("block",AnimationVariety.blocking(p.global_basis.inverse()*p.velocity,index,attack_serial))
	p.velocity = Vector3.ZERO
	p.acceleration = Vector3.ZERO
	p.reach_action = "block"
	p.reach_target = Vector3(p.contact_world("block").x,3.08,0.035 if index<6 else -0.035)
	p.reach_weight = 1.0
	p.prepare_contact("block", contact_in)
	return true

func block_pose_locked(index: int) -> bool:
	var player=players[index]
	# The grounded follow-through must not keep the root locked after landing.
	return block_jumps.get(index,-1)==wall_attack_id() and player.clip_name=="block" and not player.looping and player.animation_time<player.clips.block.recovery_end

func move_players(dt: float) -> void:
	defensive_lanes.update(self)
	middle_decoy.update(self)
	movement_snapshot.clear()
	for player in players: movement_snapshot.append({"position":player.position,"velocity":player.velocity})
	traffic_footprints.clear()
	for i in 12: traffic_footprints.append(compute_footprint_points(i))
	var action_actor := -1
	var action := ""
	match phase:
		"RECEIVE", "CPU_RECEIVE":
			action_actor = receiver
			action = recovery_action if late_receive else "receive"
		"SET", "CPU_SET":
			action_actor = setter
			action = "dump" if setter_dump else ("receive" if out_of_system<0 else ("fast_set" if fast_set else "set"))
		"ATTACK", "CPU_ATTACK":
			action_actor = hitter
			action = hitter_action
	var blockers: Array = blocking_players(1 - possession) if phase in ["ATTACK", "CPU_ATTACK"] else []
	if human_wall() and phase in ["CPU_RECEIVE","CPU_SET"]: blockers=blocking_players(0)
	if blockers.is_empty() and blocking_team >= 0 and clock_time - block_time < 0.58 and phase in ["RECEIVE", "CPU_RECEIVE"]:
		blockers = blocking_players(blocking_team)
		blockers.erase(action_actor)
	traffic_blockers=blockers
	var nominal: Array[Vector3] = []
	for i in 12:
		var team := int(i/6)
		if i==action_actor: nominal.append(players[i].stance_for_contact(action,flight_target))
		elif i==middle_decoy.index: nominal.append(middle_decoy.target)
		elif i in blockers: nominal.append(blocking_target(i,team))
		elif phase=="SERVE":
			var ready: Vector3=Tactics.serve_position(i,team,rotations[team],team==server) if i!=server_index(server) else players[i].position
			nominal.append(ready)
		elif phase=="POINT" and point_formation.size()==12: nominal.append(point_formation[i])
		elif phase=="LOOSE": nominal.append(players[i].target)
		elif human_wall() and i<6 and Tactics.front(i,rotations[0]): nominal.append(waiting_wall_target(i))
		else: nominal.append(tactical_target(i,Tactics.slot(i,rotations[team]),team,1.0 if team==0 else -1.0))
	if phase in ["ATTACK","CPU_ATTACK"]:
		var floor_plan: Dictionary=defensive_coverage.plan(self,1-possession,flight_target,blockers)
		for index in floor_plan:
			if index!=action_actor and not index in blockers: nominal[index]=floor_plan[index]
	var team_targets: Array[Vector3] = court_shape.arrange(self,nominal,action_actor,action,blockers)
	if phase in ["ATTACK","CPU_ATTACK"] and phase_time<0.22:
		for index in defensive_coverage.targets:
			if defensive_coverage.assignments.get(index,"")=="short" and not index in blockers:
				var side:=1.0 if index<6 else -1.0
				team_targets[index].z=side*lerpf(0.68,3.05,smoothstep(0.10,0.22,phase_time))
	# Keep the floor defence through the incoming spike, rather than opening
	# all non-passers for attack while the ball has only just left the hitter.
	if phase in ["RECEIVE","CPU_RECEIVE"] and incoming_kind in ["spike","soft"] and defensive_coverage.defending_team==possession and defensive_coverage.attack_id==attack_serial:
		for index in defensive_coverage.targets:
			if index==action_actor or index in blockers: continue
			var cover: Vector3=defensive_coverage.targets[index]
			var receiver_stance: Vector3=players[action_actor].stance_for_contact(action,flight_target)
			if cover.distance_to(receiver_stance)<1.4:
				var away:=cover-receiver_stance
				if away.length()<0.01: away=Vector3.RIGHT if index%2==0 else Vector3.LEFT
				cover=receiver_stance+away.normalized()*1.4
			team_targets[index]=cover
	if phase in ["SET","CPU_SET"] and action_actor>=0:
		team_targets[action_actor]=contact_navigation.route(self,action_actor,nominal[action_actor])
	if middle_decoy.index>=0 and not middle_decoy.jumped: middle_decoy.target=team_targets[middle_decoy.index]
	for i in 12:
		var p = players[i]
		p.reach_weight = maxf(0, p.reach_weight - dt * 5)
		p.motion_lock = maxf(0, p.motion_lock - dt)
		if serve_motion_active and i == serve_motion_player:
			advance_serve_body(dt)
			traffic_footprints[i] = compute_footprint_points(i)
			continue
		if dive_motions.has(i):
			advance_dive_body(i, dt)
			traffic_footprints[i] = compute_footprint_points(i)
			continue
		if middle_decoy.holds(i):
			middle_decoy.advance_body(self,dt)
			traffic_footprints[i] = compute_footprint_points(i)
			continue
		var side := 1.0 if i < 6 else -1.0
		var zone := Tactics.slot(i, rotations[int(i / 6)])
		var base: Vector3 = Tactics.serve_position(i, int(i / 6), rotations[int(i / 6)],int(i / 6)==server)
		var team := int(i / 6)
		var serving_player := phase == "SERVE" and i == server_index(server)
		var depth_limit := 12.0 if serving_player else (11.5 if i==action_actor else 10.5)
		var width_limit := 4.35 if serving_player else (7.0 if i==action_actor else 5.7)
		# Return from a save outside the sidelines by running, never by clamping
		# the athlete's root back to the ordinary support rectangle in one frame.
		depth_limit = maxf(depth_limit, absf(p.position.z))
		width_limit = maxf(width_limit, absf(p.position.x))
		var preparing_hitter := phase in ["SET", "CPU_SET"] and i == planned_hitter
		var preparing_setter: bool=phase in ["RECEIVE","CPU_RECEIVE"] and team==possession and i%6==5 and i!=action_actor
		var preparing_decoy: bool=i==middle_decoy.index
		var urgent: bool = i == action_actor or i in blockers or preparing_hitter or preparing_decoy or preparing_setter or court_shape.setter_yields.has(i)
		if team!=possession and phase in ["ATTACK","CPU_ATTACK"] and defensive_coverage.assignments.get(i,"")=="short": urgent=true
		var assignment := "contact" if i == action_actor else ("approach" if preparing_hitter else ("block" if i in blockers else ("recover" if phase == "POINT" else "cover")))
		if preparing_setter: assignment="approach"
		if i != action_actor and court_shape.bypass.has(i): assignment = "yield"
		if i != action_actor and court_shape.setter_yields.has(i): assignment = "yield"
		if preparing_decoy: assignment="approach"
		if not p.steering_ready:
			p.intent.reset(p.position)
			p.steering_ready = true
		p.intent.observe(phase + ":" + str(shot_serial), Tactics.role(i, rotations[team], team == server), assignment, clock_time)
		var chase_distance: float = p.position.distance_to(flight_target)
		p.effort = clampf(chase_distance / maxf(0.3, flight_left * 5.4), 0, 1.5) if airborne else 0.0
		p.visual_context = "quick" if fast_set and phase in ["SET", "CPU_SET", "ATTACK", "CPU_ATTACK"] else ("emergency" if (phase in ["SET", "CPU_SET"] and pass_quality < 0.65) or (i == action_actor and p.effort > 1.0) else "normal")
		p.target = team_targets[i]
		if i in blockers:
			p.target = blocking_target(i, team)
			# Travel laterally behind the net lane, then step in beside the lead.
			if team==0 and human_wall(): p.target=manual_wall_route(i,p.target)
			elif absf(p.position.x - p.target.x) > 0.8: p.target.z = side * 1.20
			if phase == "ATTACK" and hitter_action=="attack" and team == 1 and flight_left < 0.34 and can_jump_block(i, team):
				if request_block_jump(i, flight_left + 0.08):
					if block_time < 0: block_time = clock_time
					block_quality = 0.85
			if block_pose_locked(i):
				p.target = p.steering_target
		# Each athlete perceives the same cue on an individual schedule. Direct
		# contact assistance remains immediate; support and reading are staggered.
		p.steering_target = p.intent.perceive(p.target, clock_time, dt)
		var movement: Vector3 = p.steering_target - p.position
		movement.y = 0
		var max_speed: float = Reference.run_speed()*1.10 if urgent else (1.6 if phase == "POINT" else p.intent.support_speed(p.visual_context == "emergency"))
		if i == action_actor and action=="dive": max_speed = 7.2
		var arrival_speed := movement.length() * 2.5
		var arrival_distance := movement.length()
		if i == action_actor and (court_shape.recovery_bypass.has(i) or phase in ["SET","CPU_SET"]):
			# The corner is a passing point, not the ball-contact destination.
			# Pace against the whole remaining route, retaining the same deadline.
			arrival_distance += p.steering_target.distance_to(p.stance_for_contact(action,flight_target))
		if urgent: arrival_speed = arrival_distance / maxf(0.055, flight_left - 0.12)
		if preparing_hitter: arrival_speed = movement.length() * 3.5
		if court_shape.setter_yields.has(i): arrival_speed=maxf(arrival_speed,movement.length()*4.5)
		if preparing_decoy: arrival_speed=movement.length()*4.5
		if human_wall() and i in blockers: arrival_speed=movement.length()*4.5
		if urgent and action!="dive": arrival_speed = minf(arrival_speed, sqrt(2.0 * 22.0 * arrival_distance) * 0.72)
		var desired := movement.normalized() * minf(max_speed, arrival_speed)
		if movement.length() < (0.045 if urgent else p.intent.settle_distance()): desired = Vector3.ZERO
		# The contact route already clears every body; a second social-force
		# sidestep would steer it back into the very obstacles it avoided.
		if i!=action_actor or phase not in ["SET","CPU_SET"]: desired = avoid_teammates(i, desired, movement, max_speed)
		# Mild separation prevents two athletes occupying the same contact space.
		if i != action_actor:
			for j in range(team * 6, team * 6 + 6):
				if i == j: continue
				var delta: Vector3 = p.position - players[j].position
				delta.y = 0
				if delta.length() < 0.75 and delta.length() > 0.01: desired += delta.normalized() * (0.75 - delta.length()) * 3.0
		if serving_player:
			desired = Vector3.ZERO
			p.target = p.position
		desired *= p.recovery_speed_scale()
		if middle_decoy.holds(i): desired=Vector3.ZERO
		if clock_time < scramble_ready[i]: desired = Vector3.ZERO
		if block_pose_locked(i): desired = Vector3.ZERO
		var wanted_accel: Vector3 = ((desired.limit_length(max_speed) - p.velocity) / (0.055 if urgent else p.intent.response_time())).limit_length(28.0 if urgent else 9.5 + p.intent.individuality * 3.5)
		p.acceleration = wanted_accel if i == action_actor or (human_wall() and i in blockers) else p.acceleration.move_toward(wanted_accel, (150.0 if urgent else 50.0 + p.intent.individuality * 35.0) * dt)
		# Limit the requested speed, not existing momentum. A player changing
		# from contact to cover used to lose several m/s in a single tick here.
		p.velocity = (p.velocity + p.acceleration * dt).limit_length(maxf(max_speed,p.velocity.length()))
		if desired.length() < 0.01 and p.velocity.length() < 0.10:
			p.velocity = Vector3.ZERO
			p.acceleration = Vector3.ZERO
		var safe_step: Vector3 = p.velocity * dt
		for projection in 3:
			var bounded: Vector3 = p.position + safe_step
			bounded.x = clampf(bounded.x, -width_limit, width_limit)
			bounded.z = clampf(bounded.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(bounded.z, -depth_limit, -9.3 if serving_player else -0.25)
			safe_step = collision_safe_step(i, bounded - p.position)
		var endpoint: Vector3 = p.position + safe_step
		endpoint.x = clampf(endpoint.x, -width_limit, width_limit)
		endpoint.z = clampf(endpoint.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(endpoint.z, -depth_limit, -9.3 if serving_player else -0.25)
		safe_step = endpoint - p.position
		for other in range(team * 6, team * 6 + 6):
			if other != i and endpoint.distance_to(players[other].position) < Tactics.BODY_SPACE - 0.0001:
				safe_step = Vector3.ZERO
		p.position += safe_step
		if "--trace-defence" in OS.get_cmdline_user_args() and i==action_actor and action=="dive" and int(clock_time*120)%10==0:
			print("DIVE t=",clock_time," left=",flight_left," p=",p.position," target=",p.target," v=",p.velocity," desired=",desired," step=",safe_step," yaw=",p.rotation.y," goal_yaw=",p.dive_yaw," lock=",p.motion_lock)
		if safe_step.length() + 0.00001 < p.velocity.length() * dt:
			p.velocity = safe_step / maxf(dt, 0.00001)
			p.acceleration = Vector3.ZERO
		travel[i] += p.velocity.length() * dt
		if i != action_actor and not i in blockers and phase not in ["SERVE", "POINT", "LOOSE"]: support_travel[i] += p.velocity.length() * dt
		p.position.x = clampf(p.position.x, -width_limit, width_limit)
		p.position.z = clampf(p.position.z, 9.3 if serving_player else 0.25, depth_limit) if i < 6 else clampf(p.position.z, -depth_limit, -9.3 if serving_player else -0.25)
		var facing := PI if team == 0 else 0.0
		if i==action_actor and action=="dive": facing = p.dive_yaw
		if i==action_actor and action in ["set","fast_set"]: facing = p.setting_yaw
		if phase != "SERVE" and i != action_actor and not i in blockers:
			var look: Vector3 = ball_pos - p.position
			if phase == "POINT": look = Vector3(0, 0, side * 3.3) - p.position
			facing = atan2(look.x, look.z)
			if phase=="POINT" and p.velocity.length()>0.15 and movement.length()>0.18: facing=atan2(p.velocity.x,p.velocity.z)
			# Sprint facing the route, then open the shoulders to the ball on braking.
			var running_weight := smoothstep(2.25,3.6,p.velocity.length())*smoothstep(0.55,1.45,movement.length())
			facing = lerp_angle(facing,atan2(p.velocity.x,p.velocity.z),running_weight)
			if clock_time < p.intent.react_at: facing = p.rotation.y
		var turn := wrapf(facing - p.rotation.y, -PI, PI)
		var turn_speed: float = (15.0 if action=="dive" else 7.0) if urgent else 3.1 + p.intent.individuality * 0.8
		p.rotation.y += clampf(turn * (8.0 if urgent else 5.0 + p.intent.individuality * 2.0), -turn_speed, turn_speed) * dt
		p.look_target = Vector3(0, 1.7, side * 3.3) if phase == "POINT" else ball_pos
		p.ready_stance = (team == possession and phase in ["RECEIVE", "CPU_RECEIVE"] and (zone >= 3 or i == receiver)) or (team != possession and phase in ["ATTACK", "CPU_ATTACK"])
		p.block_ready_stance = team != possession and zone < 3 and absf(p.target.z)<2.0 and phase in ["RECEIVE", "CPU_RECEIVE", "SET", "CPU_SET", "ATTACK", "CPU_ATTACK"]
		if phase == "SERVE": p.ready_stance = team != server and zone >= 3
		# Wings waiting to approach and setters waiting to penetrate stand tall;
		# only passers and floor defenders stay in the low defensive posture.
		p.relaxed_stance = not p.ready_stance and i != action_actor and not i in blockers
		p.post_point=phase=="POINT"
		p.locomotion(p.velocity.length(), dt)
		if block_pose_locked(i):
			p.reach_action = "block"
			p.reach_target = Vector3(p.contact_world("block").x,3.08,side*0.035)
			p.reach_weight = 1.0
		var preparation_lead := (0.78 if fast_set else 1.12) if action == "attack" else 0.38
		preparation_lead += p.intent.individuality * 0.055 + (0.04 if p.visual_context == "emergency" else 0.0)
		preparation_lead = p.preparation_lead(action,preparation_lead)
		if i == action_actor and flight_left < preparation_lead:
			p.prepare_contact(action, maxf(0, flight_left - dt))
			p.reach_action = action
			p.reach_target = flight_target
			p.reach_weight = 1.0 - smoothstep(0.04, 0.22, flight_left)
		p.hand_adjust = block_hand if team == 0 and clock_time - block_time < 0.7 else 0
		traffic_footprints[i] = compute_footprint_points(i)
		if p.velocity.length() > 1.8 and p.step_cooldown <= 0 and not self_test:
			if match_audio: match_audio.movement(p.position, p.velocity.length(), p.velocity.x)
			p.step_cooldown = 0.32 + float(i % 3) * 0.025
	middle_decoy.try_jump(self)
	for team in 2:
		for a in range(team * 6, team * 6 + 6):
			for b in range(a + 1, team * 6 + 6):
				var distance: float = players[a].position.distance_to(players[b].position)
				minimum_player_gap = minf(minimum_player_gap, distance)
				if a in blockers and b in blockers: minimum_block_gap = minf(minimum_block_gap, distance)
	traffic_footprints.clear()

func advance_serve_body(dt: float) -> void:
	var player = players[serve_motion_player]
	var clip = clips[serve_motion_action]
	serve_motion_time = minf(clip.duration, serve_motion_time + dt * 1.15)
	var previous: Vector3 = player.position
	var destination: Vector3 = serve_motion_origin + Basis(Vector3.UP, serve_motion_yaw) * (player.action_root_motion(serve_motion_action, serve_motion_time) - player.action_root_motion(serve_motion_action, serve_motion_start_time))
	player.position += collision_safe_step(serve_motion_player, destination - player.position)
	player.rotation.y = serve_motion_yaw
	player.velocity = (player.position - previous) / maxf(dt, 0.00001)
	player.acceleration = Vector3.ZERO
	player.target = player.position
	player.animation_time = serve_motion_time
	player.contact_scheduled = true
	travel[serve_motion_player] += player.position.distance_to(previous)
	if serve_motion_time >= clip.duration - 0.001:
		serve_motion_active = false
		player.contact_scheduled = false
		player.motion_lock = 0

func advance_dive_body(index: int, dt: float) -> void:
	var player = players[index]
	var motion: Dictionary = dive_motions[index]
	var action: String = motion.action
	var clip = player.clips[action]
	motion.elapsed += dt
	motion.source_time = minf(clip.duration, motion.start_time + motion.elapsed * 1.15)
	var basis := Basis(Vector3.UP, motion.yaw)
	var start_root: Vector3 = player.action_root_motion(action, motion.start_time)
	var source_delta: Vector3 = basis * (player.action_root_motion(action, motion.source_time) - start_root)
	var contact_delta: Vector3 = basis * (player.action_root_motion(action, clip.contact_time) - start_root)
	var correction: Vector3 = motion.stance - motion.origin - contact_delta
	var progress: float = clampf(motion.elapsed / maxf(0.001, motion.duration), 0, 1)
	var destination: Vector3 = motion.origin + source_delta + correction * smoothstep(0, 1, progress)
	destination.z = maxf(0.25, destination.z) if index < 6 else minf(-0.25, destination.z)
	var previous: Vector3 = player.position
	player.position += collision_safe_step(index, destination - player.position)
	player.velocity = (player.position - previous) / maxf(dt, 0.00001)
	player.acceleration = Vector3.ZERO
	player.target = motion.stance
	player.rotation.y = lerp_angle(motion.initial_yaw, motion.yaw, smoothstep(0, minf(0.18,motion.duration), motion.elapsed))
	player.animation_time = motion.source_time
	player.contact_scheduled = true
	player.motion_lock = maxf(0, (clip.duration - motion.source_time) / 1.15)
	travel[index] += player.position.distance_to(previous)
	if motion.source_time >= clip.duration - 0.001:
		dive_motions.erase(index)
		player.motion_lock = 0
		player.contact_scheduled = false

func collision_safe_step(index: int, movement: Vector3) -> Vector3:
	var origins := footprint_points(index)
	var allowed := 1.0
	var original_length := movement.length()
	# First find a sliding direction. Re-projecting against a second neighbour
	# can reintroduce a collision with the first, so sweep only AFTER this pass.
	for iteration in 3:
		for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
			if j == index: continue
			var clearance := pair_clearance(index,j)
			for origin in origins:
				for obstacle in footprint_points(j):
					var delta: Vector3 = origin - obstacle
					delta.y = 0
					if delta.length() < clearance + 0.04 and delta.length() > 0.001:
						var normal := delta.normalized()
						var inward := movement.dot(normal)
						if inward < 0: movement -= normal * inward
	for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
		if j == index: continue
		var clearance := pair_clearance(index,j)
		for origin in origins:
			for obstacle in footprint_points(j):
				var delta: Vector3 = origin - obstacle
				delta.y = 0
				var approaching := delta.dot(movement)
				if approaching >= 0 or movement.length_squared() < 0.0000001: continue
				var c := delta.length_squared() - clearance * clearance
				if c < 0:
					allowed = 0
					continue
				var discriminant := approaching * approaching - movement.length_squared() * c
				if discriminant >= 0:
					var t := (-approaching - sqrt(discriminant)) / movement.length_squared()
					if t >= 0 and t < allowed: allowed = maxf(0, t - 0.001)
	if allowed < 1.0 or movement.length() + 0.00001 < original_length: collision_stops += 1
	return movement * allowed

func pair_clearance(index: int, other: int) -> float:
	return Tactics.BODY_SPACE if index in traffic_blockers and other in traffic_blockers else 0.98

func footprint_points(index: int) -> Array[Vector3]:
	if traffic_footprints.size() == 12: return traffic_footprints[index]
	return compute_footprint_points(index)

func compute_footprint_points(index: int) -> Array[Vector3]:
	var player = players[index]
	var result: Array[Vector3] = [player.position]
	if not player.looping and player.clips.has(player.clip_name) and player.clip_name in ["receive","recovery"]:
		if player.animation_time<player.clips[player.clip_name].contact_time+0.3:
			var hands: Vector3=player.contact_local(player.clip_name)
			hands.y=0
			result.append(player.position+Basis(Vector3.UP,player.rotation.y)*hands*0.4)
	if dive_motions.has(index):
		var motion: Dictionary = dive_motions[index]
		var clip = player.clips[motion.action]
		if motion.source_time>clip.contact_time+0.08 and motion.source_time<clip.recovery_end-0.65:
			# A player lying on the floor occupies the torso and legs, not just
			# the upright root circle. Teammates must run around the prone body.
			var forward := Vector3(sin(player.rotation.y),0,cos(player.rotation.y))
			result.append(player.position+forward*0.9)
			result.append(player.position-forward*0.6)
	return result

func avoid_teammates(index: int, desired: Vector3, route: Vector3, max_speed: float) -> Vector3:
	if route.length() < 0.20: return desired
	var contact_actor := receiver if phase in ["RECEIVE","CPU_RECEIVE"] else (setter if phase in ["SET","CPU_SET"] else hitter)
	var forward := route.normalized()
	var tangent := Vector3(forward.z, 0, -forward.x)
	var lookahead := minf(route.length()+0.35, 3.0)
	for j in range(int(index / 6) * 6, int(index / 6) * 6 + 6):
		if j == index: continue
		if index in traffic_blockers and j in traffic_blockers:
			# Closing neighbours preserve their net lane. After a rotation the
			# actual middle may still be outside a pin: allow an ordinary safe
			# passing read until their physical and tactical orders agree.
			if not human_wall() or (players[index].position.x-players[j].position.x)*(blocking_target(index,0).x-blocking_target(j,0).x)>=0: continue
		var other_velocity: Vector3=movement_snapshot[j].velocity if movement_snapshot.size()==12 else players[j].velocity
		var closing:=desired-other_velocity
		var key := str(index) + ":" + str(j)
		var threat := 0.0
		var passing_lateral := 0.0
		# Read the entire current footprint: the root alone misses the torso
		# of a prone libero, precisely where the final setting steps must pass.
		for obstacle in footprint_points(j):
			var relative: Vector3 = obstacle - players[index].position
			relative.y = 0
			if index == contact_actor and court_shape.recovery_bypass.has(index):
				var nearest := Geometry3D.get_closest_point_to_segment(obstacle,players[index].position,players[index].position+route)
				if nearest.distance_to(obstacle) > 1.08: continue
			var meeting:=clampf(relative.dot(closing)/maxf(0.001,closing.length_squared()),0,0.55)
			var predicted_gap: float=(relative-closing*meeting).length()
			var ahead := relative.dot(forward)
			var lateral := relative.dot(tangent)
			if ahead < -0.25 or ahead > lookahead or (absf(lateral)>1.35 and predicted_gap>1.35): continue
			var sample_threat := clampf((1.0-absf(lateral)/1.35)*(1.0-maxf(0,ahead)/3.0),0,1)
			if meeting>0.01: sample_threat=maxf(sample_threat,clampf(1.0-predicted_gap/1.35,0,1)*(1.0-meeting/0.75))
			if sample_threat > threat:
				threat = sample_threat
				passing_lateral = lateral
		if threat <= 0:
			passing_sides.erase(key)
			continue
		if not passing_sides.has(key): passing_sides[key] = -1.0 if passing_lateral > 0.08 else 1.0
		# Read the impending meeting before touching the collision guard.
		# Ease the forward pace and take a small stable side step, instead of
		# arriving at full speed and having the root stopped by another body.
		desired-=forward*maxf(0,desired.dot(forward))*threat*(0.20 if index==contact_actor else 0.55)
		desired+=tangent*float(passing_sides[key])*max_speed*threat*0.55
	return desired.limit_length(max_speed)

func tactical_target(index: int, _zone: int, team: int, _side: float) -> Vector3:
	return RallyAI.target(self,index,team)

func demo_input() -> void:
	if phase == "SERVE" and server == 0:
		if phase_time > 0.45 and not toss_active and not charging:
			press_action("alternate" if int(clock_time) % 2 == 0 else "action")
		if charging and current_charge() >= 0.85: release_action()
	if phase == "RECEIVE" and not armed and ball_pos.distance_to(players[receiver].contact_world("receive"))<4.5: press_action()
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
	assert(clips.size() == preload("res://src/psa_animation_library.gd").CLIPS.size(), "Every selected source animation must load")
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
			for player in players: player.play("idle",1,true)
			touches = [0, 0]
			rotations = [0, 0]
			possession = 0
			phase = "SET"
			setter = 5
			ball_pos = Vector3(0, contact_height("fast_set" if quick else "set"), 1.5)
			armed = true
			input_quality = 1.0
			pass_quality = 1.0
			fast_set = quick
			set_dir = direction
			plan_attack(direction, quick)
			players[setter].rotation.y = players[setter].setting_yaw
			players[setter].position = players[setter].stance_for_contact("fast_set" if quick else "set", ball_pos)
			var landing := RallyAI.attack_contact(self,direction,planned_hitter,ball_pos)
			landing.y = contact_height("attack")
			players[planned_hitter].position = players[planned_hitter].stance_for_contact("attack", landing)
			set_ball()
			assert(phase == "ATTACK")
			assert(flight_target.distance_to(landing) < 0.01)
			if quick: assert(flight_left < normal_time)
			else: normal_time = flight_left
			if direction == 3: assert(flight_target.z > 3.0)
	# Exercise contextual inputs and the actual serve fault/scoring branch.
	phase = "RECEIVE"
	armed = false
	flight_left = 0.02
	receive_deadline = clock_time + flight_left
	players[receiver].position = players[receiver].stance_for_contact("receive",ball_pos)
	press_action()
	assert(armed and input_quality > 0.9)
	test_charge_and_context_controls()
	test_manual_reception()
	test_bounce_and_animation()
	test_tactical_spacing()
	test_planned_attacks_and_jump_lifecycle()
	test_reference_cases()
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
	clock_time = 0
	attack_serial = 0
	shot_serial = 0
	rally_serial = 0
	last_shots = [-1,-1]
	last_ai_direction = -1
	rally_events.clear()
	rng.seed = 194260
	reset_rally()
	print("SELF TEST PASS: source meshes, four set zones, contextual Cross/Square/Circle, charge and real fault flights, arrival accuracy, block formations")

func test_reference_cases() -> void:
	server = 0
	rotations = [0,0]
	reset_rally()
	started = true
	demo = false
	possession = 0
	receiver = 4
	incoming_kind = "soft"
	incoming_power = 0.1
	set_phase("RECEIVE")
	armed = true
	input_quality = 0.24
	ball_pos = Vector3(0,contact_height("receive"),5.2)
	players[receiver].position = players[receiver].stance_for_contact("receive",ball_pos)
	receive_ball()
	assert(phase=="SET" and out_of_system<0 and setter_action=="receive")
	ball_pos = flight_target
	players[setter].position = players[setter].stance_for_contact("receive",ball_pos)
	armed = true
	input_quality = pass_quality
	set_ball()
	assert(phase=="ATTACK" and hitter_action=="receive" and block_count==0)
	ball_pos = flight_target
	players[hitter].position = players[hitter].stance_for_contact("receive",ball_pos)
	armed = true
	input_quality = 1
	charge = 0.1
	attack_ball()
	assert(phase=="CPU_RECEIVE" and incoming_kind=="free")
	# An overpass can be attacked on the first team touch, before a set.
	reset_rally()
	possession = 0
	last_touch = 0
	ball_pos = Vector3(0,contact_height("receive"),3.5)
	incoming_kind = "overpass"
	incoming_power = 0.1
	send_to_court(0,Vector3(0,0.105,-2.0),1.15)
	assert(phase=="CPU_ATTACK" and touches[1]==0 and Tactics.front(hitter,rotations[1]))
	# The tape can keep a ball alive on the opposite side, without a point.
	reset_rally()
	set_phase("CPU_RECEIVE")
	possession = 1
	last_touch = 0
	incoming_kind = "spike"
	ball_pos = Vector3(0,2.48,0.12)
	ball_vel = Vector3(0,0,-15)
	flight_spin = Vector3.ZERO
	flight_gravity = G
	flight_left = 0.3
	airborne = true
	var before_score := scores.duplicate()
	var before_net := net_contacts
	step(1.0/60.0)
	assert(net_contacts==before_net+1 and scores==before_score and ball_vel.z<0)
	assert(phase in ["CPU_RECEIVE","LOOSE"])
	# A fourth touch must finish once; callers cannot overwrite POINT.
	reset_rally()
	possession = 0
	receiver = 4
	set_phase("RECEIVE")
	armed = true
	input_quality = 1
	touches[0] = 3
	ball_pos = Vector3(0,contact_height("receive"),5.2)
	players[receiver].position = players[receiver].stance_for_contact("receive",ball_pos)
	var before: int = scores[1]
	receive_ball()
	assert(phase=="POINT" and scores[1]==before+1)
	for frame in 60: step(1.0/120.0)
	assert(phase=="POINT" and scores[1]==before+1)
	print("REFERENCE CASES PASS: out-of-system bump set / legal free third ball / first-touch overpass attack / live tape / exactly one point on fourth touch")

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
				players[setter].play("idle",1,true)
				phase = "SET" if team == 0 else "CPU_SET"
				fast_set = false
				pass_quality = 1
				armed = true
				input_quality = 1
				ball_pos = Tactics.world(team, 1.15, 1.5)
				ball_pos.y = contact_height("set")
				plan_attack(direction, false)
				players[setter].rotation.y = players[setter].setting_yaw
				players[setter].position = players[setter].stance_for_contact("set", ball_pos)
				var committed := planned_hitter
				set_ball()
				assert(hitter == committed and destination == direction)
				assert(hitter == Tactics.attacker_for(self,team,direction,setter))
				assert(not Tactics.libero(hitter, rotation, team == server))
				assert(absf(flight_target.x - RallyAI.attack_contact(self,direction,hitter,ball_pos).x) < 0.81)
				if not Tactics.front(hitter, rotation): assert(absf(flight_target.z) > 3.0)
				var predicted := BallFlight.advance(ball_pos, ball_vel, flight_spin, flight_left,flight_gravity)
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
	assert(net_contacts == before_net + 1 and phase in ["LOOSE","RECEIVE","CPU_RECEIVE"])
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
	var previous_demo := demo
	demo=true # Exercise automatic one-, two- and three-man formations here.
	var scenarios := 0
	var smallest := INF
	for team in 2:
		for rotation in 6:
			rotations = [rotation, rotation]
			assert(Tactics.slot(server_index(team), rotation) == 3)
			assert(Tactics.slot(team * 6 + 5, rotation) == posmod(Tactics.INITIAL_SLOTS[5] + rotation, 6))
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
	demo=previous_demo

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
	assert(players[serving].position.distance_to(original) < 0.01 and aim.y > 0.9 and set_dir == 3, "Left-direction controls aim without moving the server")
	Input.action_press("up")
	step(1.0 / 120.0)
	Input.action_release("up")
	assert(aim.y < -0.9 and set_dir == 1 and players[serving].position.distance_to(original) < 0.01)
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
			var serve_start: Vector3 = players[server_index(0)].position
			for frame in int(5.0 * fps):
				step(1.0 / fps)
				if phase != "SERVE": break
			assert(phase == "CPU_RECEIVE" and last_serve_fault.is_empty(), "Both max-power serve animations must contact the ball")
			assert(players[server_index(0)].position.distance_to(serve_start) > 0.4, "Jump and float serve must advance their actor with the source steps")
	# Guaranteed excess risk still travels physically and scores only on landing.
	var faults: Dictionary = {}
	for attempt in 12:
		server = 0
		reset_rally()
		send_test_button(JOY_BUTTON_A)
		charge_start = clock_time - Timing.SERVE_CHARGE_SECONDS * 1.5
		send_test_button(JOY_BUTTON_A, false)
		var before: int = scores[1]
		for frame in 600:
			step(1.0 / 120.0)
			if phase != "SERVE": break
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
			var hit_target := RallyAI.attack_contact(self,direction,planned_hitter,target)
			hit_target.y = contact_height("attack")
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
				var landing := BallFlight.intercept(ball_pos, ball_vel, flight_spin, 0.105,flight_gravity)
				assert(landing.point.distance_to(Vector3(-3.85,0.105,-8)) < 0.03, "A tap must land at the selected corner")
	# The auxiliary blocker is continuously directed by the stick, with safe slots.
	reset_rally()
	set_phase("CPU_ATTACK")
	possession = 1
	attack_serial += 1
	block_count = 2
	block_anchor = -3.4
	manual_wall.right_joined=true
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
			var threshold := 0.62 if mode == "early" else (-0.025 if mode == "late" else 0.025)
			for frame in 180:
				if mode != "none" and not sent and receive_deadline - clock_time <= threshold:
					send_test_button(JOY_BUTTON_A)
					assert(armed, "Cross reception must accept the arrival or late window")
					if mode == "early": assert(input_quality < 0.8)
					if mode == "perfect": assert(input_quality > 0.97)
					if mode == "late": assert(late_receive and input_quality < 0.8)
					sent = true
				step(1.0 / fps)
				if phase != "RECEIVE": break
			if mode == "none":
				assert(phase == "LOOSE" or phase == "POINT", "No input must never auto-save")
			else:
				assert(phase == "SET" or (mode=="early" and phase=="LOOSE") or (mode=="late" and phase in ["CPU_RECEIVE","CPU_ATTACK"]), "Manual Cross reception must physically return the ball at every frame rate")
				if mode == "perfect":
					assert(pass_quality > 0.97 and absf(flight_target.x) <= 1.51 and flight_target.z >= 0.65 and flight_target.z <= 3.01, "Perfect reception must target central zone 3")
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

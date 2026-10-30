extends SceneTree
## Real PSA/native avatars, isolated career, deterministic 30/60 Hz captures.
var game
var motor
var menu
var host
var base_config: Dictionary = {}
var checks := 0
var failures: Array[String] = []
var report: Dictionary = {}

func _initialize(): call_deferred("run")

func check(value: bool, message: String):
	checks += 1
	if not value: failures.append(message); push_error("LEGEND72 REAL: " + message)

func tick(frames: int, dt: float = 1.0 / 60.0):
	for frame in frames:
		game.step(dt)
		await process_frame

func capture(action: String):
	# Identity prints use an UPDATE_ONCE SubViewport. Let its GPU texture
	# finish before reading the stadium viewport after changing a whole roster.
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://docs/legend72-match-" + action + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "save " + action + " screenshot")
	if action=="receive":
		var p=game.players[motor.controlled_index]
		var printed: Texture2D=p.body_parts.cloth.material_override.get_shader_parameter("identity")
		printed.get_image().save_png("res://docs/legend72-shirt-print.png")
		report.shirt={"name":p.roster_identity.name,"number":p.roster_identity.jersey_number,"identity_count":game.players.filter(func(avatar): return avatar.roster_identity.get("id","")==p.roster_identity.id).size()}
	print("LEGEND72_CAPTURE ", action)

func camera_at(center: Vector3, offset: Vector3 = Vector3(-6, 3.8, 6)):
	game.camera.position = center + offset
	game.camera.fov = 48
	game.camera.look_at(center + Vector3(0, 1.2, -0.4))

func restart(role: String = "S"):
	# Build each role through the actual backend. Reusing a setter lineup
	# while injecting the same identity at OH would produce a fake duplicate.
	var manager=menu.manager
	var person: Dictionary=manager.default_profile()
	person.name="Luca Testa"; person.number=12; person.jersey_number=12
	person.role={"S":"setter", "OH":"outside_hitter", "MB":"middle_blocker", "L":"libero"}.get(role,"outside_hitter")
	check(manager.new_career(person,str(manager.starter_clubs()[0].id),{"best_of":3,"autosave":false},12),"create real "+role+" roster")
	var settings: Dictionary=manager.launch_config()
	check(motor.start(settings), "real engine starts " + role)
	check(game.players.filter(func(p): return p.roster_identity.get("id","")==settings.player.id).size()==1,"created identity appears once in real role lineup")
	game.demo = false
	game.camera_mode = 0
	for p in game.players: p.render_at_draw = false

func finite_poses():
	for p in game.players:
		check(p.skeleton != null and p.pose_tree != null and p.pose_tree.initialized, "real native skinned avatar is active")
		for transform in p.last_pose:
			if not transform.origin.is_finite() or not transform.basis.x.is_finite() or not transform.basis.y.is_finite() or not transform.basis.z.is_finite():
				check(false, "all real native pose transforms are finite")
				return
	check(true, "all real native pose transforms are finite")

func visible_hand_gap(index: int, action: String) -> float:
	var p = game.players[index]
	var correction: Vector3 = p.global_basis * p.visual_root.position
	var left: Vector3 = p.current_hand(true) + correction
	var right: Vector3 = p.current_hand(false) + correction
	if action in ["receive", "set", "block"]: return ((left + right) * 0.5).distance_to(game.ball_pos)
	return minf(left.distance_to(game.ball_pos), right.distance_to(game.ball_pos))

func place_contact(stage: String, action: String, position: Vector3):
	game.phase = {"receive":"RECEIVE", "set":"SET", "attack":"ATTACK"}[stage]
	game.possession = 0; game.touches = [0, 0]
	motor.live = true; motor.shot_stage = stage; motor.actor = motor.controlled_index
	motor.last_actor = 6; motor.last_team = 1
	game.players[motor.controlled_index].position = position
	# This staged contact has no intervening AI frame. Avoid placing the
	# subject on top of a teammate's normal receiving position in the photo.
	for index in 6:
		if index==motor.controlled_index: continue
		var teammate=game.players[index]
		if Vector2(teammate.position.x-position.x,teammate.position.z-position.z).length()<1.05:
			teammate.position.x=clampf(teammate.position.x+1.6,-4.0,4.0)
	game.ball_pos = motor.hand_point(motor.controlled_index, action)
	game.ball_vel = Vector3(0, -1, 0)
	game.ball.position = game.ball_pos

func run():
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1600, 900); root.content_scale_size = root.size
	root.position = Vector2i(-3000, -3000)
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false)
	for node in game.get_children():
		if node.get_script() == load("res://src/start_menu.gd"): host = node
	check(host != null, "real scene contains start menu")
	menu = host.legend_menu
	var manager = menu.manager
	var person: Dictionary = manager.default_profile()
	person.name = "Luca Testa"; person.number = 12; person.jersey_number = 12; person.role = "setter"
	check(manager.new_career(person, str(manager.starter_clubs()[0].id), {"best_of":3, "autosave":false}, 12), "create isolated real player career")
	base_config = manager.launch_config()
	check(not base_config.is_empty(), "real career creates match configuration")
	host.panel.hide(); host.overlay.hide(); host.play_hub.hide(); host.clubs.hide(); menu.hide()
	motor = game.legend_match
	restart()
	game.match_audio.enabled = false
	await process_frame
	finite_poses()
	check(game.players[5].roster_identity.id == person.get("id", manager.state.profile.id), "controlled real avatar uses custom career identity")
	check(game.players[5].kit_identity.get("_club_id", "") == manager.state.club_id, "actual selected club kit is active")
	camera_at(game.players[5].position)
	await capture("serve")
	var original: Vector3 = game.players[5].position
	motor.move_input = Vector2(-0.55, 0)
	await tick(100)
	var moved: Vector3 = game.players[5].position
	check(moved.distance_to(original) > 2.0, "100 frames of LS move the real root")
	check(absf(moved.y) < 0.01, "real locomotion does not start an automatic jump")
	camera_at(moved)
	await capture("run")
	motor.move_input = Vector2.ZERO
	await tick(30)
	var stopped: Vector3 = game.players[5].position
	await tick(30, 1.0 / 30.0)
	check(game.players[5].position.distance_to(stopped) < 0.005, "released LS leaves real avatar stationary at 30 Hz")
	check(game.players[5].velocity.length() < 0.01, "real root stops after braking")
	report.movement = {"distance":moved.distance_to(original), "stop_drift":game.players[5].position.distance_to(stopped)}
	restart("OH")
	game.players[0].position = Vector3(-2.7, 0, 2.5)
	camera_at(game.players[0].position, Vector3(-5, 3.6, 6))
	check(motor.jump(), "R1 starts real avatar jump")
	var peak := 0.0; var visible_peak := 0.0; var land_time := 0.0
	for frame in 70:
		await tick(1)
		var p = game.players[0]
		peak = maxf(peak, p.position.y)
		var foot: int = p.clips.idle.names.find("LeftFoot")
		if foot >= 0: visible_peak = maxf(visible_peak, p.position.y + p.last_pose[foot].origin.y + p.visual_root.position.y)
		if frame == 25: await capture("jump")
		if frame > 2 and p.position.y <= 0.001:
			land_time = (frame + 1) / 60.0; break
	check(peak > 0.65 and peak < 1.2, "real manual jump apex has plausible physical height")
	check(land_time > 0.7 and land_time < 1.2, "real manual jump lands in a plausible flight time")
	report.jump = {"physical_peak":peak,"visible_foot_peak":visible_peak,"duration":land_time}
	restart("OH")
	place_contact("receive", "receive", Vector3(0, 0, 5.2))
	var before: Vector3 = game.ball_pos
	check(motor.attempt_manual("action", .7), "real manual receive contacts nearby ball")
	check(game.ball_pos.is_equal_approx(before), "real receive does not teleport ball")
	var receive_gap := visible_hand_gap(0, "receive")
	report.receive_gap = receive_gap
	camera_at(game.players[0].position, Vector3(-4.3, 3.1, 5))
	await capture("receive")
	for p in game.players: p.visible=p==game.players[motor.controlled_index]
	await capture("identity")
	for p in game.players: p.visible=true
	restart("OH")
	game.players[0].position = Vector3(0, 0, .55)
	game.possession = 1
	motor.jump()
	await tick(21)
	game.phase = "RECEIVE"; game.possession = 0; game.incoming_kind = "spike"
	motor.live = true; motor.shot_stage = "receive"; motor.last_actor = 6
	game.ball_pos = motor.hand_point(0, "block"); game.ball_vel = Vector3(0, -1, 8)
	before = game.ball_pos
	motor.try_block(game.ball_pos - Vector3(0, 0, .1))
	game.ball.position = game.ball_pos
	check(game.ball_pos.is_equal_approx(before), "real block changes velocity without teleporting ball")
	report.block_gap = visible_hand_gap(0, "block")
	camera_at(game.players[0].position, Vector3(-5, 3.5, 5.5))
	await capture("block")
	restart("OH")
	game.players[0].position = Vector3(0, 0, 5.3)
	motor.move_input = Vector2(.7, -.7)
	check(motor.dive(), "RT explicitly starts real recovery dive")
	await tick(8)
	place_contact("receive", "dive", game.players[0].position)
	before = game.ball_pos
	check(motor.attempt_manual("dump", .55), "real manual dive contacts a ball within physical reach")
	check(game.ball_pos.is_equal_approx(before), "real dive never teleports the ball")
	report.dive_gap = visible_hand_gap(0, "dive")
	camera_at(game.players[0].position, Vector3(-4.3, 2.8, 5.5))
	await capture("dive")
	finite_poses()
	report.checks = checks; report.failures = failures
	var out := FileAccess.open("res://docs/legend72-real-capture.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(report, "\t")); out.close()
	print("LEGEND72 REAL CAPTURE ", JSON.stringify(report))
	game.free(); quit(0 if failures.is_empty() else 1)

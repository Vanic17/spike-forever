extends SceneTree
## Real scene, native source avatars and the live menu/career callback.
## Run with isolated APPDATA and -- --settings-test; never uses --fallback-test.
var game
var menu
var manager
var failures: Array[String] = []
var checks := 0
var signal_count := 0
var completed_results: Array[Dictionary] = []
var report: Dictionary = {}

class RetryRepository extends "res://src/legend_save.gd":
	var fail_writes:=false
	func write(slot: int,state: Dictionary) -> bool:
		if fail_writes: error="TEST I/O temporaneamente indisponibile"; return false
		return super.write(slot,state)

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("LEGEND INTEGRATION72: " + message)

func settle() -> void:
	await process_frame
	await process_frame

func joy(button: int, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button; event.pressed = pressed
	return event

func axis(which: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = which; event.axis_value = value
	return event

func finite_poses() -> bool:
	for avatar in game.players:
		if avatar.skeleton == null or avatar.pose_tree == null or avatar.last_pose.is_empty(): return false
		for pose in avatar.last_pose:
			if not pose.origin.is_finite() or not pose.basis.x.is_finite() or not pose.basis.y.is_finite() or not pose.basis.z.is_finite(): return false
	return true

func test_scene_and_player() -> void:
	check(game.players.size() == 12 and game.models.has("body") and game.clips.size() > 50, "the real scene loads twelve source avatars and its complete animation bank")
	check(finite_poses(), "all real native avatar poses begin finite")
	var own = game.players[game.legend_match.controlled_index]
	check(str(own.roster_identity.id) == str(manager.state.profile.id), "the fixed selected avatar wears the created career identity")
	check(str(own.kit_identity.get("_club_id", "")) == str(manager.state.club_id), "the controlled avatar wears the actual selected club kit")
	check(own.body_parts.cloth.material_override.get_shader_parameter("identity")==load("res://src/club_kits.gd").identity_print(own,manager.state.profile),"the visible shirt print belongs to the created name and number")
	var expected_variant := "home" if menu.active_fixture.home == manager.state.club_id else "away"
	check(str(own.kit_identity.get("_variant", "")) == expected_variant, "the real kit variant follows the fixture home-away order")
	check(not game.match_management.active and game.legend_match.active and game.use_player_stats, "manual motor exclusively owns gameplay with live ratings")
	check(game.display_selected() == game.legend_match.controlled_index, "main selection keeps the single manual athlete")
	var origin: Vector3 = own.position
	for frame in 10: game.step(1.0 / 60.0)
	check(own.position.distance_to(origin) < 0.001, "the real athlete does not move without manual input")
	game._unhandled_input(axis(JOY_AXIS_LEFT_X, 0.7))
	for frame in 20: game.step(1.0 / 60.0)
	check(own.position.distance_to(origin) > 0.1, "main routes left-stick input to actual continuous avatar movement")
	check(finite_poses(), "real native poses remain finite during manual running")
	game._unhandled_input(joy(JOY_BUTTON_START))
	check(game.paused, "the existing Start command pauses a manual match")
	var pause_origin: Vector3 = own.position
	game._unhandled_input(axis(JOY_AXIS_LEFT_X, 0.0))
	game.legend_match.press("action")
	game._unhandled_input(joy(JOY_BUTTON_A, false))
	game.step(0.15)
	check(own.position.is_equal_approx(pause_origin) and game.legend_match.move_input == Vector2.ZERO, "paused input releases update held axes while physical play remains stopped")
	game._unhandled_input(joy(JOY_BUTTON_START))
	check(not game.paused, "Start resumes the same manual match")
	for frame in 25: game.step(1.0 / 60.0)
	check(own.velocity.length() < 0.01, "the released left stick brakes to rest after pause")
	var rest: Vector3 = own.position
	game._unhandled_input(joy(JOY_BUTTON_RIGHT_SHOULDER))
	for frame in 12: game.step(1.0 / 60.0)
	check(own.position.y > rest.y + 0.2 and finite_poses(), "R1/RB explicitly raises the real animated avatar with finite native poses")
	for frame in 60: game.step(1.0 / 60.0)
	check(absf(own.position.y) < 0.01, "the manual physical jump lands while using real source animations")
	report.real_scene = {"clips":game.clips.size(),"models":game.models.size(),"club":manager.state.club_id,"kit_variant":expected_variant,"native":own.native_animation_enabled}

func test_result_callback() -> void:
	var fixture: Dictionary = menu.active_fixture.duplicate(true)
	var previous_history: int = manager.state.match_history.size()
	var previous_xp: int = manager.state.xp
	game.legend_match.match_finished.connect(func(result: Dictionary):
		signal_count += 1
		completed_results.append(result.duplicate(true)))
	game.scores = [24, 10]; game.phase = "RECEIVE"
	game.legend_match.award(0, "INTEGRATION SET ONE")
	check(game.sets == [1, 0] and not game.match_finished, "the first actual motor set does not finish a best-of-three match")
	game.scores = [24, 11]; game.phase = "RECEIVE"
	game.legend_match.award(0, "INTEGRATION SET TWO")
	check(signal_count == 1, "the live motor emits the completed match exactly once")
	check(manager.state.match_history.size() == previous_history + 1, "the actual UI callback records one measured career result")
	check(str(manager.last_result.fixture_id) == str(fixture.id) and manager.last_result.won, "the recorded career row identifies the played fixture and user's win")
	var away: bool = fixture.home != manager.state.club_id
	check(manager.last_result.sets == ([0, 2] if away else [2, 0]), "backend result preserves home-away score order")
	check(manager.last_result.set_scores == ([[10, 25], [11, 25]] if away else [[25, 10], [25, 11]]), "backend receives the full home-away set scores")
	check(manager.last_result.stats_source == "measured" and manager.last_result.performance.has("minutes"), "the result uses the measured performance contract")
	check(manager.state.pending_fixture_id == "" and manager.state.rewarded_ids.has(fixture.id), "the completed fixture clears pending state and records its reward once")
	check(manager.state.xp == previous_xp, "uncommanded test gameplay invents no personal performance or XP")
	await settle()
	check(not game.started and not game.legend_match.active and menu.visible and menu.view == "result", "the deferred main return displays the real career result page")
	check(menu.pending_post.is_empty() and menu.active_fixture.is_empty(), "the post-match UI consumes its pending callback exactly once")
	var count_after: int = manager.state.match_history.size()
	menu.on_match_finished(completed_results[0])
	check(manager.state.match_history.size() == count_after and signal_count == 1, "a duplicate UI completion cannot record or reward the match again")
	menu.show_page("home")
	check(menu.visible and menu.view == "home" and manager.active(), "the result page returns to the same active career hub")
	report.result = {"fixture_id":fixture.id,"away":away,"signal_count":signal_count,"history":manager.state.match_history.size(),"sets":manager.last_result.sets}

func test_cancel_cycle() -> void:
	var history_count: int = manager.state.match_history.size()
	menu.launch_match()
	check(game.started and game.legend_match.active and not menu.active_fixture.is_empty(), "a second fixture launches from the real resumed career menu")
	game.return_to_main_menu()
	await settle()
	check(not game.started and not game.legend_match.active and menu.visible and menu.view == "home", "abandoning a manual match returns directly to the active career hub")
	check(manager.state.pending_fixture_id == "" and menu.active_fixture.is_empty(), "abandonment clears both backend and UI pending fixture state")
	check(manager.state.match_history.size() == history_count and signal_count == 1, "an abandoned match creates no result or extra completion callback")
	report.cancel = true

func test_save_retry() -> void:
	var repository:=RetryRepository.new()
	manager.repository=repository; manager.engine.repository=repository
	manager.state.options.autosave=true
	menu.launch_match()
	check(game.started and game.legend_match.active,"retry case launches before simulated I/O failure")
	var fixture_id: String=menu.active_fixture.id
	var previous_history: int=manager.state.match_history.size()
	game.scores=[24,10]; game.phase="RECEIVE"
	game.legend_match.award(0,"TEST SAVE RETRY SET ONE")
	repository.fail_writes=true
	game.scores=[24,10]; game.phase="RECEIVE"
	game.legend_match.award(0,"TEST SAVE RETRY")
	await settle()
	check(menu.visible and menu.view=="result","a save failure retains the real result screen")
	check(manager.state.match_history.size()==previous_history+1 and manager.state.rewarded_ids.has(fixture_id),"the unsaved result remains recorded once in memory")
	check(is_instance_valid(menu.modal) and menu.modal.visible,"the player receives a retry warning before leaving")
	if is_instance_valid(menu.modal): menu.modal.confirmed.emit()
	await settle()
	repository.fail_writes=false
	check(manager.save(),"SALVA can retry the same completed result after storage recovers")
	var restored=load("res://src/legend_career.gd").new()
	check(restored.load_career(12) and restored.state.rewarded_ids.has(fixture_id),"the retried result and reward survive a full career reload")
	check(restored.state.match_history.size()==previous_history+1,"retry and reload never duplicate a reward")
	report.save_retry=true

func run() -> void:
	var user_path := ProjectSettings.globalize_path("user://").replace("\\", "/")
	check(user_path.contains("legend72-integration"), "integration test uses isolated workspace APPDATA")
	if not failures.is_empty(): quit(1); return
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test = true
	await settle()
	var host
	for child in game.get_children():
		if child.get_script() == load("res://src/start_menu.gd"): host = child; break
	check(host != null, "the real main scene creates its full start menu")
	if host == null: quit(1); return
	menu = host.legend_menu; manager = menu.manager
	var profile: Dictionary = manager.default_profile()
	profile.name = "Integrazione reale 72"; profile.number = 72; profile.jersey_number = 72
	var club: Dictionary = manager.starter_clubs()[0]
	check(manager.new_career(profile, str(club.id), {"best_of":3,"autosave":false,"seed":720144}, 12), "the actual menu manager creates an isolated player career: " + manager.error)
	menu.launch_match()
	check(game.legend_match.active and game.started and not menu.active_fixture.is_empty(), "the live career menu launches the actual manual motor")
	test_scene_and_player()
	await test_result_callback()
	await test_cancel_cycle()
	await test_save_retry()
	check(finite_poses(), "all real rigs retain finite poses after both career return paths")
	report.checks = checks; report.failures = failures
	FileAccess.open("res://docs/legend72-integration.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND_INTEGRATION72 ", JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

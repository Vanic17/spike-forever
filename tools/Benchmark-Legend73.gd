extends SceneTree
## CPU simulation and full native pose evaluation only; not GPU/whole-game FPS.
var game
var config: Dictionary={}
var failures: Array=[]
func _initialize():call_deferred("run")
func sample(manual: bool,ai_reference: bool=false) -> Dictionary:
	if not game.legend_match.start(config):failures.append("Could not start matched career configuration");return {}
	if not manual:
		game.legend_match.stop()
		game.match_management.configure_rosters([config.club,config.opponent],[config.club_lineup,config.opponent_lineup],{},config.options)
	game.use_player_stats=true
	game.match_best_of=int(config.best_of);game.match_points=int(config.points)
	game.legend_match.test_ai_driver=ai_reference
	game.started=true;game.paused=false;game.demo=not manual or ai_reference
	game.scores=[0,0];game.sets=[0,0];game.rotations=[0,0];game.server=0;game.match_finished=false
	game.rng.seed=730331
	# start() already prepares the manual opening rally. A second reset would
	# benchmark the between-point return walk instead of the actual launch.
	if not manual or ai_reference:game.reset_rally()
	for avatar in game.players:avatar.render_at_draw=false
	for frame in 120:game.step(1.0/60.0)
	var times: Array=[]
	var before_contacts: int=game.test_contacts
	var before_points: int=game.test_points
	for frame in 600:
		var began:=Time.get_ticks_usec();game.step(1.0/60.0);times.append(Time.get_ticks_usec()-began)
	var mean:=0.0
	for value in times:mean+=value
	times.sort()
	return {"samples":times.size(),"mean_step_us":mean/times.size(),"p95_step_us":times[int(times.size()*.95)],"max_step_us":times[-1],"contacts":game.test_contacts-before_contacts,"points":game.test_points-before_points,"manual":manual,"ai_reference":ai_reference,"avatars":game.players.size(),"native":game.players[0].native_animation_enabled,"pose_trees":game.find_children("NativePoseEvaluation","",true,false).size(),"final_phase":game.phase,"clock_seconds":game.clock_time}
func run():
	var user_path:=ProjectSettings.globalize_path("user://").replace("\\","/")
	if not user_path.contains("legend73"):push_error("Benchmark requires isolated legend73 APPDATA");quit(1);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false
	await process_frame
	var career=load("res://src/legend_career.gd").new()
	var profile: Dictionary=career.default_profile();profile.name="Benchmark Mito 73";profile.role="outside_hitter"
	if not career.new_career(profile,str(career.starter_clubs()[0].id),{"autosave":false,"seed":730331},12):push_error(career.error);game.free();quit(1);return
	config=career.launch_config()
	config.seed=730331
	var baseline: Dictionary=sample(false)
	var manual: Dictionary=sample(true)
	var ai_reference: Dictionary=sample(true,true)
	if baseline.is_empty() or manual.is_empty() or ai_reference.is_empty():push_error("Native mode benchmark did not start");game.free();quit(1);return
	var matched: bool=baseline.contacts==ai_reference.contacts and baseline.points==ai_reference.points and baseline.final_phase==ai_reference.final_phase
	if not matched:failures.append("AI reference did not reproduce the same rally workload")
	var report: Dictionary={"exhibition":baseline,"legend":manual,"legend_ai_reference":ai_reference,"mean_ratio":manual.mean_step_us/maxf(1,baseline.mean_step_us),"matched_ai_ratio":ai_reference.mean_step_us/maxf(1,baseline.mean_step_us),"matched_ai_workload":matched,"failures":failures,"scope":"Same stadium, player identities, initial rotation and twelve full native pose evaluations at 60 Hz. Legend manual leaves the user stationary, so its rally differs. The AI-reference sample keeps the adapter active with its test_ai_driver and uses exhibition demo inputs for matched-workload CPU comparison. CPU simulation/pose cost only; excludes stadium rendering, GPU and controller latency."}
	FileAccess.open("res://docs/legend73-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND PERFORMANCE73 ",JSON.stringify(report))
	game.free();quit(0 if failures.is_empty() else 1)

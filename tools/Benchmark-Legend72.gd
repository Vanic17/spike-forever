extends SceneTree
## Native twelve-avatar CPU update cost; deliberately excludes renderer/GPU FPS.
func _initialize(): call_deferred("run")
func run():
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	await process_frame
	var career=load("res://src/legend_career.gd").new()
	var profile: Dictionary=career.default_profile(); profile.name="Benchmark 72"
	if not career.new_career(profile,str(career.starter_clubs()[0].id),{"autosave":false,"seed":72072},12): push_error(career.error); quit(1); return
	game.legend_match.start(career.launch_config())
	for avatar in game.players: avatar.render_at_draw=false
	for frame in 120: game.step(1.0/60.0)
	var times: Array=[]
	for frame in 600:
		var began:=Time.get_ticks_usec(); game.step(1.0/60.0); times.append(Time.get_ticks_usec()-began)
	var mean:=0.0
	for value in times: mean+=value
	times.sort()
	var report: Dictionary={"samples":times.size(),"avatars":game.players.size(),"source_clips":game.clips.size(),"native_animation":game.players[0].native_animation_enabled,"mean_step_us":mean/times.size(),"p95_step_us":times[int(times.size()*.95)],"max_step_us":times[-1],"scope":"CPU manual simulation plus twelve full native pose evaluations at 60 Hz; excludes stadium render, GPU, driver and real controller latency"}
	FileAccess.open("res://docs/legend72-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND72 PERFORMANCE ",JSON.stringify(report))
	game.free(); quit()

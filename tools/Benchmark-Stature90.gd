extends "res://tools/Benchmark-Fluidity84.gd"
var preset:=2
var gpu_ms: Array[float]=[]
var render_cpu_ms: Array[float]=[]
var draw_calls: Array[float]=[]
var primitives: Array[float]=[]
var video_memory: Array[float]=[]
var gpu_timestamps:=false
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):preset=clampi(int(arg.trim_prefix("--preset=")),0,3)
	super.run()
	game.preferences.data.merge(game.preferences.PRESETS[preset],true);game.preferences.apply(game.preferences.data,false)
	Engine.max_fps=cap;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var db=load("res://src/league.gd").new();var kits=load("res://src/club_kits.gd")
	var ids: Array=["acqua-santanna-cuneo","cucine-lube-civitanova"]
	for side in 2:
		var club: Dictionary=db.teams.filter(func(t):return t.id==ids[side])[0];var squad: Array=db.lineup(club)
		game.team_names[side]=club.name
		for i in 6:game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(club.id,"home" if side==0 else "away"),kits.selection(club.id,"home" if side==0 else "away",true))
	game.set_home_club(ids[0],0)
	gpu_timestamps=RenderingServer.has_method("viewport_set_measure_render_time")
	if gpu_timestamps:RenderingServer.call("viewport_set_measure_render_time",root.get_viewport_rid(),true)
func draw_sample():
	if done:return
	var now:=Time.get_ticks_usec()
	if age>=4 and last_draw>0:
		frame_ms.append(float(now-last_draw)/1000);fractions.append(Engine.get_physics_interpolation_fraction())
		draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitives.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		video_memory.append(float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
		if gpu_timestamps:
			gpu_ms.append(float(RenderingServer.call("viewport_get_measured_render_time_gpu",root.get_viewport_rid())))
			render_cpu_ms.append(float(RenderingServer.call("viewport_get_measured_render_time_cpu",root.get_viewport_rid())))
	last_draw=now
	if age<20:return
	done=true
	var frame:=distribution(frame_ms)
	var report: Dictionary={"label":label,"preset":["low","medium","high","ultra"][preset],"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"window_resolution":str(root.size),"render_scale":root.scaling_3d_scale,"msaa":root.msaa_3d,"ssao":game.preferences.data.ssao,"ssil":game.preferences.data.ssil,"ssr":game.preferences.data.ssr,"mean_fps":1000/frame.mean_ms,"frame":frame,"physics_tick_cpu":distribution(physics_ms),"physics_warmup_s":2,"draw_calls":distribution(draw_calls),"primitives":distribution(primitives),"video_memory_bytes":distribution(video_memory),"contacts":game.test_contacts,"samples":frame_ms.size(),"warmup_s":4,"measured_s":age-4,"limits":"Real asynchronous 120Hz simulation and renderer. Fixed repeatable receive/set/pipe. One local run, not all match situations. VRAM is engine allocation, not driver-wide usage."}
	for metric in ["draw_calls","primitives","video_memory_bytes"]:
		var counts: Dictionary={}
		for field in report[metric]:counts[str(field).trim_suffix("_ms")]=report[metric][field]
		report[metric]=counts
	report["gpu_render_ms"]=distribution(gpu_ms) if not gpu_ms.is_empty() and gpu_ms.max()>0 else {"available":false}
	report["renderer_cpu_ms"]=distribution(render_cpu_ms) if not render_cpu_ms.is_empty() else {"available":false}
	FileAccess.open("res://docs/stature90-performance-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAPHICS89 BENCH PASS ",JSON.stringify(report));quit()

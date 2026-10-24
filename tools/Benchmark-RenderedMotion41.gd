extends SceneTree
## Real-time rendered game/arena; deliberately no movie maker/fixed-fps mode.
const Motion=preload("res://src/motion_prototypes.gd")
const WARMUP:=120
const SAMPLES:=600
const STEP:=1.0/120.0
var game
var mode:="new"
var rendered_frames:=0
var previous_draw:=0
var intervals: Array[float]=[]
var process_times: Array[float]=[]
var simulation_times: Array[float]=[]
var simulation_ms:=0.0
var measured_start:=0
var last_fixture_frame:=-1
var rendered_frames_using_newclip:=0
var observed_contact_count:=0
var measured_prototype_contacts:=0

func _initialize() -> void: call_deferred("setup")

func distribution(values: Array[float]) -> Dictionary:
	var sorted:=values.duplicate()
	sorted.sort()
	var total:=0.0
	for value in sorted: total+=value
	return {"mean_ms":total/sorted.size(),"p50_ms":sorted[int(sorted.size()*0.50)],"p95_ms":sorted[int(sorted.size()*0.95)],"p99_ms":sorted[int(sorted.size()*0.99)],"max_ms":sorted.back()}

func setup() -> void:
	assert(DisplayServer.get_name()!="headless","This test needs a real renderer; do not report headless FPS")
	mode="original" if "--motion-original" in OS.get_cmdline_user_args() else "new"
	Motion.enabled=mode=="new"
	Engine.max_fps=60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.free()
	game.started=true
	game.demo=false
	game.self_test=false
	game.paused=false
	game.camera_mode=2
	game.set_camera()
	assert(game.players.size()==12)
	for athlete in game.players:
		athlete.render_at_draw=true
		athlete.set_process(true)
	game.rng.seed=194260
	game.clock_time=0
	game.reset_rally()
	RenderingServer.frame_post_draw.connect(measure_draw)
	print("RENDERED MOTION41 READY ",mode," GPU=",RenderingServer.get_video_adapter_name()," viewport=",root.size," cap=60 vsync=off")

func begin_construction() -> void:
	# An actual deep reception -> set -> pipe naturally selects attack_line.
	# No direct animation override: the gameplay selector decides the variant.
	game.rotations=[0,0]
	game.server=1
	game.rng.seed=40001
	game.shot_serial=0
	game.reset_rally()
	game.possession=0
	game.receiver=4
	game.set_dir=3
	game.players[4].position=game.Tactics.world(0,0,5.5)
	game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[4].contact_world("receive")
	game.phase="RECEIVE"
	game.armed=true
	game.input_quality=1
	game.incoming_kind="spike"
	game.incoming_power=0.3
	game.receive_ball()
	game.press_action("action")

func _process(_elapsed: float) -> bool:
	if game==null: return false
	var begin:=Time.get_ticks_usec()
	if rendered_frames%240==0 and last_fixture_frame!=rendered_frames:
		begin_construction()
		last_fixture_frame=rendered_frames
	if game.phase=="ATTACK": game.armed=true; game.charge=0.75; game.input_quality=1
	game.step(STEP)
	if game.phase=="ATTACK": game.armed=true; game.charge=0.75; game.input_quality=1
	game.step(STEP)
	game._process(STEP*2)
	simulation_ms=float(Time.get_ticks_usec()-begin)/1000.0
	return false

func measure_draw() -> void:
	var now:=Time.get_ticks_usec()
	rendered_frames+=1
	if rendered_frames==WARMUP: measured_start=now
	if rendered_frames>WARMUP and previous_draw>0:
		intervals.append(float(now-previous_draw)/1000.0)
		process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		simulation_times.append(simulation_ms)
		var using_new:=false
		for athlete in game.players:
			if not athlete.looping and athlete.clip_name=="attack" and athlete.native_clip_name("attack")=="attack_adaptive41": using_new=true
		if using_new: rendered_frames_using_newclip+=1
		for index in range(observed_contact_count,game.contact_log.size()):
			if game.contact_log[index].variant in Motion.NAMES: measured_prototype_contacts+=1
	observed_contact_count=game.contact_log.size()
	previous_draw=now
	if intervals.size()<SAMPLES: return
	RenderingServer.frame_post_draw.disconnect(measure_draw)
	var over25:=0
	var over50:=0
	for interval in intervals:
		if interval>25.0: over25+=1
		if interval>50.0: over50+=1
	var prototype_contacts:=0
	for contact in game.contact_log:
		if contact.variant in Motion.NAMES: prototype_contacts+=1
	var stats:=distribution(intervals)
	if mode=="new": assert(rendered_frames_using_newclip>0 and measured_prototype_contacts>0,"A real new spike must be rendered and contact the ball in the measured frames")
	var report: Dictionary={"mode":mode,"scenario":"actual_receive_set_pipe_repeated_every240_frames","renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"gpu":RenderingServer.get_video_adapter_name(),"gpu_vendor":RenderingServer.get_video_adapter_vendor(),"resolution":str(root.size),"viewport_resolution":str(root.get_visible_rect().size),"cap_fps":Engine.max_fps,"vsync":"disabled","warmup_frames":WARMUP,"measured_rendered_frames":intervals.size(),"measurement_seconds":float(now-measured_start)/1000000.0,"real_rendered_frame_intervals":stats,"observed_mean_fps":1000.0/stats.mean_ms,"frames_over_25_ms":over25,"frames_over_50_ms":over50,"engine_process_monitor":distribution(process_times),"fixed_simulation_steps_cpu":distribution(simulation_times),"players":game.players.size(),"contacts":game.test_contacts,"prototype_contacts_during_run":prototype_contacts,"prototype_contacts_in_measured_frames":measured_prototype_contacts,"rendered_frames_using_newclip":rendered_frames_using_newclip,"simulation_time":game.clock_time,"phase_at_end":game.phase,"limits":["One local hardware/driver sample, capped at60 FPS; not a guarantee for other systems","Whole rendered frame intervals include scheduling and renderer waits; no direct GPU timestamp query","Two fixed120-Hz simulation steps per real rendered frame; not movie-maker or fixed-fps rendering","Reproducible actual pipe constructions, not a complete competitive match or every recovery situation"]}
	var output:=FileAccess.open("res://docs/animation41-rendered-"+mode+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	print("RENDERED MOTION41 PASS ",JSON.stringify(report))
	quit()

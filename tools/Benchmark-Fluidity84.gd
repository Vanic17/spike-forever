extends SceneTree
## Actual fixed 120-Hz simulation vs asynchronous renderer, no forced step/frame.
var game
var label:="before"
var width:=1920
var cap:=0
var age:=0.0
var last_draw:=0
var frame_ms: Array[float]=[]
var physics_ms: Array[float]=[]
var fractions: Array[float]=[]
var repeats:=0
var moving_frames:=0
var previous_ball:=Vector3.ZERO
var done:=false
var next_fixture:=0.0
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
		if arg.begins_with("--width="):width=int(arg.trim_prefix("--width="))
		if arg.begins_with("--cap="):cap=int(arg.trim_prefix("--cap="))
	root.mode=Window.MODE_WINDOWED;root.position=Vector2i(19000,19000);root.size=Vector2i(width,roundi(width*9.0/16));root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false)
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	game.started=true;game.paused=false;game.self_test=false;game.demo=false;game.match_audio.enabled=false;game.replay.enabled=false
	game.camera_mode=2;game.set_camera();game.rng.seed=194260
	Engine.max_fps=cap;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.frame_post_draw.connect(draw_sample)
	print("FLUIDITY84 READY ",label," ",root.size," ",RenderingServer.get_video_adapter_name())
func fixture():
	game.rotations=[0,0];game.server=1;game.rng.seed=40001;game.shot_serial=0;game.reset_rally();game.possession=0;game.receiver=4;game.set_dir=3
	game.players[4].position=game.Tactics.world(0,0,5.5);game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[4].contact_world("receive");game.phase="RECEIVE";game.armed=true;game.input_quality=1;game.incoming_kind="spike";game.incoming_power=.3
	game.receive_ball();game.press_action("action")
func _physics_process(dt: float) -> bool:
	if game==null or done:return false
	if age>=next_fixture:fixture();next_fixture=age+3.0
	if game.phase=="ATTACK":game.armed=true;game.charge=.85;game.input_quality=1
	var start:=Time.get_ticks_usec();game._physics_process(dt)
	if age>=2:physics_ms.append(float(Time.get_ticks_usec()-start)/1000)
	return false
func _process(dt: float) -> bool:
	if game==null or done:return false
	age+=dt;game._process(dt)
	return false
func distribution(values: Array[float]) -> Dictionary:
	var sorted:=values.duplicate();sorted.sort();var total:=0.0
	for value in sorted:total+=value
	return {"mean_ms":total/maxi(1,sorted.size()),"p95_ms":sorted[int(sorted.size()*.95)],"p99_ms":sorted[int(sorted.size()*.99)],"max_ms":sorted.back()}
func draw_sample():
	if done:return
	var now:=Time.get_ticks_usec()
	if age>=2 and last_draw>0:
		frame_ms.append(float(now-last_draw)/1000);fractions.append(Engine.get_physics_interpolation_fraction())
		if game.airborne and game.ball_vel.length()>8 and game.phase!="SERVE":
			moving_frames+=1
			if game.ball.position.distance_squared_to(previous_ball)<1e-10:repeats+=1
	previous_ball=game.ball.position;last_draw=now
	if age<12:return
	done=true
	var report: Dictionary={"label":label,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"fps_cap":cap,"vsync":false,"samples":frame_ms.size(),"frame":distribution(frame_ms),"physics_tick_cpu":distribution(physics_ms),"moving_ball_frames":moving_frames,"repeated_moving_ball_frames":repeats,"fraction_min":fractions.min(),"fraction_max":fractions.max(),"contacts":game.test_contacts,"quality":"existing graphics settings; no preset/resolution reduction","limits":"One local real-rendered 12s sample, 2s warmup, repeated receive-set-pipe. Not every gameplay case or other hardware."}
	FileAccess.open("res://docs/fluidity84-performance-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FLUIDITY84 BENCH PASS ",JSON.stringify(report));quit()

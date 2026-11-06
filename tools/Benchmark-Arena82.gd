extends SceneTree
var game
var label:="before"
var frame:=0
var last:=0
var samples: Array[float]=[]
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);root.position=Vector2i(19000,19000)
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.match_audio.enabled=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.hide();child.set_process(false)
	for p in game.players:p.set_process(false);p.render_at_draw=false
	game.camera_mode=0;game.set_camera();game.update_camera(1)
	await process_frame;await process_frame
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.frame_post_draw.connect(measure)
func measure():
	if samples.size()>=360:return
	var now:=Time.get_ticks_usec();frame+=1
	if frame>120:samples.append((now-last)/1000.0)
	last=now
	if samples.size()<360:return
	samples.sort();var sum:=0.0
	for value in samples:sum+=value
	var report={"samples":samples.size(),"mean_frame_ms":sum/samples.size(),"p95_frame_ms":samples[int(samples.size()*.95)],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"gpu":RenderingServer.get_video_adapter_name(),"crowd":game.arena_visuals.crowd_instance_count,"resolution":"1280x720","scope":"Rendered static court, crowd and animated benches; not full rally FPS"}
	FileAccess.open("res://docs/arena82-performance-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	root.get_texture().get_image().save_png("res://docs/arena82-"+label+".png")
	print("ARENA82 BENCH ",JSON.stringify(report));quit()

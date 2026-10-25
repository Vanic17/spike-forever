extends SceneTree
var service
func _initialize(): call_deferred("run")
func frames(count: int):
	for i in count: await process_frame
func fps_sample(cap: int) -> float:
	var values: Dictionary=service.data.duplicate(); values.fps=cap; values.vsync=0; service.apply(values,false)
	await frames(30)
	var start:=Time.get_ticks_usec()
	await frames(60)
	return 60000000.0/(Time.get_ticks_usec()-start)
func run():
	assert(DisplayServer.get_name()!="headless")
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1440,810)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	service=g.preferences; service.dry_run=false; service.discover_displays()
	await frames(3)
	var initial: Dictionary=service.data.duplicate(); var info: Dictionary=service.display_info(); assert(not info.is_empty())
	var current: Dictionary=service.original_mode.duplicate()
	var tested: Dictionary=service.helper(["--test",current.device,str(current.width),str(current.height),str(current.hz)])
	assert(tested.ok,"Windows must accept the enumerated current display mode")
	var invalid: Dictionary=service.helper(["--test",current.device,"1234","777","987"]); assert(not invalid.ok)
	var values: Dictionary=initial.duplicate(); values.merge({"mode":0,"width":1280,"height":720,"native_resolution":false,"fps":60,"vsync":0},true)
	assert(service.apply(values,true)); await frames(5); assert(root.mode==Window.MODE_WINDOWED and root.size==Vector2i(1280,720))
	values.mode=1; assert(service.apply(values,true)); await frames(5); assert(root.mode==Window.MODE_FULLSCREEN)
	values.mode=2; values.width=current.width; values.height=current.height; values.hz=current.hz
	var native: Vector2i=service.automatic_resolution(2)
	values.native_resolution=native==Vector2i(current.width,current.height)
	assert(service.apply(values,true)); await frames(5); assert(root.mode==Window.MODE_EXCLUSIVE_FULLSCREEN and DisplayServer.screen_get_size()==Vector2i(current.width,current.height))
	values.mode=0; values.native_resolution=false; values.width=1280; values.height=720; assert(service.apply(values,true)); await frames(10)
	var thirty: float=await fps_sample(30); var sixty: float=await fps_sample(60)
	var restored: Dictionary=service.helper(["--list"]); var displays: Array=JSON.parse_string(restored.text)
	var monitor_restored:=displays.any(func(d): return d.device==current.device and int(d.current.width)==current.width and int(d.current.height)==current.height and int(d.current.hz)==current.hz)
	assert(monitor_restored and not service.display_changed)
	service.apply(initial,false)
	FileAccess.open("res://docs/settings53-video.json",FileAccess.WRITE).store_string(JSON.stringify({"windows_mode_validation":true,"unsupported_mode_rejected":true,"windowed":"1280x720","borderless":true,"exclusive":current,"desktop_restored":monitor_restored,"fps_cap_30_observed":thirty,"fps_cap_60_observed":sixty,"renderer":RenderingServer.get_current_rendering_method(),"limits":"Only current desktop resolution/Hz applied in exclusive test; other combinations validated/enumerated by Windows without changing the user's desktop."},"  "))
	var ok: bool=absf(thirty-30)<4 and absf(sixty-60)<8
	print("VIDEO53 ","PASS" if ok else "FAIL"," real display modes + restored desktop / observed FPS ",thirty," / ",sixty)
	g.free(); quit(0 if ok else 1)

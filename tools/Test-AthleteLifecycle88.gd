extends SceneTree
var reports: Array=[]
func _initialize():call_deferred("run")
func frames(count: int):
	for i in count:await process_frame
	await RenderingServer.frame_post_draw
func run():
	root.mode=Window.MODE_WINDOWED;root.position=Vector2i(19000,19000);root.size=Vector2i(1280,720);Engine.max_fps=30
	assert("athlete88" in OS.get_environment("APPDATA").to_lower())
	var initial_actions:=InputMap.get_actions()
	for cycle in 3:
		var game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
		for p in game.players:p.set_process(false)
		for node in game.get_children():
			if node is CanvasLayer:node.hide()
		await frames(12)
		load("res://src/player_appearance.gd").apply(game.players[0],{"skin_tone":"chiara","hair_style":"corti","hair_color":"nero","beard":"piena"})
		await frames(4)
		for preset in [0,1,2,3,2]:
			var values: Dictionary=game.preferences.data.duplicate();values.merge(game.preferences.PRESETS[preset],true);game.preferences.apply(values,false)
			await frames(8)
			assert(game.players[0].body_parts.head.mesh!=null)
		reports.append({"cycle":cycle+1,"presets":[0,1,2,3,2],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"engine_video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		game.free();await frames(4)
		# The production root is normally created once per process. Restore this
		# test harness's global actions between independently created root scenes.
		for action in InputMap.get_actions():
			if not initial_actions.has(action):InputMap.erase_action(action)
		print("LIFECYCLE88 CYCLE PASS ",cycle+1)
	FileAccess.open("res://docs/athlete88-lifecycle.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"renderer":RenderingServer.get_current_rendering_method(),"cycles":reports,"kind":"real rendered 3D scene create, modify presets, free; separate editor startup tests"},"  "))
	print("LIFECYCLE88 PASS");quit()

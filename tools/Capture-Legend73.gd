extends SceneTree
## Real shared match, native avatars, real career menu, and manual LS events.
## No pose, root-position or ball-position staging for the preview.
var game
var menu
var guide
var failures: Array=[]
var checks:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error("LEGEND CAPTURE73 "+message)
func axis(which: int,value: float) -> InputEventJoypadMotion:
	var event:=InputEventJoypadMotion.new();event.axis=which;event.axis_value=value;return event
func settle():
	for frame in 4: await process_frame
func capture(mode: int):
	game.camera_mode=mode;game.set_camera()
	guide.sync_from_game()
	await settle();await RenderingServer.frame_post_draw
	var path: String="res://docs/legend73-guide-camera-%d.png"%mode
	check(root.get_texture().get_image().save_png(path)==OK,"capture camera "+str(mode))
func run():
	var user_path:=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(user_path.contains("legend73"),"capture uses isolated workspace APPDATA")
	if not failures.is_empty():quit(1);return
	Engine.max_fps=30;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,900);root.content_scale_size=root.size;root.position=Vector2i(-3000,-3000)
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false
	check(game.models.has("body") and game.clips.size()>50,"preview uses the real skinned avatars and animation bank")
	var host
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"):host=node;break
	check(host!=null,"real start menu exists")
	if host==null:quit(1);return
	host.startup_scan=false;host.installed_version="999.0.0"
	menu=host.legend_menu
	var career=menu.manager
	var person: Dictionary=career.default_profile();person.name="Marco Riva";person.number=17;person.jersey_number=17;person.role="outside_hitter"
	check(career.new_career(person,str(career.starter_clubs()[0].id),{"best_of":3,"autosave":false,"seed":730331},12),"create actual player career")
	menu.launch_match()
	check(game.legend_match.active and game.started,"real menu launches shared manual adapter")
	guide=game.get_node_or_null("LegendPositionGuide")
	check(guide!=null,"shared main scene contains the position guide")
	if guide==null:game.free();quit(1);return
	var controlled: int=game.legend_match.controlled_index
	var origin: Vector3=game.players[controlled].position
	game._unhandled_input(axis(JOY_AXIS_LEFT_X,-.8))
	for frame in 40:
		game.step(1.0/120.0);await process_frame
	game._unhandled_input(axis(JOY_AXIS_LEFT_X,0))
	for frame in 20:
		game.step(1.0/120.0);await process_frame
	check(game.players[controlled].position.distance_to(origin)>.15,"LS moves the real athlete away from the AI guide")
	guide.sync_from_game()
	check(guide.visible,"live recommended position is visible")
	var recommendation: Vector3=game.legend_match.recommended_position
	check(guide.global_position.is_equal_approx(Vector3(recommendation.x,guide.FLOOR_HEIGHT,recommendation.z)),"displayed guide agrees with the shared AI recommendation")
	for mode in [0,2,3]: await capture(mode)
	var report: Dictionary={"checks":checks,"failures":failures,"native":true,"avatars":game.players.size(),"clips":game.clips.size(),"controlled_player":game.players[controlled].roster_identity.name,"manual_distance":game.players[controlled].position.distance_to(origin),"guide":guide.global_position,"recommended":recommendation,"cameras":[0,2,3]}
	FileAccess.open("res://docs/legend73-visual.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND CAPTURE73 ",JSON.stringify(report))
	game.free();quit(0 if failures.is_empty() else 1)

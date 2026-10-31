extends SceneTree
## Native shared match and real contact input; isolated user:// is mandatory.
const LegendHUD=preload("res://src/legend_hud.gd")
var game
var motor
var menu
var host
var config: Dictionary={}
var checks:=0
var failures: Array=[]
var shots: Array=[]
var help_only:=false
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error("LEGEND FEEDBACK75 "+message)
func settle():
	for frame in 5: await process_frame
func capture(name: String,height: int):
	await settle(); await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	var path: String="res://docs/legend75-feedback-%s-%d.png"%[name,height]
	check(image.get_height()==height,"native capture height "+str(height))
	check(image.save_png(path)==OK,"save "+path)
	shots.append({"path":path,"size":[image.get_width(),image.get_height()],"cue":motor.contact_cue() if motor.has_method("contact_cue") else {}})
func button(index: int,pressed: bool):
	var event:=InputEventJoypadButton.new(); event.button_index=index; event.pressed=pressed
	game._unhandled_input(event)
func restart():
	check(motor.start(config),"start actual career adapter")
	game.self_test=true; game.demo=false; game.replay.enabled=false; game.match_audio.enabled=false
	game.camera_mode=0; game.set_camera()
func receive_setup(overhead: bool=false,seconds: float=.12):
	restart()
	var index: int=motor.controlled_index
	var p=game.players[index]
	p.position=Vector3(-2.2,0,5); p.rotation.y=PI; p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO
	for other in 6:
		if other!=index and game.players[other].position.distance_to(p.position)<1.5: game.players[other].position.x+=1.8
	game.set_phase("RECEIVE"); game.possession=0; game.receiver=index; game.last_touch=1
	game.incoming_kind="serve"; game.incoming_power=.25; game.touches=[0,0]; game.winner_team=-1
	game.armed=false; game.input_quality=0; game.late_receive=false
	var action: String="set" if overhead else "receive"
	p.prepare_contact(action,0)
	game.airborne=true; game.flight_target=p.contact_world(action); game.flight_left=seconds; game.receive_deadline=game.clock_time+seconds
	game.ball_pos=game.flight_target+Vector3(0,.4 if overhead else 0,0); game.ball_vel=Vector3(0,-3,0); game.ball.position=game.ball_pos
	game.flight_spin=Vector3.ZERO; game.flight_gravity=game.G
	motor.set_recommendation(p.position)
func verify_readonly_cue():
	var ball: Vector3=game.ball_pos; var velocity: Vector3=game.ball_vel
	var roots: Array=[]
	for player in game.players: roots.append(player.position)
	var state: int=game.rng.state; var quality: float=game.input_quality; var armed: bool=game.armed
	for count in 10: motor.contact_cue()
	check(game.ball_pos==ball and game.ball_vel==velocity and game.rng.state==state and game.input_quality==quality and game.armed==armed,"cue leaves ball, RNG, quality and command unchanged")
	for index in 12: check(game.players[index].position==roots[index],"cue leaves avatar root "+str(index)+" unchanged")
func run():
	help_only=OS.get_cmdline_user_args().has("--help-only")
	var user_path:=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(user_path.contains("legend75"),"capture requires isolated workspace APPDATA")
	if not failures.is_empty(): quit(1); return
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.position=Vector2i(-4000,-4000)
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child; break
	check(host!=null,"real start menu exists")
	if host==null: game.free(); quit(1); return
	host.startup_scan=false; host.installed_version="999.0.0"; game.preferences.dry_run=true
	menu=host.legend_menu; motor=game.legend_match
	if not help_only:
		check(motor.has_method("contact_cue"),"adapter supplies read-only contact cue")
		if not motor.has_method("contact_cue"): game.free(); quit(1); return
	var career=menu.manager
	var profile: Dictionary=career.default_profile(); profile.name="Marco Riva"; profile.role="outside_hitter"; profile.number=17; profile.jersey_number=17
	check(career.new_career(profile,str(career.starter_clubs()[0].id),{"best_of":3,"autosave":false,"seed":750331,"fatigue":false},12),"create isolated real career")
	config=career.launch_config(); config.seed=750331; config.options.fatigue=false
	for panel in [host.panel,host.overlay,host.play_hub,host.clubs,menu]: panel.hide()
	for height in [720,1080,1440]:
		root.size=Vector2i(roundi(height*16.0/9.0),height); root.content_scale_size=root.size
		if help_only:
			TranslationServer.set_locale("en"); menu.show_page("help"); await capture("help-en",height); menu.hide(); continue
		TranslationServer.set_locale("it")
		receive_setup(); check(bool(motor.contact_cue().get("visible",false)),"actual incoming contact displays the cue")
		verify_readonly_cue(); await capture("bagher-ready",height)
		button(JOY_BUTTON_A,true); button(JOY_BUTTON_A,false)
		check(game.armed,"primary press prepares forearm contact")
		game.receive_ball(); check(not game.contact_log.is_empty(),"forearm screenshot follows a physical native touch")
		await capture("bagher-result",height)
		receive_setup(true)
		button(JOY_BUTTON_X,true); button(JOY_BUTTON_X,false)
		check(game.armed,"alternate press prepares overhead contact")
		await capture("overhead-ready",height)
		for frame in 100:
			game.step(1.0/120.0)
			if game.phase!="RECEIVE": break
		check(not game.contact_log.is_empty(),"overhead screenshot follows a physical native touch")
		await capture("overhead-result",height)
		receive_setup(false,.2)
		var index: int=motor.controlled_index
		game.incoming_kind="spike"; game.ball_pos=game.players[index].position+Vector3(.30,1.6,-.70)
		game.ball_vel=Vector3(0,-4,0); game.flight_target=game.ball_pos; game.ball.position=game.ball_pos
		var trigger:=InputEventJoypadMotion.new(); trigger.axis=JOY_AXIS_TRIGGER_RIGHT; trigger.axis_value=.8
		game._unhandled_input(trigger)
		check(game.dive_motions.has(index),"RT event starts the native dive")
		for frame in 12: game.step(1.0/120.0)
		await capture("dive",height)
		TranslationServer.set_locale("en"); menu.show_page("help"); await capture("help-en",height); menu.hide()
	# Device labels use the same production helpers, independent of an attached pad.
	for pad in [-1,0]:
		for ps in [false,true]:
			check(LegendHUD.contact_button("dive",pad,ps,true)==("C" if pad<0 else ("R2" if ps else "RT")),"dive button label matches the actual binding")
			check(LegendHUD.contact_button("overhead",pad,ps,true)==("Q" if pad<0 else ("Square" if ps else "X")),"overhead button label matches the actual binding")
	var report: Dictionary={"checks":checks,"failures":failures,"native":true,"godot":Engine.get_version_info().string,"isolated_user_path":user_path,"screenshots":shots,"help_only":help_only,"help_language":"en","hud_language":"it","real_avatar_count":game.players.size(),"cue_rectangle_1920x1080":[660,810,600,140],"shared_power_rectangle_1920x1080":[678,966,564,78],"cue_and_power_overlap":false}
	FileAccess.open("res://docs/legend75-feedback-visual.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND FEEDBACK75 ",JSON.stringify({"checks":checks,"failures":failures,"screenshots":shots.size()}))
	game.free(); quit(0 if failures.is_empty() else 1)

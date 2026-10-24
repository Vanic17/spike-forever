extends SceneTree
var game
var frame:=0
var title: Label
var before:=0
var set_seen:=false
var attack_seen:=false
var scenario:=0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.demo=false; game.self_test=true
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.free()
	game.hud.hide(); game.marker.hide()
	for p in game.players: p.render_at_draw=false; p.set_process(false)
	var layer=CanvasLayer.new(); root.add_child(layer); title=Label.new(); layer.add_child(title)
	title.position=Vector2(24,20); title.add_theme_font_size_override("font_size",23); title.add_theme_color_override("font_outline_color",Color.BLACK); title.add_theme_constant_override("outline_size",8)
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for side in 2:
		var squad: Array=db.lineup(db.teams[side])
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(db.teams[side].id,"home"),kits.selection(db.teams[side].id,"home",true))
	begin(0)
func begin(which: int) -> void:
	scenario=which; set_seen=false; attack_seen=false
	game.rotations=[0,0]; game.server=1; game.rng.seed=40001; game.shot_serial=0; game.reset_rally(); game.possession=0; game.receiver=4
	game.set_dir=0 if which==1 else 1
	game.players[4].position=game.Tactics.world(0,0,5.5); game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[4].contact_world("receive"); game.phase="RECEIVE"; game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=.3
	before=game.test_contacts; game.receive_ball(); game.pass_quality=.75; game.input_quality=.75; game.out_of_system=1
	game.press_action("alternate" if which==0 else "action")
	title.text=["v48 / PRIMO TEMPO - QUADRATO / X - RICEZIONE 75%","v48 / FINTA DI PRIMO TEMPO - ALZATA IN BANDA - RICEZIONE 75%","v48 / CENTRALE - ALZATA NORMALE - RICEZIONE 75%"][which]
	game.camera.position=Vector3(3.4,4.3,8.2); game.camera.look_at(Vector3(.2,1.6,1.9)); game.camera.fov=45
func _process(_dt: float) -> bool:
	if game==null: return false
	frame+=1
	if frame in [131,261]: begin(1 if frame==131 else 2)
	for substep in 4:
		if game.phase=="ATTACK": game.armed=true; game.charge=.75; game.input_quality=1
		game.step(1.0/120)
	for p in game.players: p.apply_pose(1.0/30)
	if not set_seen and game.test_contacts>=before+2:
		set_seen=true
		var middle: int=game.Tactics.attacker(0,0,1,game.setter); var p=game.players[middle]
		var feet: float=minf(p.current_joint("LeftFoot").y,p.current_joint("RightFoot").y)
		print("PREVIEW48 SET scenario=",scenario," feet=",feet," frame=",frame," source=",p.animation_time)
		var key:=scenario
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/first-tempo48-set-"+str(key)+".png"),CONNECT_ONE_SHOT)
	if not attack_seen and game.test_contacts>=before+3:
		attack_seen=true; print("PREVIEW48 ATTACK scenario=",scenario," frame=",frame)
	if frame>=390: print("PREVIEW48 PASS"); quit()
	return false

extends SceneTree
## Actual production receive/set/attack, not a pose-only animation gallery.
## Record PNG movie frames at 30 fps for 450 frames, then encode with ffmpeg.
var game
var frame := 0
var title: Label
var before_contacts := 0
var seen_contacts := 0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false)
	game.started=true; game.demo=false; game.self_test=true
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.free()
	game.camera.position=Vector3(0,11.5,16); game.camera.look_at(Vector3(0,0,2)); game.camera.fov=54
	game.hud.hide(); game.marker.hide()
	for player in game.players: player.render_at_draw=false; player.set_process(false)
	var layer=CanvasLayer.new(); root.add_child(layer)
	title=Label.new(); title.position=Vector2(24,20); title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_outline_color",Color.BLACK); title.add_theme_constant_override("outline_size",8); layer.add_child(title)
	begin(0)
func begin(direction: int) -> void:
	game.rotations=[0,0]; game.server=1; game.rng.seed=40001; game.shot_serial=0
	game.reset_rally(); game.possession=0; game.receiver=4; game.set_dir=direction
	game.players[4].position=game.Tactics.world(0,0,5.5)
	game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[4].contact_world("receive"); game.phase="RECEIVE"
	game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=0.3
	before_contacts=game.test_contacts
	game.receive_ball(); game.press_action("action")
	seen_contacts=game.test_contacts
	title.text="v42 / " + ("Banda: apertura e rincorsa in zona 4" if direction==0 else ("Attacco dietro: apertura e rincorsa in zona 2" if direction==2 else "Centrale: preparazione davanti al palleggiatore"))
func _process(_elapsed: float) -> bool:
	if game==null: return false
	frame+=1
	if frame in [151,301]: begin(2 if frame==151 else 1)
	for substep in 4:
		if game.phase=="ATTACK": game.armed=true; game.charge=0.75; game.input_quality=1
		game.step(1.0/120)
	for player in game.players: player.apply_pose(1.0/30)
	if game.test_contacts>seen_contacts:
		print("APPROACH42 PREVIEW contact frame=",frame," phase=",game.phase," hitter=",game.hitter)
		seen_contacts=game.test_contacts
	if frame in [15,40,63,166,191,214]:
		var capture_frame:=frame
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/approach42-"+str(capture_frame)+".png"),CONNECT_ONE_SHOT)
	if frame>=450: quit()
	return false

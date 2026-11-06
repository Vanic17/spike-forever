extends SceneTree
var game
var frame:=0
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1600,900);root.content_scale_size=root.size;root.position=Vector2i(19000,19000);Engine.max_fps=30
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.match_audio.enabled=false
	for child in game.get_children():
		if child is CanvasLayer:child.hide()
	game.set_home_club("acqua-santanna-cuneo",0);game.arena_visuals.sponsors.set_process(false)
	game.camera.position=Vector3(18,9,-4);game.camera.look_at(Vector3(0,0,0));game.camera.fov=55
	await process_frame;await process_frame
	game.arena_visuals.sponsors.celebrate("MONSTER BLOCK",0,game)
	DirAccess.make_dir_recursive_absolute("res://.runtime/led82-frames")
func _process(_dt):
	if game==null:return false
	frame+=1
	game.arena_visuals.sponsors._process(1.0/30)
	if frame==12:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/arena82-home-led-wide.png"),CONNECT_ONE_SHOT)
	if frame==15:game.camera.position=Vector3(0,1.5,-9.5);game.camera.look_at(Vector3(0,.60,-14.5));game.camera.fov=75
	if frame>=20 and frame<110:
		RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_jpg("res://.runtime/led82-frames/%04d.jpg"%(frame-20),.88),CONNECT_ONE_SHOT)
	if frame==30:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/arena82-home-monster.png"),CONNECT_ONE_SHOT)
	if frame==112:game.arena_visuals.sponsors.celebrate("ACE",0,game)
	if frame==120:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/arena82-home-ace.png"),CONNECT_ONE_SHOT)
	if frame==125:game.camera.position=Vector3(-4.8,1.9,3.0);game.camera.look_at(Vector3(-8.1,1.1,0));game.camera.fov=57
	if frame==140:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/arena82-officials.png"),CONNECT_ONE_SHOT)
	if frame>142:print("ARENA82 CAPTURE PASS");quit()
	return false

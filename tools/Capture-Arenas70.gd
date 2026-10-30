extends SceneTree
var game
var clubs: Array=[]
var frame:=0
var index:=0
func _initialize():call_deferred("setup")
func setup():
	Engine.max_fps=30;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.started=true
	for n in game.get_children():
		if n is CanvasLayer:n.hide()
	game.marker.hide();game.ball.hide()
	clubs=preload("res://src/arena_profiles.gd").data().clubs.keys()
	game.camera.position=Vector3(22,17,12);game.camera.look_at(Vector3(0,0,0));game.camera.fov=53
	game.set_home_club(clubs[0])
func _process(_dt):
	if game==null:return false
	frame+=1
	if frame%12==8:
		var path="res://docs/arena70-"+str(clubs[index])+".png"
		RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png(path),CONNECT_ONE_SHOT)
	if frame%12==10:
		index+=1
		if index==clubs.size():print("ARENA70 CAPTURE PASS");quit();return false
		game.set_home_club(clubs[index])
	return false

extends SceneTree
var game
func _initialize():call_deferred("run")
func frame(count: int):
	for i in count:await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String):
	await frame(5);root.get_texture().get_image().save_png("res://docs/stature90-"+name+".png")
func run():
	assert("graphics90" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1600,900)
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false);p.render_at_draw=false
	await frame(10)
	for child in game.get_children():
		if child is CanvasLayer:child.hide()
	var db=load("res://src/league.gd").new();var kits=load("res://src/club_kits.gd")
	for side in 2:
		var team: Dictionary=db.teams[side];var squad: Array=db.lineup(team)
		for i in 6:
			var p=game.players[side*6+i];p.set_roster_identity(squad[i],squad[6],kits.selection(team.id,"home"),kits.selection(team.id,"home",true))
	game.started=true;game.phase="SERVE";game.camera_mode=0;game.set_camera()
	await shot("default-camera")
	for i in game.players.size():
		var p=game.players[i];p.set_libero(false);p.position=Vector3((i%6-2.5)*1.12,0,3+i/6*2.4);p.rotation.y=0
		p.play("idle",1,true);p.animation_time=.35;p.apply_pose(0)
	game.camera.position=Vector3(7,3.8,11);game.camera.look_at(Vector3(0,1,4));game.camera.fov=42
	await shot("kit-lineup")
	game.camera.position=Vector3(-3.5,1.2,7.8);game.camera.look_at(Vector3(-1, .6,3));game.camera.fov=38
	await shot("legwear")
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):menu=child
	menu.show();menu.clubs.editor();await shot("editor")
	print("STATURE90 CAPTURE PASS");quit()

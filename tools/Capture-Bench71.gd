extends SceneTree
var game
var frame:=0
var ready_capture:=false
func _initialize():call_deferred("setup")
func setup():
	Engine.max_fps=30;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	await process_frame
	for n in game.get_children():
		if n is CanvasLayer:n.hide()
	game.hud.hide();game.marker.hide();game.ball.hide()
	var db=load("res://src/league.gd").new();var kits=load("res://src/club_kits.gd")
	var squads=[]
	for team in 2:
		var roster=db.lineup(db.teams[team]);squads.append(roster)
		for i in 6:game.players[team*6+i].set_roster_identity(roster[i],roster[6],kits.selection(db.teams[team].id,"home"),kits.selection(db.teams[team].id,"home",true))
	game.match_management.configure_rosters([db.teams[0],db.teams[1]],squads)
	game.set_home_club(db.teams[0].id);game.started=true;game.phase="SERVE";game.reset_rally()
	var bench=game.arena_visuals.get_node("TeamBenches");bench.sync_identity()
	bench.set_process(false);game.paused=false
	print("BENCH71 PREVIEW rosters=",game.match_management.rosters.map(func(r):return r.size())," bench=",[game.match_management.bench(0).size(),game.match_management.bench(1).size()]," visible=",bench.actors.filter(func(e):return e.actor.visible).size())
	game.camera.position=Vector3(-2.5,4.0,11.5);game.camera.look_at(Vector3(-7.2,1,6.8));game.camera.fov=52
	ready_capture=true
func _process(_dt):
	if not ready_capture:return false
	frame+=1
	if frame in [20,180]:game.phase="POINT";game.server=0;game.scores=[1 if frame==20 else 2,0]
	game.arena_visuals.get_node("TeamBenches")._process(1.0/30)
	if frame in [65,110,225,270]:
		var path="res://docs/bench71-reactions-"+str(frame)+".png"
		RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png(path),CONNECT_ONE_SHOT)
	if frame==290:
		game.camera.position=Vector3(-3.9,2.5,3.2);game.camera.look_at(Vector3(-8.0,.85,0));game.camera.fov=48
	if frame==320:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/bench71-table.png"),CONNECT_ONE_SHOT)
	if frame==330:
		game.camera.position=Vector3(0,12.5,19.8);game.camera.look_at(Vector3(0,.8,0));game.camera.fov=48
	if frame==350:RenderingServer.frame_post_draw.connect(func():root.get_texture().get_image().save_png("res://docs/bench71-court.png"),CONNECT_ONE_SHOT)
	if frame>353:print("BENCH71 CAPTURE PASS");quit()
	return false

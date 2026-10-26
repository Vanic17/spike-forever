extends SceneTree
var game
var frame:=0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,900); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.hide()
	game.hud.hide(); game.marker.hide()
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for side in 2:
		var team: Dictionary=db.teams[side]; var squad: Array=db.lineup(team)
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(team.id,"home"),kits.selection(team.id,"home",true))
	game.reset_rally()
	game.camera.position=Vector3(-3.6,4.8,11.5); game.camera.look_at(Vector3(-7.1,1,5.9)); game.camera.fov=48
func _process(_dt: float) -> bool:
	if game==null: return false
	frame+=1
	if frame==25: game.phase="POINT"; game.server=0; game.scores=[1,0]
	if frame in [50,90]:
		var path: String="res://docs/arena61-bench.png" if frame==50 else "res://docs/arena61-referee.png"
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png(path),CONNECT_ONE_SHOT)
	if frame==55:
		game.camera.position=Vector3(-2.7,4.5,4.2); game.camera.look_at(Vector3(-6,2.7,0)); game.camera.fov=44
	if frame>=92: print("ARENA61 CAPTURE PASS"); quit()
	return false

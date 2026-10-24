extends SceneTree
var game
var frame:=0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,900); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.free()
	game.hud.hide(); game.marker.hide()
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for side in 2:
		var team: Dictionary=db.teams[side]; var squad: Array=db.lineup(team)
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(team.id,"home"),kits.selection(team.id,"home",true))
	game.reset_rally()
	game.camera.position=Vector3(-9.8,4.4,4.4); game.camera.look_at(Vector3(-5.8,2.5,0)); game.camera.fov=47
func _process(_dt: float) -> bool:
	if game==null: return false
	frame+=1
	if frame==50: game.phase="POINT"; game.winner_team=0; game.scores=[1,0]
	if frame in [38,95,120]:
		var key: String={38:"referee-serve",95:"referee-point",120:"court"}[frame]
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/equipment46-"+key+".png"),CONNECT_ONE_SHOT)
	if frame==100:
		game.camera.position=Vector3(0,10.5,17.8); game.camera.look_at(Vector3(0,1.1,0)); game.camera.fov=53
	if frame>=122: print("EQUIPMENT46 CAPTURE PASS"); quit()
	return false

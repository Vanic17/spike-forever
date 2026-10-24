extends SceneTree
var game
var age := 0
var club := "cisterna-volley"
var db
var pending: Array=[]
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--club="): club=arg.trim_prefix("--club=")
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(2400,1000); root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): node.free()
	game.hud.hide(); game.marker.hide()
	game.arena_visuals.hide(); game.ball.hide(); game.shadow.hide()
	db=load("res://src/league.gd").new()
	if "--all" in OS.get_cmdline_user_args():
		for team in db.teams: pending.append(team.id)
		club=pending.pop_front()
	show_club()
	game.camera.position=Vector3(0,1.55,5.9); game.camera.look_at(Vector3(0,1.05,0)); game.camera.fov=26
func show_club() -> void:
	var teams: Array=db.teams.filter(func(t): return t.id==club)
	var squad: Array=db.lineup(teams[0])
	var kits=load("res://src/club_kits.gd")
	for i in game.players.size():
		var p=game.players[i]
		p.set_process(false); p.render_at_draw=false; p.indicator.hide()
		if i>=6: p.hide(); continue
		var variant: String=["home","away","libero"][i/2]
		var kit: Dictionary=kits.selection(club,"home",variant=="libero") if variant=="libero" else kits.selection(club,variant)
		p.set_roster_identity(squad[0],squad[6],kit,kits.selection(club,"home",true))
		if variant=="libero": p.set_libero(true)
		p.position=Vector3((i-2.5)*1.10,0,0)
		p.clips.relaxed=p.source_clips.relaxed
		p.clip_name="relaxed"; p.animation_time=0.4; p.blend_left=0; p.relaxed_stance=true
		p.apply_pose(0)
		p.rotation.y=0 if i%2==0 else PI
		p.visual_root.rotation.y=0
		var label=Label3D.new(); label.text=variant.to_upper()+" / "+("FRONT" if i%2==0 else "BACK")
		label.position=Vector3(p.position.x,2.12,0); label.font_size=28; label.pixel_size=.002; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		game.add_child(label)
func _process(_dt: float) -> bool:
	if game==null: return false
	age+=1
	if age==20:
		RenderingServer.frame_post_draw.connect(func():
			root.get_texture().get_image().save_png("res://docs/kits45-"+club+".png")
			print("KIT PREVIEW SAVED ",club)
			if pending.is_empty(): quit()
			else:
				club=pending.pop_front(); age=0; show_club()
		,CONNECT_ONE_SHOT)
	return false

extends SceneTree
var g
var frame:=0
var menu
func _initialize(): call_deferred("setup")
func setup():
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,810); root.content_scale_size=root.size
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): menu=n
	menu.installed_version="999.0.0"
func _process(_dt: float):
	frame+=1
	if frame==4: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/menu51-home.png"),CONNECT_ONE_SHOT)
	if frame==6: menu.online_menu.open()
	if frame==10: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/menu51-online.png"),CONNECT_ONE_SHOT)
	if frame==12:
		menu.online_menu.hide(); menu.clubs.editor(); menu.clubs.enter_details()
	if frame==16: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/menu51-preferences.png"),CONNECT_ONE_SHOT)
	if frame==18:
		menu.clubs.hide(); g.started=true; g.hud.hide()
		var db=load("res://src/league.gd").new(); var club: Dictionary=db.teams[0]; var squad: Array=db.lineup(club); var kits=load("res://src/club_kits.gd")
		for i in 12:
			var p=g.players[i]; p.visible=i in [0,6]
			if not p.visible: continue
			var identity: Dictionary=squad[0].duplicate(true); identity.dominant_hand="left" if i==6 else "right"
			p.set_roster_identity(identity,identity,kits.selection(club.id,"home"),kits.selection(club.id,"home"))
			p.position=Vector3(-1.5 if i==0 else 1.5,0,0); p.rotation.y=0; p.select_variant("attack","attack_pin_left"); p.play("attack",1,false); p.animation_time=p.clips.attack.contact_time; p.blend_left=0; p.apply_pose(0)
		g.camera.position=Vector3(0,3.1,10); g.camera.look_at(Vector3(0,2.0,0)); g.camera.fov=40
	if frame==22: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/handed51-preview.png"),CONNECT_ONE_SHOT)
	if frame==24: print("ONLINE51 CAPTURE PASS"); quit()
	return false

extends SceneTree
var g
var frame:=0
var views: Array=[]
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	Engine.max_fps=30; root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,900); root.content_scale_size=root.size
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): n.free()
	g.hud.hide(); g.marker.hide()
	var styles: Array=load("res://src/player_appearance.gd").STYLES.keys()+["pelato","corti"]
	var colors: Array=["biondo","marrone","nero","marrone","nero","nero","nero","marrone","marrone","nero","nero","marrone"]
	var db=load("res://src/league.gd").new(); var squad: Array=db.lineup(db.teams[0]); var kits=load("res://src/club_kits.gd")
	for i in 12:
		var p=g.players[i]; var person: Dictionary=squad[0].duplicate(true)
		person.appearance={"hair_style":styles[i],"hair_color":colors[i],"beard":"piena" if i==10 else ("corta" if i==11 else "nessuna"),"skin_tone":"ebano" if i in [4,5,9] else "chiara"}
		p.set_roster_identity(person,person,kits.selection("allianz-milano","home"),kits.selection("allianz-milano","home")); p.position=Vector3((i%4)*1.65-2.5,int(i/4)*2.45,0); p.rotation.y=0
		p.play("relaxed",1,true); p.apply_pose(0)
		var tag=Label3D.new(); tag.text=styles[i]+(" + BARBA" if i>=10 else ""); tag.position.y=2.25; tag.font_size=35; tag.pixel_size=.003; tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED; p.add_child(tag)
	g.camera.position=Vector3(0,3.8,14); g.camera.look_at(Vector3(0,3.8,0)); g.camera.fov=32
func _process(_dt: float) -> bool:
	if g==null: return false
	frame+=1
	if frame==35: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/appearance47-presets.png"),CONNECT_ONE_SHOT)
	if frame==38: g.free(); print("APPEARANCE47 PREVIEW PASS"); quit()
	return false

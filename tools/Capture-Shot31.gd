extends SceneTree
var game
var frames:=0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.hud.visible=false; game.marker.visible=false
	game.camera.position=Vector3(8,5,9); game.camera.look_at(Vector3(0,1.8,0)); game.camera.fov=48
	var p=game.players[0]; p.position=Vector3(-2,0,1); p.rotation.y=PI
	p.select_variant("attack","attack_tip_2"); p.prepare_contact("attack",0); game.ball.position=p.contact_world("attack")
	game.dynamic_net.impact(Vector3(0,2,0),Vector3(2,-2,-24))
func _process(_dt: float) -> bool:
	if not is_instance_valid(game): return false
	frames+=1
	if frames==8: RenderingServer.frame_post_draw.connect(save_frame,CONNECT_ONE_SHOT)
	if frames>12: quit()
	return false
func save_frame() -> void:
	root.get_texture().get_image().save_png("res://docs/shot31-preview.png")

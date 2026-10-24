extends "res://tools/Preview-Approach42.gd"
func setup() -> void:
	super.setup()
	game.camera.position=Vector3(0,7.2,12.3); game.camera.look_at(Vector3(0,1.0,2)); game.camera.fov=51
	begin(1); title.text="v46 / CENTRALE: PREPARAZIONE DEL PRIMO TEMPO"
func _process(elapsed: float) -> bool:
	if game==null: return false
	super._process(elapsed)
	if frame==151: title.text="v46 / RINCORSA E ATTACCO IN ZONA 2"
	if frame in [12,28,45,82,175,200]:
		var number:=frame
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/approach46-"+str(number)+".png"),CONNECT_ONE_SHOT)
	if frame>=225: print("APPROACH46 PREVIEW PASS"); quit()
	return false

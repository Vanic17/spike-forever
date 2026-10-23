extends "res://tools/Capture-TV37.gd"
func save_frame() -> void:
	root.get_texture().get_image().save_png("res://docs/arena39-tv-preview.png")
	print("ARENA39 TV preview; floor pigments adjusted, existing lights and sponsor assets retained")

func _process(_dt: float) -> bool:
	if g==null: return false
	frames+=1
	if frames==5: RenderingServer.frame_post_draw.connect(save_frame,CONNECT_ONE_SHOT)
	if frames==7:
		g.hud.visible=true
		g.phase="POINT"; g.point_reason="PALLA A TERRA"; g.feedback=g.team_names[0]; g.feedback_left=2.0
	if frames==12: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/arena39-point-preview.png"),CONNECT_ONE_SHOT)
	if frames>15: quit()
	return false

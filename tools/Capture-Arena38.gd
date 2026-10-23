extends "res://tools/Capture-TV37.gd"
func setup() -> void:
	super.setup()
	for node in g.get_children():
		if node.has_method("crowd_react"): node.crowd_react()
func save_frame() -> void:
	root.get_texture().get_image().save_png("res://docs/arena38-tv-preview.png")
	print("ARENA38 TV render draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))

func _process(_dt: float) -> bool:
	if g==null: return false
	frames+=1
	if frames==5: RenderingServer.frame_post_draw.connect(save_frame,CONNECT_ONE_SHOT)
	if frames==7:
		g.camera_mode=0; g.set_camera()
		for node in g.get_children():
			if node.has_method("crowd_react"): node.sponsors._process(16.1)
	if frames==12: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/arena38-endline-preview.png"),CONNECT_ONE_SHOT)
	if frames>15: quit()
	return false

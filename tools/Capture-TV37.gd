extends "res://tools/Capture-Coverage36.gd"
func setup() -> void:
	super.setup()
	g.camera_mode=2; g.set_camera()
func save_frame() -> void: root.get_texture().get_image().save_png("res://docs/tv37-preview.png")

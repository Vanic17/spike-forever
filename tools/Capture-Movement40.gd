extends "res://tools/Capture-Coverage36.gd"
func setup() -> void:
	super.setup()
	g.manual_wall.right_joined=false; g.manual_wall.left_joined=false
	for frame in 120:
		g.clock_time+=1.0/60; g.phase_time+=1.0/60; g.move_players(1.0/60)
		for p in g.players: p.tick(1.0/60,false,true)
	g.hud.show()
func save_frame() -> void: root.get_texture().get_image().save_png("res://docs/wall40-preview.png")
func _process(_dt: float) -> bool:
	if g==null: return false
	frames+=1
	if frames==5: RenderingServer.frame_post_draw.connect(save_frame,CONNECT_ONE_SHOT)
	if frames==7:
		g.award(0,"PALLA A TERRA")
		for frame in 180:
			g.clock_time+=1.0/60; g.move_players(1.0/60)
			for p in g.players: p.tick(1.0/60,false,true)
	if frames==12: RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/regroup40-preview.png"),CONNECT_ONE_SHOT)
	if frames>15: quit()
	return false

extends SceneTree
var g
var frames:=0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.demo=false; g.self_test=true; g.hud.visible=false; g.marker.visible=false
	g.server=1; g.rotations=[0,0]; g.reset_rally(); g.possession=1; g.phase="CPU_ATTACK"; g.hitter=6; g.hitter_action="attack"; g.flight_target=Vector3(3.4,3.3,-1); g.flight_left=0.5
	g.manual_wall.right_joined=true
	for frame in 180:
		g.clock_time+=1.0/60; g.phase_time+=1.0/60; g.move_players(1.0/60)
		for p in g.players: p.tick(1.0/60,false,false)
	for p in g.players: p.render_at_draw=false; p.apply_pose(0)
	g.ball.position=g.flight_target
	g.camera.position=Vector3(0,11.5,16); g.camera.look_at(Vector3(0,0,1)); g.camera.fov=54
func _process(_dt: float) -> bool:
	if g==null: return false
	frames+=1
	if frames==5: RenderingServer.frame_post_draw.connect(save_frame,CONNECT_ONE_SHOT)
	if frames>8: quit()
	return false
func save_frame() -> void: root.get_texture().get_image().save_png("res://docs/coverage36-preview.png")

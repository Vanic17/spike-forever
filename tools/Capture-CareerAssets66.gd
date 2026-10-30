extends SceneTree
var arena
func _initialize(): call_deferred("run")
func shot(id: String,eye: Vector3,focus: Vector3,fov: float):
	arena.camera.position=eye; arena.camera.fov=fov; arena.camera.look_at(focus)
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/ui/career66/"+id+".png")
func run():
	root.size=Vector2i(1600,900); root.content_scale_size=root.size; root.mode=Window.MODE_WINDOWED
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	for child in game.get_children():
		if child is CanvasLayer: child.hide()
	arena=game.arena_visuals
	DirAccess.make_dir_recursive_absolute("res://assets/ui/career66")
	for actor in arena.find_children("*","Node3D",true,false):
		if actor.get_script()==load("res://src/avatar.gd"): actor.hide()
	arena.ball.hide(); arena.marker.hide(); arena.shadow.hide()
	await shot("arena",Vector3(14,8,15),Vector3(0,1,0),53)
	await shot("net",Vector3(6.3,3.2,4),Vector3(0,2.1,0),45)
	await shot("stands",Vector3(0,3.8,3),Vector3(-6,5.5,-18),57)
	await shot("court",Vector3(4,3,6),Vector3(0,0,-1),48)
	arena.ball.show(); arena.ball.position=Vector3(0,.15,3)
	await shot("ball",Vector3(.9,.7,4.2),arena.ball.position,43)
	FileAccess.open("res://assets/ui/career66/manifest.json",FileAccess.WRITE).store_string(JSON.stringify({"source":"Internal Godot arena renders from Spike Forever 0.66","license":"Project assets; existing third-party terms in licenses/","credit":"Spike Forever","remote_required":false,"fallback":"native gradient","images":["arena","net","stands","court","ball"]},"  "))
	print("CAREER ASSETS66 PASS five neutral native arena renders / local provenance manifest"); quit()

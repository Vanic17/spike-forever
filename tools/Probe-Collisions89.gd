extends SceneTree
func _initialize():call_deferred("run")
func run():
	var label:="after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	var game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false)
	for i in 4:await process_frame
	game.arena_contacts.build()
	var shapes: Array=game.arena_contacts.shapes.map(func(s):return [str(s.bounds),s.kind,s.bounce])
	FileAccess.open("res://docs/graphics89-collisions-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(shapes,"  "))
	print("COLLISIONS89 PASS ",label," ",shapes.size());game.free();quit()

extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	print("PROBE86 BEFORE SCENE")
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false)
	print("PROBE86 BEFORE DEFERRED")
	for i in 5:await process_frame
	print("PROBE86 READY")
	for preset in 4:
		print("PROBE86 PRESET ",preset)
		var values: Dictionary=game.preferences.data.duplicate();values.merge(game.preferences.PRESETS[preset],true);game.preferences.apply(values,false)
		await process_frame
	print("PROBE86 BEFORE FREE");game.free();print("PROBE86 AFTER FREE");quit()

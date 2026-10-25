extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	game.test_manual_reception()
	print("MANUAL RECEPTION56 PASS: original input windows and source late saves")
	game.free(); quit()

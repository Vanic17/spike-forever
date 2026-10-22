extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	game.server=0
	game.reset_rally()
	game.camera_mode=2
	game.set_camera()
	var before: Vector3=game.ball_pos
	var controls=[["up",0],["right",1],["down",2],["left",3]]
	for binding in controls:
		Input.action_press(binding[0])
		game.read_controls(0)
		Input.action_release(binding[0])
		assert(game.set_dir==binding[1],"TV screen directions must select the projected attack lanes")
	assert(game.ball_pos==before)
	var left: Vector2=game.camera.unproject_position(Vector3(-3.4,0,1))
	var right: Vector2=game.camera.unproject_position(Vector3(3.4,0,1))
	assert(left.y<right.y,"Z4 must appear above Z2 in the actual TV projection")
	game.possession=1
	game.set_phase("CPU_SET")
	var wall: float=game.block_helper_x
	Input.action_press("up")
	game.read_controls(0.1)
	Input.action_release("up")
	assert(game.block_helper_x<wall,"TV up must move the wall toward its visible upper antenna")
	game.server=0
	game.reset_rally()
	Input.action_press("right")
	game.read_controls(0)
	Input.action_release("right")
	assert(game.aim.y<0 and absf(game.aim.x)<0.01,"TV screen right must aim service deeper into the opponent court")
	var tv_origin: Vector3=game.camera.position
	game.update_camera(0.1)
	assert(game.camera.position.distance_to(tv_origin)<0.001,"Serving must retain the side camera")
	for mode in 3:
		game.camera_mode=mode
		var event:=InputEventJoypadButton.new()
		event.button_index=JOY_BUTTON_Y
		event.pressed=true
		game._unhandled_input(event)
		assert(game.camera_mode==(mode+1)%3)
	print("TV CAMERA PASS: real projection / four set directions / service aim / wall movement / controller camera cycle / no ball mutation")
	game.free()
	quit()

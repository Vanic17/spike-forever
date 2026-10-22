extends SceneTree
func _initialize() -> void: call_deferred("run")
func button(game, index: int, down: bool=true) -> void:
	var event:=InputEventJoypadButton.new()
	event.button_index=index
	event.pressed=down
	game._unhandled_input(event)
func axis(index: int, value: float) -> void:
	var event:=InputEventJoypadMotion.new()
	event.axis=index
	event.axis_value=value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): child.panel.hide()
	for binding in [["action",JOY_BUTTON_A],["alternate",JOY_BUTTON_X],["dump",JOY_BUTTON_B],["start",JOY_BUTTON_START]]:
		var event:=InputEventJoypadButton.new()
		event.button_index=binding[1]
		event.pressed=true
		assert(event.is_action_pressed(binding[0]))
	game.server=0
	game.reset_rally()
	button(game,JOY_BUTTON_A)
	assert(game.charging and game.serve_type==1)
	game.clock_time+=0.75
	button(game,JOY_BUTTON_A,false)
	assert(game.toss_active and not game.charging)
	game.reset_rally()
	button(game,JOY_BUTTON_X)
	assert(game.charging and game.serve_type==0)
	button(game,JOY_BUTTON_X,false)
	game.reset_rally()
	button(game,JOY_BUTTON_START)
	assert(game.paused)
	button(game,JOY_BUTTON_START)
	assert(not game.paused)
	game.possession=1
	game.server=1
	game.set_phase("CPU_SET")
	game.manual_wall.reset()
	axis(JOY_AXIS_TRIGGER_LEFT,1)
	game.read_controls(0)
	assert(game.manual_wall.left_joined and not game.manual_wall.right_joined and game.manual_wall.members(game).size()==2)
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	game.read_controls(0)
	assert(game.manual_wall.members(game).size()==3)
	axis(JOY_AXIS_LEFT_X,1)
	assert(game.stick().x>0.9)
	var before: float=game.block_helper_x
	game.read_controls(0.1)
	assert(game.block_helper_x>before)
	axis(JOY_AXIS_LEFT_X,0)
	axis(JOY_AXIS_RIGHT_X,1)
	assert(game.stick().length()<0.01,"Right stick must not aim or move the wall")
	axis(JOY_AXIS_RIGHT_X,0)
	axis(JOY_AXIS_TRIGGER_LEFT,0)
	game.read_controls(0)
	assert(not game.manual_wall.left_joined and game.manual_wall.right_joined and game.manual_wall.members(game).size()==2)
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	game.read_controls(0)
	assert(game.manual_wall.members(game).size()==1)
	button(game,JOY_BUTTON_A)
	assert(game.block_commanded and not game.manual_wall.jumped.is_empty())
	print("XBOX PASS: A jump serve/charge/release/block; X float; B setter dump mapping; Menu pause; LS aim and wall; LT/RT independent and triple; RS ignored / connected hardware=",Input.get_connected_joypads().size())
	game.free()
	quit()

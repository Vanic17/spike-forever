extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.demo=false
	game.self_test=true
	var cases:=0
	for fps in [60,120]:
		for rotation in 6:
			for mask in 4:
				Input.action_release("block_left")
				Input.action_release("block_right")
				game.rotations=[rotation,rotation]
				game.server=1
				game.reset_rally()
				game.possession=1
				game.set_phase("CPU_SET")
				game.setter=11
				game.flight_target=Vector3(0,2.5,-1.5)
				game.flight_left=1
				if mask&1: Input.action_press("block_left")
				if mask&2: Input.action_press("block_right")
				game.read_controls(0)
				var row: Array=game.manual_wall.line(game)
				assert(game.selected==row[1] and game.Tactics.ROLES[row[1]].begins_with("MB"))
				var active: Array=game.blocking_players(0)
				assert(active.size()==1+(1 if mask&1 else 0)+(1 if mask&2 else 0))
				assert((row[0] in active)==bool(mask&1) and (row[2] in active)==bool(mask&2))
				for i in 6:
					if game.Tactics.front(i,rotation): game.players[i].position=Vector3(-3.4 if i==row[0] else (3.4 if i==row[2] else 0.0),0,0.68)
				var before: int=game.block_jump_log.size()
				Input.action_press("right",0.5)
				var expected: float=game.stick().x*3.8*0.5
				for frame in fps/2: game.read_controls(1.0/fps)
				Input.action_release("right")
				assert(absf(game.block_helper_x-expected)<0.001 and expected>0.2,"Stick displacement must integrate time and strength instead of snapping to a pin")
				for frame in fps*2:
					game.clock_time+=1.0/fps
					game.move_players(1.0/fps)
					for p in game.players: p.tick(1.0/fps,false,false)
				assert(game.block_jump_log.size()==before,"Only Cross may jump")
				for i in active:
					assert(game.players[i].position.distance_to(game.blocking_target(i,0))<0.25,"Every selected blocker must physically reach the moving formation")
					assert(game.players[i].position.z<0.90)
				game.send_test_button(JOY_BUTTON_A)
				assert(game.block_jump_log.size()==before+active.size())
				Input.action_release("block_left")
				Input.action_release("block_right")
				game.read_controls(0)
				assert(game.blocking_players(0)==active,"Trigger release in flight must preserve the actual blocking hands")
				game.send_test_button(JOY_BUTTON_A)
				assert(game.block_jump_log.size()==before+active.size(),"One takeoff per blocker and attack")
				game.ball_pos=Vector3(0,game.contact_height("set"),-1.5)
				game.players[11].setting_yaw=PI/2
				game.players[11].rotation.y=PI/2
				game.players[11].position=game.players[11].stance_for_contact("set",game.ball_pos)
				game.pass_quality=0.9
				game.input_quality=0.9
				game.out_of_system=1
				game.plan_attack(0,false)
				game.set_ball()
				assert(game.phase=="CPU_ATTACK" and game.block_commanded)
				for i in active: assert(game.block_jumps[i]==game.attack_serial,"Early jump must survive the opposing set")
				game.set_phase("RECEIVE")
				game.blocking_team=0
				game.clock_time=game.block_time+0.10
				assert(game.blocking_players(0)==active,"The opponent's hit must retain the actual wall roster during our receive phase")
				for i in active: assert(game.blocking_target(i,0).is_finite())
				cases+=1
	# Also start from the actual stacked reception formations, not only an
	# already ordered net line. The middle must be the real front-row MB.
	for rotation in 6:
		game.rotations=[rotation,rotation]
		game.server=1
		game.reset_rally()
		game.possession=1
		game.set_phase("CPU_SET")
		game.setter=11
		game.flight_target=Vector3(0,2.5,-1.5)
		game.flight_left=1
		Input.action_press("block_left")
		Input.action_press("block_right")
		game.read_controls(0)
		for frame in 240:
			game.clock_time+=1.0/60.0
			game.move_players(1.0/60.0)
			for p in game.players: p.tick(1.0/60.0,false,false)
		for i in game.blocking_players(0):
			if game.players[i].position.distance_to(game.blocking_target(i,0))>=0.35: print("WALL ROTATION GAP r=",rotation," i=",i," pos=",game.players[i].position," target=",game.blocking_target(i,0))
			assert(game.players[i].position.distance_to(game.blocking_target(i,0))<0.35,"The real rotation formation must settle into the role-based triple wall")
		Input.action_release("block_right")
		game.read_controls(0)
		assert(game.blocking_players(0).size()==2)
		Input.action_release("block_left")
		game.read_controls(0)
		assert(game.blocking_players(0).size()==1,"Trigger release on the floor removes the wing immediately")
	game.reset_rally()
	game.set_phase("CPU_SET")
	for axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var event:=InputEventJoypadMotion.new()
		event.axis=axis
		event.device=9
		event.axis_value=1.0
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	game.read_controls(0)
	assert(game.blocking_players(0).size()==3,"L2 and R2 physical axis events must form a triple block")
	for axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var event:=InputEventJoypadMotion.new()
		event.axis=axis
		event.device=9
		event.axis_value=0.0
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	game.read_controls(0)
	assert(game.blocking_players(0).size()==1)
	print("MANUAL WALL PASS: ",cases," rotation/membership/rate cases / central always selected / L2-R2 physical axes / continuous LS / actual closure / manual jump / early jump retained")
	game.queue_free()
	quit()

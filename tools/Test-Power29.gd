extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	assert(game.Timing.SERVE_CHARGE_SECONDS<game.Timing.ATTACK_CHARGE_SECONDS)
	assert(not game.Timing.winning_power(0.969) and not game.Timing.winning_power(1.01))
	for power in [0.97,0.985,1.0]:
		game.reset_rally(); game.phase="ATTACK"; game.possession=0; game.hitter=0; game.hitter_action="attack"
		var p=game.players[0]; p.position=Vector3(-3,0,1.3); p.rotation.y=PI; p.prepare_contact("attack",0)
		game.ball_pos=p.contact_world("attack"); game.armed=true; game.input_quality=1; game.charge=power
		var before: int=game.scores[0]
		game.attack_ball(); assert(game.winner_team==0)
		assert(game.scores[0]==before,"No immediate automatic award")
		for frame in 360:
			if game.phase=="POINT": break
			game.step(1.0/120)
		assert(game.phase=="POINT" and game.scores[0]==before+1,"Winning attack must land for the attacker")
	for power in [0.97,1.0]:
		game.server=0; game.reset_rally(); game.send_test_button(JOY_BUTTON_A)
		game.charge_start=game.clock_time-game.Timing.SERVE_CHARGE_SECONDS*power
		game.send_test_button(JOY_BUTTON_A,false)
		var before: int=game.scores[0]
		for frame in 720:
			if game.phase=="POINT": break
			game.step(1.0/120)
			if game.phase=="CPU_RECEIVE": assert(game.winner_team==0,"Exact 97 percent must survive floating-point charge arithmetic")
		assert(game.phase=="POINT" and game.scores[0]==before+1,"Winning serve must score physically")
	game.reset_rally(); game.possession=1; game.phase="CPU_SET"
	game.read_controls(0); game.press_action()
	var row: Array=game.manual_wall.jumped.duplicate(); assert(not row.is_empty())
	for index in row: game.players[index].animation_time=game.players[index].clips.block.recovery_end+0.01
	game.read_controls(0); assert(not game.block_commanded and game.manual_wall.jumped.is_empty())
	game.press_action(); assert(game.block_commanded and not game.manual_wall.jumped.is_empty(),"Manual re-jump allowed after landing in same construction")
	game.reset_rally(); game.phase="SET"; game.armed=true; game.clock_time=10; game.press_action(); assert(game.attack_buffer_start==10)
	game.clock_time+=0.2; game.release_action(); assert(game.attack_buffer_power>0.3)
	load("res://tools/Test-RecoveryTraffic.gd").prepare_case(game,0)
	while game.phase=="SET" and game.flight_left>0.12: game.step(1.0/120)
	game.press_action()
	while game.phase=="SET": game.step(1.0/120)
	assert(game.phase=="ATTACK" and game.charging,"An early second press during the set must start the actual attack charge")
	game.release_action(); assert(game.armed)
	game.reset_rally(); game.phase="CPU_ATTACK"; game.possession=1; game.last_touch=1; game.winner_team=1
	game.block_time=game.clock_time-0.2
	var middle: int=game.manual_wall.line(game)[1]
	var blocker=game.players[middle]; blocker.position=Vector3(0,0,0.68); blocker.rotation.y=PI; blocker.prepare_contact("block",0)
	game.ball_pos=(blocker.current_hand(true)+blocker.current_hand(false))*0.5; game.ball_vel=Vector3(0,-1,15)
	game.try_block(); assert(game.phase=="LOOSE" and game.last_touch==0,"Actual blocking hands must yield a physical losing deflection in the winning band")
	print("POWER29 PASS: 97/98.5/100% actual winning attacks / physical scoring / re-jump same construction / buffered attack / distinct charge speeds")
	quit()

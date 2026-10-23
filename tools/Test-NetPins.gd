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
	var cases:=0
	for rotation in 6:
		for phase in ["CPU_SET","CPU_ATTACK"]:
			for mask in 4:
				for antenna in [-3.4,3.4]:
					game.rotations=[rotation,rotation]
					game.server=1
					game.reset_rally()
					game.possession=1
					game.set_phase(phase)
					game.setter=11
					game.hitter=game.Tactics.attacker(1,rotation,0,11)
					game.hitter_action="attack"
					game.flight_target=Vector3(antenna,3.3,-1.0)
					game.flight_left=0.8
					game.block_helper_x=antenna*0.7
					var row: Array=game.manual_wall.line(game)
					for order in 3:
						var player=game.players[row[order]]
						player.position=Vector3((order-1)*3.4,0,0.68)
						player.velocity=Vector3.ZERO
						player.acceleration=Vector3.ZERO
						player.steering_ready=false
					game.manual_wall.left_joined=bool(mask&1)
					game.manual_wall.right_joined=bool(mask&2)
					for frame in 90:
						game.clock_time+=1.0/60
						game.phase_time+=1.0/60
						game.move_players(1.0/60)
						for player in game.players: player.tick(1.0/60,false,false)
						for pin in [row[0],row[2]]:
							if phase=="CPU_ATTACK" and not pin in game.manual_wall.members(game): continue
							assert(game.players[pin].position.z<0.96,"Actual wall members stay at the net; free front players cover short balls")
					cases+=1
	print("NET PINS PASS: ",cases," rotation/phase/membership cases / actual wall members held near net / free front defenders allowed to cover short")
	game.free()
	quit()

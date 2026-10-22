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
	for team in 2:
		for rotation in [0,3,4,5]:
			for direction in [0,1,2,3]:
				for command_at in [0.0,0.6,0.95]:
					for quick in [false,true]:
						game.rotations=[rotation,rotation]
						game.server=1-team
						game.reset_rally()
						game.possession=team
						game.receiver=team*6+4
						game.set_dir=direction
						game.players[game.receiver].position=game.Tactics.world(team,0,1.5)
						game.players[team*6+5].position=game.Tactics.world(team,1.65,2.0)
						game.ball_pos=game.players[game.receiver].contact_world("receive")
						game.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE")
						game.armed=true
						game.input_quality=1
						game.incoming_kind="spike"
						game.incoming_power=0.3
						var before: int=game.test_contacts
						game.receive_ball()
						assert(game.phase in ["SET","CPU_SET"])
						if team==1: game.plan_attack(direction,quick)
						var duration: float=game.flight_left
						var elapsed:=0.0
						for frame in 300:
							if game.phase not in ["SET","CPU_SET"]: break
							if team==0 and elapsed>=duration*command_at and not game.armed: game.press_action("alternate" if quick else "action")
							game.step(1.0/120)
							elapsed+=1.0/120
						if game.phase not in ["ATTACK","CPU_ATTACK","RECEIVE","CPU_RECEIVE"]: print("SET RELIABILITY FAILURE team=",team," dir=",direction," command=",command_at," phase=",game.phase," setter=",game.setter)
						assert(game.phase in ["ATTACK","CPU_ATTACK","RECEIVE","CPU_RECEIVE"] and game.test_contacts==before+2,"Pressed sets and CPU sets must complete actual contact despite crowded passer and early/late confirmation")
						cases+=1
	var ref=game.Reference
	assert(ref.set_seconds(1,true,1,2,false)<ref.set_seconds(1,false,1,2,false))
	assert(is_equal_approx(ref.set_seconds(1,false,1,2,false),0.62))
	assert(ref.set_seconds(2,true,1,5,false)>0.62 and ref.set_seconds(2,true,1,5,false)<ref.set_seconds(2,false,1,5,false))
	assert(absf(ref.set_seconds(3,true,1,5,false)-ref.set_seconds(3,false,1,5,false))<0.05)
	print("SET RELIABILITY PASS: ",cases," actual reception-set sequences / early-middle-late confirmation / CPU / all directions / differentiated centre-wing-pipe tempo")
	game.free()
	quit()

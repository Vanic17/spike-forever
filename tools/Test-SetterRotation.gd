extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.demo=false
	game.started=true
	var formation_cases:=0
	for team in 2:
		for rotation in 6:
			game.rotations=[rotation,rotation]
			game.server=1-team
			game.reset_rally()
			for frame in 180:
				game.clock_time+=1.0/60.0
				game.phase_time+=1.0/60.0
				game.move_players(1.0/60.0)
				for p in game.players: p.tick(1.0/60.0,false,false)
				for back in range(team*6,team*6+6):
					var slot: int=game.Tactics.slot(back,rotation)
					if slot<3: continue
					for front in range(team*6,team*6+6):
						if game.Tactics.slot(front,rotation)!=5-slot: continue
						assert(absf(game.players[back].position.z)>absf(game.players[front].position.z)+0.1,"Before serve contact each back-row player must remain behind his actual corresponding front-row player")
			formation_cases+=1
	var contacts:=0
	var minimum:=INF
	for team in 2:
		for fps in [60,120]:
			game.rotations=[0,0]
			game.server=1-team
			game.reset_rally()
			game.possession=team
			game.set_phase("SET" if team==0 else "CPU_SET")
			game.setter=team*6+5
			game.receiver=team*6+3
			game.pass_quality=0.65
			game.input_quality=0.95
			game.out_of_system=1
			game.armed=true
			game.fast_set=false
			var side:=1.0 if team==0 else -1.0
			for i in range(team*6,team*6+6):
				game.players[i].position=game.Tactics.world(team,-4+(i%3)*4,7.5+(i%2))
				game.players[i].velocity=Vector3.ZERO
				game.players[i].acceleration=Vector3.ZERO
				game.players[i].steering_ready=false
			game.players[game.setter].setting_yaw=-PI/2 if team==0 else PI/2
			game.players[game.setter].rotation.y=game.players[game.setter].setting_yaw
			game.players[game.setter].position=game.Tactics.world(team,-2.5,4.2)
			# A stationary teammate directly across the penetration corridor.
			game.players[game.receiver].position=game.Tactics.world(team,-2.15,3.0)
			var point: Vector3=game.Tactics.world(team,-1.8,1.4)
			point.y=game.contact_height("set")
			game.ball_pos=game.Tactics.world(team,-3,5)+Vector3.UP*1.3
			game.launch(point,1.10)
			game.plan_attack(0,false)
			game.armed=true
			var before: int=game.test_contacts
			for frame in int(fps*1.3):
				if game.phase not in ["SET","CPU_SET"]: break
				game.step(1.0/fps)
				minimum=minf(minimum,game.players[game.setter].position.distance_to(game.players[game.receiver].position))
			if game.phase not in ["ATTACK","CPU_ATTACK"]: print("SETTER FAILURE team=",team," p=",game.players[game.setter].position," target=",point," yields=",game.court_shape.setter_yields)
			assert(game.phase in ["ATTACK","CPU_ATTACK"] and game.test_contacts==before+1,"A teammate across the approach must yield and allow a real set contact, not just an arm animation")
			contacts+=1
	assert(minimum>=0.775,"The setter corridor cannot be cleared by passing through teammates")
	print("SETTER ROTATION PASS: ",formation_cases," receiving formations / correct front-back correspondence / ",contacts," obstructed approaches with real set contact / minimum spacing=",minimum)
	game.queue_free()
	quit()

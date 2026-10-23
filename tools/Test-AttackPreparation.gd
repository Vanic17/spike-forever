extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	var cases:=0
	for team in 2:
		for rotation in 6:
			for direction in [0,1,2]:
				game.rotations=[rotation,rotation]; game.server=1-team; game.reset_rally()
				game.possession=team; game.receiver=team*6+4; game.setter=team*6+5
				for i in range(team*6,team*6+6):
					if game.Tactics.libero(i,rotation,false): game.receiver=i
				game.players[game.receiver].position=game.Tactics.world(team,0,4)
				game.ball_pos=game.players[game.receiver].contact_world("receive")
				game.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE"); game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=0.3
				game.receive_ball(); game.set_dir=direction; game.plan_attack(direction,false)
				var runner: int=game.planned_hitter
				if runner<0: continue
				var side:=1 if team==0 else -1
				# Deliberately reproduce the wide pin and the middle behind a setter.
				if direction!=1: game.players[runner].position=game.Tactics.world(team,-5.2 if direction==0 else 5.2,3.5)
				var initial_contacts: int=game.test_contacts
				for frame in 1000:
					if game.phase in ["SET","CPU_SET"]:
						if team==0 and not game.armed: game.press_action()
					elif game.phase in ["ATTACK","CPU_ATTACK"]:
						game.armed=true; game.charge=0.65; game.input_quality=1
					else: break
					game.step(1.0/120)
				if game.test_contacts<initial_contacts+2: print("HITTER FAILURE pos=",game.players[runner].position," target=",game.players[runner].target," stance=",game.players[runner].stance_for_contact("attack",game.ball_pos)," yields=",game.court_shape.setter_yields," bypass=",game.court_shape.bypass)
				assert(game.test_contacts>=initial_contacts+2,"Chosen hitter must complete the actual attack, not only the set: team=%d rot=%d direction=%d phase=%s"%[team,rotation,direction,game.phase])
				cases+=1
	print("ATTACK PREPARATION PASS: ",cases," receive-set-attack sequences / wide pins / both teams / six rotations")
	quit()

extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.started=true
	game.demo=false
	var cases:=0
	for native in [false,true]:
		game.Avatar.native_animation_enabled=native
		for fps in [60,120]:
			for rng_seed in [194260,20261022]:
				for x in [-2.8,0.0,2.5]:
					game.rng.seed=rng_seed
					game.rotations=[0,0]
					game.server=0
					game.reset_rally()
					game.award(1,"FIRST OPPONENT POINT")
					game.reset_rally()
					assert(game.rotations==[0,1],"Only the opponent rotates after taking our service")
					var target:=Vector3(x,game.contact_height("receive"),6.1)
					game.receiver=game.choose_receiver(0,target,true)
					game.select_receive_pose(game.receiver,target)
					game.possession=0
					game.incoming_kind="serve"
					game.incoming_power=0.75
					game.ball_pos=Vector3(2,3.1,-10.5)
					game.set_phase("RECEIVE")
					game.launch(target,1.1)
					game.set_dir=0
					var before: int=game.test_contacts
					var launched:=false
					for frame in fps*10:
						if game.phase=="RECEIVE": game.armed=true; game.input_quality=1.0
						if game.phase=="SET" and not game.armed: game.press_action()
						if game.phase=="ATTACK":
							launched=true
							assert(game.hitter==0 and game.flight_target.x<0,"Zone 4 must belong to OH1")
							game.armed=true
							game.input_quality=1.0
							game.charge=0.65
						game.step(1.0/fps)
						if game.phase in ["POINT","LOOSE"] or (launched and game.phase!="ATTACK"): break
					if game.phase!="CPU_RECEIVE": print("FIRST SIDEOUT FAILURE native=",native," fps=",fps," seed=",rng_seed," x=",x," phase=",game.phase)
					assert(launched and game.phase=="CPU_RECEIVE" and game.test_contacts==before+3,"First opponent point: reception, set to 4 and OH attack must all make real contact")
					cases+=1
	print("FIRST SIDEOUT PASS: ",cases," real reception-set-attack sequences / left-centre-right passing / 60-120Hz / PSA-native / correct side-out / OH1 zone 4")
	game.free()
	quit()

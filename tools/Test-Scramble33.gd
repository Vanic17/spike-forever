extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true
	assert(game.timing.quality(0.3)>0.6 and game.Timing.SERVE_CHARGE_SECONDS==0.46)
	game.server=1; game.reset_rally(); game.possession=0; game.touches=[1,0]; game.receiver=4
	game.ball_pos=Vector3(0,1.2,5); game.players[4].position=Vector3(0,0,5)
	load("res://src/scramble_recovery.gd").start(game,4)
	assert(game.receiver!=4 and game.late_receive and game.incoming_kind=="shank" and game.touches[0]==1)
	# Complete the real second touch at its physical contact stance.
	var p=game.players[game.receiver]; p.position=p.stance_for_contact("recovery",game.flight_target); p.prepare_contact("recovery",0)
	game.ball_pos=p.contact_world("recovery"); game.armed=true; game.input_quality=0.8
	var before: int=game.test_contacts; game.receive_ball()
	assert(game.test_contacts==before+1 and game.touches[0]==2 and game.phase=="ATTACK","A low save must become the second touch, not manufacture a fourth touch")
	assert(game.hitter_action=="attack")
	print("SCRAMBLE33 PASS: wider timing / unchanged serve bar / teammate recovery / actual second contact / emergency attack")
	quit()

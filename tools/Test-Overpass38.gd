extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	var cases:=0
	for team in 2:
		for rotation in 6:
			game.rotations=[rotation,rotation]; game.server=1-team; game.reset_rally(); game.rng.seed=3800+rotation
			var front: Array=[]
			for i in range(team*6,team*6+6):
				var player=game.players[i]; player.rotation.y=PI if team==0 else 0; player.velocity=Vector3.ZERO; player.acceleration=Vector3.ZERO
				player.clip_name="idle"; player.looping=true; player.steering_ready=false
				if game.Tactics.front(i,rotation): front.append(i)
				player.position=game.Tactics.world(team,-3+(i%3)*3,6)
			for k in 3: game.players[front[k]].position=game.Tactics.world(team,-2.5+k*2.5,1.0)
			game.ball_pos=game.Tactics.world(1-team,0,1.5); game.ball_pos.y=1.2
			game.incoming_kind="overpass"; game.incoming_power=0.18; game.out_of_system=-1
			var landing: Vector3=game.Tactics.world(team,0,2.0); landing.y=0.105
			var before: int=game.test_contacts; var score_before: int=game.scores[team]
			game.send_to_court(1-team,landing,1.8)
			assert(game.phase in ["ATTACK","CPU_ATTACK"] and game.armed and game.charge==1 and game.overpass_attack_team==team,"Reachable overpass must arm an automatic full-power first touch for either team")
			assert(game.scores[team]==score_before,"Scheduling an overpass must not award a point")
			for frame in 360:
				if game.test_contacts>before: break
				game.step(1.0/120)
			assert(game.test_contacts==before+1 and game.last_power==1.0 and game.winner_team==team,"Automatic overpass kill needs a real authored hand contact at 100 percent")
			assert(game.scores[team]==score_before,"The actual kill contact still must not award a point in the air")
			assert(game.incoming_kind=="spike" and is_equal_approx(game.incoming_power,1),"CPU overpass must not randomly select a soft shot")
			assert(game.contact_log.back().gap<=0.18)
			for frame in 480:
				if game.phase=="POINT": break
				game.step(1.0/120)
			assert(game.phase=="POINT" and game.scores[team]==score_before+1,"The kill must score once through a real floor trajectory")
			cases+=1
	print("OVERPASS38 PASS: ",cases," automatic full-power kills / all rotations / both teams / actual hand contact / point at ground only")
	game.free(); quit()

extends SceneTree
var g
func _initialize(): call_deferred("run")
func prepare(grade: int,power: float):
	g.use_player_stats=true; g.server=1; g.rotations=[0,0]; g.reset_rally(); g.possession=0; g.setter=5; g.hitter=0; g.out_of_system=1; g.stats_set_grade=grade
	g.phase="ATTACK"; g.armed=true; g.charge=power; g.input_quality=1; g.hitter_action="attack"; g.attack_tip=false
	g.ball_pos=g.Tactics.world(0,-3.4,1.05); g.ball_pos.y=g.players[0].contact_local("attack").y
	var p=g.players[0]; p.rotation.y=PI; p.position=p.stance_for_contact("attack",g.ball_pos); p.blend_left=0; p.prepare_contact("attack",0); p.apply_pose(0)
func run():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false; g.replay.set_process(false); g.match_audio.enabled=false
	var rows=[]
	for grade in 3:
		g.stats_set_grade=grade; var low=g.PlayerStats.green_low(g,false)
		assert(g.PlayerStats.perfect(1.0000005,low) and not g.PlayerStats.perfect(1.00001,low),"Numerical tolerance only, not real overcharge")
		for power in [low,low+.002,1.0]:
			prepare(grade,power); g.scores=[0,0]; g.sets=[0,0]; g.attack_ball()
			assert(g.phase=="CPU_RECEIVE" and g.winner_team==0,"Every DB green band guarantees the attacker point")
			assert(is_equal_approx(g.incoming_power,power),"No power or pace reduction for the winning path")
			for frame in 800:
				if g.phase=="POINT": break
				g.step(1.0/120)
				if frame%4==0:
					for p in g.players: p.apply_pose(1.0/30)
			assert(g.phase=="POINT" and g.scores==[1,0],"Green attack must produce a real physical point")
			rows.append({"grade":grade,"low":low,"power":power,"score":g.scores.duplicate()})
		prepare(grade,low-.003); g.attack_ball(); assert(g.winner_team==-1,"Below green has no automatic point")
		prepare(grade,1.03); g.rng.seed=67015; g.attack_ball(); assert(g.winner_team==-1,"Overcharge is not green")
	FileAccess.open("res://docs/gameplay67-green.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("GREEN ATTACK67 PASS all 3 DB windows / 9 physical winning points / unchanged power / outside and overcharge excluded"); g.free(); quit()

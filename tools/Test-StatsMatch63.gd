extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var rows: Array=[]
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for side in 2:
		var squad: Array=db.lineup(db.teams[side])
		for i in 6: g.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(db.teams[side].id,"home"),kits.selection(db.teams[side].id,"home",true))
	for enabled in [false,true]:
		g.use_player_stats=enabled; g.clock_time=0; g.rng.seed=63009; g.started=true; g.demo=true; g.paused=false; g.match_finished=false
		g.scores=[0,0]; g.sets=[0,0]; g.rotations=[0,0]; g.server=0; g.match_best_of=1; g.match_points=15; g.reset_rally()
		var steps:=0; var initial: int=g.test_contacts; var finished:=false; var final_score: Array=[]
		while g.started and steps<60000:
			var before: Array=g.scores.duplicate()
			g.step(1.0/60); steps+=1
			if g.match_finished and not finished:
				finished=true; final_score=before
				final_score[0 if g.sets[0]>0 else 1]+=1
			if steps%2==0:
				for p in g.players: p.apply_pose(1.0/30)
			assert(g.ball_pos.is_finite() and g.ball_vel.is_finite())
		assert(not g.started and finished,"A whole simulated set must finish and return home")
		assert(maxi(final_score[0],final_score[1])>=15 and absi(final_score[0]-final_score[1])>=2)
		rows.append({"stats":enabled,"scores":final_score,"sets":g.sets.duplicate(),"steps":steps,"contacts":g.test_contacts-initial,"returned_home":not g.started})
	FileAccess.open("res://docs/stats63-matches.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("STATS MATCH63 PASS ",JSON.stringify(rows)); g.free(); quit()

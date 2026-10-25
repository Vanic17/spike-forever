extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for hz in [60,120]:
			g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team; g.rng.seed=56001
			for i in range(team*6,team*6+6):
				g.players[i].position=g.Tactics.world(team,3.8,8.0-float(i%6)*.8); g.players[i].play("idle",1,true); g.players[i].blend_left=0
			var passer: int=team*6; var rescuer: int=team*6+4
			g.players[passer].position=g.Tactics.world(team,-2,3.5); g.players[rescuer].position=g.Tactics.world(team,-2.7,5.1)
			g.ball_pos=g.Tactics.world(team,-2,4)+Vector3.UP*1.15; g.touches=[0,0]; g.touches[team]=1
			g.set_dir=0; var count: int=g.test_contacts
			load("res://src/scramble_recovery.gd").start(g,passer)
			assert(g.receiver==rescuer and g.dive_motions.has(rescuer),"Low rescue must own root motion, not generic locomotion")
			var velocity: Vector3=g.ball_vel; var origin: Vector3=g.ball_pos; var duration: float=g.flight_left
			var largest_step:=0.0
			for frame in 300:
				if g.phase not in ["RECEIVE","CPU_RECEIVE"] or g.test_contacts>count: break
				g.armed=true; g.input_quality=.8
				var previous: Vector3=g.players[rescuer].position
				g.step(1.0/hz); largest_step=maxf(largest_step,g.players[rescuer].position.distance_to(previous))
				for p in g.players: p.apply_pose(1.0/hz)
			var touched: bool=g.test_contacts==count+1
			rows.append({"team":team,"hz":hz,"contact":touched,"phase":g.phase,"max_root_step":largest_step,"duration":duration,"motion_active":g.dive_motions.has(rescuer)})
			assert(touched and g.phase in ["ATTACK","CPU_ATTACK"],"Source-driven second-touch rescue must stay playable")
			assert(largest_step<.20,"No root teleport")
	FileAccess.open("res://docs/low-recovery56-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("LOW RECOVERY56 PASS 4 contacts / source motion / both sides / 60-120Hz / no extra touches")
	g.free(); quit()

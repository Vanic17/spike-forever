extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var cases:=0
	for team in 2:
		for previous in ["receive","run"]:
			g.reset_rally(); g.possession=team; g.receiver=team*6+3
			var p=g.players[g.receiver]
			p.play(previous,1,true if previous=="run" else false)
			p.animation_time=p.clips.receive.contact_time+0.08 if previous=="receive" else 0.25
			p.position=g.Tactics.world(team,0,4); p.velocity=Vector3(1.5,0,0.5)
			p.target=g.Tactics.world(team,-4,1); p.contact_scheduled=true
			g.ball_pos=g.Tactics.world(team,3,6)+Vector3.UP*0.6; g.ball_vel=Vector3(3,-6,1)
			g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.late_receive=false
			var animation_before: float=p.animation_time; var ball_before: Vector3=g.ball_pos; var velocity_before: Vector3=g.ball_vel
			load("res://src/winning_shot.gd").failed_save(g)
			assert(p.clip_name==previous and p.animation_time==animation_before,"A missed winning ball must not restart a backward forearm animation")
			assert(p.target.distance_to(p.position)<0.4 and (p.target-p.position).dot(p.velocity)>0,"The obsolete chase becomes a short momentum-preserving stop")
			assert(not p.contact_scheduled and p.reach_weight==0)
			assert(g.ball_pos==ball_before and g.ball_vel==velocity_before,"A missed save cannot change the flight")
			cases+=1
	print("RECOVERY PRESENTATION43 PASS cases=",cases," / missed winning ball / no animation restart / no stale chase / physical flight retained")
	g.free(); quit()

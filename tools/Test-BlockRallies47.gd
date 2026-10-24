extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var response=load("res://src/block_response.gd"); var rows: Array=[]; var stuff_points:=0; var soft_live:=0
	for hard in [false,true]:
		for trial in 12:
			g.server=1; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=47001+trial
			g.test_rallies=3; g.winner_team=-1; g.last_touch=0; g.block_checked=true; g.block_time=-100
			for i in range(6,12):
				g.players[i].position=Vector3((i-8.5)*1.3,0,-4.5-absf(i-8.5)*.6); g.players[i].play("relaxed",1,true); g.players[i].apply_pose(0)
			# Coverage near the spiker can recover a soft touch; the hitter
			# is still landing and cannot instantly dig a pressed-down stuff.
			g.players[8].position=Vector3(.1,0,-1.35)
			g.players[8].play("attack",1,false); g.players[8].animation_time=g.players[8].clips.attack.contact_time+.04
			g.ball_pos=Vector3((trial-5.5)*.06,3.05,.035)
			var r: Dictionary=response.solve(Vector3(0,-3,30),0,.97 if hard else .58,.96 if hard else .80,0,Vector3(0,0.7 if not hard else 0,0))
			g.ball_vel=r.velocity; g.flight_spin=Vector3.ZERO; g.airborne=true
			var contacts: int=g.test_contacts; var points: int=g.scores[0]
			g.resume_deflection("block")
			for frame in 600:
				if g.phase=="POINT" or g.test_contacts>contacts: break
				g.step(1.0/120)
				if frame%4==0:
					for p in g.players: p.apply_pose(1.0/30)
			var point: bool=g.scores[0]>points; var live: bool=g.test_contacts>contacts
			if hard and point: stuff_points+=1
			if not hard and live: soft_live+=1
			rows.append({"kind":r.kind,"hard":hard,"point_for_block":point,"cpu_recovered":live,"phase":g.phase})
	print("BLOCK RALLIES47 RESULTS hard points=",stuff_points,"/12 soft recoveries=",soft_live,"/12")
	FileAccess.open("res://docs/block-rallies47-report.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":"spiker landing; remaining floor coverage 4.5m+ deep","hard_points":stuff_points,"hard_total":12,"soft_recoveries":soft_live,"soft_total":12,"cases":rows},"  "))
	assert(stuff_points>=8,"A hard well-sealed block must produce real floor points against the landing hitter")
	assert(soft_live>=6,"Soft high touches must remain recoverable rather than every block becoming a winner")
	print("BLOCK RALLIES47 PASS"); g.free(); quit()

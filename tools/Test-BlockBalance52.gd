extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var old=load("res://docs/baseline-v51/block_response.gd"); var revised=load("res://src/block_response.gd")
	var points: Array=[0,0]; var saves: Array=[0,0]; var rows: Array=[]
	for trial in 40:
		var strength: float=lerpf(.55,.98,float(trial%10)/9)
		var quality: float=.80+float(trial/10)*.06
		var variation:=Vector3(sin(trial)*.6,sin(trial*2.1),cos(trial)*.6)
		for version in 2:
			g.server=1; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=52001+trial
			g.test_rallies=3; g.winner_team=-1; g.last_touch=0; g.block_checked=true; g.block_time=-100
			for i in range(6,12):
				g.players[i].position=Vector3((i-8.5)*1.3,0,-4.5-absf(i-8.5)*.6); g.players[i].play("relaxed",1,true); g.players[i].apply_pose(0)
			g.players[8].position=Vector3(.1,0,-1.35); g.players[8].play("attack",1,false)
			g.players[8].animation_time=g.players[8].clips.attack.contact_time+.04
			g.ball_pos=Vector3((trial%10-4.5)*.04,3.05,.035)
			var r: Dictionary=(old if version==0 else revised).solve(Vector3(0,-3,32),0,strength,quality,0,variation)
			g.ball_vel=r.velocity; g.flight_spin=Vector3.ZERO; g.airborne=true
			var contacts: int=g.test_contacts; var score: int=g.scores[0]
			g.resume_deflection("block")
			for frame in 600:
				if g.phase=="POINT" or g.test_contacts>contacts: break
				g.step(1.0/120)
				if frame%4==0:
					for p in g.players: p.apply_pose(1.0/30)
			var point: bool=g.scores[0]>score; var save: bool=g.test_contacts>contacts
			if point: points[version]+=1
			if save: saves[version]+=1
			rows.append({"trial":trial,"version":51+version,"strength":strength,"quality":quality,"kind":r.kind,"point":point,"saved":save})
	FileAccess.open("res://docs/block52-balance.json",FileAccess.WRITE).store_string(JSON.stringify({"matched_trials":40,"points_before":points[0],"points_after":points[1],"saves_before":saves[0],"saves_after":saves[1],"cases":rows},"  "))
	print("BLOCK BALANCE52 points=",points," recoveries=",saves," /40 matched real floor-or-contact trials")
	var ok: bool=points[1]>points[0] and saves[1]>=8
	g.free(); quit(0 if ok else 1)

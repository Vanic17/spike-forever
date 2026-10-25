extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var points: Array=[0,0]; var saves: Array=[0,0]; var rows: Array=[]
	for trial in 120:
		for version in 2:
			g.cpu_defense=load("res://docs/baseline-v53/block_coverage.gd" if version==0 else "res://src/cpu_defense.gd").new()
			g.server=1; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=54001+trial; g.test_rallies=3; g.winner_team=-1; g.last_touch=0; g.block_checked=true; g.block_time=-100
			for i in range(6,12):
				g.players[i].position=Vector3((i-8.5)*1.3,0,-4.5-absf(i-8.5)*.6); g.players[i].play("relaxed",1,true); g.players[i].apply_pose(0)
			g.players[8].position=Vector3(.1,0,-1.35); g.players[8].play("attack",1,false); g.players[8].animation_time=g.players[8].clips.attack.contact_time+.04
			if trial>=40: g.players[9].position=Vector3(.65,0,-lerpf(2.4,4.8,float(trial-40)/79))
			g.ball_pos=Vector3((trial%10-4.5)*.04,3.05,.035)
			var response: Dictionary=load("res://src/block_response.gd").solve(Vector3(0,-3,32),0,lerpf(.55,.98,float(trial%10)/9),.8+float((trial%40)/10)*.06,0,Vector3(sin(trial)*.6,sin(trial*2.1),cos(trial)*.6))
			g.ball_vel=response.velocity; g.flight_spin=Vector3.ZERO; g.airborne=true
			var contact_count: int=g.test_contacts; var score: int=g.scores[0]; g.resume_deflection("block")
			for frame in 600:
				if g.phase=="POINT" or g.test_contacts>contact_count: break
				g.step(1.0/120)
				if frame%4==0:
					for p in g.players: p.apply_pose(1.0/30)
			if g.scores[0]>score: points[version]+=1
			if g.test_contacts>contact_count: saves[version]+=1
			rows.append({"trial":trial,"version":53+version,"point":g.scores[0]>score,"save":g.test_contacts>contact_count})
	# An opponent block going out is left; our own block must still be saved.
	for last in [0,1]:
		g.reset_rally(); g.last_touch=last; g.ball_pos=Vector3(3,2.9,-.1); g.ball_vel=Vector3(5,0,-9); g.flight_spin=Vector3.ZERO; g.airborne=true
		g.resume_deflection("block"); assert(g.possession==1)
		assert(g.incoming_out==(last==0),"Leave only a ball last touched by the opponent")
		if last==0:
			var contacts: int=g.test_contacts; g.receive_ball(); assert(g.test_contacts==contacts and g.phase=="LOOSE")
	FileAccess.open("res://docs/coverage54-report.json",FileAccess.WRITE).store_string(JSON.stringify({"trials":120,"points":points,"saves":saves,"cases":rows},"  "))
	print("COVERAGE54 points=",points," saves=",saves," /120; leave-out and own-touch rescue PASS")
	assert(points[1]>=points[0] and saves[1]>=8,"Keep block coverage playable")
	g.free(); quit()

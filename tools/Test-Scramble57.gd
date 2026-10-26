extends SceneTree
const Scramble=preload("res://src/scramble_recovery.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for hz in [60,120]:
			prepare(g,team)
			var passer: int=team*6; var unavailable: int=team*6+3; var rescuer: int=team*6+4
			# The random shank offset is world-space, so the same seed drifts
			# left on both halves. Keep the nearer obstacle beside that real arc.
			g.players[unavailable].position=g.Tactics.world(team,-3.2 if team==0 else -.5,3.6)
			g.players[unavailable].play("recovery",1,false); g.players[unavailable].animation_time=0; g.players[unavailable].motion_lock=2
			var before: int=g.test_contacts
			Scramble.start(g,passer)
			var handoff:=false
			for event in g.rally_events:
				if event.get("kind","")=="low_save_handoff": handoff=true
			print("SCRAMBLE57 fixture team=",team," receiver=",g.receiver," expected=",rescuer," phase=",g.phase," handoff=",handoff)
			assert(handoff,"The fixture must prove that the original nearest-player choice was unavailable")
			assert(preload("res://src/low_recovery.gd").plan(g,unavailable).is_empty(),"The original nearest-only path rejects this recovery")
			assert(g.phase in ["RECEIVE","CPU_RECEIVE"] and g.receiver==rescuer,"A ready reachable teammate must replace the nearest recovering player")
			assert(not g.armed,"Low save must still require the human input")
			var duration: float=g.flight_left
			var max_step:=0.0
			for frame in 160:
				if g.phase not in ["RECEIVE","CPU_RECEIVE"] or g.test_contacts>before: break
				g.armed=true; g.input_quality=.8
				var previous: Vector3=g.players[rescuer].position
				g.step(1.0/hz); max_step=maxf(max_step,g.players[rescuer].position.distance_to(previous))
				for player in g.players: player.apply_pose(1.0/hz)
			var touched: bool=g.test_contacts==before+1
			if not touched:
				for event in g.rally_events:
					if event.kind in ["contact_rejected","low_save_plan"]: print("SCRAMBLE57 FAILED ",event)
			rows.append({"team":team,"hz":hz,"case":"nearest_recovering","nearest":unavailable,"receiver":g.receiver,"handoff":handoff,"contact":touched,"variant":g.players[rescuer].variant_names.get("dive","dive"),"max_root_step":max_step,"duration":duration})
			assert(touched and g.phase in ["ATTACK","CPU_ATTACK"],"The alternative rescuer must complete a real second touch")
			assert(max_step<.20,"Rescue movement must not teleport")
			prepare(g,team)
			for index in range(team*6,team*6+6):
				if index!=passer: g.players[index].position=g.Tactics.world(team,6.5,10.5)
			before=g.test_contacts
			Scramble.start(g,passer)
			rows.append({"team":team,"hz":hz,"case":"all_unreachable","phase":g.phase,"contacts":g.test_contacts-before})
			assert(g.phase=="LOOSE" and g.test_contacts==before and g.dive_motions.is_empty(),"Unreachable shank must remain missed")
			if team==0:
				prepare(g,team); before=g.test_contacts; Scramble.start(g,passer)
				for frame in 150:
					if g.phase=="POINT": break
					g.step(1.0/hz)
					for player in g.players: player.apply_pose(1.0/hz)
				rows.append({"team":team,"hz":hz,"case":"no_input","phase":g.phase,"contacts":g.test_contacts-before})
				assert(g.test_contacts==before,"An uncommanded human rescue must never touch the ball")
	FileAccess.open("res://docs/scramble57-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("SCRAMBLE57 PASS 4 alternative rescuer contacts / 4 unreachable shanks / 2 no-input cases / both sides 60-120Hz")
	g.free(); quit()

func prepare(g, team: int) -> void:
	g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team; g.rng.seed=56001; g.rally_events.clear()
	for i in range(team*6,team*6+6):
		g.players[i].position=g.Tactics.world(team,3.8,8.0-float(i%6)*.8); g.players[i].play("idle",1,true); g.players[i].blend_left=0
	g.players[team*6].position=g.Tactics.world(team,-2,3.5)
	g.players[team*6+4].position=g.Tactics.world(team,-2.7,5.1)
	g.ball_pos=g.Tactics.world(team,-2,4)+Vector3.UP*1.15; g.touches=[0,0]; g.touches[team]=1; g.set_dir=0
	g.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE"); g.incoming_kind="spike"

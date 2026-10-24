extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]; var failures:=0
	for rotation in [0,1]:
		for direction in 4:
			for sector in 8:
				g.rotations=[rotation,rotation]; g.server=1; g.reset_rally(); g.possession=0
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.rng.seed=47001; g.receiver=4; g.set_dir=direction
				g.players[4].position=g.Tactics.world(0,0,5.5); g.players[5].position=g.Tactics.world(0,1.65,2)
				g.ball_pos=g.players[4].contact_world("receive"); g.phase="RECEIVE"; g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=.3
				var before: int=g.test_contacts
				g.receive_ball(); g.press_action("action")
				var pressed:=false
				for frame in 900:
					if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
					if g.phase=="ATTACK" and not pressed and g.flight_left<(.36 if sector%2==0 else .18):
						g.aim=Vector2.from_angle(sector*PI/4); g.press_action("alternate"); pressed=true
					if pressed and g.charging:
						g.charge_start=g.clock_time-g.Timing.ATTACK_CHARGE_SECONDS*.75; g.release_action()
					g.step(1.0/120)
					if frame%8==0:
						for p in g.players: p.apply_pose(1.0/15)
				var ok: bool=pressed and g.test_contacts==before+3
				rows.append({"rotation":rotation,"direction":direction,"sector":sector,"contact":ok,"phase":g.phase})
				if not ok:
					failures+=1; print("TIP47 FAIL ",rows[-1]," hitter=",g.hitter," pos=",g.players[g.hitter].position," ball=",g.ball_pos," local=",g.players[g.hitter].contact_local("attack"))
	FileAccess.open("res://docs/tips47-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("TIPS47 RESULTS cases=",rows.size()," failures=",failures)
	g.free(); quit(0 if failures==0 else 1)

extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]; var failures:=0
	for rotation in 6:
		for quality in [.35,.65,.95]:
			for direction in [2,3]:
				for quick in [false,true]:
					if "--probe" in OS.get_cmdline_user_args() and (rotation!=1 or quality!=.35 or direction!=2 or not quick): continue
					g.rotations=[rotation,rotation]; g.server=1; g.rng.seed=55001; g.shot_serial=0; g.reset_rally(); g.possession=0
					g.receiver=4; g.set_dir=direction; g.players[4].position=Vector3(0,0,5.5); g.players[5].position=Vector3(1.65,0,2)
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.ball_pos=g.players[4].contact_world("receive"); g.phase="RECEIVE"; g.armed=true; g.input_quality=quality; g.incoming_kind="net"; g.incoming_power=.3
					var before: int=g.test_contacts; g.receive_ball()
					if g.phase!="SET": continue
					g.plan_attack(direction,quick); g.press_action("alternate" if quick else "action")
					var planned: int=g.planned_hitter; var changed:=false; var max_y:=0.0
					for frame in 1000:
						if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+3: break
						if g.phase=="ATTACK":
							g.armed=true; g.charge=.85; g.input_quality=1
							changed=changed or g.destination!=direction or g.hitter!=planned
						g.step(1.0/120); max_y=maxf(max_y,g.ball_pos.y)
						if "--probe" in OS.get_cmdline_user_args() and g.phase=="ATTACK" and frame%12==0: print("TRACE55 left=",g.flight_left," root=",g.players[g.hitter].position," yaw=",g.players[g.hitter].rotation.y," goal=",g.attack_run.goal," vel=",g.players[g.hitter].velocity," bodies=",g.players.slice(0,6).map(func(p): return p.position))
						if frame%4==0:
							for p in g.players: p.apply_pose(1.0/30)
					var good: bool=g.test_contacts>=before+3 and not changed and max_y<12
					var row={"rotation":rotation,"quality":quality,"direction":direction,"quick":quick,"planned":planned,"contacts":g.test_contacts-before,"changed":changed,"max_height":max_y,"ok":good,"events":g.rally_events.slice(-3) if not good else []}
					rows.append(row)
					if not good: failures+=1; print("CONSTRUCTION55 FAIL ",row)
	FileAccess.open("res://docs/constructions55-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("CONSTRUCTIONS55 ",rows.size()-failures,"/",rows.size()); g.free(); quit(1 if failures else 0)

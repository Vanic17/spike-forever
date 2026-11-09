extends SceneTree
const Second=preload("res://src/setter_second96.gd")
const Net=preload("res://src/net_spec94.gd")
var errors: Array=[]
var rows: Array=[]
func check(ok: bool,label: String):
	if not ok:errors.append(label);print("FAIL98 ",label)
func _initialize():call_deferred("run")
func run():
	assert("strikes96" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.started=true;g.self_test=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	await process_frame
	g.online_session.playing=true
	var p=g.players[5]
	for name in ["dump_back96","dump_down96","dump_forward96"]:
		p.left_handed=false
		var normal: Array[Transform3D]=p.normalized_pose("source:"+name,g.clips[name].contact_time,false)
		p.left_handed=true
		var mirrored: Array[Transform3D]=p.normalized_pose("source:"+name,g.clips[name].contact_time,false)
		for bone in normal.size():check(normal[bone].origin.distance_to(mirrored[bone].origin)<.0001,"fixed hand no handedness mirror "+name)
	for hz in [60,120]:
		for team in 2:
			for rotation in 6:
				for lead in [.50,.12]:
					for direction in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
						if "--probe" in OS.get_cmdline_user_args() and (hz!=120 or team!=0 or rotation!=4 or lead<.4 or direction!=Vector2.DOWN):continue
						g.rotations=[rotation,rotation];g.server=1-team;g.reset_rally();g.possession=team;g.input_team=team;g.receiver=team*6+4;g.rng.seed=98421
						g.players[g.receiver].position=g.Tactics.world(team,0,5.5);g.ball_pos=g.players[g.receiver].contact_world("receive")
						g.phase="RECEIVE" if team==0 else "CPU_RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="free";g.incoming_power=0
						g.receive_ball();g.aim=direction
						var old: int=g.contact_log.size();var requested:=false;var choice:=0
						for frame in 500:
							if not requested and g.flight_left<lead:requested=Second.request(g);choice=g.setter_second96
							g.step(1.0/hz)
							if g.phase not in ["SET","CPU_SET"]:break
						var touched: bool=g.contact_log.size()>old and g.contact_log.back().action=="dump"
						var row: Dictionary={"hz":hz,"team":team,"rotation":rotation,"lead":lead,"kind":choice,"front":g.Tactics.front(g.setter,rotation),"requested":requested,"contact":touched,"phase":g.phase}
						check(touched,"live palm "+str(row))
						if not touched:print("CONTEXT98 ",g.rally_events.slice(-5))
						check(g.phase not in ["POINT","LOOSE"],"no instant own point "+str(row))
						p=g.players[g.setter]
						if touched:
							var palm: Vector3=p.current_hand(choice==3)
							row.palm_gap=palm.distance_to(g.contact_log.back().ball)
							row.yaw_error=absf(wrapf(p.rotation.y-p.setting_yaw,-PI,PI))
							check(row.palm_gap<.18,"correct striking hand "+str(row))
							check(row.yaw_error<.12,"parallel to net "+str(row))
							var origin: Vector3=g.ball_pos;var vel: Vector3=g.ball_vel;row.release_y=vel.y;row.release_height=origin.y
							var crossed:=false;var mesh:=false;var point: Vector3=origin
							for tick in 180:
								var next: Array=g.BallFlight.advance(point,vel,g.flight_spin,1.0/120,g.flight_gravity)
								if point.z*next[0].z<=0:
									crossed=true;mesh=not Net.crossing(point,next[0],vel).is_empty();break
								point=next[0];vel=next[1]
							row.crossed=crossed;row.mesh=mesh
							if choice==3 and row.release_y>=0:check(false,"classic must not become an upward lob "+str(row))
							if row.front and lead>.4 or choice!=3:check(crossed and not mesh,"clear actual net "+str(row))
							else:check(crossed,"low-ball gesture follows physical net trajectory "+str(row))
							if choice==3 and lead>.4 and row.front:check(row.release_y<0,"classic pushed down "+str(row))
						rows.append(row)
	var report: Dictionary={"pass":errors.is_empty(),"cases":rows.size(),"errors":errors,"rows":rows}
	FileAccess.open("res://docs/setter98-tests"+("-fallback" if "--psa-original" in OS.get_cmdline_user_args() else "")+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SETTER98 ","PASS" if errors.is_empty() else "FAIL"," cases=",rows.size()," failures=",errors.size());quit(0 if errors.is_empty() else 1)

extends SceneTree
const Second=preload("res://src/setter_second96.gd")
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_spec94.gd")
var errors: Array=[]
var rows: Array=[]
func _initialize():call_deferred("run")
func run():
	assert("short101" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false;g.replay.enabled=false
	for player in g.players:player.set_process(false);player.render_at_draw=false
	for team in 2:
		g.possession=team;g.setter=team*6+5;g.players[g.setter].setting_yaw=-PI/2 if team==0 else PI/2
		for x in [-1.2,0,1.2]:
			for height in [2.8,3.1]:
				for depth in [.4,.9]:
					g.ball_pos=Vector3(x,height,depth if team==0 else -depth)
					for kind in [2,7]:
						g.setter_second96=kind;var shot: Dictionary=Second.trajectory(g)
						var point: Vector3=g.ball_pos;var velocity: Vector3=Flight.velocity_to(point,shot.target,shot.seconds,shot.spin,g.flight_gravity)
						var before: Vector3=point
						for tick in 400:
							before=point;var step:=Flight.advance(point,velocity,shot.spin,1.0/240,g.flight_gravity);point=step[0];velocity=step[1]
							if point.y<=Net.BALL_RADIUS:
								point=before.lerp(point,(before.y-Net.BALL_RADIUS)/maxf(.000001,before.y-point.y));break
						var okay: bool=point.z*(-1 if team==0 else 1)>.5 and absf(point.z)<2.8 and absf(point.x)>3.3 and absf(point.x)<4.3 and Second.crosses_cleanly(g,shot.target,shot.seconds,shot.spin)
						var row: Dictionary={"team":team,"kind":kind,"origin":str(g.ball_pos),"landing":str(point),"pass":okay};rows.append(row)
						if not okay:errors.append(row)
	FileAccess.open("res://docs/short101-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"cases":rows.size(),"errors":errors,"rows":rows},"  "))
	print("SHORT101 ","PASS" if errors.is_empty() else "FAIL"," cases=",rows.size()," errors=",errors);quit(0 if errors.is_empty() else 1)

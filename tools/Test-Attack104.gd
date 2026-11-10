extends SceneTree
const Delivery=preload("res://src/attack_delivery104.gd")
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_spec94.gd")
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message)
func _initialize():call_deferred("run")
func run():
	assert("attack104" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	var samples: Array=[];var maximum_us:=0
	for team in 2:
		for depth in [.55,1.05,2.65,5.0]:
			for x in [-3.4,0,3.4]:
				for landing_x in [-3.85,0,3.85]:
					for landing_z in [3.3,5.4,8.0]:
						var side: float=1 if team==0 else -1
						g.possession=team;g.ball_pos=Vector3(x,3.04,side*depth);g.attack_tip=false;g.hitter_action="attack";g.incoming_kind="spike";g.out_of_system=1;g.aim=Vector2(1,1)
						var target:=Vector3(landing_x,.105,-side*landing_z)
						var old: float=preload("res://src/winning_shot.gd").flight_seconds(g,target,.44,Net.TOP+Net.BALL_RADIUS+.018)
						var start:=Time.get_ticks_usec();var shot:=Delivery.solve(g,target,old,.96,false);maximum_us=maxi(maximum_us,Time.get_ticks_usec()-start)
						if not shot.has("spin"):continue
						var v:=Flight.velocity_to(g.ball_pos,target,shot.seconds,shot.spin)
						var end:=Flight.advance(g.ball_pos,v,shot.spin,shot.seconds)
						check(end[0].distance_to(target)<.025,"physical landing accurate")
						check(Delivery.crossing(g.ball_pos,target,shot.seconds,shot.spin)>=Net.TOP+Net.BALL_RADIUS+.0179,"legal tape clearance both sides")
						check(absf(shot.spin.x)<=12.001,"reduced topspin")
						if depth==.55:
							check(v.y<0,"tight high contact leaves hand downward")
							check(shot.seconds<old,"tight powerful hit is faster")
						if x==-3.4 and landing_x==0:samples.append({"team":team,"depth":depth,"target_depth":landing_z,"seconds":shot.seconds,"vertical_velocity":v.y,"speed":v.length(),"spin":str(shot.spin)})
	for kind in ["tip","free","serve","block"]:
		g.incoming_kind=kind
		check(Delivery.solve(g,Vector3(0,.105,-5),.8,1,false)=={"seconds":.8},"other ball kinds untouched")
	g.incoming_kind="spike";g.attack_tip=true
	check(Delivery.solve(g,Vector3(0,.105,-5),.8,1,false)=={"seconds":.8},"tip trajectory untouched")
	var p=g.players[0];p.select_variant("attack","attack_pin_left");p.intent.task="approach";p.rotation.y=PI;p.velocity=Vector3(0,0,-4);p.looping=true
	check(p.choose_gait(4,"walk")=="run","pin approach uses running cycle")
	p.tick(.1,false,false);check(p.pin_reference_load>0,"original pin performance now receives running backswing")
	p.pin_run104=true
	var State=preload("res://src/online_state.gd")
	var snapshot: Dictionary=State.decode(State.encode(State.capture(g)))
	check(State.valid(snapshot) and snapshot.players[0].pin_run104,"online snapshot preserves approach state")
	var f:=FileAccess.open("res://docs/attack104-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors,"maximum_planning_us":maximum_us,"samples":samples},"\t"));f.close()
	print("ATTACK104 PHYSICS ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," max_us=",maximum_us," errors=",errors);quit(0 if errors.is_empty() else 1)

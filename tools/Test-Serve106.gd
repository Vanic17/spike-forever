extends SceneTree
const Aim=preload("res://src/serve_target106.gd")
const Flight=preload("res://src/ball_flight.gd")
var errors: Array=[]
var checks:=0
func check(value: bool,message: String):
	checks+=1
	if not value:errors.append(message)
func _initialize():call_deferred("run")
func run():
	assert("serve106" in OS.get_environment("APPDATA"))
	var random:=RandomNumberGenerator.new();random.seed=1062026
	var table: Array=[]
	for skill in [40,70,99]:
		for floating in [true,false]:
			for arrow in ["UP","UP_RIGHT","NEUTRAL","DOWN_RIGHT","DOWN"]:
				for power in [.7,1.0,1.1,1.2,1.5]:
					var r:=Aim.radius(skill,arrow,power,floating)
					var inside:=0
					for i in 4000:
						if Aim.draw(random,r).length()<=r:inside+=1
					var fraction:=inside/4000.0
					check(absf(fraction-.9)<.025,"r90 coverage skill=%d arrow=%s power=%s"%[skill,arrow,str(power)])
					table.append({"skill":skill,"float":floating,"arrow":arrow,"power":power,"r90":r,"observed_inside":fraction})
	check(Aim.radius(90,"NEUTRAL",1,true)<Aim.radius(60,"NEUTRAL",1,true),"higher skill narrows scatter")
	check(Aim.radius(85,"NEUTRAL",1,true)<Aim.radius(85,"NEUTRAL",1,false),"float narrower than jump")
	var previous:=0.0
	for arrow in ["UP","UP_RIGHT","NEUTRAL","DOWN_RIGHT","DOWN"]:
		var r:=Aim.radius(85,arrow,1,true);check(r>previous,"all five arrows monotonically widen scatter");previous=r
	previous=0
	for power in [.7,.8,.9,1.0,1.1,1.2,1.3,1.5,2.0]:
		var c:=Aim.power_coefficient(power);check(c>=previous,"unbounded monotone overload");previous=c
	var outside:=0
	for i in 4000:
		var target:=Vector3(4.49,.105,-8.99);var offset:=Aim.draw(random,Aim.radius(70,"DOWN",1.2,false));target+=Vector3(offset.x,0,offset.y)
		if absf(target.x)>4.5 or absf(target.z)>9:outside+=1
	check(outside>2000,"line targets are not corrected back into court")
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	g.server=0;g.reset_rally();g.use_player_stats=true
	var p=g.players[g.server_index(0)];var original: Dictionary=p.roster_identity.duplicate(true)
	p.roster_identity={"id":"serve106_test","ratings":{"battuta":70}};g.form99={"arrows":{"serve106_test":"UP"}}
	check(g.serve_target106.parameters(g,1).skill==70,"raw skill, no double arrow adjustment")
	check(g.serve_target106.parameters(g,1).arrow=="UP","already locked match arrow")
	g.use_player_stats=false;check(g.serve_target106.parameters(g,1).skill==85 and g.serve_target106.parameters(g,1).arrow=="NEUTRAL","stats-off preserves equal baseline")
	p.roster_identity=original
	for mode in [0,2,3]:
		g.camera_mode=mode;g.set_camera();g.serve_aim106=Vector3(0,.105,-4.5)
		var event:=InputEventKey.new();event.physical_keycode=KEY_L;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
		g.serve_target106.input_tick(g,.1)
		event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
		var expected_right:=Vector3(g.camera.global_basis.x.x,0,g.camera.global_basis.x.z).normalized()
		check((g.serve_aim106-Vector3(0,.105,-4.5)).dot(expected_right)>.30,"screen-relative target input camera %d"%mode)
	g.camera_mode=0;g.set_camera()
	g.serve_aim106=Vector3(2,.105,-7);g.press_action("alternate")
	check(g.serve_locked106 and g.charging and g.serve_type==0,"type press locks cursor and starts unchanged float charge")
	g.serve_target106.accept(g,Vector3(-3,.105,-2),0);check(g.serve_aim106.x==2,"absolute network aim cannot move locked cursor")
	g.clock_time+=g.charge_seconds("serve")*1.1;g.release_action()
	var frozen: Dictionary=g.serve_target106.sample.duplicate(true)
	g.serve_target106.freeze(g,2);check(g.serve_target106.sample==frozen,"sample exactly once, including repeat toss safety retreat")
	var state: Dictionary=g.online_session.State.capture(g)
	var decoded: Dictionary=g.online_session.State.decode(g.online_session.State.encode(state))
	check(decoded.serve_locked106 and decoded.serve_aim106.distance_to(g.serve_aim106)<.002,"aim and lock survive network encoding")
	var nominal:=Vector3(0,.105,-6)
	g.ball_pos=Vector3(0,3.1,10.8);g.serve_type=1
	var delivery:=preload("res://src/serve_delivery105.gd").full(g,nominal,false,float(Aim.settings().nominal_clearance))
	var nets:=0
	for i in 300:
		var offset:=Aim.draw(random,Aim.radius(40,"DOWN",1.3,false))
		var endpoint:=nominal+Vector3(offset.x,0,offset.y)
		if endpoint.z<-.1 and preload("res://src/attack_delivery104.gd").crossing(g.ball_pos,endpoint,delivery.seconds,delivery.spin)<2.543:nets+=1
	check(nets>0 and nets<250,"net faults emerge from sampled flight, not a second fault lottery")
	var serves: Array=[]
	for team in 2:
		for type in 2:
			for power in [.7,1.0,1.1]:
				g.server=team;g.reset_rally();g.input_team=team;g.serve_type=type;g.serve_power=power;g.rng.seed=10600+team*100+type
				g.serve_aim106=Vector3(1,.105,-6 if team==0 else 6);g.serve_target106.freeze(g,power);g.begin_serve_toss()
				for i in 500:
					g.step(1.0/120)
					if g.phase!="SERVE":break
				check(g.phase in ["RECEIVE","CPU_RECEIVE"],"serve real toss/contact team%d type%d power%s"%[team,type,str(power)])
				var expected: Vector3=g.serve_target106.sample.sampled
				var landing:=Flight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,.105)
				check(not landing.is_empty() and landing.point.distance_to(expected)<.04,"physical integrator lands on uncorrected sampled endpoint")
				serves.append({"team":team,"type":type,"power":power,"speed":g.ball_vel.length(),"target":expected,"spin":g.flight_spin,"sample":g.serve_target106.sample})
	var far:=0;var close:=0
	g.possession=1;g.receiver=6;g.winner_team=-1
	for i in 120:
		g.ball_pos=Vector3(0,1.1,-5);g.ball_vel=Vector3(0,-5,-20);g.flight_spin=Vector3.ZERO;g.phase="CPU_RECEIVE"
		preload("res://src/defense_failure106.gd").shank(g)
		var hit:=Flight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,.105)
		if not hit.is_empty():
			if absf(hit.point.x)>2.4:far+=1
			else:close+=1
	check(far>75 and close>0,"failed contacts mostly travel laterally far, with occasional short drops")
	var tuning: Dictionary=Aim.settings().cpu.duplicate(true)
	var before:=0.0;var after:=0.0
	for mode in 2:
		Aim.config.cpu=tuning.duplicate(true)
		if mode==0:Aim.config.cpu.timing_scale=1.0;Aim.config.cpu.extra_reaction_seconds=0;Aim.config.cpu.hesitation_chance=.035
		g.rng.seed=106;g.incoming_kind="spike";g.incoming_power=.9;g.incoming_out=false
		for i in 4000:
			g.cpu_defense.prepare(g)
			var quality: float=0 if g.cpu_defense.frozen else g.cpu_defense.quality(.9,.9)
			if mode==0:before+=quality/4000
			else:after+=quality/4000
	Aim.config.cpu=tuning
	check(after<before and before-after<.09,"CPU defense slightly weaker, bounded change")
	Aim.config.enabled=false;g.server=0;g.reset_rally();g.input_team=0;g.use_player_stats=false;g.press_action("action");g.apply_direction(Vector2.RIGHT,.01)
	check(not g.serve_locked106 and g.aim==Vector2.RIGHT,"legacy switch restores left-stick charge aiming")
	g.clock_time+=g.charge_seconds("serve")*.8;g.release_action()
	check(g.serve_target106.sample.is_empty(),"legacy fallback does not sample a new target")
	Aim.config.enabled=true
	var report:={"pass":errors.is_empty(),"checks":checks,"errors":errors,"dispersion":table,"real_serves":serves,"shanks":{"far":far,"short":close},"cpu_average_quality":{"before":before,"after":after}}
	FileAccess.open("res://docs/serve106-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SERVE106 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)

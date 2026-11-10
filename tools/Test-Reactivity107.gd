extends SceneTree
const Read=preload("res://src/defense_read107.gd")
const Aim=preload("res://src/serve_target106.gd")
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message)
func _initialize():call_deferred("run")
func run():
	assert("review107" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	g.server=0;g.reset_rally();g.possession=1;g.phase="CPU_RECEIVE";g.receiver=6;g.incoming_kind="spike";g.attack_tip=false;g.winner_team=-1;g.incoming_out=false
	g.ball_pos=Vector3(0,3.2,.6);g.flight_spin=Vector3.ZERO
	var target:=Vector3(3.8,.105,-3.1)
	g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,target,.29,g.flight_spin)
	for i in range(6,12):
		g.players[i].position=Vector3(-2+(i-6)*.8,0,-6.8);g.players[i].velocity=Vector3.ZERO;g.players[i].play("ready",1,true)
	var impossible: Dictionary=Read.assess(g)
	check(impossible.miss,"hard short downward spike cannot be saved from deep defence")
	for power in [.3,.89,.99,1.2]:
		g.incoming_power=power;g.charge=power
		check(Read.assess(g).miss,"physical miss independent of charge percentage "+str(power))
	g.cpu_defense.prepare(g);check(g.cpu_defense.physical_miss,"CPU captures physical read before assistance")
	var velocity: Vector3=g.ball_vel;var position: Vector3=g.ball_pos
	check(not g.queue_recovery(true),"an impossible drive cannot be rescued by a late assisted dive")
	g.receive_ball();check(g.phase=="LOOSE" and g.ball_pos==position and g.ball_vel==velocity,"unreachable drive continues physically to floor, no score/velocity override")
	g.phase="CPU_RECEIVE";g.players[6].position=g.players[6].stance_for_contact("receive",g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,g.players[6].contact_local("receive").y).point)
	check(not Read.assess(g).miss,"an already positioned defender may still defend that same shot")
	g.attack_tip=true;check(not Read.assess(g).miss,"soft tips are not treated as unstoppable hard drives")
	g.attack_tip=false;g.incoming_kind="block";check(not Read.assess(g).miss,"ordinary block rebounds retain recoveries")
	g.receiver=6;g.possession=1;g.last_touch=1;g.flight_target=Vector3(5.5,1,-6);g.flight_left=.65
	check(Read.chase(g,6),"own touched ball just outside sideline is a chase")
	g.last_touch=0;check(not Read.chase(g,6),"opponent ball heading out is left alone")
	g.last_touch=1;g.flight_target.x=8;check(not Read.chase(g,6),"do not chase far beyond the bounded free zone")
	var radii: Array=[]
	for power in [1.0,1.05,1.1,1.2,1.4]:
		var r: float=Aim.radius(85,"NEUTRAL",power,false)
		var old: float=(.25+.012*14)*1.12*(1.11+1.3*pow(maxf(0,power*100-100)/20,1.5))
		check(is_equal_approx(r,old) if power==1 else r>old,"overcharge-only dispersion increase at "+str(power))
		radii.append({"power":power,"before":old,"after":r})
	var arm_names: Array[String]=g.clips.approach105.names
	var clip=g.clips.approach105
	var a: Array=g.players[0].normalized_pose("source:approach105",clip.duration*.4,false)
	var b: Array=g.players[0].normalized_pose("source:approach105",clip.duration*.9,false)
	check(a[arm_names.find("RightHand")].origin.distance_to(b[arm_names.find("RightHand")].origin)>.2,"backswing is a late moving preparation, not a held pose")
	check(preload("res://src/motion_prototypes.gd").supplement(g.clips).has_animation("approach105"),"updated run is native AnimationTree-compatible")
	var old=load("res://assets/active/native_motion105.res")
	var fresh=load("res://assets/active/native_motion107.res")
	for name in old.get_animation_list():
		if name=="approach105":continue
		var a_clip: Animation=old.get_animation(name);var b_clip: Animation=fresh.get_animation(name)
		var identical: bool=a_clip.get_track_count()==b_clip.get_track_count()
		for track in a_clip.get_track_count():
			if a_clip.track_get_key_count(track)!=b_clip.track_get_key_count(track):identical=false;break
			for key in a_clip.track_get_key_count(track):
				if a_clip.track_get_key_value(track,key)!=b_clip.track_get_key_value(track,key):identical=false;break
		check(identical,"unchanged native contact/jump animation "+str(name))
	check(not FileAccess.get_file_as_string("res://src/main.gd").contains("recovery_action = \"recovery\"") and not FileAccess.get_file_as_string("res://src/legend_contact.gd").contains("recovery_action=\"recovery\""),"no late backward-bagher activation in exhibition or career")
	var file:=FileAccess.open("res://docs/reactivity107-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors,"physical_read":impossible,"radii":radii},"  "));file.close()
	print("REACTIVITY107 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)

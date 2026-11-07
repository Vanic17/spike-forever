extends SceneTree
const Policy=preload("res://src/online_command89.gd")
const State=preload("res://src/online_state.gd")
var g
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);push_error("ONLINE89 "+label)
func _initialize():call_deferred("run")
func run():
	assert("online89" in OS.get_environment("APPDATA").to_lower())
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.self_test=true;g.set_process(false);g.set_physics_process(false)
	for p in g.players:p.set_process(false)
	for frame in 3:await process_frame
	var net=g.online_session;net.active=true;net.playing=true;net.test_mode=true;g.demo=false;g.paused=false
	g.rally_serial=9;g.shot_serial=12;g.attack_serial=5;g.clock_time=100.0
	# An extra attacking X used to fall through to jump_manual_wall(),
	# commanding the OTHER human's blockers in the shared host simulation.
	for side in 2:
		g.phase="ATTACK" if side==0 else "CPU_ATTACK";g.possession=side;g.input_team=side;g.armed=true;g.block_commanded=false
		g.press_action("action")
		check(not g.block_commanded,"attacking side cannot jump opponent wall "+str(side))
		g.armed=false;g.charging=true;g.press_action("action")
		check(not g.block_commanded,"repeated attack press during charge cannot jump opponent wall "+str(side))
		g.charging=false
	g.phase="ATTACK";g.possession=0;g.input_team=0;g.armed=false
	var attack=Policy.capture(g,0,"action")
	check(Policy.valid(g,0,attack),"current attack accepted")
	g.phase="CPU_SET";g.possession=1;g.shot_serial+=1
	var count: int=g.block_jump_log.size()
	net.apply_command(0,1,"action",true,{"direction":Vector2.ZERO},-1,attack)
	check(g.block_jump_log.size()==count and not g.block_commanded,"delayed attacking X cannot turn into defensive jump")
	var block=Policy.capture(g,0,"action")
	check(block.intent=="block" and Policy.valid(g,0,block),"intentional early wall jump accepted")
	net.apply_command(0,2,"action",true,{"direction":Vector2.ZERO},-1,block)
	check(g.block_commanded and g.block_jump_log.size()>count,"intentional defensive X still jumps the controlled wall")
	g.block_commanded=false
	g.rally_serial+=1
	check(not Policy.valid(g,0,block),"old rally wall command refused")
	var malformed: Dictionary=block.duplicate();malformed.clock=[]
	check(not Policy.valid(g,0,malformed),"malformed command timestamps refused")
	g.rally_serial-=1
	# Receiving and setting commands carry the flight they were chosen for.
	g.phase="RECEIVE";g.possession=0;g.armed=false;g.receive_deadline=100.1
	var receive=Policy.capture(g,0,"action")
	check(Policy.valid(g,0,receive),"current receiving command accepted")
	g.phase="SET";g.shot_serial+=1
	check(not Policy.valid(g,0,receive),"reception cannot become a set or wall command")
	var setting=Policy.capture(g,0,"alternate")
	check(Policy.valid(g,0,setting),"fast set accepted as set")
	g.armed=true
	var early_attack=Policy.capture(g,0,"action",setting)
	check(early_attack.intent=="attack" and Policy.valid(g,0,early_attack),"first tempo charge buffered during armed set")
	g.phase="ATTACK";g.attack_serial+=1;g.armed=false
	check(Policy.valid(g,0,early_attack),"same first tempo buffer survives set-to-attack boundary")
	check(not Policy.valid(g,0,setting),"old set cannot be applied as attack")
	g.attack_serial+=1
	check(not Policy.valid(g,0,early_attack),"old first tempo charge refused on next attack")
	net.applying_context89={"intent":"receive","clock":99.94}
	check(is_equal_approx(net.receive_remaining89(.01),.07),"receive timing uses displayed authoritative clock")
	net.applying_context89={}
	check(is_equal_approx(net.receive_remaining89(.01),.01),"no timing adjustment outside receiving command")
	for side in 2:
		net.local_side=side;g.camera_mode=0;g.phase="SERVE";g.set_camera()
		check(is_equal_approx(g.camera.position.z,20.5*(1 if side==0 else -1)) and is_equal_approx(g.camera.fov,48.0),"low serve camera mirrored for peer "+str(side))
		g.phase="ATTACK";g.set_camera()
		check(is_equal_approx(g.camera.position.z,18.4*(1 if side==0 else -1)) and is_equal_approx(g.camera.fov,42.0),"low rally camera mirrored for peer "+str(side))
	# At a snapshot bracket midpoint the ball, controls, clips and procedural
	# cursors must all describe the same presentation time.
	net.local_side=1;g.possession=0;g.phase="SET";g.clock_time=101;g.phase_time=.2;g.test_contacts=0;g.armed=true
	g.players[0].play("set",1,false);g.players[0].animation_time=.10;g.players[0].middle_load=.4;g.players[0].pin_reference_load=.2
	var a=State.capture(g);a.arrived=Time.get_ticks_msec()/1000.0
	g.phase="ATTACK";g.clock_time=101.04;g.phase_time=.01;g.test_contacts=1;g.armed=false
	g.players[0].play("attack",1,false);g.players[0].animation_time=.01;g.players[0].middle_load=.6;g.players[0].pin_reference_load=.4
	var b=State.capture(g);b.seq=int(a.seq)+1;b.arrived=a.arrived
	net.buffered=[a,b];net.render_clock84=101.02
	State.render(net,.001)
	check(g.phase=="SET" and g.armed,"client does not anticipate ATTACK controls before ball contact")
	check(g.players[0].clip_name=="set" and g.test_contacts==0,"client does not anticipate attack clip or hit sound")
	var blend: float=(g.clock_time-101)/.04
	check(absf(g.players[0].middle_load-lerpf(.4,.6,blend))<.00001,"middle load is sampled, not advanced twice")
	check(absf(g.players[0].pin_reference_load-lerpf(.2,.4,blend))<.00001,"approach load synchronized to authoritative pose")
	net.render_clock84=101.04;State.render(net,0)
	check(g.phase=="ATTACK" and g.players[0].clip_name=="attack" and g.test_contacts==1,"client switches action at contact boundary")
	var roundtrip=State.decode(State.encode(b))
	check(State.valid(roundtrip) and roundtrip.rally_serial==b.rally_serial and is_equal_approx(roundtrip.players[0].pin_reference_load,.4),"new event context and approach pose survive wire codec")
	net.playing=false;net.active=false
	FileAccess.open("res://docs/online89-command-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"cases":"stale receive/set/attack/block, wrong-team jump, first-tempo input buffering, receive clock, snapshot boundary and pose codec"},"  "))
	print("ONLINE89 COMMANDS ","PASS" if failures.is_empty() else "FAIL"," ",checks," ",failures);g.free();quit(0 if failures.is_empty() else 1)

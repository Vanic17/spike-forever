extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var guest_mode:=false
var age:=0.0
var submitted:=false
var stage:=-1
var sent:=-1
var next_at:=0.0
var done_at:=-1.0
var contacts:=0
var errors: Array=[]
func _initialize():guest_mode="--guest" in OS.get_cmdline_user_args();Engine.max_fps=120;call_deferred("setup")
func setup():
	assert("middle102" in OS.get_environment("APPDATA"))
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.replay.enabled=false;g.match_audio.enabled=false;net=g.online_session;net.test_mode=true;net.port=26802
	net.menu.open()
	if guest_mode:net.menu.code.text=Code.encode("127.0.0.1",26802,0x123102);net.menu.join.pressed.emit()
	else:net.menu.create.pressed.emit();net.generation=0x123102;net.menu.host.clubs.match_rotations[0]=3;net.choose(net.menu.choice(),true)
func finish(ok: bool,message: String):
	if not ok:errors.append(message)
	FileAccess.open("res://docs/middle102-online-"+("guest" if guest_mode else "host")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"contacts":contacts,"sequence":"one hand / normal / normal / normal / one hand"},"  "))
	print("ONLINE102 ","PASS" if errors.is_empty() else "FAIL"," ","guest" if guest_mode else "host"," ",message);quit(0 if errors.is_empty() else 1)
func fixture():
	stage+=1;g.rotations=[3,3];g.server=0;g.reset_rally();g.started=true;g.self_test=true;g.demo=false;g.paused=false
	g.rally_serial=1000+stage;g.shot_serial+=1;g.phase="CPU_SET";g.possession=1;g.setter=11;g.touches=[0,1];g.armed=false;g.pass_quality=1;g.out_of_system=1;g.set_dir=1;g.planned_visual_key=""
	var p=g.players[11];p.play("idle",1,true);p.select_variant("set","set");p.rotation.y=PI/2;p.setting_yaw=PI/2;p.left_handed=false;p.blend_left=0
	g.flight_target=Vector3(0,p.contact_local("set").y,-.72);g.ball_pos=g.flight_target+Vector3(0,1.3,0);g.flight_left=.65;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.65,Vector3.ZERO);g.airborne=true
	p.position=p.stance_for_contact("set",g.flight_target);p.target=p.position
	var random:=RandomNumberGenerator.new()
	for seed_value in 100:
		random.seed=seed_value
		if random.randf()<.25:g.rng.seed=seed_value;break
	next_at=age+.25
func _process(dt):
	if net==null:return false
	age+=dt
	if age>35:finish(false,"timeout stage "+str(stage));return false
	if not guest_mode and done_at>=0:
		if age>done_at+.7:finish(errors.is_empty(),"five guest first-tempo commands, three-play interval")
		return false
	if guest_mode and net.guest!=0 and not submitted:submitted=true;net.menu.host.clubs.match_rotations[0]=3;net.choose(net.menu.choice(),true)
	if not guest_mode and not net.playing and net.ready_flags[0] and net.ready_flags[1]:net.start_match();g.set_process(false);g.set_physics_process(false);next_at=age+.5
	if not net.playing:return false
	if guest_mode:
		g.set_process(false);g.set_physics_process(false)
		if g.rally_serial==1999:contacts=5;finish(g.first_set_cooldown102[1]==3,"cooldown and pose synchronized after five remote sets");return false
		var current: int=g.rally_serial-1000
		if current>=0 and current<5 and current!=sent and g.phase=="CPU_SET" and not g.armed:
			sent=current;Input.action_release("down");Input.action_press("up");var button:=InputEventJoypadButton.new();button.button_index=JOY_BUTTON_A;button.pressed=true;g._unhandled_input(button)
		return false
	g.clock_time+=dt
	if done_at>=0:
		if age>done_at+.7:finish(errors.is_empty(),"five guest first-tempo commands, three-play interval")
		return false
	if stage<0 and age>=next_at:fixture()
	elif stage>=0 and g.armed and g.phase=="CPU_SET":
		var p=g.players[11];var one: bool=p.variant_names.get("set","")=="set_first96"
		if one!=(stage in [0,4]):errors.append("wrong variant stage "+str(stage)+" "+str(p.variant_names))
		p.position=p.stance_for_contact("set",g.flight_target);p.target=p.position;p.rotation.y=p.setting_yaw;p.blend_left=0;p.prepare_contact("set",0);g.ball_pos=g.flight_target
		g.set_ball();contacts+=1
		if g.phase!="CPU_ATTACK":errors.append("set contact failed stage "+str(stage)+" "+g.phase)
		if g.first_set_cooldown102[1]!=[3,2,1,0,3][stage]:errors.append("wrong cooldown stage "+str(stage))
		if stage==4:g.rally_serial=1999;done_at=age
		else:next_at=age+.3
	elif stage>=0 and g.phase=="CPU_ATTACK" and age>next_at:fixture()
	return false

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
func _initialize():
	guest_mode="--guest" in OS.get_cmdline_user_args();Engine.max_fps=120;call_deferred("setup")
func setup():
	assert("strikes96" in OS.get_environment("APPDATA"))
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.replay.enabled=false;g.match_audio.enabled=false;net=g.online_session;net.test_mode=true;net.port=26779
	net.menu.open()
	if guest_mode:
		net.menu.code.text=Code.encode("127.0.0.1",26779,0x123496);net.menu.join.pressed.emit()
	else:
		net.menu.stats_pick.select(1);net.menu.stats_pick.item_selected.emit(1);net.menu.create.pressed.emit();net.generation=0x123496;net.menu.host.clubs.match_rotations[0]=3;net.choose(net.menu.choice(),true)
func finish(ok: bool,message: String):
	if not ok:errors.append(message)
	FileAccess.open("res://docs/strokes96-online-"+("guest" if guest_mode else "host")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"transport":"ENet loopback","new_second_touches":contacts,"database":g.use_player_stats},"  "))
	print("ONLINE96 ","PASS" if errors.is_empty() else "FAIL"," ","guest" if guest_mode else "host"," ",message);quit(0 if errors.is_empty() else 1)
func fixture():
	stage+=1;g.rotations=[3,3];g.server=0;g.reset_rally();g.started=true;g.self_test=true;g.demo=false;g.paused=false
	g.rally_serial=1000+stage;g.shot_serial+=1;g.phase="CPU_SET";g.possession=1;g.setter=11;g.touches=[0,1];g.armed=false;g.pass_quality=1;g.out_of_system=1
	var p=g.players[11];p.position=Vector3(0,0,-.55);p.rotation.y=0;p.setting_yaw=PI/2;p.left_handed=stage==1;p.blend_left=0;p.play("set",1,false)
	var name: String=["dump_back96","dump_down96","dump_forward96"][stage]
	g.flight_target=Vector3(0,g.clips[name].contact_offset.y*p.height_scale90,-.55)
	g.ball_pos=g.flight_target+Vector3(.1,1.1,-.1);g.flight_left=.55;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.55,Vector3.ZERO);g.airborne=true
	next_at=age+.30
func _process(dt: float):
	if net==null:return false
	age+=dt
	if age>28:finish(false,"timeout stage "+str(stage));return false
	if not guest_mode and done_at>=0:
		if age>done_at+.7:finish(errors.is_empty(),"three remote actions committed as second touches")
		return false
	if guest_mode and net.guest!=0 and not submitted:
		submitted=true;net.menu.host.clubs.match_rotations[1]=3;net.choose(net.menu.choice(),true)
	if not guest_mode and not net.playing and net.ready_flags[0] and net.ready_flags[1]:
		net.start_match();g.set_process(false);g.set_physics_process(false);next_at=age+.5
	if not net.playing:return false
	if guest_mode:
		g.set_process(false);g.set_physics_process(false)
		if g.rally_serial==1999:contacts=g.test_contacts;finish(contacts>=3 and g.use_player_stats,"three guest triangle commands synchronized");return false
		var current: int=g.rally_serial-1000
		if current>=0 and current<3 and current!=sent and g.phase=="CPU_SET" and not g.armed:
			sent=current
			for action in ["left","right","up","down"]:Input.action_release(action)
			Input.action_press(["right","down","left"][current])
			var button:=InputEventJoypadButton.new();button.button_index=JOY_BUTTON_Y;button.pressed=true;g._unhandled_input(button)
		return false
	g.clock_time+=dt
	if done_at>=0:
		if age>done_at+.7:finish(errors.is_empty(),"three remote actions committed as second touches")
		return false
	if stage<0 and age>=next_at:fixture()
	elif stage>=0 and g.setter_second96>0:
		var expected: int=[2,3,7][stage]
		if g.setter_second96!=expected:errors.append("wrong direction "+str(stage))
		var p=g.players[11];p.position=p.target;p.rotation.y=p.setting_yaw;p.blend_left=0;g.ball_pos=g.flight_target
		g.dump_ball();contacts+=1
		if g.last_touch!=1 or g.phase!="RECEIVE":errors.append("guest contact failed "+str(stage))
		if stage==2:g.rally_serial=1999;done_at=age
		else:next_at=age+.30
	elif stage>=0 and g.phase=="RECEIVE" and age>next_at:fixture()
	return false

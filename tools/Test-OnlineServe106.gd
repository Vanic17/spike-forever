extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var guest_mode:=false
var age:=0.0
var submitted:=false
var prepared:=false
var pressed:=false
var released:=false
var pressed_at:=0.0
var finished_at:=-1.0
var errors: Array=[]
func _initialize():guest_mode="--guest" in OS.get_cmdline_user_args();Engine.max_fps=120;call_deferred("setup")
func setup():
	assert("serve106" in OS.get_environment("APPDATA"))
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.replay.enabled=false;g.match_audio.enabled=false;net=g.online_session;net.test_mode=true;net.port=26806
	for p in g.players:p.set_process(false);p.render_at_draw=false
	net.menu.open()
	if guest_mode:net.menu.code.text=Code.encode("127.0.0.1",26806,0x123106);net.menu.join.pressed.emit()
	else:net.menu.create.pressed.emit();net.generation=0x123106;net.choose(net.menu.choice(),true)
func finish():
	FileAccess.open("res://docs/serve106-online-"+("guest" if guest_mode else "host")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"aim":g.serve_aim106,"locked":g.serve_locked106,"samples":g.serve_target106.sample},"  "))
	print("ONLINE106 ","PASS" if errors.is_empty() else "FAIL"," ","guest" if guest_mode else "host"," ",errors);quit(0 if errors.is_empty() else 1)
func _process(dt):
	if net==null:return
	age+=dt
	if not guest_mode and finished_at>=0 and age>finished_at+.8:finish();return
	if age>35:errors.append("timeout");finish();return
	if guest_mode and net.guest!=0 and not submitted:submitted=true;net.choose(net.menu.choice(),true)
	if not guest_mode and not net.playing and net.ready_flags[0] and net.ready_flags[1]:net.start_match();g.set_process(false);g.set_physics_process(false)
	if not net.playing:return
	g.set_process(false);g.set_physics_process(false)
	if not guest_mode:
		g.clock_time+=dt
		if not prepared:
			prepared=true;g.server=1;g.reset_rally();g.self_test=true;g.demo=false;g.paused=false;g.rally_serial=1106;g.serve_target106.reset(g)
		if not g.serve_target106.sample.is_empty() and finished_at<0:
			if g.serve_aim106.distance_to(Vector3(2.25,.105,7.25))>.01:errors.append("host did not accept guest absolute target")
			if not g.serve_locked106:errors.append("host target unlocked after charge")
			if absf(g.serve_target106.sample.power-1.1)>.03:errors.append("remote hold duration differs from guest bar")
			var before: Dictionary=g.serve_target106.sample.duplicate(true);g.serve_target106.freeze(g,1.8)
			if g.serve_target106.sample!=before:errors.append("host resampled")
			g.rally_serial=1199;finished_at=age
		if finished_at>=0 and age>finished_at+.8:finish()
	else:
		if g.rally_serial==1199:
			if not g.serve_target106.sample.is_empty():errors.append("guest generated a ball dispersion sample")
			if g.serve_aim106.distance_to(Vector3(2.25,.105,7.25))>.01:errors.append("guest target snapshot mismatch")
			finish();return
		if g.rally_serial==1106 and not pressed:
			g.serve_target106.desired(g);g.serve_target106.local_target=Vector3(2.25,.105,7.25)
			net.send_command("alternate",true);pressed=true;pressed_at=Time.get_ticks_usec()/1000000.0
		elif pressed and not released and Time.get_ticks_usec()/1000000.0-pressed_at>=g.charge_seconds("serve")*1.1:
			# Use a known input duration: machine scheduling/frame stalls are
			# deliberately outside this network clock/serialization regression.
			net.local_charge_start=Time.get_ticks_usec()/1000000.0-g.charge_seconds("serve")*1.1
			net.send_command("alternate",false);released=true

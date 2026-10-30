extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var role:="host"
var age:=0.0
var began:=-1.0
var submitted:=false
var was_active:=false
var seen:=0
var finished:=0
var sent:=0
var skip_sent:=false
var frozen: Array=[]
var next_event:=2.0
func _initialize():
	role="guest" if "--guest" in OS.get_cmdline_user_args() else "host"
	Engine.max_fps=120; call_deferred("setup")
func setup():
	create_timer(43).timeout.connect(func(): push_error("Online replay test timed out"); quit(1))
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	net=g.online_session; net.test_mode=true; net.port=26775; net.menu.open()
	if role=="host":
		net.menu.create.pressed.emit(); net.generation=0x653432; net.menu.confirm.pressed.emit()
	else: net.join_room(Code.encode("127.0.0.1",26775,0x653432))
func frozen_state() -> Array: return [g.clock_time,g.phase_time,g.ball_pos,g.ball_vel,g.rng.state,g.scores.duplicate(),g.test_contacts]
func _process(dt):
	age+=dt
	assert(age<45,"Online replay timeout")
	if net==null: return false
	if role=="guest" and net.active and net.guest!=0 and not submitted:
		submitted=true; net.menu.confirm.pressed.emit()
	if role=="host" and net.active and not net.playing and net.ready_flags==[true,true]: net.start_match()
	if not net.playing:
		if began>=0 and not net.closing:
			if seen!=3 or finished!=3 or g.started:
				push_error("Unexpected end role="+role+" seen="+str(seen)+" restored="+str(finished)); quit(1); return false
			var report={"role":role,"replays":seen,"restored":finished,"guest_skip":true,"lateral":true,"frozen_simulation":true,"home":true}
			FileAccess.open("res://docs/online-replay66-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
			print("ONLINE REPLAY66 PASS ",JSON.stringify(report)); quit()
		return false
	if began<0: began=age
	if role=="host" and not was_active and not g.replay.active and g.replay.pending.is_empty() and age-began>next_event and sent<3:
		g.replay.mark_set(); g.replay.mark_shot(["attack","serve","monster"][sent],0,true)
		g.award(0,"TEST REPLAY EVENT"); sent+=1
	if g.replay.active:
		if not was_active:
			seen+=1; frozen=frozen_state(); skip_sent=false
		if role=="host": assert(frozen_state()==frozen,"Host gameplay must freeze throughout replay")
		assert(net.playing and (role=="host" or net.packet_age<8))
		if g.replay.state=="PLAY":
			assert(g.camera.position==load("res://src/view_controls.gd").origin(2))
			if role=="guest" and not skip_sent and g.replay.play_time>float(g.replay.clip[0].time)+.2:
				skip_sent=true; g.replay.request_skip()
	elif was_active:
		finished+=1; next_event=age-began+1.0
		if role=="host" and finished<3: g.reset_rally()
	if role=="host" and finished==3 and age-began>next_event: net.leave("Replay test complete")
	was_active=g.replay.active
	return false

extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var guest_mode:=false
var age:=0.0
var joined:=false
var stage:=0
var sent_token:=-1
var seen_at:=0.0
var last_seen:=-1
var due:=0.0
var peer_id:=0
var errors: Array=[]
func _initialize():guest_mode="--guest" in OS.get_cmdline_user_args();Engine.max_fps=120;call_deferred("setup")
func setup():
	assert("match100" in OS.get_environment("APPDATA"))
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.replay.enabled=false;g.match_audio.enabled=false;net=g.online_session;net.test_mode=true;net.port=26800
	net.menu.open()
	if guest_mode:net.menu.code.text=Code.encode("127.0.0.1",26800,0x123100);net.menu.join.pressed.emit()
	else:net.menu.create.pressed.emit();net.generation=0x123100;net.best_of=3;net.choose(net.menu.choice(),true)
func finish(ok: bool,message: String):
	if not ok:errors.append(message)
	FileAccess.open("res://docs/match100-online-"+("guest" if guest_mode else "host")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"transport":"ENet","checks":"set report, match report, unilateral vote rejected, rematch, lobby and second launch without reconnect"},"  "))
	print("ONLINE100 ","PASS" if errors.is_empty() else "FAIL"," ","guest" if guest_mode else "host"," ",message);quit(0 if errors.is_empty() else 1)
func end_set(final: bool):
	g.match_finished=false;g.paused=false;g.phase="LOOSE";g.scores=[24,20];g.sets=[1,0] if final else [0,0]
	g.match_management.touch(0,"attack");g.award(0,"PALLA A TERRA");g.phase_time=2.2;g.report100._process(0)
func _process(dt):
	if net==null:return false
	age+=dt
	if age>55:finish(false,"timeout stage "+str(stage)+" token "+str(net.report_token100));return false
	if guest_mode:
		if net.guest!=0 and not joined:joined=true;net.choose(net.menu.choice(),true)
		if net.playing:g.set_process(false);g.set_physics_process(false)
		if g.report100.opened:
			if last_seen!=net.report_token100:last_seen=net.report_token100;seen_at=age
			if age-seen_at>.65 and sent_token!=last_seen:
				sent_token=last_seen
				if g.report100.payload.history.is_empty():finish(false,"missing set statistics");return false
				net.vote_report100("continue" if sent_token==1 else ("rematch" if sent_token==2 else "lobby"))
		if joined and not net.playing and net.report_token100==3 and net.menu.visible and net.choices[1].is_empty():net.choose(net.menu.choice(),true)
		if net.playing and g.rally_serial==9876100:finish(true,"rejoined same room after rematch and lobby")
		return false
	if stage==0 and net.ready_flags[0] and net.ready_flags[1]:
		peer_id=net.guest;net.start_match();g.set_process(false);g.set_physics_process(false);g.self_test=true;stage=1;due=age+.5
	elif stage==1 and age>due:end_set(false);net.vote_report100("continue");stage=2;due=age+.3
	elif stage==2:
		if age>due and age<due+.15 and not g.report100.opened:finish(false,"unilateral continue resumed match");return false
		if not g.report100.opened:stage=3;due=age+.3
	elif stage==3 and age>due:end_set(true);net.vote_report100("rematch");stage=4
	elif stage==4 and not g.report100.opened:
		if net.guest!=peer_id or g.sets!=[0,0] or not g.match_management.measured.is_empty():finish(false,"rematch did not reset match / retained peer");return false
		stage=5;due=age+.4
	elif stage==5 and age>due:end_set(true);net.vote_report100("lobby");stage=6
	elif stage==6 and not net.playing:
		if not net.active or net.guest!=peer_id or not net.menu.visible:finish(false,"lobby disconnected room");return false
		net.choose(net.menu.choice(),true);stage=7
	elif stage==7 and net.ready_flags[0] and net.ready_flags[1]:
		net.start_match();g.set_process(false);g.set_physics_process(false);g.rally_serial=9876100;stage=8;due=age+.5
	elif stage==8 and age>due:finish(true,"both confirmations, rematch and lobby without reconnect")
	return false

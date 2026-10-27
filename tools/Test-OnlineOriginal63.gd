extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var role:="host"
var age:=0.0
var seq_action:=""
var initial_contacts:=0
var observed: Dictionary={}
var completed:=false
var switched:=false
var finalize:=false
var match_started:=false
var pause_sent:=false
var resume_sent:=false
var pause_seen:=false
var submitted:=false
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg=="--guest": role="guest"
	Engine.max_fps=120
	call_deferred("setup")
func setup():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	net=g.online_session; net.test_mode=true; net.port=26771
	net.menu.open()
	Input.action_press("block_left",1); Input.action_press("block_right",1)
	var db=load("res://src/league.gd").new()
	if role=="host":
		net.menu.format.select(0); net.menu.format.item_selected.emit(0)
		net.menu.target.select(1); net.menu.target.item_selected.emit(1)
		net.menu.create.pressed.emit(); check(net.active,"host button bind")
		net.generation=0x123456; net.menu.scope.select(1); net.menu.scope.item_selected.emit(1)
		net.menu.own_team.select(0); net.menu.own_team.item_selected.emit(0)
		net.menu.host.clubs.match_rotations[0]=3
		net.menu.confirm.pressed.emit()
	else:
		net.menu.code.text=Code.encode("127.0.0.1",26771,0x123456); net.menu.join.pressed.emit(); check(net.active,"join button dial")
func check(ok: bool, message: String):
	if not ok: push_error("ONLINE ORIGINAL63 FAIL "+role+" "+message); quit(1)
func _process(dt: float):
	if net==null: return false
	age+=dt
	if age>65: check(false,"timeout phase="+g.phase+" contacts="+str(g.test_contacts)); return false
	if role=="guest" and net.active and net.guest!=0 and not submitted:
		submitted=true
		net.menu.own_team.select(1); net.menu.own_team.item_selected.emit(1)
		net.menu.own_kit.select(1); net.menu.own_kit.item_selected.emit(1)
		net.menu.formation.pressed.emit()
		var clubs=net.menu.host.clubs
		var options=clubs.formation_dialog.find_children("*","OptionButton",true,false)
		options[0].select(2); options[0].item_selected.emit(2)
		for pick in options:
			if pick.get_parent() is VBoxContainer and pick.get_parent().get_child(0) is Label and pick.get_parent().get_child(0).text.begins_with("OPP"):
				for i in pick.item_count:
					if "· OH ·" in pick.get_item_text(i): pick.select(i); pick.item_selected.emit(i); break
		clubs.formation_dialog.confirmed.emit(); clubs.formation_dialog.hide()
		net.menu.confirm.pressed.emit()
	if role=="host" and net.active and not net.playing and net.ready_flags[0] and net.ready_flags[1]:
		check(net.choices[1].roster[2].role=="outside_hitter","guest OH placed in opposite slot")
		check(net.choices[1].rotation==2 and net.choices[1].kit=="away","guest formation and kit synchronized")
		net.menu.launch.pressed.emit(); check(net.playing,"host start button"); match_started=true
	if not net.playing:
		if net.closing: return false
		if match_started and not completed:
			completed=true; check(not g.started,"return home")
			print("ONLINE ORIGINAL63 PASS ",role," contacts=",g.test_contacts," observed=",observed," home=true snapshot_max=",net.snapshot_max_bytes," pause=",pause_seen)
			FileAccess.open("res://docs/online-original63-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify({"role":role,"contacts":g.test_contacts,"observed":observed,"home":not g.started,"pause":pause_seen,"snapshot_max":net.snapshot_max_bytes,"version":"0.63.0"},"  "))
			quit()
		return false
	match_started=true
	check(not g.use_player_stats,"original mode default")
	check(g.match_best_of==1 and g.match_points==15,"host match settings synchronized")
	if role=="guest" and age>9 and not pause_sent: pause_sent=true; net.pause_request(true)
	if g.paused: pause_seen=true
	if role=="guest" and age>10 and pause_sent and not resume_sent: resume_sent=true; net.pause_request(false)
	if g.paused: return false
	var side: int=net.local_side
	check((g.camera.position.z>0)==(side==0),"own-side camera")
	var phase: String=g.phase.trim_prefix("CPU_")
	if g.server==side and phase=="SERVE" and not g.toss_active and not g.serve_adjusting:
		if not g.charging and g.phase_time>.4: net.send_command("alternate" if side==0 else "action",true)
		elif g.charging and g.current_charge()>=.72: net.send_command("alternate" if side==0 else "action",false)
	if g.possession==side:
		if phase=="RECEIVE" and not g.armed and g.receive_deadline-g.clock_time<.24:
			net.send_command("action",true); net.send_command("action",false)
		elif phase=="SET" and not g.armed:
			net.send_command("action",true); net.send_command("action",false)
		elif phase=="ATTACK" and not g.armed:
			if not g.charging: net.send_command("action",true)
			elif g.current_charge()>=.70: net.send_command("action",false)
	elif phase=="ATTACK" and not g.block_commanded and g.flight_left<.24:
		net.send_command("action",true); net.send_command("action",false)
	if role=="host":
		for contact in g.contact_log: observed[str(int(contact.player/6))+":"+contact.action]=true
		if not switched and age>13:
			switched=true; g.server=1; g.reset_rally(); print("ONLINE ORIGINAL63 host switched server to guest")
		if switched and age>35 and not finalize:
			for failure in g.rally_events:
				if failure.kind=="online_miss": print("ONLINE ORIGINAL63 DIAGNOSTIC ",failure)
			finalize=true; check(net.last_sequence[1]>0,"remote commands received")
			check(pause_seen,"remote pause synchronized")
			check(observed.has("1:power"),"guest jump serve physical contact")
			check(observed.has("0:float"),"host float serve physical contact")
			check(observed.has("0:receive") and observed.has("1:receive"),"both receptions are human")
			check(observed.has("0:set") or observed.has("1:set"),"real set contact")
			g.scores=[14,0]; g.sets=[0,0]; g.phase="SERVE"; g.award(0,"TEST MATCH END")
	return false

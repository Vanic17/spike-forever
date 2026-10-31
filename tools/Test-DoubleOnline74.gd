extends SceneTree
## Two actual ENet peers exercise the existing host-authoritative substitution path.
var g
var net
var role:="host"
var age:=0.0
var began:=-1.0
var stage:=0
var submitted:=false
var original: Array=[]
var reserve_o:=""
var reserve_s:=""
var observed:=false
var returned:=false
var finished:=-1.0
var checks:=0
func _initialize():
	role="guest" if "--guest" in OS.get_cmdline_user_args() else "host"
	Engine.max_fps=90; call_deferred("setup")
func check(ok: bool,message: String):
	checks+=1
	if not ok: push_error("DOUBLE ONLINE74 "+role+" "+message); quit(1)
func setup():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false
	net=g.online_session; net.test_mode=true; net.port=26780
	if role=="host":
		net.host_room(); net.generation=0x741234; net.choose(net.menu.choice(),true)
	else: net.join_room(load("res://src/room_code.gd").encode("127.0.0.1",26780,0x741234))
func _process(dt):
	age+=dt
	if net==null: return false
	if age>32: check(false,"timeout stage="+str(stage)); return false
	if role=="guest" and net.active and net.guest!=0 and not submitted: submitted=true; net.choose(net.menu.choice(),true)
	if role=="host" and net.active and not net.playing and began<0 and net.ready_flags==[true,true]:
		check(net.start_match(),"start actual online match")
		g.rotations=[0,3]; g.reset_rally(); g.match_management.lock_lineup(); g.paused=true; net.broadcast_management()
	var m=g.match_management
	if not net.playing: return false
	if began<0:
		began=age; original=m.current[1].duplicate()
		var choices_o: Array=m.bench(1).filter(func(p): return p.role=="opposite")
		var choices_s: Array=m.bench(1).filter(func(p): return p.role=="setter")
		check(not choices_o.is_empty() and not choices_s.is_empty(),"actual club contains two reserves")
		reserve_o=str(choices_o[0].id); reserve_s=str(choices_s[0].id)
	if m.counts[1]==2:
		observed=true
		check(m.setter_slot(1)==2 and m.current[1][2]==reserve_s and m.current[1][5]==reserve_o,"paired identities and regista synchronized")
		check(m.counts[0]==0 and m.current[0]==m.starters[0],"guest never changes host lineup")
	if m.counts[1]==4:
		returned=true
		check(m.current[1]==original and m.setter_slot(1)==5,"both starters and role restored")
		if finished<0: finished=age
	if role=="guest" and age-began>.7:
		if stage==0:
			net.request_double_substitution(reserve_s,reserve_o); stage=1
		elif stage==1 and age-began>1.2:
			check(m.counts[1]==0 and m.current[1]==original,"wrong-role pair rejected atomically by host")
			m.menu.open(); m.menu.open_double(); m.menu.choose_double_opposite(reserve_o); m.menu.choose_double_setter(reserve_s)
			check(not m.menu.confirm_button.disabled,"guest pair menu can confirm")
			m.menu.apply_double(); stage=2
		elif stage==2 and observed:
			g.paused=true; m.menu.open(); m.menu.open_double()
			check(m.menu.double_return and not m.menu.confirm_button.disabled,"guest return menu receives authoritative pair")
			m.menu.apply_double(); stage=3
		elif stage==3 and returned:
			net.request_double_substitution(reserve_o,reserve_s); stage=4
	if finished>0 and age-finished>.8:
		check(observed and returned and m.counts[1]==4 and m.current[1]==original,"second use rejected; four total ordinary changes")
		check(g.scores==[0,0] and g.test_contacts==0,"no scoring or physics change during request")
		var report={"role":role,"checks":checks,"entry_and_return":true,"count":m.counts[1],"invalid_pair_atomic":true,"second_use_rejected":true,"identity_and_role_synchronized":true,"host_untouched":true}
		FileAccess.open("res://docs/double74-online-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("DOUBLE ONLINE74 PASS ",JSON.stringify(report)); quit()
	return false

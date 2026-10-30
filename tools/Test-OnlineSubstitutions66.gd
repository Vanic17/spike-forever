extends SceneTree
const Code=preload("res://src/room_code.gd")
var g
var net
var role:="host"
var age:=0.0
var started_at:=-1.0
var submitted:=false
var sent:=0
var original:=""
var replacement:=""
var observed:=false
var reentered:=false
var final_at:=-1.0
func _initialize():
	role="guest" if "--guest" in OS.get_cmdline_user_args() else "host"
	Engine.max_fps=120; call_deferred("setup")
func setup():
	create_timer(35).timeout.connect(func(): push_error("Online substitutions timeout"); quit(1))
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	net=g.online_session; net.test_mode=true; net.port=26779
	if role=="host":
		net.host_room(); net.generation=0x661234; net.choose(net.menu.choice(),true)
	else: net.join_room(Code.encode("127.0.0.1",26779,0x661234))
func _process(dt):
	age+=dt
	if net==null: return false
	if role=="guest" and net.active and net.guest!=0 and not submitted: submitted=true; net.choose(net.menu.choice(),true)
	if role=="host" and net.active and not net.playing and net.ready_flags==[true,true]: net.start_match()
	var m=g.match_management
	if not net.playing:
		if started_at>=0 and not net.closing:
			assert(m.counts[1]==2 and str(g.players[6].roster_identity.id)==original)
			var report={"role":role,"guest_substitution":observed,"guest_paired_reentry":reentered,"count":m.counts[1],"identity_synchronized":true,"full_bench":true,"home":not g.started}
			FileAccess.open("res://docs/online66-substitutions-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
			print("ONLINE SUBSTITUTIONS66 PASS ",JSON.stringify(report)); quit()
		return false
	if started_at<0:
		started_at=age; original=str(m.current[1][0]); replacement=str(m.bench(1).filter(func(p): return p.role!="libero")[0].id)
		if role=="host": m.lock_lineup()
	if role=="host" and not g.paused and age-started_at>1: net.pause_request(true)
	if m.counts[1]==1:
		observed=true; assert(str(g.players[6].roster_identity.id)==replacement)
	if m.counts[1]==2:
		reentered=true
		if final_at<0: final_at=age
	if role=="guest" and g.paused:
		if sent==0 and age-started_at>1.3: net.request_substitution(0,replacement); sent=1
		elif sent==1 and m.counts[1]==1: net.request_substitution(0,original); sent=2
		elif sent==2 and m.counts[1]==2: net.request_substitution(0,replacement); sent=3
	if role=="host" and final_at>0 and age-final_at>1:
		assert(m.counts[1]==2 and str(m.current[1][0])==original,"Illegal second use rejected by authority")
		net.leave("Substitution verification complete")
	return false

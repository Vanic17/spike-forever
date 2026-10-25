extends SceneTree
var g
var net
var guest:=false
var seen:=false
var sent:=false
var age:=0.0
func _initialize():
	guest="--guest" in OS.get_cmdline_user_args(); Engine.max_fps=120; call_deferred("setup")
func setup():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	net=g.online_session; net.test_mode=true; net.port=26773
	net.multiplayer.peer_connected.connect(func(_id): seen=true)
	if guest: net.join_room(net.Code.encode("127.0.0.1",26773,0x345678))
	else: net.host_room(); net.generation=0x345678
func _process(dt: float):
	if net==null: return false
	age+=dt
	if age>15: push_error("LOBBY LEAVE51 FAIL timeout"); quit(1)
	if guest and net.guest!=0 and not sent: sent=true; seen=true; net.leave("Guest leaves lobby")
	if seen and not net.active and not net.closing:
		print("LOBBY LEAVE51 PASS ","guest" if guest else "host"," / explicit leave delivered / port closed")
		g.free(); quit()
	return false

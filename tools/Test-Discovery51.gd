extends SceneTree
var g
var net
var age:=0.0
var completed:=false
func _initialize(): call_deferred("setup")
func setup():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_physics_process(false); g.set_process(false); g.self_test=true
	net=g.online_session; net.port=26779
	if net.host_room()!=OK: push_error("DISCOVERY51 FAIL bind"); quit(1)
func _process(dt: float):
	if net==null or completed: return false
	age+=dt
	if (not net.public_ip.is_empty() and net.mapper==null) or age>12:
		net.update_code(false)
		var internet: bool=not net.room_code.is_empty() and not net.Code.decode(net.room_code).is_empty()
		var mapped: bool=net.mapping_result.get("ok",false)
		net.update_code(true)
		var lan: bool=not net.Code.decode(net.room_code).is_empty()
		completed=true; finish(internet,lan,mapped)
	return false

func finish(internet: bool,lan: bool,mapped: bool):
	net.leave("Test completato")
	await create_timer(.3).timeout
	var probe:=ENetMultiplayerPeer.new(); var free_port: bool=probe.create_server(26779,1)==OK
	probe.close()
	FileAccess.open("res://docs/discovery51-report.json",FileAccess.WRITE).store_string(JSON.stringify({"internet_code":internet,"lan_code":lan,"upnp_mapping":mapped,"port_closed":free_port},"  "))
	print("DISCOVERY51 ","PASS" if internet and lan and free_port else "FAIL"," public-IP invite=",internet," LAN invite=",lan," UPnP=",mapped," port cleanup=",free_port)
	g.free(); quit(0 if internet and lan and free_port else 1)

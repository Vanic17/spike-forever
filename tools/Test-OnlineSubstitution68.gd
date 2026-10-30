extends SceneTree
var game
var net
var role:="host"
var age:=0.0
var playing_age:=0.0
var selected:=false
var requested:=false
var scene_seen:=false
var finished_age:=-1.0
var started:=false
var last_scene_state:=""
var passed:=false
func _initialize():
	if "--guest" in OS.get_cmdline_user_args(): role="guest"
	Engine.max_fps=90; call_deferred("run")
func run():
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	net=game.online_session; net.test_mode=true; net.port=26778; game.substitution_scene.testing=true
	net.menu.open()
	if role=="host":
		net.menu.create.pressed.emit(); net.generation=0x686868
		net.menu.scope.select(1); net.menu.scope.item_selected.emit(1); net.menu.confirm.pressed.emit()
	else:
		net.menu.code.text=load("res://src/room_code.gd").encode("127.0.0.1",26778,0x686868); net.menu.join.pressed.emit()
func check(ok: bool,message: String):
	if not ok: push_error("ONLINE68 FAIL "+role+" "+message); quit(1)
func _process(dt: float):
	if net==null: return false
	age+=dt
	if passed:
		if age-finished_age>2.0: quit()
		return false
	if age>40: check(false,"timeout playing=%s active=%s state=%s pending=%d scene_seen=%s phase=%s"%[net.playing,game.substitution_scene.active,game.substitution_scene.state,game.substitution_scene.pending.size(),scene_seen,game.phase]); return false
	if role=="guest" and net.active and net.guest!=0 and not selected:
		selected=true; net.menu.own_team.select(1); net.menu.own_team.item_selected.emit(1); net.menu.confirm.pressed.emit()
	if role=="host" and net.active and not net.playing and net.ready_flags[0] and net.ready_flags[1]:
		check(net.start_match(),"start"); game.match_management.lock_lineup(); net.broadcast_management()
	if not net.playing: return false
	started=true; playing_age+=dt
	var presentation: String=str([game.substitution_scene.active,game.substitution_scene.state,game.substitution_scene.pending.size()])
	if presentation!=last_scene_state: print("SCENE68 ",role," ",presentation); last_scene_state=presentation
	if role=="guest" and playing_age>.8 and not requested:
		requested=true; net.pause_request(true)
		for person in game.match_management.bench(1):
			if game.match_management.eligibility(1,0,person.id).is_empty(): net.request_substitution(0,person.id); break
	if game.substitution_scene.active:
		scene_seen=true
		check(not game.players[6].visible,"only replaced live actor hidden")
	if scene_seen and not game.substitution_scene.active:
		if finished_age<0: finished_age=age
		if age-finished_age>.15 and not game.paused:
			check(game.match_management.counts[1]==1,"one legal substitution shared")
			check(game.players[6].visible and not game.paused,"actor and gameplay restored")
			check(game.test_contacts==0 and game.scores==[0,0],"no gameplay advanced in scene")
			FileAccess.open("res://docs/patch68-online-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify({"role":role,"scene":scene_seen,"substitutions":game.match_management.counts,"restored":true},"  "))
			print("ONLINE SUBSTITUTION68 PASS ",role," reliable guest request / legal count / synchronized scene / resume"); passed=true; finished_age=age
	return false

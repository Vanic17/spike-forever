extends SceneTree
const League=preload("res://src/league.gd")
var game
var net
var role:="host"
var age:=0.0
var started_age:=-1.0
var chosen:=false
var fatigue_sent:=false
var switched:=false
var checked_on:=false
var finished:=false
var original_hash:=""
var original_ids: Array=[]
func check(ok: bool,label: String):
	if not ok:push_error("ONLINE82 FAIL "+role+" "+label);quit(1)
func _initialize():
	if "--guest" in OS.get_cmdline_user_args():role="guest"
	Engine.max_fps=60;call_deferred("run")
func run():
	check(ProjectSettings.globalize_path("user://").contains("online82"),"isolated fixture")
	var db=League.new();var club: Dictionary=db.teams[0]
	for p in club.roster:
		p.name=("Host " if role=="host" else "Guest ")+p.name
		p.ratings.difesa=23 if role=="host" else 91
		for key in preload("res://src/player_stats_gameplay.gd").KEYS:p.ratings[key]=23 if role=="host" else 91
		p.appearance.skin_tone="chiara" if role=="host" else "scura"
		p.appearance.hair_style="corti" if role=="host" else "mossi"
		p.jersey_number=19 if role=="host" else 28
		p.dominant_hand="right" if role=="host" else "left"
		p.serve_preference="jump" if role=="host" else "float"
		check(db.save(p)==OK,"save isolated personal override")
	original_hash=FileAccess.get_sha256(League.PATH)
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	net=game.online_session;net.test_mode=true;net.port=26761;net.menu.open()
	if role=="host":
		check(net.host_room()==OK,"bind test host")
		net.generation=0x828282;net.update_code(true);net.use_player_stats=true;net.use_fatigue=true
		net.choose(net.menu.choice(),true)
	else:
		var invite:=preload("res://src/room_code.gd").display(preload("res://src/room_code.gd").encode("127.0.0.1",26761,0x828282))
		check(invite.length()==13 and net.join_room(invite)==OK,"connect using thirteen typed characters")
func _process(dt: float):
	if finished or net==null:return false
	age+=dt
	if age>30:check(false,"timeout "+net.info);return false
	if role=="guest" and net.active and net.guest!=0 and not chosen:
		chosen=true;net.choose(net.menu.choice(),true)
	if role=="host" and not net.playing and net.ready_flags==[true,true]:
		check(net.start_match(),"start shared club match");game.paused=true
	if not net.playing:return false
	if started_age<0:started_age=age
	var elapsed:=age-started_age
	var manager=game.match_management
	var host: Dictionary=manager.identity(manager.current[0][0]);var guest: Dictionary=manager.identity(manager.current[1][0])
	check(host.id!=guest.id and host.database_id==guest.database_id,"same database ID has separate session identity")
	check(host.name.begins_with("Host ") and guest.name.begins_with("Guest "),"personal names synchronized separately")
	check(host.ratings.difesa==23 and guest.ratings.difesa==91,"host/guest ratings survive management setup")
	check(game.PlayerStats.rating(game,0,"difesa")==23 and game.PlayerStats.rating(game,6,"difesa")==91,"gameplay reads correct per-team database")
	for key in game.PlayerStats.KEYS:check(game.PlayerStats.rating(game,0,key)==23 and game.PlayerStats.rating(game,6,key)==91,"all six skill values preserved "+key)
	check(host.ratings.generale==23 and guest.ratings.generale==91,"weighted overall recalculated consistently")
	check(host.appearance.skin_tone=="chiara" and guest.appearance.skin_tone=="scura" and guest.appearance.hair_style=="mossi","personal appearance preserved")
	check(host.jersey_number==19 and guest.jersey_number==28,"personal jersey numbers preserved")
	check(host.dominant_hand=="right" and guest.dominant_hand=="left" and guest.serve_preference=="float","hand and serve preference preserved")
	check(FileAccess.get_sha256(League.PATH)==original_hash,"online never writes received roster to local overrides")
	if role=="host" and not fatigue_sent and elapsed>.3:
		fatigue_sent=true;manager.conditions[host.id].fatigue=37;manager.update_condition_vector();net.broadcast_management()
		preload("res://src/arena_events82.gd").show(game,"MONSTER BLOCK",0)
	if not checked_on and elapsed>1:
		check(game.use_player_stats,"database ON propagated")
		check(absf(game.match_condition[0]-37)<.1 and game.match_condition[6]==0,"fatigue independent for duplicate players")
		check(game.arena_visuals.sponsors.event_kind=="MONSTER BLOCK","Home LED event synchronized over actual RPC")
		checked_on=true
	if role=="host" and not switched and elapsed>1.8:
		switched=true;net.begin_match.rpc_id(net.guest,net.choices,3,15,false,false);net.begin_local(net.choices,3,15,false,false);game.paused=true
	if elapsed>2.7:
		check(not game.use_player_stats and not net.use_fatigue,"database OFF and fatigue OFF propagated")
		FileAccess.open("res://docs/online82-database-"+role+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"same_club":true,"host_defense":host.ratings.difesa,"guest_defense":guest.ratings.difesa,"different_session_ids":host.id!=guest.id,"database_modes":[true,false],"local_overrides_unchanged":FileAccess.get_sha256(League.PATH)==original_hash,"compact_invite":true},"  "))
		finished=true;print("ONLINE82 DATABASE PASS ",role);create_timer(.8).timeout.connect(func():quit())
	return false

extends SceneTree
const Code=preload("res://src/room_code.gd")
const Catalog=preload("res://src/online_catalog108.gd")
class Ack108 extends Node:
	var last:=-2
	@rpc("any_peer","call_remote","reliable",0)
	func seen(value: int) -> void:last=value
var g
var net
var guest_mode:=false
var age:=0.0
var submitted:=false
var staged:=false
var finished_at:=-1.0
var errors: Array=[]
var local_digest:=""
var observed:=false
var stage108:=-1
var next_stage108:=0.0
var seen108: Array=[]
var durations108: Array=[]
var sync108: Ack108
var announced108:=false
var client_done108:=-1.0
func _initialize():guest_mode="--guest" in OS.get_cmdline_user_args();Engine.max_fps=120;call_deferred("setup")
func setup():
	assert("online108" in OS.get_environment("APPDATA"))
	g=load("res://src/main.tscn").instantiate();root.add_child(g);g.replay.enabled=false;g.match_audio.enabled=false;net=g.online_session;net.test_mode=true;net.port=26808
	sync108=Ack108.new();sync108.name="DatabaseTest108";g.add_child(sync108)
	for p in g.players:p.set_process(false);p.render_at_draw=false
	# Contrasting local databases, only in memory. The guest must never supply
	# its 40/99 values, names, hands, heights or serve preference to the match.
	for team in net.menu.host.clubs.db.teams:
		for p in team.roster:
			p.ratings.schiacciata=40 if guest_mode else 91;p.ratings.battuta=40 if guest_mode else 87
			p.name=("GUEST-" if guest_mode else "HOST-")+str(p.id)
			p.dominant_hand="left" if guest_mode else "right";p.height_cm=180 if guest_mode else 205
	local_digest=Catalog.digest({"teams":net.menu.host.clubs.db.teams})
	net.menu.open()
	if guest_mode:net.menu.code.text=Code.encode("127.0.0.1",26808,0x123108);net.menu.join.pressed.emit()
	else:net.menu.create.pressed.emit();net.generation=0x123108;net.use_player_stats=true;net.choose(net.menu.choice(),true)
func finish():
	if Catalog.digest({"teams":net.menu.host.clubs.db.teams})!=local_digest:errors.append("local database mutated")
	FileAccess.open("res://docs/online108-"+("guest" if guest_mode else "host")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"catalog_hash":net.catalog_hash108,"attack_seconds":g.charge_seconds("attack"),"serve_seconds":g.charge_seconds("serve"),"observed":observed,"stages":seen108,"durations":durations108,"local_database_unchanged":Catalog.digest({"teams":net.menu.host.clubs.db.teams})==local_digest},"  "))
	print("DATABASE108 ","PASS" if errors.is_empty() else "FAIL"," ","guest" if guest_mode else "host"," ",errors);quit(0 if errors.is_empty() else 1)
func _process(dt):
	if net==null:return
	age+=dt
	if guest_mode and client_done108>=0 and age>client_done108:finish();return
	if not guest_mode and finished_at>=0 and age>finished_at+1.0:finish();return
	if age>40:errors.append("timeout");finish();return
	if guest_mode and net.guest!=0 and not submitted:
		if not net.catalog_ready108:errors.append("formation enabled before catalog verified")
		var value: Dictionary=net.menu.choice()
		if value.roster.any(func(p):return not str(p.name).begins_with("HOST-")):errors.append("guest menu uses local roster")
		# Prove host rejects supplied ratings even with a valid player ID.
		value=value.duplicate(true)
		for p in value.roster:p.ratings.schiacciata=1;p.name="FORGED"
		net.choose(value,true);submitted=true
	if not guest_mode and not net.playing and net.ready_flags[0] and net.ready_flags[1] and net.catalog_ack108:net.start_match();g.set_process(false);g.set_physics_process(false)
	if not net.playing:return
	g.set_process(false);g.set_physics_process(false)
	if not guest_mode:
		g.clock_time+=dt
		if stage108<5 and sync108.last>=stage108 and age>=next_stage108:
			stage108+=1;next_stage108=age+.65
			staged=true;g.self_test=true;g.paused=false;g.phase="CPU_ATTACK";g.possession=1;g.hitter=7;g.destination=[1,0,2,3,1,0][stage108];g.use_player_stats=stage108<5;g.stats_release_flight=.23 if g.destination==1 else .9;g.stats_release_clock=g.clock_time;g.rally_serial=1108+stage108;g.armed=false;g.charging=false;g.airborne=false
			if stage108==5:finished_at=age+1.0
			for side in 2:
				for p in net.choices[side].roster:
					if p.ratings.schiacciata!=91 or not str(p.name).begins_with("HOST-"):errors.append("guest values accepted by authority")
			observed=true
	else:
		if not announced108:announced108=true;sync108.seen.rpc_id(1,-1)
		if g.rally_serial>=1108 and g.rally_serial<=1113 and g.phase=="CPU_ATTACK" and not g.rally_serial in seen108:
			seen108.append(g.rally_serial)
			observed=true
			if g.destination!=[1,0,2,3,1,0][g.rally_serial-1108]:errors.append("actual attack zone missing from snapshot")
			if g.players[g.hitter].roster_identity.ratings.schiacciata!=91:errors.append("runtime player uses guest stats")
			if not is_equal_approx(g.charge_seconds("attack"),g.charge_attack108):errors.append("client ignores authoritative charge duration")
			var local_expected: float=g.PlayerStats.charge_seconds(g,"attack") if g.use_player_stats else g.Timing.ATTACK_CHARGE_SECONDS
			if absf(local_expected-g.charge_attack108)>.002:errors.append("host/client effective ratings or central duration differ")
			# Poison local fields: bar duration must still be the host's value.
			var saved: float=g.players[g.hitter].roster_identity.ratings.schiacciata
			g.players[g.hitter].roster_identity.ratings.schiacciata=1
			if not is_equal_approx(g.charge_seconds("attack"),g.charge_attack108):errors.append("local database can change client bar")
			g.players[g.hitter].roster_identity.ratings.schiacciata=saved
			durations108.append({"zone":g.destination,"stats":g.use_player_stats,"seconds":g.charge_seconds("attack"),"expected":local_expected})
			sync108.seen.rpc_id(1,g.rally_serial-1108)
			if net.connections108.recent.is_empty():errors.append("successful join not remembered")
			if seen108.size()==6:client_done108=age+.3

extends SceneTree
class FakeTactics:
	static func front(_i,_rotation):return true
	static func role_for(_game,i):return "MB1" if i==7 else "OH1"
class FakeGame:
	extends RefCounted
	var Tactics=FakeTactics
	var middle_decoy: Dictionary={"index":1,"cue":"","target":Vector3.ZERO}
	var phase:="SET"
	var possession:=0
	var rally_serial:=0
	var pass_quality:=1.0
	var rng:=RandomNumberGenerator.new()
	var flight_left:=.3
	var rotations: Array=[0,0]
	var players: Array=[]
	var online:=false
	var jumps:=0
	var clock_time:=1.0
	var block_time:=-100.0
	var block_quality:=0.0
	func _init():for i in 12:players.append({"position":Vector3(0,0,-.65)})
	func network_match():return online
	func cpu_team(team):return team==1
	func request_block_jump(_i,_time):jumps+=1;return true
	func log_rally_event(_kind,_data):pass
func _initialize():
	var g:=FakeGame.new();var read=preload("res://src/middle_read100.gd").new();g.rng.seed=100427
	for i in 1000:
		g.rally_serial=i;g.middle_decoy.cue=str(i);g.flight_left=.4;read.update(g)
		g.flight_left=.15;read.update(g);var before: int=g.jumps;read.update(g);assert(g.jumps==before,"one read per cue")
	assert(g.jumps>=170 and g.jumps<=270,"occasional read, not constant")
	var commits: int=g.jumps;g.online=true
	assert(read.route(g,7,Vector3.ONE)==Vector3.ONE,"online route remains manual")
	for i in 1000:g.rally_serial+=1;read.update(g)
	assert(g.jumps==commits,"online walls never auto jump")
	g.online=false;g.pass_quality=.4
	for i in 100:g.rally_serial+=1;read.update(g)
	assert(g.jumps==commits,"poor passes do not fool middle")
	read.commits=true;read.used=false;read.cue=str(g.rally_serial)+":"+str(g.middle_decoy.cue);g.possession=1
	assert(read.route(g,1,Vector3.ONE)==Vector3.ONE,"human middle route remains manual")
	FileAccess.open("res://docs/match100-middle-read.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"trials":1000,"commits":commits,"online_automatic_jumps":0},"  "))
	print("MIDDLE READ100 PASS commits=",commits,"/1000, online=0");quit()

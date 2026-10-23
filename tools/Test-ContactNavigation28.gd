extends SceneTree
const Navigation = preload("res://src/contact_navigation.gd")
class Fixture extends RefCounted:
	var players: Array[Node3D]=[]
	var extra: Dictionary={}
	var dive_motions: Dictionary={}
	var phase := "SET"
	var shot_serial := 1
	var clock_time := 0.0
	func _init() -> void:
		for i in 12:
			var player := Node3D.new()
			player.position=Vector3(-6+float(i%6)*2,0,11.5 if i<6 else -11.5)
			players.append(player)
	func compute_footprint_points(index: int) -> Array[Vector3]:
		var points: Array[Vector3]=[players[index].position]
		for offset in extra.get(index,[]): points.append(players[index].position+offset)
		return points
	func dispose() -> void:
		for player in players: player.free()
var checks := 0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		push_error(message)
		quit(1)
		assert(value,message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var clear_times: Array[float]=[]
	var blocked_times: Array[float]=[]
	for team in 2:
		var game := Fixture.new()
		var navigation := Navigation.new()
		var actor := team*6+5
		var side := 1.0 if team==0 else -1.0
		var start := Vector3(-3,0,side*3)
		var goal := Vector3(3,0,side*3)
		game.players[actor].position=start
		check(navigation.route(game,actor,goal)==goal,"Clear route changed destination")
		check(navigation.routes.is_empty(),"Clear route allocated a grid cache")
		check(is_equal_approx(navigation.length_for(game,actor,goal),6),"Clear length wrong")
		for frame in 600:
			game.clock_time+=1.0/120
			var began := Time.get_ticks_usec()
			navigation.route(game,actor,goal)
			clear_times.append(float(Time.get_ticks_usec()-began)/1000)
		game.players[team*6].position=Vector3(-0.6,0,side*3)
		game.players[team*6+1].position=Vector3(1.0,0,side*3.8)
		game.extra[team*6]=[Vector3(0.7,0,0),Vector3(-0.6,0,0)]
		var distance := navigation.length_for(game,actor,goal)
		check(is_finite(distance) and distance>6,"Two-body detour did not exist")
		var cached_time := -INF
		var rebuilds := 0
		for frame in 600:
			game.clock_time+=1.0/120
			var began := Time.get_ticks_usec()
			var waypoint: Vector3=navigation.route(game,actor,goal)
			blocked_times.append(float(Time.get_ticks_usec()-began)/1000)
			check(navigation.segment_clear(start,waypoint,navigation.samples(game,actor),0.98),"Unsafe cached shortcut")
			if navigation.routes.has(actor) and navigation.routes[actor].time!=cached_time:
				cached_time=navigation.routes[actor].time
				rebuilds+=1
		check(rebuilds<=43,"120Hz calls rebuilt grid every frame")
		for frame in 600:
			game.clock_time+=1.0/120
			var previous: Vector3=game.players[actor].position
			var waypoint: Vector3=navigation.route(game,actor,goal)
			var next := previous.move_toward(waypoint,4.0/120)
			check(navigation.segment_clear(previous,next,navigation.samples(game,actor),0.98),"Physical route crossed teammate footprint")
			game.players[actor].position=next
			if next.distance_to(goal)<0.03: break
		check(game.players[actor].position.distance_to(goal)<0.03,"Detour failed to reach contact")
		game.players[actor].position=start
		game.players[team*6+2].position=goal
		navigation.reset()
		check(is_inf(navigation.length_for(game,actor,goal)),"Occupied contact returned finite length")
		check(navigation.route(game,actor,goal)==start,"Occupied contact allowed body penetration")
		# A newly moving body blocks an already cached shortcut immediately.
		game.players[team*6+2].position=Vector3(5,0,side*10)
		var waypoint: Vector3=navigation.route(game,actor,goal)
		game.players[team*6+2].position=start.lerp(waypoint,0.7)
		var revised: Vector3=navigation.route(game,actor,goal)
		check(navigation.segment_clear(start,revised,navigation.samples(game,actor),0.98),"Moving body ignored before cache refresh")
		game.dispose()
	clear_times.sort()
	blocked_times.sort()
	print("CONTACT_NAVIGATION28 PASS: ",checks," checks / both teams / standing and prone footprints / physical detours / occupied endpoint / live obstacle / clear p95_ms=",clear_times[int(clear_times.size()*0.95)]," blocked p95_ms=",blocked_times[int(blocked_times.size()*0.95)]," blocked max_ms=",blocked_times.back())
	quit(0)

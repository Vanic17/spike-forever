extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.demo=false
	var results: Array=[]
	for crossing in [false,true]:
		game.reset_rally()
		game.set_phase("LOOSE")
		for i in 12:
			game.players[i].position=Vector3(-3.2+(i%3)*3.2,0,(1.0+(i%6)/3*2.0)*(1 if i<6 else -1))
			game.players[i].target=game.players[i].position
			game.players[i].velocity=Vector3.ZERO
			game.players[i].acceleration=Vector3.ZERO
			game.players[i].steering_ready=false
		game.players[5].position=Vector3(4,0,9)
		game.players[5].target=game.players[5].position
		game.players[3].position=Vector3(-2,0,6)
		game.players[3].target=Vector3(2,0,6)
		game.players[4].position=Vector3(0,0,4) if crossing else Vector3(2,0,6)
		game.players[4].target=Vector3(0,0,8) if crossing else Vector3(-2,0,6)
		var minimum:=INF
		var early:=false
		var stalls:=0
		for frame in 420:
			var previous: Vector3=game.players[3].velocity
			var previous_position: Vector3=game.players[3].position
			game.clock_time+=1.0/60.0
			game.move_players(1.0/60.0)
			for p in game.players: p.tick(1.0/60.0,false,false)
			var distance: float=game.players[3].position.distance_to(game.players[4].position)
			minimum=minf(minimum,distance)
			if absf(game.players[3].position.z-6)>0.03 and distance>1.35: early=true
			if previous.length()>1.0 and game.players[3].position.distance_to(previous_position)<0.002: stalls+=1
		assert(early,"Support must read the meeting and adjust before body contact")
		assert(minimum>=0.975,"Support trajectories cannot intersect")
		assert(stalls==0,"Support cannot slam into another player and stop abruptly")
		for i in [3,4]: assert(game.players[i].position.distance_to(game.players[i].target)<0.35,"Avoidance must still reach the assigned position")
		results.append({"crossing":crossing,"minimum_distance_m":minimum,"abrupt_stalls":stalls})
	var output=FileAccess.open("res://docs/traffic-read-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(results,"  "))
	print("TRAFFIC READ PASS: head-on and crossing paths / early adjustment / no abrupt collision stop / targets reached")
	game.queue_free()
	quit()

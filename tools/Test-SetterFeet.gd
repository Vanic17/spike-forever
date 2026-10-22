extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.demo=false
	game.started=true
	var cases:=0
	for team in 2:
		for fps in [60,120]:
			for offset in [-1.0,1.0]:
				var fixture=load("res://tools/Test-RecoveryTraffic.gd").prepare_case(game,team)
				game.dive_motions.clear()
				var setter=game.players[game.setter]
				var passer=game.players[game.receiver]
				setter.position=fixture.stance+Vector3(-0.5*offset,0,0)
				passer.position=fixture.stance+Vector3(0.55*offset,0,0)
				passer.play("receive",1.0,false)
				passer.animation_time=passer.clips.receive.contact_time
				passer.motion_lock=0
				game.traffic_footprints.clear()
				game.court_shape.reset()
				var before: int=game.test_contacts
				var gap:=INF
				for frame in fps*2:
					if game.phase not in ["SET","CPU_SET"]: break
					game.step(1.0/fps)
					gap=minf(gap,setter.position.distance_to(passer.position))
				print("SETTER FEET case ",team,"/",fps,"/",offset," phase=",game.phase," gap=",gap," stance error=",setter.position.distance_to(fixture.stance))
				assert(game.phase in ["ATTACK","CPU_ATTACK"] and game.test_contacts==before+1,"Short pass next to passer must produce an actual set")
				assert(gap>=0.978,"Passer must yield with actual movement, preserving body clearance")
				cases+=1
	print("SETTER FEET PASS: ",cases," real second touches / both sides of passer / both teams / 60-120Hz / original reception deadline")
	game.free()
	quit()

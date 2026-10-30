extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.started=true; game.paused=false
	await process_frame
	var bench=game.arena_visuals.get_node("TeamBenches"); bench.set_process(false)
	game.phase="POINT"; bench._process(.1); game.scores=[1,0]; game.server=0
	var start:=Time.get_ticks_usec()
	for i in 1000:
		game.ball_pos=Vector3(sin(i*.1)*3,2,cos(i*.05)*7); bench._process(1.0/30+.00001)
	var mean:=float(Time.get_ticks_usec()-start)/1000
	var report={"measurement":"CPU sideline pose update, not rendered FPS","mean_update_usec":mean,"samples":1000,"update_hz":30,"team_actors":bench.actors.size(),"officials":bench.officials.size(),"extra_match_animation_trees":0}
	FileAccess.open("res://docs/sideline69-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SIDELINE69 PASS ",JSON.stringify(report)); game.free(); quit()

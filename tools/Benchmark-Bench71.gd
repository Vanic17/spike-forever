extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false
	await process_frame
	var bench=game.arena_visuals.get_node("TeamBenches")
	bench.set_process(false);bench.identity_poll=-10000;game.started=true;game.paused=false
	for entry in bench.actors:entry.actor.visible=true
	var times=[]
	for i in 2000:
		game.phase="POINT" if i%150<100 else "SERVE"
		if i%150==0:game.scores=[int(i/150),0];game.server=0
		var start=Time.get_ticks_usec();bench._process(1.0/30);times.append(Time.get_ticks_usec()-start)
	times.sort();var total=0.0
	for time in times:total+=time
	var report={"samples":times.size(),"actors":bench.actors.size()+bench.officials.size(),"mean_update_us":total/times.size(),"p95_update_us":times[int(times.size()*.95)],"animation_trees_added":0,"scope":"CPU time of the cosmetic sideline updater; not whole-game GPU FPS"}
	FileAccess.open("res://docs/bench71-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BENCH71 PERFORMANCE ",JSON.stringify(report));quit()

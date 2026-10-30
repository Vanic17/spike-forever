extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var m=g.match_management; var db=load("res://src/league.gd").new(); var teams=[db.teams[0],db.teams[1]]; var squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	assert(m.configure_rosters(teams,squads,{}, {"fatigue":true,"injuries":false}))
	g.started=true; g.paused=false; g.phase="RECEIVE"
	var stamp=Time.get_ticks_usec()
	for i in 10000: m.tick(1.0/60.0)
	var tick_us=(Time.get_ticks_usec()-stamp)/10000.0
	var c=load("res://src/career_manager.gd").new(); stamp=Time.get_ticks_usec(); assert(c.new_career(teams[0].id,{"seed":66099,"autosave":false},9)); var create_ms=(Time.get_ticks_usec()-stamp)/1000.0
	stamp=Time.get_ticks_usec()
	for i in 30: assert(not c.simulate_next().is_empty())
	var sim_ms=(Time.get_ticks_usec()-stamp)/30000.0
	FileAccess.open("res://docs/career66-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"measurement":"CPU microbenchmark, not rendered FPS","management_tick_us":tick_us,"samples":10000,"new_career_ms":create_ms,"simulate_next_average_ms":sim_ms},"  "))
	print("CAREER PERFORMANCE66 PASS ",tick_us," microseconds per management tick; ",sim_ms," ms per simulation step"); g.free(); quit()

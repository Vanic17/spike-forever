extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var Rules=load("res://src/career_rules.gd")
	for row in [[2,0,3],[2,1,2],[1,2,1],[0,2,0],[3,0,3],[3,1,3],[3,2,2],[2,3,1],[1,3,0]]:
		assert(Rules.points_for_score(row[0],row[1])==row[2])
	var db=load("res://src/league.gd").new()
	var manager=load("res://src/career_manager.gd").new()
	assert(manager.new_career(db.teams[0].id,{"best_of":3,"autosave":false,"injuries":false,"seed":68030},10))
	assert(manager.best_of()==3)
	assert(manager._validate_result({"sets":[2,1],"set_scores":[[25,20],[20,25],[16,14]]}))
	assert(not manager._validate_result({"sets":[2,1],"set_scores":[[25,20],[20,25],[15,14]]}))
	assert(not manager._validate_result({"sets":[3,0],"set_scores":[[25,20],[25,20],[25,20]]}))
	var count:=0
	while not manager.state.complete:
		var result: Dictionary=manager.simulate_next(); assert(not result.is_empty()); count+=1
		assert(maxi(result.sets[0],result.sets[1])==2)
		if result.set_scores.size()==3: assert(maxi(result.set_scores[2][0],result.set_scores[2][1])>=15)
	var points:=0
	for row in manager.standings(): points+=int(row.points)
	assert(points==396,"132 regular season matches allocate exactly 3 points each")
	manager.update_options({"news_frequency":2}); assert(manager.best_of()==3)
	assert(manager.save()); var reload=load("res://src/career_manager.gd").new(); assert(reload.load_career(10)); assert(reload.best_of()==3)
	var Views=load("res://src/view_controls.gd")
	assert(Views.next_camera(0)==2 and Views.next_camera(2)==3 and Views.next_camera(3)==0 and Views.next_camera(1)==0)
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true
	await process_frame
	var teams=[db.teams[0],db.teams[1]]; var squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	for side in 2:
		for slot in 6: game.players[side*6+slot].set_roster_identity(squads[side][slot],squads[side][6],load("res://src/club_kits.gd").selection(teams[side].id,"home"),{})
	assert(game.match_management.configure_rosters(teams,squads)); game.match_management.lock_lineup()
	game.started=true; game.phase="POINT"; game.paused=false; game.replay.testing=true; game.replay.set_process(false)
	for power in [1.01,1.12,1.3]:
		game.replay.reset(); game.last_power=power; game.touches=[3,0]
		for i in 4: game.clock_time=i*.1; game.replay.capture(true)
		game.replay.mark_shot("attack",0,false); game.replay.on_point(0)
		assert(not game.replay.pending.is_empty(),"A successful overcharged attack gets a replay")
		game.replay.pending.clear(); game.replay.on_point(1); assert(game.replay.pending.is_empty(),"A failed overcharge must not get an attack replay")
	game.replay.reset()
	game.paused=true
	var benches=game.arena_visuals.get_node("TeamBenches"); benches.sync_identity(); assert(benches.officials.size()==3)
	var incoming: Dictionary={}
	for person in game.match_management.bench(0):
		if game.match_management.eligibility(0,0,person.id).is_empty(): incoming=person; break
	assert(not incoming.is_empty())
	var scene=game.substitution_scene; scene.testing=true; scene.set_process(false)
	var camera: Transform3D=game.camera.transform; var field: Transform3D=game.players[0].transform
	var score: Array=game.scores.duplicate(); var random_state=game.rng.state; var contacts=game.test_contacts
	assert(game.match_management.substitute(0,0,incoming.id).is_empty()); assert(scene.pending.size()==1)
	assert(scene.begin()); assert(not game.players[0].visible)
	scene.advance(scene.TRANSITION_SECONDS+.01)
	for i in ceili(float(scene.timeline.end)*30)+1: scene.advance(1.0/30); game.step(1.0/30)
	scene.advance(.1); scene.advance(scene.TRANSITION_SECONDS+.01)
	assert(not scene.active and game.players[0].visible and not game.paused)
	assert(game.camera.transform==camera and game.players[0].transform==field)
	assert(game.rng.state==random_state and game.scores==score and game.test_contacts==contacts)
	assert(game.match_management.current[0][0]==incoming.id and game.match_management.counts[0]==1)
	scene.enqueue(0,0,incoming,squads[0][0]); game.started=false; scene.advance(.1); assert(scene.pending.is_empty() and not scene.active,"An abandoned match cannot carry a queued scene into the next match")
	var report={"best_of_three_complete_season":manager.state.results.size(),"calendar_advances":count,"league_points":points,"save_format_retained":true,"overcharged_winning_replays":3,"cameras":[0,2,3],"table_officials":3,"cinematic_state_and_rng_preserved":true,"substitution_count":1}
	FileAccess.open("res://docs/patch68-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PATCH68 PASS ",JSON.stringify(report)); game.free(); quit()

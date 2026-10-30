extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false
	var host
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node
	host.installed_version="999.0.0"; host.startup_scan=false
	var career=host.career_menu; career.ensure_manager(); var reports: Array=[]
	for best_of in [3,5]:
		for away in [false,true]:
			for deciding in [false,true]:
				assert(career.manager.new_career(host.clubs.db.teams[0].id,{"seed":68077,"best_of":best_of,"autosave":false,"fatigue":false,"injuries":false},10))
				var next=career.manager.next_fixture(); career.manager.state.club_id=next.away if away else next.home
				var fixture=career.manager.next_fixture(); career.launch_match(); assert(g.started and g.match_best_of==best_of)
				var needed: int=int(best_of/2)+1
				var winners: Array=[0,1,0] if best_of==3 and deciding else ([0,1,0,1,0] if deciding else ([0,0] if best_of==3 else [0,0,0]))
				for i in winners.size():
					g.phase="ATTACK"; var winning: int=winners[i]; var target:=15 if i==best_of-1 else 25
					g.scores=[target-1,target-2]; if winning==1: g.scores.reverse()
					g.hitter=winning*6; g.match_management.touch(g.hitter,"attack"); g.award(winning,"PALLA A TERRA")
				assert(g.match_finished and not career.pending_post.is_empty())
				var result: Dictionary=career.manager.fixture(fixture.id).result
				assert(not result.is_empty() and maxi(result.sets[0],result.sets[1])==needed)
				assert(result.winner==career.club())
				var table=career.manager.standings(); var own=table.filter(func(r): return r.team_id==career.club())[0]
				assert(own.points==(2 if deciding else 3))
				g.return_to_main_menu(); await process_frame; await process_frame
				assert(career.visible and career.view=="result" and career.pending_post.is_empty())
				reports.append({"best_of":best_of,"away":away,"deciding":deciding,"sets":result.sets,"points":own.points,"returned_to_career":true})
	FileAccess.open("res://docs/patch68-career-formats.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("CAREER FORMAT68 PASS: eight actual matches / 3 and 5 sets / home and away / straight and deciding / standings and return"); g.free(); quit()

extends SceneTree
var g
var menu
var career
var reports=[]
func _initialize(): call_deferred("run")
func run():
	g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.replay.testing=true; g.match_audio.enabled=false
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): menu=node
	menu.installed_version="999.0.0"; menu.startup_scan=false; career=menu.career_menu; career.ensure_manager()
	for away in [false,true]:
		assert(career.manager.new_career(menu.clubs.db.teams[0].id,{"seed":66077,"autosave":false,"fatigue":false,"injuries":false,"stats":false},10))
		var next=career.manager.next_fixture()
		if (next.home!=career.club())!=away:
			career.manager.state.club_id=next.away if away else next.home
		var fixture=career.manager.next_fixture(); career.launch_match(); assert(g.started and g.match_management.active)
		var scorer=str(g.match_management.actor_id(0)); var opponent=str(g.match_management.actor_id(6))
		for set_index in 3:
			g.phase="ATTACK"; g.scores=[24,23]; g.sets=[set_index,0]; g.hitter=0; g.match_management.touch(0,"attack"); g.award(0,"PALLA A TERRA")
		assert(g.match_finished and not career.pending_post.is_empty())
		var result=career.manager.fixture(fixture.id).result
		assert(result.sets==([0,3] if away else [3,0]))
		assert(result.set_scores==([[23,25],[23,25],[23,25]] if away else [[25,23],[25,23],[25,23]]))
		assert(result.stats_source=="measured" and result.players[scorer].attack_kills==3)
		assert(result.team_stats[1 if away else 0].attack_kills==3 and result.team_stats[0 if away else 1].attack_kills==0,"Away teams retain their own measured stats")
		var count=career.manager.state.results.size(); career.match_completed(g.match_management.last_result); assert(career.manager.state.results.size()==count,"One callback only")
		g.return_to_main_menu(); await process_frame; await process_frame
		assert(career.visible and career.view=="result" and career.pending_post.is_empty())
		reports.append({"away":away,"sets":result.sets,"set_scores":result.set_scores,"measured_kills":3,"recorded_once":true,"post_match_home_flow":true})
	FileAccess.open("res://docs/career66-played-match.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("CAREER PLAYED66 PASS home/away actual scoring path / measured results / no duplicate / post-match"); g.free(); quit()


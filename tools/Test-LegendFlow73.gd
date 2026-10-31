extends SceneTree
## The actual shared match must feed the existing player-career result/save UI.
var g
var menu
var checks:=0
var failures: Array=[]
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error("LEGEND FLOW73 "+message)
func settle():
	await process_frame
	await process_frame
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend73"),"isolated test profile")
	if not failures.is_empty(): quit(1); return
	g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false; g.replay.enabled=false
	var host
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node; break
	host.startup_scan=false; host.installed_version="999.0.0"; menu=host.legend_menu
	var manager=menu.manager
	var profile: Dictionary=manager.default_profile(); profile.name="Carriera condivisa 73"; profile.role="setter"
	check(manager.new_career(profile,str(manager.starter_clubs()[0].id),{"best_of":3,"autosave":true,"seed":73073},12),"create career with existing save schema")
	menu.launch_match()
	check(g.legend_match.active and g.match_management.active,"career uses exhibition MatchManagement")
	check(g.display_selected()==5 and g.legend_match.manual_available,"created setter remains selected")
	var id: String=manager.state.profile.id
	var fixture: Dictionary=menu.active_fixture.duplicate(true)
	# These are measured manager events: nobody else's points are personal XP.
	g.match_management.touch(5,"set")
	g.legend_match.assists=1
	g.legend_match.active_minutes=12
	var signals: Array=[]
	g.legend_match.match_finished.connect(func(result): signals.append(result.duplicate(true)))
	g.phase="RECEIVE"; g.scores=[24,12]; g.award(0,"TEST SET ONE")
	check(g.sets==[1,0] and not g.match_finished,"first set keeps the shared match running")
	g.phase="RECEIVE"; g.scores=[24,15]; g.award(0,"TEST SET TWO")
	check(g.match_finished and signals.size()==1,"shared scoring finishes and emits once")
	check(g.match_management.last_result.players[id].sets==1,"the source manager records the created athlete's actual touch")
	await settle()
	check(not g.started and not g.legend_match.active and menu.visible and menu.view=="result","completed match returns to the career result page")
	check(manager.state.match_history.size()==1 and manager.last_result.fixture_id==fixture.id,"exactly one result enters the existing career")
	check(manager.last_result.performance.sets==1 and manager.last_result.performance.assists==1,"personal stats use measured shared events")
	var away: bool=fixture.home!=manager.state.club_id
	check(manager.last_result.sets==([0,2] if away else [2,0]),"home/away result order is preserved")
	var restored=load("res://src/legend_career.gd").new()
	check(restored.load_career(12) and restored.state.match_history.size()==1,"shared match rewards survive save and reload")
	menu.on_match_finished(signals[0]); check(manager.state.match_history.size()==1,"duplicate completion cannot reward twice")
	menu.show_page("home"); menu.launch_match()
	check(g.legend_match.active,"a following match can launch")
	g.return_to_main_menu(); await settle()
	check(menu.visible and menu.view=="home" and manager.state.match_history.size()==1,"abandon returns without result/reward")
	check(manager.state.pending_fixture_id=="","abandon clears pending fixture")
	var report: Dictionary={"checks":checks,"failures":failures,"shared_stats":true,"result_once":true,"save_reload":true,"abandon":true}
	FileAccess.open("res://docs/legend73-flow.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND FLOW73 ",JSON.stringify(report)); g.free(); quit(0 if failures.is_empty() else 1)

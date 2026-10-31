extends SceneTree
var game
var manager
var menu
var teams: Array=[]
var squads: Array=[]
var checks:=0
var failures: Array=[]
var device:=0
var cases: Array=[]
func _initialize(): call_deferred("run")
func settle():
	await process_frame
	await process_frame
func check(value: bool,message: String):
	checks+=1
	if not value: failures.append(message); push_error("DOUBLE UI74 "+message)
func press(button: int):
	var event=InputEventJoypadButton.new(); event.device=device; event.button_index=button; event.pressed=true
	Input.parse_input_event(event); await settle()
	event=event.duplicate(); event.pressed=false; Input.parse_input_event(event); await settle()
func axis(value: float):
	var event=InputEventJoypadMotion.new(); event.device=device; event.axis=JOY_AXIS_LEFT_Y; event.axis_value=value
	menu.repeat_left=0; Input.parse_input_event(event); await settle()
	event=event.duplicate(); event.axis_value=0; Input.parse_input_event(event); await settle()
func prepare(phase: String):
	game.substitution_scene.cancel(); manager.configure_rosters(teams,squads,{},{"fatigue":true,"auto_subs":false}); manager.lock_lineup()
	game.started=true; game.phase=phase; game.paused=true; game.charging=false; game.toss_active=false; game.match_finished=false; game.rotations=[3,3]
	for p in game.players: p.libero_active=false
	menu.open(); await settle()
func flow(size: Vector2i,phase: String,last: bool):
	root.size=size; root.content_scale_size=size; await settle(); await prepare(phase)
	check(root.gui_get_focus_owner()==menu.rows[0],"ordinary roster starts focused")
	await press(JOY_BUTTON_DPAD_UP)
	check(root.gui_get_focus_owner()==menu.single_button,"up reaches mode bar")
	await press(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner()==menu.double_button,"right reaches double substitution")
	check(not menu.double_mode,"mode is not chosen by scrolling")
	await press(JOY_BUTTON_A)
	check(menu.double_mode and menu.double_stage==0,"A/Cross opens double substitution")
	check(menu.rows.size()>=3 and menu.candidates.size()>=3,"all reserve options available")
	var outgoing: Array=manager.current[0].duplicate()
	var target: int=menu.rows.size()-1 if last else 0
	for i in target: await press(JOY_BUTTON_DPAD_DOWN)
	check(menu.double_opposite.is_empty() and menu.double_setter.is_empty() and manager.current[0]==outgoing,"scrolling makes no roster change")
	var opp: String=menu.rows[target].get_meta("player_id")
	check(root.gui_get_focus_owner()==menu.rows[target],"controller reaches lower opposite row")
	check(menu.rows[target].get_global_rect().end.y<=menu.left_scroll.get_global_rect().end.y+2,"focused opposite scrolls fully into view")
	await press(JOY_BUTTON_A)
	check(menu.double_opposite==opp and menu.double_stage==1 and root.gui_get_focus_owner()==menu.candidates[0],"opposite selection advances to setter")
	var setter_target: int=menu.candidates.size()-1 if last else 0
	for i in setter_target: await press(JOY_BUTTON_DPAD_DOWN)
	var setter: String=menu.candidates[setter_target].get_meta("player_id")
	check(root.gui_get_focus_owner()==menu.candidates[setter_target],"controller reaches lower setter row")
	check(menu.candidates[setter_target].get_global_rect().end.y<=menu.right_scroll.get_global_rect().end.y+2,"focused setter scrolls fully into view")
	await press(JOY_BUTTON_A)
	check(menu.double_setter==setter and not menu.confirm_button.disabled and root.gui_get_focus_owner()==menu.confirm_button,"both choices reach single confirmation")
	check(manager.current[0]==outgoing and manager.counts[0]==0,"both remain unchanged until confirm")
	await press(JOY_BUTTON_B)
	check(menu.double_stage==1 and menu.double_setter.is_empty() and menu.double_opposite==opp,"B/Circle cancels only the confirmation step")
	for i in setter_target: await press(JOY_BUTTON_DPAD_DOWN)
	await press(JOY_BUTTON_A)
	var rect: Rect2=menu.confirm_button.get_global_rect()
	check(rect.position.y>=0 and rect.end.y<=size.y+1,"confirmation visible at "+str(size))
	check(menu.left_scroll.get_global_rect().end.y<=menu.detail.get_global_rect().position.y,"roster does not overlap summary")
	await press(JOY_BUTTON_A)
	check(not menu.opened and not game.paused,"single confirmation closes and resumes")
	if phase=="SET":
		check(manager.queued_changes.size()==1 and manager.counts[0]==0 and manager.current[0]==outgoing,"rally pair queued as one transaction")
		game.phase="POINT"; manager.apply_queued_changes()
	check(manager.current[0][5]==opp and manager.current[0][2]==setter and manager.counts[0]==2,"both entry substitutions applied together")
	check(manager.setter_slot(0)==2,"new setter is active")
	game.substitution_scene.cancel(); game.paused=true; game.phase="SERVE"; game.rotations[0]=0
	menu.open(); await settle()
	await press(JOY_BUTTON_DPAD_UP); await press(JOY_BUTTON_DPAD_RIGHT); await press(JOY_BUTTON_A)
	check(menu.double_return and root.gui_get_focus_owner()==menu.confirm_button and not menu.confirm_button.disabled,"active pair offers direct starters return confirmation")
	await press(JOY_BUTTON_B)
	check(not menu.double_mode and menu.opened and manager.counts[0]==2,"B cancels return without changing either player")
	await press(JOY_BUTTON_A)
	check(menu.double_return,"A reopens return from focused mode button")
	await press(JOY_BUTTON_A)
	check(manager.current[0]==outgoing and manager.counts[0]==4 and manager.setter_slot(0)==5,"single return confirmation restores both starters for two more substitutions")
	cases.append({"resolution":str(size),"device":device,"phase":phase,"last_reserves":last,"substitutions":manager.counts[0]})
func run():
	if not ProjectSettings.globalize_path("user://").contains("double74"):
		push_error("Requires isolated double74 APPDATA"); quit(1); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	await settle(); manager=game.match_management; menu=manager.menu; game.substitution_scene.set_process(false); game.substitution_scene.testing=true
	var db=load("res://src/league.gd").new(); teams=[db.teams[0].duplicate(true),db.teams[1].duplicate(true)]; squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	for role in ["opposite","setter"]:
		var template: Dictionary=teams[0].roster.filter(func(p): return str(p.role)==role)[0]
		for i in 7:
			var person=template.duplicate(true); person.id="double74-ui-"+role+str(i); person.name="Reserve "+role+" "+str(i+1); person.jersey_number=30+i
			teams[0].roster.append(person)
	var mappings: Dictionary={}
	for action in ["ui_accept","ui_cancel"]:
		mappings[action]=InputMap.action_get_events(action); InputMap.action_erase_events(action)
	var sizes: Array=[Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]
	for i in sizes.size():
		device=[0,3,7][i]
		for phase in ["SERVE","SET"]:
			for last in [false,true]: await flow(sizes[i],phase,last)
	await prepare("SERVE"); await axis(1)
	check(root.gui_get_focus_owner()==menu.rows[1] and menu.zone==0,"raw left stick navigates without selecting")
	TranslationServer.set_locale("en"); menu.open_double(); await settle()
	menu.choose_double_opposite(str(menu.rows[0].get_meta("player_id"))); menu.choose_double_setter(str(menu.candidates[0].get_meta("player_id")))
	check(menu.confirm_button.text=="CONFIRM DOUBLE SUBSTITUTION","new confirmation uses full English translation")
	menu.apply_double(); game.substitution_scene.cancel(); game.paused=true; game.phase="SERVE"; menu.open(); menu.open_double(); await settle()
	check(menu.confirm_button.text=="CONFIRM STARTERS' RETURN","return confirmation uses full English translation")
	TranslationServer.set_locale("it")
	for action in mappings:
		for event in mappings[action]: InputMap.action_add_event(action,event)
	var report={"checks":checks,"failures":failures,"cases":cases,"native_input":true,"no_action_mappings_required":true,"pair_confirmations":24}
	FileAccess.open("res://docs/double74-ui-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DOUBLE UI74 ","PASS " if failures.is_empty() else "FAIL ",JSON.stringify(report)); game.free(); quit(0 if failures.is_empty() else 1)

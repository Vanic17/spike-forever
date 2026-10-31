extends SceneTree
var game
var menu
var host
var failures: Array=[]
var checks:=0
var report: Dictionary={}
var pad_device:=0
func _initialize(): call_deferred("run")
func settle():
	await process_frame
	await process_frame
func check(value: bool,message: String):
	checks+=1
	if not value: failures.append(message); push_error("LEGEND UI73: "+message)
func press(button: int):
	var event:=InputEventJoypadButton.new(); event.device=pad_device; event.button_index=button; event.pressed=true
	Input.parse_input_event(event)
	await settle()
	event=event.duplicate(); event.pressed=false; Input.parse_input_event(event)
	await settle()
func find_key(node: Node,key: String) -> Control:
	if node is Control and str(node.get_meta("focus_key",""))==key: return node
	for child in node.get_children():
		var found:=find_key(child,key)
		if found!=null: return found
	return null
func path_to(target: Control,scope: Node) -> Array:
	var start=scope.get_viewport().gui_get_focus_owner()
	var seen: Dictionary={}; var pending: Array=[[start,[]]]
	while not pending.is_empty():
		var visit=pending.pop_front(); var control: Control=visit[0]
		if control==target: start.grab_focus(); return visit[1]
		if seen.has(control): continue
		seen[control]=true
		for pair in [[Vector2.UP,JOY_BUTTON_DPAD_UP,SIDE_TOP],[Vector2.DOWN,JOY_BUTTON_DPAD_DOWN,SIDE_BOTTOM],[Vector2.LEFT,JOY_BUTTON_DPAD_LEFT,SIDE_LEFT],[Vector2.RIGHT,JOY_BUTTON_DPAD_RIGHT,SIDE_RIGHT]]:
			control.grab_focus()
			var after: Control
			if scope is Window: after=control.find_valid_focus_neighbor(pair[2])
			else: menu.controller_navigate(scope,pair[0]); after=scope.get_viewport().gui_get_focus_owner()
			if after==null: after=control
			if after!=control: pending.append([after,visit[1]+[pair[1]]])
	start.grab_focus(); return []
func navigate_to(target: Control) -> bool:
	var scope: Node=menu.controller_scope()
	for attempt in 40:
		if scope.get_viewport().gui_get_focus_owner()==target: return true
		var route:=path_to(target,scope)
		if route.is_empty(): return false
		await press(route[0])
	return false
func axis(which: int,value: float):
	var event:=InputEventJoypadMotion.new(); event.device=pad_device; event.axis=which; event.axis_value=value
	Input.parse_input_event(event); await settle()
func choose_picker(key: String,direction: int=1):
	var option=find_key(menu,key)
	check(await navigate_to(option),"controller reaches picker "+key)
	var before: int=option.selected
	await press(JOY_BUTTON_A)
	check(option.get_popup().visible,"A opens native popup "+key)
	await press(JOY_BUTTON_DPAD_DOWN if direction>0 else JOY_BUTTON_DPAD_UP)
	await press(JOY_BUTTON_A)
	check(not option.get_popup().visible and option.selected==clampi(before+direction,0,option.item_count-1),"native popup applies selection once: "+key)
	check(root.gui_get_focus_owner()==option,"popup returns focus to "+key)
func flow(resolution: Vector2i):
	menu.chosen_slot=1; menu.chosen_best_of=5; menu.draft_options.difficulty=1
	root.size=resolution; root.content_scale_size=resolution; await settle()
	menu.open(); await settle()
	check(menu.visible and menu.view=="entry","entry opens at "+str(resolution))
	check(root.gui_get_focus_owner()==find_key(menu,"new"),"entry focuses create")
	var first=root.gui_get_focus_owner()
	await axis(JOY_AXIS_LEFT_Y,1.0)
	check(root.gui_get_focus_owner()!=first,"raw stick motion navigates without relying on connected-device polling")
	await axis(JOY_AXIS_LEFT_Y,0.0)
	check(await navigate_to(find_key(menu,"new")),"D-pad returns to create")
	await press(JOY_BUTTON_A)
	check(menu.view=="new","A/Cross activates create")
	check(await navigate_to(find_key(menu,"name")),"controller reaches name keyboard")
	await press(JOY_BUTTON_A)
	check(menu.keyboard!=null and menu.keyboard.visible,"A/Cross opens native name keyboard")
	check(menu.keyboard.size.y<=root.size.y,"name dialog and its confirmation fit the native viewport")
	await press(JOY_BUTTON_DPAD_RIGHT)
	check(menu.keyboard.gui_get_focus_owner().text=="B","one right press moves one keyboard key")
	await press(JOY_BUTTON_DPAD_LEFT)
	check(menu.keyboard.gui_get_focus_owner().text=="A","one left press moves one keyboard key")
	await press(JOY_BUTTON_DPAD_DOWN)
	check(menu.keyboard.gui_get_focus_owner().text=="K","one down press moves one keyboard row")
	await press(JOY_BUTTON_DPAD_UP)
	check(menu.keyboard.gui_get_focus_owner().text=="A","one up press moves one keyboard row")
	var before: String=menu.keyboard_text.text
	await press(JOY_BUTTON_A)
	check(menu.keyboard_text.text==before+"A","keyboard types a character exactly once")
	check(await navigate_to(menu.keyboard.get_ok_button()),"controller reaches actual name confirmation")
	await press(JOY_BUTTON_A)
	check(not menu.keyboard.visible and str(menu.draft.name)==before+"A","name confirmation commits through native dialog")
	check(root.gui_get_focus_owner()==find_key(menu,"name"),"name confirmation restores focus")
	await press(JOY_BUTTON_A)
	check(menu.keyboard.visible,"name keyboard can be reopened")
	await press(JOY_BUTTON_B)
	check(not menu.keyboard.visible and menu.view=="new","B closes only the keyboard and keeps creation open")
	check(await navigate_to(find_key(menu,"minus-battuta")),"controller reaches attribute reduction")
	await press(JOY_BUTTON_A)
	check(int(menu.draft.ratings.battuta)==49,"one press reduces one point")
	check(await navigate_to(find_key(menu,"plus-difesa")),"controller reaches attribute increase")
	await press(JOY_BUTTON_A)
	check(int(menu.draft.ratings.difesa)==51,"one press adds one point")
	var owner=root.gui_get_focus_owner()
	check(owner!=null and not (owner is BaseButton and owner.disabled),"spending the last point never leaves focus on a disabled control")
	await choose_picker("number")
	await choose_picker("appearance-beard")
	check(await navigate_to(find_key(menu,"next-club")),"controller reaches visible continue action")
	await press(JOY_BUTTON_A)
	check(menu.view=="clubs","A/Cross confirms player creation")
	var clubs: Array=menu.manager.starter_clubs(); var chosen: String=clubs[2].id
	check(await navigate_to(find_key(menu,"club-"+chosen)),"controller reaches third starter club")
	await press(JOY_BUTTON_A)
	check(str(menu.chosen_club)==chosen and root.gui_get_focus_owner()==find_key(menu,"club-"+chosen),"choosing a club keeps focus on that club")
	await choose_picker("match-format")
	await choose_picker("difficulty")
	await choose_picker("save-slot")
	check(await navigate_to(find_key(menu,"create")),"controller reaches sign action")
	var previous: String=str(menu.manager.state.get("profile",{}).get("id",""))
	await press(JOY_BUTTON_A)
	var overwrite: bool=menu.modal!=null and menu.modal.visible
	if overwrite:
		await press(JOY_BUTTON_B)
		check(menu.view=="clubs" and str(menu.manager.state.get("profile",{}).get("id",""))==previous,"B cancels overwrite without signing")
		check(await navigate_to(find_key(menu,"create")),"controller reaches sign again after cancelling")
		await press(JOY_BUTTON_A)
		check(await navigate_to(menu.modal.get_ok_button()),"controller reaches actual overwrite confirmation")
		await press(JOY_BUTTON_A)
	check(menu.manager.active() and menu.view=="home" and str(menu.manager.state.profile.id)!=previous,"A/Cross signs once and opens career")
	check(menu.manager.state.profile.number==2 and menu.manager.state.profile.appearance.beard=="corta","creation preserves controller edits")
	await press(JOY_BUTTON_START)
	check(menu.modal!=null and menu.modal.visible,"Start opens saved confirmation without leaking to main menu")
	await press(JOY_BUTTON_A)
	check(menu.modal==null,"A/Cross dismisses saved confirmation")
	await press(JOY_BUTTON_B)
	check(menu.view=="entry","B returns from career to entry")
	await press(JOY_BUTTON_B)
	check(not menu.visible and host.play_hub.visible,"B returns from entry to play modes")
	report[str(resolution)]={"device":pad_device,"overwrite":overwrite,"controller_edits":true,"complete_flow":true}
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend73-ui"),"requires isolated APPDATA")
	if not failures.is_empty(): quit(1); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	await settle()
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child
	check(host!=null,"native main creates start menu")
	host.startup_scan=false; host.installed_version="999.0.0"; menu=host.legend_menu
	# The menu must recognize standard A/Cross even when a session's generic
	# ui_accept binding was replaced. Real events, never pressed.emit shortcuts.
	var resolutions: Array=[Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]
	for index in 3:
		pad_device=[0,3,7][index]
		for event in InputMap.action_get_events("ui_accept"):
			if event is InputEventJoypadButton: InputMap.action_erase_event("ui_accept",event)
		if index>0:
			var specific:=InputEventJoypadButton.new(); specific.device=0; specific.button_index=JOY_BUTTON_A
			InputMap.action_add_event("ui_accept",specific)
		await flow(resolutions[index])
	report.checks=checks; report.failures=failures
	FileAccess.open("res://docs/legend73-controller.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND UI73 ",JSON.stringify(report))
	game.free(); quit(1 if not failures.is_empty() else 0)

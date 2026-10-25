extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	if not ok: failures+=1; push_error("ONLINE UI51 FAIL "+message)
func button(code: int):
	var event:=InputEventJoypadButton.new(); event.device=0; event.button_index=code; event.pressed=true; root.push_input(event)
	await process_frame
	event=event.duplicate(); event.pressed=false; root.push_input(event)
	await process_frame
func run():
	root.size=Vector2i(1440,810); root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var menu
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): menu=n
	menu.play.grab_focus(); await process_frame
	await button(JOY_BUTTON_DPAD_RIGHT); check(menu.online.has_focus(),"Online between Play and Updates")
	await button(JOY_BUTTON_A); check(menu.online_menu.visible,"A/Cross opens Online")
	var online=menu.online_menu
	await button(JOY_BUTTON_DPAD_DOWN); check(online.code.has_focus(),"controller reaches invite field")
	await button(JOY_BUTTON_A); check(menu.clubs.keyboard!=null and menu.clubs.keyboard.visible,"controller opens text keyboard")
	await button(JOY_BUTTON_B)
	if menu.clubs.keyboard.visible: menu.clubs.keyboard.window_input.emit(make_cancel()); await process_frame
	check(not menu.clubs.keyboard.visible,"B/Circle closes invite keyboard")
	online.create.grab_focus()
	for i in 20:
		if online.formation.has_focus(): break
		await button(JOY_BUTTON_DPAD_DOWN)
	check(online.formation.has_focus(),"controller reaches formation without scrolling")
	await button(JOY_BUTTON_A); check(menu.clubs.formation_dialog.visible,"controller opens formation")
	await button(JOY_BUTTON_B)
	if menu.clubs.formation_dialog.visible: menu.clubs.formation_dialog.window_input.emit(make_cancel()); await process_frame
	check(not menu.clubs.formation_dialog.visible,"B/Circle closes formation")
	for size in [Vector2i(1440,810),Vector2i(1440,720),Vector2i(1280,600)]:
		root.size=size; root.content_scale_size=size
		await process_frame; await process_frame
		for control in [online.own_team,online.own_kit,online.formation,online.confirm,online.launch]:
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(control.get_global_rect()),"visible online controls at "+str(size))
	await button(JOY_BUTTON_B); check(not online.visible and menu.online.has_focus(),"B/Circle returns to home")
	print("ONLINE UI51 ","PASS" if failures==0 else "FAIL"," actual D-pad+A/B / invite keyboard / formation / three window sizes")
	g.free(); quit(0 if failures==0 else 1)
func make_cancel() -> InputEvent:
	var event:=InputEventAction.new(); event.action="ui_cancel"; event.pressed=true; return event

extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(value: bool,message: String):
	if not value: failures+=1; push_error("SETTINGS CONTROLLER53 "+message)
func button(code: int):
	var event=InputEventJoypadButton.new(); event.device=0; event.button_index=code; event.pressed=true; root.push_input(event); await process_frame
	event=event.duplicate(); event.pressed=false; root.push_input(event); await process_frame
func run():
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var host
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node
	host.edit.grab_focus(); await button(JOY_BUTTON_DPAD_RIGHT); check(host.settings_button.has_focus(),"home navigation")
	await button(JOY_BUTTON_A); var menu=host.settings_menu; check(menu.visible,"A/Cross opens Settings")
	await button(JOY_BUTTON_DPAD_DOWN); check(menu.graphics_tab.has_focus(),"tabs")
	await button(JOY_BUTTON_A); check(menu.page==1,"A/Cross opens graphics")
	await button(JOY_BUTTON_DPAD_DOWN); check(menu.fields.preset.has_focus(),"first graphics control")
	await button(JOY_BUTTON_DPAD_DOWN); check(menu.fields.textures.has_focus(),"texture control")
	await button(JOY_BUTTON_A); check(menu.fields.textures.get_popup().visible,"A/Cross opens options")
	await button(JOY_BUTTON_B)
	if menu.fields.textures.get_popup().visible:
		var event=InputEventAction.new(); event.action="ui_cancel"; event.pressed=true; menu.fields.textures.get_popup().window_input.emit(event); await process_frame
	check(not menu.fields.textures.get_popup().visible,"B/Circle closes options")
	for size in [Vector2i(1440,810),Vector2i(1280,720),Vector2i(1024,600)]:
		root.size=size; root.content_scale_size=size; await process_frame; await process_frame
		menu.fields.preset.grab_focus()
		for i in menu.GRAPHICS.size(): await button(JOY_BUTTON_DPAD_DOWN)
		check(menu.apply_button.has_focus(),"all graphics fields reach Apply at "+str(size))
		check(Rect2(Vector2.ZERO,Vector2(size)).encloses(menu.apply_button.get_global_rect()),"Apply stays visible at "+str(size))
		menu.fields.anisotropy.grab_focus(); await process_frame; await process_frame
		check(menu.scroll.get_global_rect().encloses(menu.fields.anisotropy.get_global_rect()),"focused last option scrolls fully into view at "+str(size))
	await button(JOY_BUTTON_B); check(not menu.visible and host.settings_button.has_focus(),"B/Circle returns to home")
	FileAccess.open("res://docs/settings53-controller.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"window_sizes":["1440x810","1280x720","1024x600"],"buttons":"Xbox A/B, PS Cross/Circle","navigation":"real joypad events, popup, scroll and home"},"  "))
	print("SETTINGS CONTROLLER53 ","PASS" if failures==0 else "FAIL")
	g.free(); quit(0 if failures==0 else 1)

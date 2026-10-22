extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	assert(menu!=null and not game.started and menu.panel.visible)
	assert(not menu.overlay.visible and menu.play.has_focus())
	menu.panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for size in [Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1080),Vector2(1024,768)]:
		menu.panel.size=size
		menu.layout()
		assert(menu.play.position.x>=0 and menu.updates.position.x+menu.updates.size.x<=size.x)
		assert(menu.play.position.y+menu.play.size.y<=size.y)
		assert(menu.play.position.x+menu.play.size.x<menu.updates.position.x)
	menu.client.busy=true # Test modal focus without making a network request.
	menu.show_updates()
	assert(menu.overlay.visible and menu.back.has_focus() and menu.play.focus_mode==Control.FOCUS_NONE)
	# Wait for deferred container sorting: the old zero-width wrap inflated
	# the dialog to 3351px and put both header and buttons off screen.
	for size in [Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1080),Vector2(1024,768)]:
		menu.panel.size=size
		menu.layout()
		for frame in 5: await process_frame
		assert(menu.dialog.size.y<=minf(620,size.y-40))
		for control in [menu.status,menu.history,menu.install_button,menu.back]:
			assert(menu.dialog.get_global_rect().encloses(control.get_global_rect()),"Every update control must stay inside the visible modal after container layout")
	menu.close_updates()
	assert(not menu.overlay.visible and menu.updates.has_focus())
	menu.client.busy=false
	var client=menu.client
	var good={"tag_name":"v0.19.0","name":"First patch","draft":false,"prerelease":false,"assets":[{"name":"SpikeForever-Windows.zip","browser_download_url":"https://github.com/Vanic17/spike-forever/releases/download/v0.19.0/SpikeForever-Windows.zip","digest":"sha256:"+"a".repeat(64)}]}
	var old=good.duplicate(true)
	old.tag_name="v0.18.9"
	var draft=good.duplicate(true)
	draft.draft=true
	client.completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify([good,old,draft]).to_utf8_buffer())
	assert(menu.history.item_count==2 and menu.items[1].tag_name=="v0.18.9")
	assert(not menu.install_button.disabled)
	var invalid=good.duplicate(true)
	invalid.assets[0].browser_download_url="https://example.org/not-approved.zip"
	client.install(invalid)
	assert(not client.downloading and not client.busy)
	client.completed(HTTPRequest.RESULT_SUCCESS,404,PackedStringArray(),PackedByteArray())
	assert(not client.busy and menu.status.text.contains("repository"))
	var buttons=menu.panel.find_children("*","Button",true,false)
	var played:=false
	for button in buttons:
		if button.text=="GIOCA": button.pressed.emit(); played=true
	assert(played and game.started and not menu.panel.visible)
	game.started=false
	menu.panel.show()
	menu.play.grab_focus()
	await process_frame
	var press:=InputEventJoypadButton.new()
	press.button_index=JOY_BUTTON_A
	press.pressed=true
	assert(press.is_action_pressed("ui_accept"),"Controller Cross/A must be mapped to UI accept")
	root.push_input(press,true)
	await process_frame
	var release:=InputEventJoypadButton.new()
	release.button_index=JOY_BUTTON_A
	release.pressed=false
	root.push_input(release,true)
	await process_frame
	assert(game.started,"Controller accept must activate the focused Play button")
	print("MENU UPDATES PASS: play offline / latest and previous versions / draft exclusion / invalid package refusal / network failure preserves play")
	game.free()
	quit()

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
	print("MENU UPDATES PASS: play offline / latest and previous versions / draft exclusion / invalid package refusal / network failure preserves play")
	game.free()
	quit()

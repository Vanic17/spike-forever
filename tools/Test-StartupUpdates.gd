extends SceneTree
class FakeClient extends "res://src/update_client.gd":
	var checks:=0
	var installs: Array=[]
	func check() -> void: checks+=1
	func install(release: Dictionary) -> void: installs.append(release)

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	var fake:=FakeClient.new()
	menu.add_child(fake)
	menu.client=fake
	menu.installed_version="0.21.0"
	var available={"tag_name":"v0.22.0","assets":[{"name":"SpikeForever-Windows.zip","browser_download_url":"https://github.com/Vanic17/spike-forever/releases/download/v0.22.0/SpikeForever-Windows.zip","digest":"sha256:"+"a".repeat(64)}]}
	assert(fake.compare_versions("v0.21.0","0.21.0")==0)
	assert(fake.compare_versions("v0.9.0","0.21.0")<0)
	assert(fake.compare_versions("v0.100.0","0.21.0")>0)
	assert(fake.compare_versions("invalid","0.21.0")<0)
	menu.check_startup_updates()
	assert(fake.checks==1 and menu.startup_scan and not game.started)
	menu.on_versions_ready([available])
	assert(menu.update_prompt.visible and game.paused and fake.installs.is_empty())
	menu.update_prompt.canceled.emit()
	assert(not menu.update_prompt.visible and not game.paused and fake.installs.is_empty())
	menu.check_startup_updates()
	var old=available.duplicate(true)
	old.tag_name="v0.20.0"
	menu.on_versions_ready([old])
	assert(not menu.update_prompt.visible)
	game.started=true
	game.phase="ATTACK"
	game.charging=true
	menu.check_startup_updates()
	menu.on_versions_ready([available])
	assert(not menu.update_prompt.visible and menu.prompt_waiting and not game.paused)
	game.phase="POINT"
	game.charging=false
	menu.maybe_prompt_update()
	assert(menu.update_prompt.visible and game.paused)
	menu.update_prompt.canceled.emit()
	game.started=false
	menu.check_startup_updates()
	menu.on_versions_ready([available])
	menu.update_prompt.confirmed.emit()
	assert(fake.installs.size()==1 and fake.installs[0].tag_name=="v0.22.0")
	print("STARTUP UPDATES PASS: background startup check / numeric version comparison / no downgrade popup / no interruption of charge or rally / explicit confirmation / postpone resumes / selected newest package")
	game.free()
	quit()

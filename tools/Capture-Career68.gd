extends SceneTree
var game
var host
var career
func _initialize(): call_deferred("run")
func shot(name: String):
	await process_frame; await process_frame; await create_timer(.15).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/patch68-ui-"+name+".png")
func run():
	root.size=Vector2i(1440,900); root.content_scale_size=root.size; root.mode=Window.MODE_WINDOWED
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	for node in game.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node
	host.startup_scan=false; host.installed_version="999.0.0"; career=host.career_menu; career.open(); career.show_page("new")
	await shot("new")
	var UI=load("res://src/career_widgets.gd")
	for control in UI.controls(career.page):
		if control is OptionButton and control.item_count==2 and control.get_item_text(0)=="Meglio dei 5":
			control.select(1); control.grab_focus()
	await shot("format")
	for control in UI.controls(career.page):
		if control is Button and control.text=="INIZIA LA CARRIERA": control.pressed.emit(); break
	assert(not career.manager.state.is_empty() and career.manager.best_of()==3,"Visible format selector must create a best-of-three career")
	await shot("home")
	career.show_page("impostazioni"); await shot("settings")
	career.show_page("statistiche"); await shot("stats")
	print("CAREER68 CAPTURE PASS / visible format selector creates best-of-three / clean UI"); game.free(); quit()

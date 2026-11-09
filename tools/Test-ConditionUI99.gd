extends SceneTree
var failures: Array=[]
func check(ok: bool,message: String):
	if not ok:failures.append(message);push_error("CONDITION UI99 "+message)
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame;await process_frame
func run():
	assert("condition99" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	var start=g.get_children().filter(func(n):return n.get_script()==load("res://src/start_menu.gd"))[0]
	start.installed_version="999.0.0";start.startup_scan=false
	var clubs=start.clubs;clubs.match_setup();await settle()
	for size99 in [Vector2i(1920,1080),Vector2i(1280,720)]:
		root.size=size99;root.content_scale_size=size99;await settle()
		clubs.show_match_formation(0,clubs.db.teams[0],clubs.setup_start);await settle()
		var popup=clubs.formation_dialog
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			popup.get_texture().get_image().save_png("res://docs/condition99-formation-"+str(size99.x)+".png")
		var frozen: Dictionary=g.form99.duplicate(true)
		check(not frozen.arrows.is_empty(),"formation draws full roster")
		check(popup.get_ok_button().get_global_rect().end.y<=popup.size.y,"confirmation stays visible")
		popup.hide();clubs.show_match_formation(0,clubs.db.teams[0],clubs.setup_start);await settle()
		check(g.form99==frozen,"cancel/reopen cannot reroll")
		popup=clubs.formation_dialog
		var scroll=popup.get_child(popup.get_child_count()-1)
		var picks: Array=[]
		collect(popup,picks)
		check(picks.size()==8,"rotation plus seven lineup selectors")
		for rotation in 6:
			picks[0].select(rotation);picks[0].item_selected.emit(rotation);await settle()
			var libre=picks.filter(func(p):return p!=picks[0] and str(p.get_parent().get_child(0).text).begins_with("L "))
			if not libre.is_empty():
				var target=libre[0].get_node(libre[0].focus_neighbor_bottom)
				check(target is Button and "ROSA COMPLETA" in target.text,"libero reaches roster and confirmation for every rotation")
		popup.get_ok_button().grab_focus();popup.get_ok_button().pressed.emit();await settle()
		check(clubs.formation_done99[0]==str(clubs.db.teams[0].id),"formation confirmation persists")
	clubs.hide();start.career_menu.open();var career=start.career_menu
	check(career.manager.new_career(str(clubs.db.teams[0].id),{"seed":99111,"autosave":false},8),"isolated career")
	career.show_page("prematch");await settle();career.formation_screen(career.club());await settle()
	check(is_instance_valid(career.modal) and career.modal.visible,"career shared formation opens")
	career.close_modal();await settle()
	FileAccess.open("res://docs/condition99-ui-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"errors":failures,"resolutions":["1920x1080","1280x720"]},"  "))
	print("CONDITION UI99 ","PASS" if failures.is_empty() else "FAIL"," ",failures);quit(0 if failures.is_empty() else 1)
func collect(node: Node,result: Array):
	if node is OptionButton:result.append(node)
	for child in node.get_children():collect(child,result)

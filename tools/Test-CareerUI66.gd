extends SceneTree
var game
var menu
var career
func _initialize(): call_deferred("run")
func button(code: int):
	var event=InputEventJoypadButton.new(); event.device=13; event.button_index=code; event.pressed=true; root.push_input(event)
	await process_frame; event=event.duplicate(); event.pressed=false; root.push_input(event); await process_frame
func settle():
	await process_frame; await process_frame
func run():
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	menu.installed_version="999.0.0"; menu.startup_scan=false
	menu.play.pressed.emit(); await settle(); assert(menu.play_hub.visible and menu.online.is_visible_in_tree())
	await button(JOY_BUTTON_B); assert(not menu.play_hub.visible)
	career=menu.career_menu; career.open(); await settle()
	assert(career.manager.new_career(menu.clubs.db.teams[0].id,{"seed":66022,"autosave":false,"fatigue":true,"injuries":false},11),career.manager.error)
	var cases=[]
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=size; root.content_scale_size=size; await settle()
		for view in ["home","calendario","classifica","competizioni","rosa","statistiche","notizie","archivio","impostazioni","prematch"]:
			career.show_page(view); await settle()
			assert(career.header.get_global_rect().end.y<career.nav.get_global_rect().position.y,"Header and navigation never overlap")
			for child in career.header.get_children():
				assert(career.header.get_global_rect().encloses(child.get_global_rect()),"Header content remains within the header")
			var controls=career.UI.controls(career.page); assert(not controls.is_empty(),"Every view needs a controller target "+view)
			assert(career.get_viewport().gui_get_focus_owner()!=null)
			for control in controls:
				control.grab_focus(); await process_frame
				var clipped=false; var ancestor=control.get_parent()
				while ancestor!=null:
					if ancestor is ScrollContainer: clipped=true; break
					ancestor=ancestor.get_parent()
				if not clipped: assert(Rect2(Vector2.ZERO,Vector2(size)).encloses(control.get_global_rect()),"Controller target outside screen "+view+" "+control.text+" "+str(control.get_global_rect()))
			if view=="classifica":
				var list=career.page.get_child(1).get_child(0)
				var header_cells=list.get_child(0).get_child(0).get_child(0).get_children()
				var row_cells=list.get_child(1).get_child(0).get_child(0).get_children()
				for i in header_cells.size(): assert(absf(header_cells[i].global_position.x-row_cells[i].global_position.x)<.1,"Standings header and values share exact column geometry")
			cases.append({"size":str(size),"view":view,"targets":controls.size()})
	career.show_page("rosa"); await settle(); career.formation_screen(career.club()); await settle(); assert(career.modal.visible)
	var reached=false
	for i in 18:
		var event=InputEventAction.new(); event.action="ui_down"; event.pressed=true; career.modal_input(event); await settle()
		if career.modal.get_ok_button().has_focus(): reached=true; break
	assert(reached,"Controller can reach the formation confirmation")
	career.close_modal()
	career.show_page("classifica"); await settle(); var first=career.UI.controls(career.page)[0]; first.grab_focus(); first.pressed.emit(); await settle(); assert(career.view=="team"); career.back(); await settle(); assert(career.view=="classifica")
	career.show_page("prematch"); await settle(); var fixture=career.manager.next_fixture(); career.launch_match(); assert(game.started and game.match_best_of==5 and game.match_points==25 and not career.visible)
	assert(game.match_management.active and game.match_management.rosters.size()==2)
	game.return_to_main_menu(); await settle(); assert(career.visible and career.manager.fixture(fixture.id).result.is_empty(),"Abandoned match cannot fabricate a result")
	FileAccess.open("res://docs/career66-ui-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"layouts":cases,"controller_back":true,"formation_modal":true,"team_navigation":true,"gameplay_launch":true,"abandon_keeps_pending":true},"  "))
	print("CAREER UI66 PASS ",cases.size()," layouts / controller / formation / profiles / 6v6 launch / abandon isolation"); game.free(); quit()

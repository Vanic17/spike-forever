extends SceneTree
const UI=preload("res://src/career_widgets.gd")
const League=preload("res://src/league.gd")

class Section extends Control:
	var db=League.new()
	func open(): show()
	func match_setup(): show()

class MatchStub extends Node:
	signal match_finished(result: Dictionary)
	var config: Dictionary={}
	var active:=false
	func start(value: Dictionary) -> bool: config=value; active=true; return true
	func stop(): active=false

class GameStub extends Node:
	var started:=false
	var players: Array=[]
	var match_management=null
	var gallery:=false
	var camera_mode:=0
	var legend_match=MatchStub.new()
	func _ready(): add_child(legend_match)
	func return_to_main_menu(): started=false

class HostStub extends Control:
	var clubs=Section.new()
	var online_menu=Section.new()
	var career_menu=Section.new()
	var overlay=Control.new()
	var play=Button.new()
	var online: Button
	var play_hub
	var legend_menu
	func _ready():
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for child in [clubs,online_menu,career_menu,overlay,play]: add_child(child); child.hide()

var game
var host
var menu
var failures:=0
var assertions:=0
var cases: Array=[]

func _initialize(): call_deferred("run")
func settle(): await process_frame; await process_frame
func check(ok: bool,message: String):
	assertions+=1
	if not ok: failures+=1; push_error("LEGEND UI72 FAIL "+message)

func pad(button: int):
	var event:=InputEventJoypadButton.new(); event.button_index=button; event.pressed=true; root.push_input(event)
	await process_frame
	event=event.duplicate(); event.pressed=false; root.push_input(event); await process_frame

func text_controls(node: Node) -> Array:
	var result: Array=[]
	for child in node.get_children():
		if child is LineEdit: result.append(child)
		result.append_array(text_controls(child))
	return result

func find_button(node: Node,needle: String) -> Button:
	for child in node.get_children():
		if child is Button and str(child.text).to_lower().contains(needle.to_lower()): return child
		var nested:=find_button(child,needle)
		if nested!=null: return nested
	return null

func run():
	TranslationServer.set_locale("it")
	var user_path:=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(user_path.contains("legend72-appdata"),"UI tests require isolated workspace APPDATA")
	if not user_path.contains("legend72-appdata"): quit(2); return
	# Exercise the menu without depending on the live 3D match simulation.
	game=GameStub.new(); root.add_child(game)
	host=HostStub.new(); root.add_child(host)
	menu=load("res://src/legend_menu.gd").new(); menu.host=host; menu.game=game; host.legend_menu=menu; host.add_child(menu)
	var hub=load("res://src/play_hub.gd").new(); hub.host=host; hub.game=game; host.play_hub=hub; host.add_child(hub)
	await settle()
	var controller=load("res://src/start_menu.gd").new()
	controller.setup_controller_navigation(); controller.free()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution; root.content_scale_size=resolution; await settle()
		hub.open(); await settle()
		check(hub.mode_buttons.size()==4,"All four game modes remain available")
		for button in hub.mode_buttons:
			check(button.is_visible_in_tree(),"Mode visible: "+str(button.text))
			check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(button.get_global_rect()),"Mode action within viewport: "+str(button.text))
		var first: Control=hub.first; first.grab_focus(); await pad(JOY_BUTTON_DPAD_RIGHT)
		check(root.gui_get_focus_owner()!=first,"Controller traverses mode cards")
		hub.mode_buttons[3].pressed.emit(); await settle()
		check(menu.visible and not hub.visible,"Fourth card opens player career")
		menu.show_page("create"); await settle()
		check(not UI.controls(menu.page).is_empty(),"Creation has controller actions")
		cases.append({"resolution":str(resolution),"page":"create","targets":UI.controls(menu.page).size()})
		menu.show_page("clubs"); await settle()
		var choices: Array=UI.controls(menu.page)
		check(choices.filter(func(control): return str(control.get_meta("focus_key","")).begins_with("club-")).size()==3,"Club screen offers exactly the three allowed starters")
		for control in choices:
			check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(control.get_global_rect()),"Starter club action within viewport: "+str(control.text))
		cases.append({"resolution":str(resolution),"page":"clubs","targets":choices.size()})
	menu.show_page("create"); await settle()
	menu.name_input.grab_focus(); await pad(JOY_BUTTON_A)
	check(is_instance_valid(menu.keyboard) and menu.keyboard.visible,"Controller opens virtual name keyboard")
	menu.keyboard_text.text="Campione 72"; menu.keyboard.confirmed.emit(); menu.keyboard.hide(); await settle()
	check(str(menu.draft.name)=="Campione 72" and menu.name_input.text=="Campione 72","Virtual keyboard commits name into creation profile")
	var initial: int=menu.draft.ratings.battuta
	menu.attribute_buttons.battuta[1].pressed.emit()
	check(int(menu.draft.ratings.battuta)==initial,"Exhausted creation budget prevents attribute increases")
	menu.attribute_buttons.battuta[0].pressed.emit(); menu.attribute_buttons.difesa[1].pressed.emit()
	check(int(menu.draft.ratings.battuta)==initial-1 and int(menu.draft.ratings.difesa)==51,"Creation can redistribute the fixed skill budget")
	check(str(menu.budget_label.text).contains("0 / 300"),"Creation displays the remaining budget")
	check(is_instance_valid(menu.preview) and menu.preview.data.get("name","")=="Campione 72","Profile preview follows identity changes")
	menu.chosen_best_of=3; menu.chosen_slot=8; menu.show_page("clubs"); await settle(); menu.create_career()
	if is_instance_valid(menu.modal): menu.modal.confirmed.emit()
	await settle()
	check(menu.manager.active() and menu.manager.state.profile.name=="Campione 72","Creation screen signs the configured player contract")
	check(menu.manager.engine.best_of()==3 and int(menu.manager.state.slot)==8,"Creation preserves selected format and separate save slot")
	# Set up a legitimate backend state for every career tab.
	var draft: Dictionary=menu.manager.default_profile(); draft.name="UI Atleta"; draft.number=72
	check(menu.manager.new_career(draft,str(menu.manager.starter_clubs()[0].id),{"seed":72040,"autosave":false,"best_of":3},9),menu.manager.error)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution; root.content_scale_size=resolution; await settle()
		for page_name in ["home","profile","growth","calendar","standings","offers","history","saves","help"]:
			menu.show_page(page_name); await settle()
			check(menu.header.get_global_rect().end.y<=menu.nav.get_global_rect().position.y+1,"Header and navigation stay separate: "+page_name)
			var controls: Array=UI.controls(menu.page)
			check(not controls.is_empty(),"Every page exposes a controller action: "+page_name)
			check(root.gui_get_focus_owner()!=null,"Focus exists on "+page_name)
			for control in controls:
				control.grab_focus(); await process_frame
				var ancestor=control.get_parent(); var scroll:=false
				while ancestor!=null:
					if ancestor is ScrollContainer: scroll=true; break
					ancestor=ancestor.get_parent()
				if not scroll: check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(control.get_global_rect()),"Action within viewport: "+page_name+" "+str(control.text))
			cases.append({"resolution":str(resolution),"page":page_name,"targets":controls.size()})
	menu.show_page("home"); await settle()
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	check(str(menu.view)!="home","R1/RB switches career tab")
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	await pad(JOY_BUTTON_B)
	check(menu.visible or hub.visible,"Controller back returns to an available menu")
	menu.show_page("profile"); await settle()
	var changed_style:=false
	for control in UI.controls(menu.page):
		if str(control.get_meta("focus_key",""))=="appearance-hair_style":
			control.select(4); control.item_selected.emit(4); changed_style=true; break
	check(changed_style and menu.manager.state.profile.appearance.hair_style=="ricci","Wardrobe picker updates the saved player identity")
	var training_rating: int=menu.manager.state.profile.ratings.battuta
	menu.manager.state.skill_points=3; menu.show_page("growth"); await settle()
	var trained:=false
	for control in UI.controls(menu.page):
		if str(control.get_meta("focus_key",""))=="upgrade-battuta": control.pressed.emit(); trained=true; break
	await settle()
	check(trained and int(menu.manager.state.profile.ratings.battuta)==training_rating+1,"Training action spends earned skill budget")
	check(menu.manager.save(),menu.manager.error)
	check(menu.manager.list_saves().any(func(row): return row.slot==9 and row.player_name=="UI Atleta"),"Separate player-career save browser metadata")
	menu.on_match_abandoned(); await settle()
	check(menu.visible and str(menu.manager.state.pending_fixture_id).is_empty(),"Abandon returns to career and clears pending match")
	game.started=true; menu.launch_match(); await settle()
	check(not menu.visible and not game.legend_match.config.is_empty(),"Career launches the isolated manual match engine")
	var config: Dictionary=game.legend_match.config
	var side:=0 if config.home_club_id==config.club.id else 1
	var sets: Array=[0,0]; sets[side]=2; var scores: Array=[[25,18],[25,18]] if side==0 else [[18,25],[18,25]]
	game.legend_match.match_finished.emit({"fixture_id":config.fixture_id,"score_order":"home_away","sets":sets,"set_scores":scores,"won":true,"performance":{"serves":12,"aces":2,"attacks":20,"kills":15,"digs":10,"receptions":12,"sets":8,"assists":6,"blocks":3,"errors":1,"touches":70,"minutes":42}})
	game.started=false; menu.on_match_abandoned(); await settle()
	check(menu.visible and str(menu.view)=="result" and int(menu.manager.state.xp)>0,"Measured match returns to career result screen with earned XP")
	check(menu.manager.state.match_history.size()==1,"Completed manual match is recorded once")
	TranslationServer.set_locale("en"); menu.show_page("create"); await settle()
	check(str(menu.budget_label.text).begins_with("POINTS LEFT:"),"English locale translates formatted creation budget")
	check(load("res://src/legend_locale.gd").text("BAGHER · 84%")=="FOREARM PASS · 84%","English live contact feedback retains its percentage")
	hub.open(); await settle()
	check(hub.mode_buttons[3].text=="BEGIN YOUR STORY","The fourth play card updates when the language changes")
	hub.hide()
	TranslationServer.set_locale("it"); menu.show_page("result"); await settle()
	FileAccess.open("res://docs/legend72-ui-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"assertions":assertions,"failures":failures,"layouts":cases,"four_modes":true,"controller_navigation":true,"separate_saves":true,"abandon_to_career":true},"  "))
	print("LEGEND UI72 ","PASS" if failures==0 else "FAIL"," assertions=",assertions," layouts=",cases.size())
	host.free(); game.free(); quit(1 if failures else 0)

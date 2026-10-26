extends CanvasLayer
var game
var panel: Control
var status: Label
var history: ItemList
var items: Array=[]
var client
var install_button: Button
var play: Button
var updates: Button
var online: Button
var online_menu
var settings_button: Button
var tutorial_button: Button
var settings_menu
var download_bar: ProgressBar
var download_label: Label
var edit: Button
var clubs
var back: Button
var overlay: Control
var dialog: Panel
var version_label: Label
var brush: FontFile
var installed_version:=""
var startup_scan:=false
var pending_release: Dictionary={}
var update_prompt: ConfirmationDialog
var prompt_previous_pause:=false
var installing_from_prompt:=false
var prompt_waiting:=false

func _ready() -> void:
	layer=20
	setup_controller_navigation()
	client=preload("res://src/update_client.gd").new()
	add_child(client)
	panel=Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var art:=TextureRect.new()
	art.texture=ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/start_background.png"))
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brush=FontFile.new()
	brush.load_dynamic_font("res://assets/ui/PermanentMarker-Regular.ttf")
	play=hero_button("GIOCA",true)
	updates=hero_button("AGGIORNAMENTI",false)
	play.focus_neighbor_right=play.get_path_to(updates)
	play.focus_neighbor_bottom=play.get_path_to(updates)
	updates.focus_neighbor_left=updates.get_path_to(play)
	updates.focus_neighbor_top=updates.get_path_to(play)
	clubs=preload("res://src/club_menu.gd").new(); clubs.game=game; clubs.host=self; add_child(clubs)
	online=hero_button("ONLINE",false)
	online_menu=preload("res://src/online_menu.gd").new(); online_menu.host=self; online_menu.game=game; online_menu.session=game.online_session; add_child(online_menu)
	game.online_session.menu=online_menu
	online.pressed.connect(online_menu.open)
	edit=hero_button("MODIFICA",false)
	settings_button=hero_button("IMPOSTAZIONI",false)
	settings_menu=preload("res://src/settings_menu.gd").new(); settings_menu.host=self; settings_menu.service=game.preferences; add_child(settings_menu)
	settings_button.pressed.connect(settings_menu.open)
	tutorial_button=hero_button("TUTORIAL",false)
	tutorial_button.pressed.connect(func(): game.tutorial.open(self))
	updates.focus_neighbor_right=updates.get_path_to(edit)
	edit.focus_neighbor_left=edit.get_path_to(updates)
	edit.pressed.connect(clubs.editor)
	play.pressed.connect(clubs.match_setup)
	updates.pressed.connect(show_updates)
	var navigation: Array=[play,online,tutorial_button,updates,edit,settings_button]
	for i in navigation.size():
		navigation[i].focus_neighbor_left=navigation[i].get_path_to(navigation[i-1 if i%3>0 else i])
		navigation[i].focus_neighbor_right=navigation[i].get_path_to(navigation[i+1 if i%3<2 else i])
		navigation[i].focus_neighbor_top=navigation[i].get_path_to(navigation[i-3 if i>=3 else i])
		navigation[i].focus_neighbor_bottom=navigation[i].get_path_to(navigation[i+3 if i<3 else i])
	version_label=Label.new()
	var version=JSON.parse_string(FileAccess.get_file_as_string("res://version.json")).version
	installed_version=str(version)
	version_label.text="v"+str(version)
	version_label.modulate=Color(0.85,0.86,0.9,0.7)
	panel.add_child(version_label)
	build_updates(str(version))
	client.download_progress.connect(func(received,total):
		download_bar.show(); download_label.show()
		download_bar.value=clampf(float(received)/total*100.0,0,100) if total>0 else 0
		download_label.text="%d%% · %.1f / %.1f MB"%[int(download_bar.value),received/1048576.0,total/1048576.0] if total>0 else "%.1f MB scaricati · dimensione in attesa"%[received/1048576.0])
	update_prompt=ConfirmationDialog.new()
	update_prompt.title="Aggiornamento disponibile"
	update_prompt.ok_button_text="AGGIORNA"
	update_prompt.cancel_button_text="NON ORA"
	update_prompt.exclusive=true
	add_child(update_prompt)
	update_prompt.confirmed.connect(accept_update)
	update_prompt.canceled.connect(defer_update)
	client.changed.connect(func(message):
		status.text=message
		play.disabled=client.downloading
		back.disabled=client.downloading
		install_button.disabled=client.busy or history.get_selected_items().is_empty())
	client.changed.connect(func(_message):
		if startup_scan and not client.busy and not client.downloading: startup_scan=false
		if installing_from_prompt and not client.busy and not client.downloading:
			installing_from_prompt=false
			game.paused=prompt_previous_pause
			if game.started: overlay.hide())
	client.versions_loaded.connect(func(versions):
		items=versions
		history.clear()
		for entry in versions: history.add_item(str(entry.get("tag_name",""))+" — "+str(entry.get("name","")))
		if not versions.is_empty(): history.select(0); install_button.disabled=false
		on_versions_ready(versions))
	panel.resized.connect(layout)
	layout()
	play.grab_focus()
	# Headless verification uses deterministic fake responses instead of DNS.
	if DisplayServer.get_name()!="headless": call_deferred("check_startup_updates")

func check_startup_updates() -> void:
	startup_scan=true
	client.check()

func on_versions_ready(versions: Array) -> void:
	if not startup_scan: return
	startup_scan=false
	pending_release=client.newer_release(versions,installed_version)
	if pending_release.is_empty(): return
	prompt_waiting=true
	maybe_prompt_update()

func maybe_prompt_update() -> void:
	if game.network_match(): return
	if game.tutorial!=null and (game.tutorial.active or game.tutorial.menu.visible): return
	if not prompt_waiting or update_prompt.visible: return
	# A slow network response must not steal a held charge or a live rally.
	if game.started and game.phase!="POINT" and not (game.phase=="SERVE" and not game.charging and not game.toss_active): return
	prompt_waiting=false
	prompt_previous_pause=game.paused
	game.paused=true
	update_prompt.dialog_text="È disponibile Spike Forever "+String(pending_release.tag_name)+".\nVersione installata: "+installed_version+".\n\nVuoi scaricare e installare l'aggiornamento?\nIl gioco si riavvierà dopo l'installazione."
	update_prompt.popup_centered(Vector2i(620,230))
	update_prompt.get_ok_button().grab_focus()

func accept_update() -> void:
	if pending_release.is_empty(): return
	update_prompt.hide()
	installing_from_prompt=true
	overlay.show()
	client.install(pending_release)

func defer_update() -> void:
	update_prompt.hide()
	game.paused=prompt_previous_pause
	pending_release={}
	prompt_waiting=false
	if not game.started: play.grab_focus()

func setup_controller_navigation() -> void:
	# UI bindings are explicit: runtime Godot does not necessarily load the
	# editor's built-in joypad events. Gameplay action bindings stay untouched.
	for binding in [["ui_accept",JOY_BUTTON_A],["ui_cancel",JOY_BUTTON_B]]:
		if not InputMap.has_action(binding[0]): InputMap.add_action(binding[0])
		var event:=InputEventJoypadButton.new()
		event.device=-1
		event.button_index=binding[1]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)
	for binding in [["ui_left",JOY_AXIS_LEFT_X,-1.0],["ui_right",JOY_AXIS_LEFT_X,1.0],["ui_up",JOY_AXIS_LEFT_Y,-1.0],["ui_down",JOY_AXIS_LEFT_Y,1.0]]:
		if not InputMap.has_action(binding[0]): InputMap.add_action(binding[0],0.5)
		var event:=InputEventJoypadMotion.new()
		event.device=-1
		event.axis=binding[1]
		event.axis_value=binding[2]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)

func hero_button(text: String, gold: bool) -> Button:
	var button:=Button.new()
	button.text=text
	button.add_theme_font_override("font",brush)
	button.add_theme_color_override("font_color",Color("fff9e8") if gold else Color("d7d9dc"))
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	button.add_theme_color_override("font_focus_color",Color.WHITE)
	button.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	button.add_theme_constant_override("shadow_offset_x",2)
	button.add_theme_constant_override("shadow_offset_y",3)
	var image:=Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/button_dark.svg"))
	var slab:=StyleBoxTexture.new()
	slab.texture=ImageTexture.create_from_image(image)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: slab.set_texture_margin(side,12)
	button.add_theme_stylebox_override("normal",slab)
	var hover:=slab.duplicate()
	hover.modulate_color=Color(1.18,1.15,1.05)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("hover_pressed",hover)
	var pressed:=slab.duplicate()
	pressed.modulate_color=Color(0.75,0.72,0.68)
	button.add_theme_stylebox_override("pressed",pressed)
	var focus:=StyleBoxFlat.new()
	focus.bg_color=Color.TRANSPARENT
	focus.draw_center=false
	focus.border_color=Color("ffe2a0")
	focus.set_border_width_all(2)
	focus.shadow_color=Color(1,0.65,0.2,0.65)
	focus.shadow_size=0
	button.add_theme_stylebox_override("focus",focus)
	var gold_image:=Image.new(); gold_image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/button_gold.svg"))
	var active:=slab.duplicate(); active.texture=ImageTexture.create_from_image(gold_image)
	button.add_theme_stylebox_override("hover",active)
	button.add_theme_stylebox_override("hover_pressed",active)
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.focus_entered.connect(func(): button.add_theme_stylebox_override("normal",active))
	button.focus_exited.connect(func(): button.add_theme_stylebox_override("normal",slab))
	button.mouse_entered.connect(func(): button.grab_focus())
	panel.add_child(button)
	return button

func build_updates(version: String) -> void:
	overlay=Control.new()
	panel.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new()
	shade.color=Color(0.01,0.015,0.025,0.80)
	overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# A hidden PanelContainer can retain the enormous height first computed
	# by wrapped labels at zero width. Keep the modal bounds independent of
	# its contents, then let the inner container lay out inside those bounds.
	dialog=Panel.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("10151eee")
	style.border_color=Color("b99555")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	dialog.add_theme_stylebox_override("panel",style)
	overlay.add_child(dialog)
	var margin:=MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,25)
	dialog.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	margin.add_child(column)
	var title:=Label.new()
	title.text="AGGIORNAMENTI"
	title.add_theme_font_override("font",brush)
	title.add_theme_font_size_override("font_size",32)
	column.add_child(title)
	var installed:=Label.new()
	installed.text="Versione installata: "+version+"   ·   Patch e versioni precedenti"
	installed.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(installed)
	status=Label.new()
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.text="Gioca offline oppure cerca una versione da installare."
	if FileAccess.file_exists("res://update-result.json"):
		var result=JSON.parse_string(FileAccess.get_file_as_string("res://update-result.json"))
		if result is Dictionary: status.text=str(result.get("message",status.text))
	column.add_child(status)
	download_bar=ProgressBar.new(); download_bar.custom_minimum_size.y=24; download_bar.show_percentage=false; column.add_child(download_bar); download_bar.hide()
	var fill=StyleBoxFlat.new(); fill.bg_color=Color("d4ad5c"); fill.set_corner_radius_all(5); download_bar.add_theme_stylebox_override("fill",fill)
	download_label=Label.new(); column.add_child(download_label); download_label.hide()
	client.changed.connect(func(_message):
		if not client.downloading: download_bar.hide(); download_label.hide())
	history=ItemList.new()
	history.custom_minimum_size.y=110
	history.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(history)
	install_button=Button.new()
	install_button.text="INSTALLA LA VERSIONE SELEZIONATA"
	install_button.custom_minimum_size.y=46
	install_button.disabled=true
	column.add_child(install_button)
	history.item_selected.connect(func(_index): install_button.disabled=client.busy)
	install_button.pressed.connect(func():
		var selected:=history.get_selected_items()
		if not selected.is_empty(): client.install(items[selected[0]]))
	back=Button.new()
	back.text="TORNA AL MENU"
	back.custom_minimum_size.y=40
	column.add_child(back)
	back.pressed.connect(close_updates)
	overlay.hide()

func layout() -> void:
	var size:=panel.size
	var scale:=minf(size.x/1672.0,size.y/941.0)
	var origin: Vector2=(size-Vector2(1672,941)*scale)*0.5
	var buttons: Array=[play,online,tutorial_button,updates,edit,settings_button]
	for i in buttons.size():
		buttons[i].position=origin+Vector2(150+(i%3)*466,766+(i/3)*74)*scale
		buttons[i].size=Vector2(440,64)*scale
		buttons[i].add_theme_font_size_override("font_size",maxi(13,int(29*scale)))
	version_label.position=Vector2(18,size.y-30)
	dialog.size=Vector2(minf(900,size.x-40),minf(620,size.y-40))
	dialog.position=(size-dialog.size)*0.5

func show_updates() -> void:
	overlay.show()
	layout()
	play.focus_mode=Control.FOCUS_NONE
	updates.focus_mode=Control.FOCUS_NONE
	online.focus_mode=Control.FOCUS_NONE; edit.focus_mode=Control.FOCUS_NONE
	settings_button.focus_mode=Control.FOCUS_NONE
	tutorial_button.focus_mode=Control.FOCUS_NONE
	back.grab_focus()
	client.check()

func close_updates() -> void:
	if client.downloading: return
	overlay.hide()
	play.focus_mode=Control.FOCUS_ALL
	updates.focus_mode=Control.FOCUS_ALL
	online.focus_mode=Control.FOCUS_ALL; edit.focus_mode=Control.FOCUS_ALL
	settings_button.focus_mode=Control.FOCUS_ALL
	tutorial_button.focus_mode=Control.FOCUS_ALL
	updates.grab_focus()

func _process(_dt: float) -> void:
	if panel: panel.visible=not game.started or installing_from_prompt
	maybe_prompt_update()

func _input(event: InputEvent) -> void:
	if client==null: return
	if game.tutorial!=null and game.tutorial.menu.visible: return
	if not game.started and event.is_action_pressed("start"):
		if not clubs.visible and not online_menu.visible and not settings_menu.visible and not game.tutorial.menu.visible: clubs.match_setup()
		get_viewport().set_input_as_handled()
		return
	if update_prompt!=null and update_prompt.visible:
		if event.is_action_pressed("start"): get_viewport().set_input_as_handled()
		return
	if client.downloading:
		get_viewport().set_input_as_handled()
	elif overlay!=null and overlay.visible and event.is_action_pressed("ui_cancel"):
		close_updates()
		get_viewport().set_input_as_handled()

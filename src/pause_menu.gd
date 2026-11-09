extends CanvasLayer
var game
var surface: Control
var resume_button: Button
var menu_button: Button
var substitution_button: Button
var condition_button99: Button
var condition_dialog99: AcceptDialog
func _ready() -> void:
	layer=15
	surface=Control.new(); add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade=ColorRect.new(); shade.color=Color(0.015,0.025,0.045,0.84); surface.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre=CenterContainer.new(); surface.add_child(centre); centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel=PanelContainer.new(); panel.custom_minimum_size=Vector2(480,0); centre.add_child(panel)
	var style=StyleBoxFlat.new(); style.bg_color=Color("142438"); style.border_color=Color("d8b962"); style.set_border_width_all(2); style.set_corner_radius_all(12)
	style.content_margin_left=36; style.content_margin_right=36; style.content_margin_top=30; style.content_margin_bottom=30
	panel.add_theme_stylebox_override("panel",style)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",20); panel.add_child(column)
	var title=Label.new(); title.text="PARTITA IN PAUSA"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",28); column.add_child(title)
	resume_button=Button.new(); resume_button.text="RIPRENDI PARTITA"; resume_button.custom_minimum_size.y=60; column.add_child(resume_button)
	substitution_button=Button.new(); substitution_button.text="SOSTITUZIONI / RESISTENZA"; substitution_button.custom_minimum_size.y=60; column.add_child(substitution_button)
	condition_button99=Button.new();condition_button99.text="CONDIZIONE GIOCATORI";condition_button99.custom_minimum_size.y=60;column.add_child(condition_button99)
	condition_button99.pressed.connect(show_condition99)
	menu_button=Button.new(); menu_button.text="TORNA AL MENU PRINCIPALE"; menu_button.custom_minimum_size.y=60; column.add_child(menu_button)
	resume_button.focus_neighbor_bottom=resume_button.get_path_to(substitution_button); substitution_button.focus_neighbor_top=substitution_button.get_path_to(resume_button)
	substitution_button.focus_neighbor_bottom=substitution_button.get_path_to(menu_button); menu_button.focus_neighbor_top=menu_button.get_path_to(substitution_button)
	resume_button.pressed.connect(func(): game.request_pause(false))
	substitution_button.pressed.connect(func(): game.match_management.open())
	menu_button.pressed.connect(func(): game.return_to_main_menu())
	var hint=Label.new(); hint.text="A / Croce: conferma · B / Cerchio: riprendi"; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; column.add_child(hint)
	surface.hide()
func _process(_dt: float) -> void:
	var legend: bool=game.legend_match!=null and game.legend_match.active
	substitution_button.visible=not legend
	substitution_button.disabled=legend or not game.match_management.active
	menu_button.text=preload("res://src/legend_locale.gd").text("TORNA ALLA CARRIERA") if legend else "TORNA AL MENU PRINCIPALE"
	condition_button99.visible=not game.form99.is_empty()
	var order99: Array=[resume_button]
	if not legend:order99.append(substitution_button)
	if condition_button99.visible:order99.append(condition_button99)
	order99.append(menu_button)
	for i in order99.size():
		order99[i].focus_neighbor_top=order99[i].get_path_to(order99[maxi(0,i-1)])
		order99[i].focus_neighbor_bottom=order99[i].get_path_to(order99[mini(order99.size()-1,i+1)])
	var wanted: bool=game.started and game.paused and not game.match_finished and (game.tutorial==null or not game.tutorial.active) and not (game.substitution_scene!=null and game.substitution_scene.active)
	if surface.visible==wanted: return
	surface.visible=wanted
	if wanted and not game.match_management.menu.opened: resume_button.grab_focus()
func _input(event: InputEvent) -> void:
	if is_instance_valid(condition_dialog99) and condition_dialog99.visible:return
	if game.match_management!=null and game.match_management.menu.opened: return
	if surface!=null and surface.visible and event.is_action_pressed("ui_cancel"):
		game.request_pause(false)
		get_viewport().set_input_as_handled()

func show_condition99() -> void:
	if is_instance_valid(condition_dialog99):condition_dialog99.queue_free()
	condition_dialog99=AcceptDialog.new();condition_dialog99.title=tr("CONDIZIONE GIOCATORI");condition_dialog99.exclusive=true;surface.add_child(condition_dialog99)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",24);condition_dialog99.add_child(columns)
	for side in 2:
		var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(box)
		var heading:=Label.new();heading.text=game.team_names[side];heading.add_theme_font_size_override("font_size",23);box.add_child(heading)
		var grid=preload("res://src/condition_ui99.gd").list(box,game.match_management.rosters[side],game.form99,game.use_player_stats);grid.columns=1
	condition_dialog99.confirmed.connect(func():condition_button99.grab_focus())
	condition_dialog99.window_input.connect(func(event):
		if event.is_action_pressed("ui_cancel"):condition_dialog99.hide();condition_button99.grab_focus();get_viewport().set_input_as_handled())
	condition_dialog99.popup_centered(Vector2i(1120,600));condition_dialog99.get_ok_button().grab_focus()

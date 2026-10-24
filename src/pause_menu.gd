extends CanvasLayer
var game
var surface: Control
var resume_button: Button
var menu_button: Button
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
	menu_button=Button.new(); menu_button.text="TORNA AL MENU PRINCIPALE"; menu_button.custom_minimum_size.y=60; column.add_child(menu_button)
	resume_button.focus_neighbor_bottom=resume_button.get_path_to(menu_button); menu_button.focus_neighbor_top=menu_button.get_path_to(resume_button)
	resume_button.pressed.connect(func(): game.paused=false)
	menu_button.pressed.connect(func(): game.return_to_main_menu())
	var hint=Label.new(); hint.text="A / Croce: conferma · B / Cerchio: riprendi"; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; column.add_child(hint)
	surface.hide()
func _process(_dt: float) -> void:
	var wanted: bool=game.started and game.paused
	if surface.visible==wanted: return
	surface.visible=wanted
	if wanted: resume_button.grab_focus()
func _input(event: InputEvent) -> void:
	if surface!=null and surface.visible and event.is_action_pressed("ui_cancel"):
		game.paused=false
		get_viewport().set_input_as_handled()

extends Node
## Master mute covers match voices, ambience, menu music and future buses.
signal mute_changed(value: bool)
var game
var settings_path:="user://audio_preferences.cfg"
var muted:=false
var pressed_devices: Dictionary={}
var keyboard_pressed:=false
var toast: Label
var toast_left:=0.0

func _ready() -> void:
	var config:=ConfigFile.new()
	if config.load(settings_path)==OK: muted=bool(config.get_value("audio","muted",false))
	AudioServer.set_bus_mute(0,muted)
	get_tree().node_added.connect(watch_window)
	watch_window(get_tree().root)
	for node in get_tree().root.find_children("*","Window",true,false): watch_window(node)
	var layer:=CanvasLayer.new(); layer.layer=100; add_child(layer)
	toast=Label.new(); toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast.add_theme_font_size_override("font_size",22); toast.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast.add_theme_constant_override("shadow_offset_x",2); toast.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(toast); toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); toast.offset_top=145; toast.offset_bottom=180; toast.hide()

func watch_window(node: Node) -> void:
	if node is Window and not node.window_input.is_connected(handle_input): node.window_input.connect(handle_input)

func _input(event: InputEvent) -> void: handle_input(event)

func handle_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.button_index==JOY_BUTTON_LEFT_STICK:
		if event.pressed:
			if not pressed_devices.get(event.device,false): set_muted(not muted)
			pressed_devices[event.device]=true
		else: pressed_devices.erase(event.device)
	elif event is InputEventKey and event.physical_keycode==KEY_M:
		var owner:=get_viewport().gui_get_focus_owner()
		if event.pressed and (owner is LineEdit or owner is TextEdit): return
		if event.pressed and not event.echo:
			if not keyboard_pressed: set_muted(not muted)
			keyboard_pressed=true
		elif not event.pressed: keyboard_pressed=false

func set_muted(value: bool) -> void:
	muted=value; AudioServer.set_bus_mute(0,muted)
	var config:=ConfigFile.new(); config.set_value("audio","muted",muted); config.save(settings_path)
	if toast!=null:
		toast.text="AUDIO DISATTIVATO · L3 / LS per riattivare" if muted else "AUDIO ATTIVO · L3 / LS per disattivare"
		toast_left=2.5; toast.show()
	mute_changed.emit(muted)

func _process(dt: float) -> void:
	if toast_left>0:
		toast_left-=dt
		if toast_left<=0 and toast!=null: toast.hide()

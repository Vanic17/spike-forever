extends CanvasLayer
var game
var panel: Control
var status: Label
var history: ItemList
var items: Array=[]
var client
var install_button: Button

func _ready() -> void:
	client=preload("res://src/update_client.gd").new()
	add_child(client)
	panel=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.025,0.04,0.07,0.97)
	panel.add_theme_stylebox_override("panel",style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,45)
	panel.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	var title:=Label.new()
	title.text="SPIKE FOREVER"
	title.add_theme_font_size_override("font_size",44)
	column.add_child(title)
	var version:=Label.new()
	version.text="Versione "+str(JSON.parse_string(FileAccess.get_file_as_string("res://version.json")).version)+"  |  S · Setter   OH · Outside Hitter   MB · Middle Blocker   OPP · Opposite   L · Libero"
	version.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(version)
	var play:=Button.new()
	play.text="GIOCA"
	play.custom_minimum_size.y=54
	column.add_child(play)
	play.pressed.connect(func(): game.started=true; panel.hide())
	var updates:=Button.new()
	updates.text="AGGIORNAMENTI E VERSIONI PRECEDENTI"
	updates.custom_minimum_size.y=48
	column.add_child(updates)
	updates.pressed.connect(client.check)
	status=Label.new()
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.text="Gioca offline oppure cerca aggiornamenti e patch precedenti."
	if FileAccess.file_exists("res://update-result.json"):
		var result=JSON.parse_string(FileAccess.get_file_as_string("res://update-result.json"))
		if result is Dictionary: status.text=str(result.get("message",status.text))
	column.add_child(status)
	history=ItemList.new()
	history.custom_minimum_size.y=180
	history.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(history)
	install_button=Button.new()
	install_button.text="INSTALLA LA VERSIONE SELEZIONATA"
	install_button.disabled=true
	column.add_child(install_button)
	history.item_selected.connect(func(_index): install_button.disabled=client.busy)
	install_button.pressed.connect(func():
		var selected:=history.get_selected_items()
		if not selected.is_empty(): client.install(items[selected[0]]))
	client.changed.connect(func(message): status.text=message; play.disabled=client.downloading; install_button.disabled=client.busy or history.get_selected_items().is_empty())
	client.versions_loaded.connect(func(versions):
		items=versions
		history.clear()
		for entry in versions: history.add_item(str(entry.get("tag_name",""))+" — "+str(entry.get("name","")))
		if not versions.is_empty(): history.select(0); install_button.disabled=false)
	play.grab_focus()

func _process(_dt: float) -> void:
	if panel: panel.visible=not game.started

func _input(_event: InputEvent) -> void:
	if client!=null and client.downloading: get_viewport().set_input_as_handled()

extends Control
const UI=preload("res://src/career_widgets.gd")
var host
var game
var frame: Control
var online: Button
var first: Button
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=UI.theme()
	var bg=ColorRect.new(); bg.color=Color("081322"); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new(); add_child(frame); frame.size=Vector2(1920,1080)
	var title=UI.heading(frame,"SCEGLI COME GIOCARE",62); title.position=Vector2(75,92)
	var sub=UI.label(frame,"Il campo è tuo. Una partita, una sfida online, una stagione intera.",26,UI.MUTED); sub.position=Vector2(78,174)
	var cards=HBoxContainer.new(); frame.add_child(cards); cards.position=Vector2(75,265); cards.size=Vector2(1770,650); cards.add_theme_constant_override("separation",24)
	var entries=[["01 / MATCH DAY","ESIBIZIONE","Scegli squadre, divise e formazione.\nUna partita, alle tue condizioni.","GIOCA UNA PARTITA","arena",func(): hide(); host.clubs.match_setup()], ["02 / HEAD TO HEAD","ONLINE","Crea una stanza o usa un codice.\nDue allenatori, un solo campo.","CREA O UNISCITI","net",func(): hide(); host.online_menu.open()], ["03 / MASTER LEAGUE","CAMPIONATO","Guida uno dei dodici club della SuperLega.\nCalendario, rosa, coppe e una storia da scrivere.","ENTRA IN CAMPIONATO","stands",func(): hide(); host.career_menu.open()]]
	for i in entries.size():
		var entry=entries[i]; var v=UI.card(cards,570,650)
		var image=TextureRect.new(); image.texture=UI.Brand.texture("assets/ui/career66/"+entry[4]+".png"); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.custom_minimum_size=Vector2(510,275); v.add_child(image)
		UI.label(v,entry[0],20,UI.GOLD); UI.heading(v,entry[1],54); UI.wrap(v,entry[2],25,UI.MUTED)
		var spacer=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(spacer)
		var b=UI.button(v,entry[3],entry[5]); if i==0: first=b
		if i==1: online=b; host.online=b
	var back=UI.button(frame,"B / CERCHIO  ·  INDIETRO",close); back.position=Vector2(75,965); back.size=Vector2(550,62)
	resized.connect(layout); layout(); hide()
func layout():
	if frame==null: return
	var factor=minf(size.x/1920.0,size.y/1080.0); frame.scale=Vector2.ONE*factor; frame.position=(size-Vector2(1920,1080)*factor)*.5
func open():
	host.clubs.hide(); host.online_menu.hide(); host.career_menu.hide(); host.overlay.hide(); show(); first.grab_focus()
func close(): hide(); host.play.grab_focus()
func _input(event):
	if not visible: return
	if event.is_action_pressed("ui_cancel"): close(); get_viewport().set_input_as_handled()
	var direction=Vector2.ZERO
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]): direction=pair[1]
	if direction!=Vector2.ZERO: UI.navigate(self,direction); get_viewport().set_input_as_handled()

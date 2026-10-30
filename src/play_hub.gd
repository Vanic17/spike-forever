extends Control
const UI=preload("res://src/career_widgets.gd")
const Locale=preload("res://src/legend_locale.gd")
var host
var game
var frame: Control
var online: Button
var first: Button
var mode_buttons: Array[Button]=[]
func _ready():
	auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=UI.theme()
	var bg=ColorRect.new(); bg.color=Color("081322"); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new(); add_child(frame); frame.size=Vector2(1920,1080)
	var title=UI.heading(frame,"SCEGLI COME GIOCARE",62); title.position=Vector2(75,55)
	var sub=UI.label(frame,"Il campo è tuo. Una partita, una sfida online, una stagione o la tua carriera.",26,UI.MUTED); sub.position=Vector2(78,153)
	var cards=GridContainer.new(); cards.columns=2; frame.add_child(cards); cards.position=Vector2(75,235); cards.size=Vector2(1770,684); cards.add_theme_constant_override("h_separation",24); cards.add_theme_constant_override("v_separation",24)
	var entries=[["01 / MATCH DAY","ESIBIZIONE","Scegli squadre, divise e formazione.\nUna partita, alle tue condizioni.","GIOCA UNA PARTITA","arena",func(): hide(); host.clubs.match_setup()], ["02 / HEAD TO HEAD","ONLINE","Crea una stanza o usa un codice.\nDue allenatori, un solo campo.","CREA O UNISCITI","net",func(): hide(); host.online_menu.open()], ["03 / MASTER LEAGUE","CAMPIONATO","Guida uno dei dodici club della SuperLega.\nCalendario, rosa, coppe e una storia da scrivere.","ENTRA IN CAMPIONATO","stands",func(): hide(); host.career_menu.open()], ["04 / CARRIERA GIOCATORE","DIVENTA UN MITO","Crea il tuo atleta e conquista un posto tra i grandi.\nUn solo giocatore, tutta la sua carriera.","INIZIA LA TUA STORIA","arena",func(): hide(); host.legend_menu.open()]]
	for i in entries.size():
		var entry=entries[i]; var v=UI.card(cards,873,330)
		var row=HBoxContainer.new(); row.add_theme_constant_override("separation",24); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(row)
		var image=TextureRect.new(); image.texture=UI.Brand.texture("assets/ui/career66/"+entry[4]+".png"); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.custom_minimum_size=Vector2(220,260); row.add_child(image)
		if i==3: image.modulate=Color("9ae2df")
		var details=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(details)
		UI.label(details,entry[0],20,UI.GOLD); UI.heading(details,entry[1],44); UI.wrap(details,entry[2],25,UI.MUTED)
		var spacer=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; details.add_child(spacer)
		var b=UI.button(details,entry[3],entry[5]); b.custom_minimum_size.y=58; b.add_theme_font_size_override("font_size",25); mode_buttons.append(b)
		if i==0: first=b
		if i==1: online=b; host.online=b
	var back=UI.button(frame,"B / CERCHIO  ·  INDIETRO",close); back.position=Vector2(75,965); back.size=Vector2(550,62)
	resized.connect(layout); layout(); localize(frame); hide()
func localize(node: Node):
	if node is Label or node is Button:
		if not node.has_meta("mode_text"): node.set_meta("mode_text",node.text)
		node.text=Locale.text(str(node.get_meta("mode_text")))
	for child in node.get_children(): localize(child)
func layout():
	if frame==null: return
	var factor=minf(size.x/1920.0,size.y/1080.0); frame.scale=Vector2.ONE*factor; frame.position=(size-Vector2(1920,1080)*factor)*.5
func open():
	host.clubs.hide(); host.online_menu.hide(); host.career_menu.hide(); host.overlay.hide()
	if host.get("legend_menu")!=null: host.legend_menu.hide()
	localize(frame); show(); first.grab_focus()
func close(): hide(); host.play.grab_focus()
func _input(event):
	if not visible: return
	if event.is_action_pressed("ui_cancel"): close(); get_viewport().set_input_as_handled()
	var direction=Vector2.ZERO
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]): direction=pair[1]
	if direction!=Vector2.ZERO: UI.navigate(self,direction); get_viewport().set_input_as_handled()

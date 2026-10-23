extends Control
var game
var host
var db=preload("res://src/league.gd").new()
var body: VBoxContainer
var team_pick: OptionButton
var player_pick: ItemList
var fields: VBoxContainer
var current: Dictionary={}
var inputs: Dictionary={}
var music:=AudioStreamPlayer.new()
var last_track:=-1
var message: Label
var player_card
var editor_scroll: ScrollContainer
var keyboard: ConfirmationDialog
var keyboard_text: LineEdit
var keyboard_target: LineEdit
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme_new=Theme.new()
	theme_new.default_font_size=19
	for type in ["PanelContainer","Button","LineEdit","OptionButton","SpinBox","ItemList"]:
		var style=StyleBoxFlat.new(); style.bg_color=Color("152435"); style.border_color=Color("b99850")
		style.set_border_width_all(1); style.set_corner_radius_all(8); style.content_margin_left=18; style.content_margin_right=18; style.content_margin_top=12; style.content_margin_bottom=12
		theme_new.set_stylebox("normal" if type!="PanelContainer" else "panel",type,style)
	theme=theme_new
	var focus=StyleBoxFlat.new(); focus.bg_color=Color(0,0,0,0); focus.border_color=Color("ffe2a0"); focus.set_border_width_all(3); focus.set_corner_radius_all(8)
	for type in ["Button","LineEdit","OptionButton","ItemList"]: theme_new.set_stylebox("focus",type,focus)
	var bg=ColorRect.new(); bg.color=Color(0.025,0.04,0.065,0.98); add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin=MarginContainer.new(); add_child(margin); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,36)
	body=VBoxContainer.new(); body.add_theme_constant_override("separation",18); margin.add_child(body)
	add_child(music); music.volume_db=-15; music.finished.connect(next_track)
	get_viewport().gui_focus_changed.connect(func(control):
		if visible and is_instance_valid(editor_scroll) and control!=null and editor_scroll.is_ancestor_of(control): editor_scroll.ensure_control_visible(control))
	hide()
func next_track() -> void:
	var choices=[0,1,2,3]; choices.erase(last_track); last_track=choices.pick_random()
	music.stream=AudioStreamMP3.load_from_file("res://assets/audio/menu/track%d.mp3"%last_track); music.play()
func _process(_dt: float) -> void:
	if game.started: music.stop()
	elif not music.playing: next_track()
	if visible and is_instance_valid(editor_scroll) and editor_scroll.is_visible_in_tree() and (keyboard==null or not keyboard.visible):
		for device in Input.get_connected_joypads():
			var axis=Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y)
			if absf(axis)>0.25: editor_scroll.scroll_vertical+=roundi(axis*650*_dt)

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventJoypadButton or not event.pressed: return
	if keyboard!=null and keyboard.visible: return
	var focused=get_viewport().gui_get_focus_owner()
	if focused!=null and event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN] and (focused is LineEdit or focused is SpinBox):
		var next=focused.find_prev_valid_focus() if event.button_index==JOY_BUTTON_DPAD_UP else focused.find_next_valid_focus()
		if next!=null: next.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if focused is SpinBox and event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
		focused.value+=focused.step*(-1 if event.button_index==JOY_BUTTON_DPAD_LEFT else 1)
		get_viewport().set_input_as_handled()
		return
	if focused is LineEdit:
		if focused.get_parent() is SpinBox:
			var spin: SpinBox=focused.get_parent()
			if event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
				spin.value+=spin.step*(-1 if event.button_index==JOY_BUTTON_DPAD_LEFT else 1)
				get_viewport().set_input_as_handled()
		elif event.button_index==JOY_BUTTON_A:
			open_keyboard(focused)
			get_viewport().set_input_as_handled()

func open_keyboard(target: LineEdit) -> void:
	keyboard_target=target
	if keyboard==null:
		keyboard=ConfirmationDialog.new(); keyboard.title="MODIFICA NOME"; keyboard.ok_button_text="SALVA NOME"; keyboard.cancel_button_text="ANNULLA"; add_child(keyboard)
		var box=VBoxContainer.new(); keyboard.add_child(box)
		keyboard_text=LineEdit.new(); box.add_child(keyboard_text)
		var grid=GridContainer.new(); grid.columns=10; box.add_child(grid)
		for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-àèéìòù'":
			var key: String=character
			button(grid,key,func(): keyboard_text.text+=key)
		var actions=HBoxContainer.new(); box.add_child(actions)
		button(actions,"SPAZIO",func(): keyboard_text.text+=" ")
		button(actions,"CANCELLA",func(): keyboard_text.text=keyboard_text.text.left(maxi(0,keyboard_text.text.length()-1)))
		keyboard.confirmed.connect(func():
			if is_instance_valid(keyboard_target):
				keyboard_target.text=keyboard_text.text; keyboard_target.text_changed.emit(keyboard_text.text); keyboard_target.grab_focus())
	keyboard_text.text=target.text
	keyboard.popup_centered(Vector2i(780,580))
	var container=keyboard_text.get_parent()
	container.get_child(1).get_child(0).grab_focus()
func clear(title: String) -> void:
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	var top=HBoxContainer.new(); body.add_child(top)
	var heading=Label.new(); heading.text=title; heading.add_theme_font_size_override("font_size",36); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(heading)
	button(top,"TORNA AL MENU",func(): hide(); host.play.grab_focus())
	show()
	if top.get_child_count()>1: top.get_child(1).grab_focus()
func button(parent: Node,text: String,callback: Callable) -> Button:
	var b=Button.new(); b.text=text; b.pressed.connect(callback); parent.add_child(b); return b
func label(parent: Node,text: String) -> void:
	var l=Label.new(); l.text=text; parent.add_child(l)
func picker(parent: Node,options: Array) -> OptionButton:
	var p=OptionButton.new(); for option in options: p.add_item(str(option))
	parent.add_child(p); return p
func editor() -> void:
	clear("MODIFICA  /  SUPERLEGA 2026–27")
	label(body,"Il tuo roster personale • salvato su questo PC • conservato dopo gli aggiornamenti")
	var toolbar=HBoxContainer.new(); body.add_child(toolbar)
	team_pick=picker(toolbar,db.teams.map(func(t): return t.name)); team_pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(toolbar,"FORMAZIONE INIZIALE",edit_lineup)
	var columns=HBoxContainer.new(); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",28); body.add_child(columns)
	player_pick=ItemList.new(); player_pick.custom_minimum_size.x=265; player_pick.add_theme_font_size_override("font_size",16); columns.add_child(player_pick)
	player_card=preload("res://src/player_card.gd").new(); player_card.custom_minimum_size=Vector2(355,530); columns.add_child(player_card)
	var scroll=ScrollContainer.new(); scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_child(scroll)
	editor_scroll=scroll
	fields=VBoxContainer.new(); fields.size_flags_horizontal=Control.SIZE_EXPAND_FILL; fields.add_theme_constant_override("separation",12); scroll.add_child(fields)
	message=Label.new(); body.add_child(message)
	team_pick.item_selected.connect(func(_i): roster()); player_pick.item_selected.connect(edit_player); roster()
func roster() -> void:
	player_pick.clear()
	for p in db.teams[team_pick.selected].roster:
		var role: String={"setter":"S","opposite":"OPP","outside_hitter":"OH","middle_blocker":"MB","libero":"L"}.get(p.role,p.role)
		var shirt:=str(int(p.jersey_number)) if p.get("jersey_number")!=null else "?"
		player_pick.add_item("%s   %s  ·  %s"%[shirt,p.name,role])
	player_pick.select(0); edit_player(0)

func edit_lineup() -> void:
	player_card.hide()
	for child in fields.get_children(): fields.remove_child(child); child.queue_free()
	var team: Dictionary=db.teams[team_pick.selected]
	label(fields,"FORMAZIONE INIZIALE / "+team.name)
	label(fields,"Seleziona sei titolari e libero. Ogni giocatore può occupare un solo posto.")
	var existing: Array=db.lineup(team)
	var choices: Array=[]
	var candidates: Array=[]
	var names=["OH1 · Banda","MB1 · Centrale","OPP · Opposto","OH2 · Banda","MB2 · Centrale","S · Palleggiatore","L · Libero"]
	for i in 7:
		label(fields,names[i])
		var slot: int=i
		var options: Array=team.roster.filter(func(p): return p.role==(db.ROLES+["libero"])[slot])
		candidates.append(options)
		var pick=picker(fields,options.map(func(p): return "%s · %s"%[str(p.get("jersey_number","?")),p.name]))
		if existing.size()==7:
			for j in options.size():
				if options[j].id==existing[i].id: pick.select(j)
		choices.append(pick)
	button(fields,"SALVA FORMAZIONE",func():
		var ids: Array=[]
		for i in 7:
			if choices[i].selected<0: message.text="Manca un giocatore per uno dei ruoli."; return
			ids.append(candidates[i][choices[i].selected].id)
		var error=db.save_lineup(team,ids)
		message.text="Formazione salvata: verrà usata nella prossima partita." if error==OK else "Formazione non salvata: scegli sette giocatori distinti, con i ruoli corretti.")
func edit_player(index: int) -> void:
	player_card.show()
	editor_scroll.scroll_vertical=0
	for child in fields.get_children(): fields.remove_child(child); child.queue_free()
	current=db.teams[team_pick.selected].roster[index]; inputs={}
	player_card.update_player(current)
	label(fields,"Controller: A / Croce sul nome · ← → numeri · stick destro per scorrere")
	label(fields,"IDENTITÀ E ASPETTO")
	label(fields,"Nome")
	var name_field=LineEdit.new(); name_field.text=current.name; fields.add_child(name_field); inputs.name=name_field
	name_field.text_changed.connect(func(value): player_card.player=current.duplicate(true); player_card.player.name=value; player_card.queue_redraw())
	label(fields,"Numero di maglia")
	var number=SpinBox.new(); number.min_value=1; number.max_value=99; number.value=float(current.get("jersey_number",1) if current.get("jersey_number")!=null else 1); fields.add_child(number); inputs.number=number
	label(fields,"Ruolo")
	inputs.role=picker(fields,["outside_hitter","middle_blocker","opposite","setter","libero"])
	inputs.role.select(["outside_hitter","middle_blocker","opposite","setter","libero"].find(current.role))
	inputs.role.item_selected.connect(func(_i): player_card.player=player_card.player.duplicate(true); player_card.player.role=inputs.role.get_item_text(inputs.role.selected); player_card.queue_redraw())
	for key in ["hair_length","hair_color","skin_tone"]:
		label(fields,{"hair_length":"Capelli · lunghezza","hair_color":"Capelli · colore","skin_tone":"Carnagione"}[key])
		var values={"hair_length":["Non specificato","corti","lunghi","pelato"],"hair_color":["Non specificato","nero","marrone","biondo"],"skin_tone":["Non specificato","rosa","nero"]}[key]
		var field=picker(fields,values); field.select(maxi(0,values.find(current.appearance.get(key)))); inputs[key]=field
	label(fields,"VALORI  /  SOLO DATABASE · nessun effetto sul gameplay")
	for key in current.ratings:
		label(fields,key.capitalize()); var value=SpinBox.new(); value.min_value=0; value.max_value=100; value.value=current.ratings[key]; fields.add_child(value); inputs["rating_"+key]=value
		var skill: String=key
		value.value_changed.connect(func(v): player_card.ratings[skill]=int(v); player_card.queue_redraw())
	button(fields,"SALVA MODIFICHE",save_player)
func save_player() -> void:
	if inputs.name.text.strip_edges().is_empty(): message.text="Inserisci un nome."; return
	current.name=inputs.name.text.strip_edges(); current.jersey_number=int(inputs.number.value); current.role=inputs.role.get_item_text(inputs.role.selected)
	for key in ["hair_length","hair_color","skin_tone"]: current.appearance[key]=null if inputs[key].selected==0 else inputs[key].get_item_text(inputs[key].selected)
	for key in current.ratings: current.ratings[key]=int(inputs["rating_"+key].value)
	message.text="Salvato in locale ✓" if db.save(current)==OK else "Salvataggio non riuscito: riprova."
	player_pick.set_item_text(player_pick.get_selected_items()[0],"%d   %s  ·  %s"%[current.jersey_number,current.name,current.role])
func match_setup() -> void:
	clear("GIOCA  /  PREPARA LA PARTITA")
	var scroll=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; body.add_child(scroll)
	var content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",12); scroll.add_child(content)
	var row=HBoxContainer.new(); row.add_theme_constant_override("separation",30); content.add_child(row)
	var picks: Array=[]; var kits: Array=[]
	for side in 2:
		var frame=PanelContainer.new(); frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(frame)
		var card=VBoxContainer.new(); card.add_theme_constant_override("separation",12); frame.add_child(card)
		label(card,"LA TUA SQUADRA" if side==0 else "AVVERSARIA")
		var p=picker(card,db.teams.map(func(t): return t.name)); p.select(side); picks.append(p)
		label(card,"DIVISA"); var kit_pick=picker(card,["Casa","Trasferta"]); kits.append(kit_pick)
		var swatch=ColorRect.new(); swatch.custom_minimum_size.y=12; card.add_child(swatch)
		var roster_label=Label.new(); roster_label.add_theme_font_size_override("font_size",17); card.add_child(roster_label)
		var refresh=func(_index):
			var t=db.teams[p.selected]; var names=PackedStringArray(); for player in db.lineup(t): names.append("%s  ·  %s"%[player.role,player.name])
			roster_label.text="\n".join(names)
			swatch.color=Color(t.uniform_colors["home" if kit_pick.selected==0 else "away"].primary_hex_approx)
		p.item_selected.connect(refresh); refresh.call(0)
		kit_pick.item_selected.connect(refresh)
	label(content,"FORMATO PARTITA"); var format=picker(content,["1 set","Meglio dei 3","Meglio dei 5"]); format.select(2)
	label(body,"PUNTI PER SET · vantaggio di due punti; set decisivo sempre a 15")
	var points=picker(content,["25","15"])
	var error=Label.new(); body.add_child(error)
	button(body,"SCENDI IN CAMPO",func():
		for side in 2:
			if db.lineup(db.teams[picks[side].selected]).is_empty(): error.text="Roster incompleto: servono 2 OH, 2 MB, 1 OPP, 1 S e 1 L."; return
		game.match_best_of=[1,3,5][format.selected]; game.match_points=[25,15][points.selected]
		for side in 2:
			var t=db.teams[picks[side].selected]; game.team_names[side]=t.name
			var squad=db.lineup(t)
			for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],t.uniform_colors["home" if kits[side].selected==0 else "away"],t.uniform_colors.libero)
		game.scores=[0,0]; game.sets=[0,0]; game.rotations=[0,0]; game.server=0; game.paused=false; game.reset_rally(); game.started=true; hide(); music.stop())

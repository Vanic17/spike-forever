extends Control
var game
var host
var db=preload("res://src/league.gd").new()
var body: VBoxContainer
const Branding=preload("res://src/league_branding.gd")
var team_emblem: TextureRect
var team_pick: OptionButton
var player_pick: ItemList
var fields: VBoxContainer
var current: Dictionary={}
var inputs: Dictionary={}
var music:=AudioStreamPlayer.new()
var last_track:=-1
var music_queue: Array=[]
var match_rosters: Array=[[],[]]
var match_rotations: Array=[0,0]
var formation_dialog: ConfirmationDialog
var formation_return: Control
var message: Label
var player_card
var editor_scroll: ScrollContainer
var formation_buttons: Array[Button]=[]
var setup_start: Button
var keyboard: ConfirmationDialog
var keyboard_text: LineEdit
var keyboard_target: LineEdit
var lineup_open:=false
var editing_details:=false

func enter_details() -> void:
	if lineup_open or not is_instance_valid(fields): return
	editing_details=true
	for control in fields.find_children("*","Control",true,false):
		if control is LineEdit or control is OptionButton or control is Button or control is SpinBox: control.focus_mode=Control.FOCUS_ALL
	inputs.name.grab_focus()
	editor_scroll.ensure_control_visible(inputs.name)
var settings_stats: OptionButton
var settings_fatigue: OptionButton
var settings_format: OptionButton
var settings_points: OptionButton

func go_back() -> void:
	if editing_details and (keyboard==null or not keyboard.visible):
		editing_details=false
		for control in fields.find_children("*","Control",true,false):
			if control is LineEdit or control is OptionButton or control is Button or control is SpinBox: control.focus_mode=Control.FOCUS_CLICK
		player_pick.grab_focus(); return
	if formation_dialog!=null and formation_dialog.visible:
		formation_dialog.hide()
		if is_instance_valid(formation_return): formation_return.grab_focus()
		return
	if keyboard!=null and keyboard.visible:
		keyboard.hide()
		if is_instance_valid(keyboard_target): keyboard_target.grab_focus()
	elif lineup_open:
		lineup_open=false; edit_player(player_pick.get_selected_items()[0])
	else:
		var exhibition=is_instance_valid(body) and body.get_child_count()>0 and str(body.get_child(0).get_child(0).text).begins_with("GIOCA")
		hide()
		if exhibition and host.get("play_hub")!=null: host.play_hub.open()
		else: host.edit.grab_focus()

func focus_editor_step(backwards: bool) -> bool:
	if not is_instance_valid(fields): return false
	var owner=get_viewport().gui_get_focus_owner()
	if owner==null or not fields.is_ancestor_of(owner): return false
	if owner is OptionButton and owner.get_popup().visible: return false
	var controls: Array[Control]=[]
	for child in fields.get_children():
		if child is LineEdit or child is SpinBox or child is OptionButton or child is Button: controls.append(child)
	var index=controls.find(owner)
	if index<0 and owner.get_parent() is SpinBox: index=controls.find(owner.get_parent())
	if index<0: return false
	index=clampi(index+(-1 if backwards else 1),0,controls.size()-1)
	if controls[index] is SpinBox: controls[index].get_line_edit().grab_focus()
	else: controls[index].grab_focus()
	editor_scroll.call_deferred("ensure_control_visible",controls[index])
	return true
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
	if music_queue.is_empty():
		music_queue=range(9); music_queue.shuffle()
		if music_queue[0]==last_track: music_queue.reverse()
	last_track=music_queue.pop_front()
	music.stream=AudioStreamMP3.load_from_file("res://assets/audio/menu/track%d.mp3"%last_track); music.play()
func _process(_dt: float) -> void:
	if game.started: music.stop()
	elif not music.playing: next_track()
	if visible and is_instance_valid(editor_scroll) and editor_scroll.is_visible_in_tree() and (keyboard==null or not keyboard.visible):
		for device in Input.get_connected_joypads():
			var axis=Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y)
			if absf(axis)>0.25: editor_scroll.scroll_vertical+=roundi(axis*650*_dt)

func _input(event: InputEvent) -> void:
	if not game.started and event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_RIGHT_STICK:
		next_track(); get_viewport().set_input_as_handled(); return
	if not visible: return
	if is_instance_valid(player_pick) and player_pick.is_visible_in_tree() and not lineup_open and player_pick.has_focus():
		if event.is_action_pressed("ui_accept"):
			enter_details(); get_viewport().set_input_as_handled(); return
		if event.is_action_pressed("ui_right"):
			get_viewport().set_input_as_handled(); return
	if formation_dialog!=null and formation_dialog.visible:
		if event.is_action_pressed("ui_cancel"): go_back(); get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		var owner=get_viewport().gui_get_focus_owner()
		if owner is OptionButton and owner.get_popup().visible:
			owner.get_popup().hide(); get_viewport().set_input_as_handled(); return
		go_back(); get_viewport().set_input_as_handled(); return
	if keyboard==null or not keyboard.visible:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
			if focus_editor_step(event.is_action_pressed("ui_up")):
				get_viewport().set_input_as_handled(); return
	if not event is InputEventJoypadButton or not event.pressed: return
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
	keyboard.title="MODIFICA NOME" if target==inputs.get("name") else "INSERISCI TESTO"
	keyboard.ok_button_text="CONFERMA"
	keyboard_text.text=target.text
	keyboard.popup_centered(Vector2i(780,580))
	var container=keyboard_text.get_parent()
	container.get_child(1).get_child(0).grab_focus()
func clear(title: String) -> void:
	body.add_theme_constant_override("separation",18)
	for edge in ["left","right","top","bottom"]: body.get_parent().add_theme_constant_override("margin_"+edge,36)
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	var top=HBoxContainer.new(); body.add_child(top)
	var heading=Label.new(); heading.text=title; heading.add_theme_font_size_override("font_size",36); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(heading)
	button(top,"INDIETRO · B / CERCHIO",go_back)
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
	editing_details=false
	lineup_open=false
	clear("MODIFICA  /  SUPERLEGA 2026–27")
	label(body,"Il tuo roster personale • salvato su questo PC • conservato dopo gli aggiornamenti")
	var toolbar=HBoxContainer.new(); body.add_child(toolbar)
	team_emblem=Branding.emblem(toolbar,db.teams[0].id,64,54)
	team_pick=picker(toolbar,db.teams.map(func(t): return t.name)); team_pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(toolbar,"FORMAZIONE INIZIALE",edit_lineup)
	var columns=HBoxContainer.new(); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",28); body.add_child(columns)
	player_pick=ItemList.new(); player_pick.custom_minimum_size.x=265; player_pick.add_theme_font_size_override("font_size",16); columns.add_child(player_pick)
	player_card=preload("res://src/player_card.gd").new(); player_card.custom_minimum_size=Vector2(355,350); columns.add_child(player_card)
	var scroll=ScrollContainer.new(); scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_child(scroll)
	editor_scroll=scroll
	fields=VBoxContainer.new(); fields.size_flags_horizontal=Control.SIZE_EXPAND_FILL; fields.add_theme_constant_override("separation",12); scroll.add_child(fields)
	message=Label.new(); body.add_child(message)
	team_pick.item_selected.connect(func(_i): roster()); player_pick.item_selected.connect(edit_player); roster()
func roster() -> void:
	team_emblem.texture=Branding.logo(db.teams[team_pick.selected].id,true)
	player_pick.clear()
	for p in db.teams[team_pick.selected].roster:
		var role: String={"setter":"S","opposite":"OPP","outside_hitter":"OH","middle_blocker":"MB","libero":"L"}.get(p.role,p.role)
		var shirt:=str(int(p.jersey_number)) if p.get("jersey_number")!=null else "?"
		player_pick.add_item("%s   %s  ·  %s"%[shirt,p.name,role])
	player_pick.select(0); edit_player(0)

func edit_lineup() -> void:
	editing_details=false
	lineup_open=true
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
		var options: Array=team.roster.filter(func(p): return db.fits_slot(p.role,slot))
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
	editing_details=false
	lineup_open=false
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
	label(fields,"MANO DOMINANTE")
	inputs.dominant_hand=picker(fields,["Destra","Mancino"]); inputs.dominant_hand.select(1 if current.get("dominant_hand","right")=="left" else 0)
	label(fields,"BATTUTA PREFERITA / CPU")
	inputs.serve_preference=picker(fields,["Salto","Float"]); inputs.serve_preference.select(1 if current.get("serve_preference","jump")=="float" else 0)
	for key in ["hair_style","hair_color","beard","skin_tone"]:
		label(fields,{"hair_style":"Capelli · taglio","hair_color":"Capelli · colore","beard":"Barba","skin_tone":"Carnagione"}[key])
		var values={"hair_style":["Non specificato","corti","rasati","sfumati","mossi","ricci","afro","frangia","riga","lunghi","treccine","pelato"],"hair_color":["Non specificato","nero","marrone","castano chiaro","biondo","rosso","grigio"],"beard":["Non specificato","nessuna","corta","piena"],"skin_tone":["Non specificato","chiara","olivastra","ambrata","scura","ebano","rosa","nero"]}[key]
		var field=picker(fields,values); field.select(maxi(0,values.find(current.appearance.get(key)))); inputs[key]=field
	label(fields,"VALORI  /  SOLO DATABASE · nessun effetto sul gameplay")
	for key in current.ratings:
		label(fields,key.capitalize()); var value=SpinBox.new(); value.min_value=0; value.max_value=100 if key=="generale" else 99; value.value=current.ratings[key]; fields.add_child(value); inputs["rating_"+key]=value
		var skill: String=key
		value.value_changed.connect(func(v): player_card.ratings[skill]=int(v); player_card.queue_redraw())
	button(fields,"SALVA MODIFICHE",save_player)
	for control in fields.find_children("*","Control",true,false):
		if control is LineEdit or control is OptionButton or control is Button or control is SpinBox: control.focus_mode=Control.FOCUS_CLICK
func save_player() -> void:
	if inputs.name.text.strip_edges().is_empty(): message.text="Inserisci un nome."; return
	current.name=inputs.name.text.strip_edges(); current.jersey_number=int(inputs.number.value); current.role=inputs.role.get_item_text(inputs.role.selected)
	current.dominant_hand="left" if inputs.dominant_hand.selected==1 else "right"
	current.serve_preference="float" if inputs.serve_preference.selected==1 else "jump"
	for key in ["hair_style","hair_color","beard","skin_tone"]: current.appearance[key]=null if inputs[key].selected==0 else inputs[key].get_item_text(inputs[key].selected)
	current.appearance.hair_length="pelato" if current.appearance.hair_style=="pelato" else ("lunghi" if current.appearance.hair_style=="lunghi" else "corti")
	for key in current.ratings: current.ratings[key]=int(inputs["rating_"+key].value)
	message.text="Salvato in locale ✓" if db.save(current)==OK else "Salvataggio non riuscito: riprova."
	player_pick.set_item_text(player_pick.get_selected_items()[0],"%d   %s  ·  %s"%[current.jersey_number,current.name,current.role])
func match_setup() -> void:
	if host.get("play_hub")!=null: host.play_hub.hide()
	match_rosters=[[],[]]
	match_rotations=[0,0]
	lineup_open=false
	clear("GIOCA  /  PREPARA LA PARTITA")
	body.add_theme_constant_override("separation",12)
	for edge in ["left","right","top","bottom"]: body.get_parent().add_theme_constant_override("margin_"+edge,24)
	var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",24); body.add_child(row)
	formation_buttons.clear()
	var picks: Array=[]; var kits: Array=[]
	for side in 2:
		var frame=PanelContainer.new(); frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(frame)
		var card=VBoxContainer.new(); card.add_theme_constant_override("separation",8); frame.add_child(card)
		label(card,"LA TUA SQUADRA" if side==0 else "AVVERSARIA")
		var team_row=HBoxContainer.new(); card.add_child(team_row)
		var emblem=Branding.emblem(team_row,db.teams[side].id,74,54)
		var p=picker(team_row,db.teams.map(func(t): return t.name)); p.size_flags_horizontal=Control.SIZE_EXPAND_FILL; p.select(side); picks.append(p)
		var kit_row=HBoxContainer.new(); kit_row.add_theme_constant_override("separation",14); card.add_child(kit_row)
		label(kit_row,"DIVISA"); var kit_pick=picker(kit_row,["Casa","Trasferta"]); kit_pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL; kits.append(kit_pick)
		var team_side: int=side
		var formation=button(card,"FORMAZIONI / SOSTITUZIONI",func(): show_match_formation(team_side,db.teams[p.selected],formation_buttons[team_side]))
		formation_buttons.append(formation)
		var swatch=preload("res://src/kit_preview.gd").new(); card.add_child(swatch)
		# Only the artwork yields height. Selectors and formations remain
		# outside a scroll area and visible even in a short/wide window.
		swatch.size_flags_vertical=Control.SIZE_EXPAND_FILL
		swatch.image.custom_minimum_size=Vector2(200,0); swatch.image.size_flags_vertical=Control.SIZE_EXPAND_FILL
		var refresh=func(_index):
			var t=db.teams[p.selected]
			emblem.texture=Branding.logo(t.id,true)
			swatch.show_kit(t.id,"home" if kit_pick.selected==0 else "away")
		p.item_selected.connect(func(index): match_rosters[team_side]=[]; refresh.call(index)); refresh.call(0)
		kit_pick.item_selected.connect(refresh)
	var settings=HBoxContainer.new(); settings.add_theme_constant_override("separation",24); body.add_child(settings)
	var format_box=VBoxContainer.new(); format_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; settings.add_child(format_box)
	label(format_box,"FORMATO PARTITA"); var format=picker(format_box,["1 set","Meglio dei 3","Meglio dei 5"]); format.select(2); settings_format=format
	var points_box=VBoxContainer.new(); points_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; settings.add_child(points_box)
	label(points_box,"PUNTI PER SET"); var points=picker(points_box,["25","15"]); settings_points=points
	var stats_box=VBoxContainer.new(); stats_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; settings.add_child(stats_box)
	label(stats_box,"VALORI GIOCATORI"); settings_stats=picker(stats_box,["Disattivati · originale","Attivi · database V1"])
	var fatigue_box=VBoxContainer.new(); fatigue_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; settings.add_child(fatigue_box)
	label(fatigue_box,"AFFATICAMENTO"); settings_fatigue=picker(fatigue_box,["Attivo","Disattivato"])
	var error=Label.new(); body.add_child(error); error.hide()
	setup_start=button(body,"SCENDI IN CAMPO",func():
		for side in 2:
			if db.lineup(db.teams[picks[side].selected]).is_empty():
				error.text="Roster incompleto: servono 2 OH, 2 MB, 1 OPP, 1 S e 1 L."; error.show(); return
		game.use_player_stats=settings_stats.selected==1
		game.match_best_of=[1,3,5][format.selected]; game.match_points=[25,15][points.selected]
		var teams: Array=[]; var squads: Array=[]
		for side in 2:
			var t=db.teams[picks[side].selected]; game.team_names[side]=t.name
			var squad: Array=match_rosters[side] if not match_rosters[side].is_empty() else db.lineup(t)
			teams.append(t); squads.append(squad)
			var variant := "home" if kits[side].selected==0 else "away"
			var club_kits = preload("res://src/club_kits.gd")
			var chosen_kit: Dictionary = club_kits.selection(t.id,variant)
			var chosen_libero: Dictionary = club_kits.selection(t.id,variant,true)
			for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],chosen_kit,chosen_libero)
		if game.get("match_management")!=null:
			if not game.match_management.configure_rosters(teams,squads,{}, {"fatigue":settings_fatigue.selected==0,"injuries":false}): error.text="Rosa non disponibile per iniziare la partita."; error.show(); return
		game.scores=[0,0]; game.sets=[0,0]; game.rotations=match_rotations.duplicate(); game.server=0; game.paused=false; game.match_finished=false; game.reset_rally(); game.started=true; hide(); music.stop())
	var back: Control=body.get_child(0).get_child(1)
	for side in 2:
		var column: Array=[picks[side],kits[side],formation_buttons[side],format if side==0 else points]
		var other: Array=[picks[1-side],kits[1-side],formation_buttons[1-side],points if side==0 else format]
		for i in column.size():
			var current: Control=column[i]
			current.focus_neighbor_top=current.get_path_to(back if i==0 else column[i-1])
			current.focus_neighbor_bottom=current.get_path_to(setup_start if i==column.size()-1 else column[i+1])
			current.focus_neighbor_right=current.get_path_to(other[i] if side==0 else current)
			current.focus_neighbor_left=current.get_path_to(other[i] if side==1 else current)
			current.focus_next=current.focus_neighbor_bottom
	back.focus_neighbor_bottom=back.get_path_to(picks[0])
	setup_start.focus_neighbor_top=setup_start.get_path_to(format); setup_start.focus_next=setup_start.get_path_to(back)
	format.focus_neighbor_right=format.get_path_to(points)
	points.focus_neighbor_right=points.get_path_to(settings_stats)
	settings_stats.focus_neighbor_left=settings_stats.get_path_to(points)
	settings_stats.focus_neighbor_right=settings_stats.get_path_to(settings_fatigue)
	settings_stats.focus_neighbor_top=settings_stats.get_path_to(formation_buttons[1])
	settings_stats.focus_neighbor_bottom=settings_stats.get_path_to(setup_start)
	settings_stats.focus_next=settings_stats.get_path_to(setup_start)
	settings_fatigue.focus_neighbor_left=settings_fatigue.get_path_to(settings_stats)
	settings_fatigue.focus_neighbor_bottom=settings_fatigue.get_path_to(setup_start)
	settings_fatigue.focus_neighbor_top=settings_fatigue.get_path_to(formation_buttons[1])
	picks[0].grab_focus()

func show_match_formation(side: int, team: Dictionary, return_to: Control) -> void:
	formation_return=return_to
	if formation_dialog!=null: formation_dialog.queue_free()
	formation_dialog=ConfirmationDialog.new(); formation_dialog.title="FORMAZIONE / "+team.name; formation_dialog.ok_button_text="CONFERMA"; formation_dialog.cancel_button_text="ANNULLA"; add_child(formation_dialog)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",16); formation_dialog.add_child(column)
	label(column,"RETE — prima linea · bande e opposti sono intercambiabili")
	label(column,"Sestetto base + libero · il libero entra al posto del centrale di seconda linea durante la partita")
	label(column,"ROTAZIONE INIZIALE")
	var rotation_pick=picker(column,["P1 · S: 1","P6 · S: 6","P5 · S: 5","P4 · S: 4","P3 · S: 3","P2 · S: 2"]); rotation_pick.select(match_rotations[side])
	var court=PanelContainer.new(); column.add_child(court)
	var surface=StyleBoxFlat.new(); surface.bg_color=Color("174451"); surface.border_color=Color("d5e7e7"); surface.set_border_width_all(2)
	for edge in ["left","right","top","bottom"]: surface.set("content_margin_"+edge,12)
	court.add_theme_stylebox_override("panel",surface)
	var grid=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",18); court.add_child(grid)
	var squad: Array=match_rosters[side].duplicate() if not match_rosters[side].is_empty() else db.lineup(team)
	if squad.size()!=7: label(column,"Roster incompleto: completa i ruoli nel menu Modifica."); formation_dialog.popup_centered(); return
	var controls: Dictionary={}; var options: Dictionary={}
	var zone_labels: Dictionary={}
	var slots=[2,1,0,3,4,5,6]
	var abbreviations=["OH1","MB1","OPP","OH2","MB2","S","L"]
	for slot in slots:
		var index: int=slot
		var cell=VBoxContainer.new(); cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_child(cell)
		var zone_label=Label.new(); cell.add_child(zone_label); zone_labels[index]=zone_label
		var candidates: Array=team.roster.filter(func(player): return db.fits_slot(player.role,index)); options[index]=candidates
		var labels: Array=candidates.map(func(player): return "%s · %s · %s · GEN %d"%[str(int(player.jersey_number)) if player.get("jersey_number")!=null else "?",{"outside_hitter":"OH","opposite":"OPP","middle_blocker":"MB","setter":"S","libero":"L"}.get(player.role,player.role),player.name,int(player.ratings.get("generale",0))])
		var pick=picker(cell,labels); pick.add_theme_font_size_override("font_size",13); pick.fit_to_longest_item=false; pick.clip_text=true; pick.custom_minimum_size=Vector2(320,48); controls[index]=pick
		for j in candidates.size():
			if candidates[j].id==squad[index].id: pick.select(j)
		pick.item_selected.connect(func(selected):
			var old: Dictionary=squad[index]; var chosen: Dictionary=options[index][selected]
			for other in 7:
				if other==index or squad[other].id!=chosen.id: continue
				squad[other]=old
				for j in options[other].size():
					if options[other][j].id==old.id: controls[other].select(j)
			squad[index]=chosen)
	var refresh_rotation=func(_value):
		var ordered: Array=[]
		for zone_slot in [0,1,2,5,4,3]:
			for index in 6:
				if game.Tactics.slot(index,rotation_pick.selected)==zone_slot: ordered.append(index)
		ordered.append(6)
		for order in ordered.size():
			var index: int=ordered[order]; grid.move_child(controls[index].get_parent(),order)
			zone_labels[index].text=abbreviations[index]+(" · LIBERO" if index==6 else " · ZONA "+str(game.Tactics.Rotation.ZONES[game.Tactics.slot(index,rotation_pick.selected)]))
		for order in ordered.size():
			var control: Control=controls[ordered[order]]
			var above: Control=rotation_pick if order<3 else controls[ordered[order-3]]
			var below: Control=controls[ordered[order+3]] if order+3<ordered.size() else formation_dialog.get_ok_button()
			control.focus_neighbor_top=control.get_path_to(above); control.focus_neighbor_bottom=control.get_path_to(below)
			control.focus_next=control.get_path_to(controls[ordered[order+1]] if order+1<ordered.size() else formation_dialog.get_ok_button())
		rotation_pick.focus_neighbor_bottom=rotation_pick.get_path_to(controls[ordered[0]])
		var ok=formation_dialog.get_ok_button(); var cancel=formation_dialog.get_cancel_button()
		ok.focus_neighbor_top=ok.get_path_to(controls[6]); ok.focus_neighbor_right=ok.get_path_to(cancel)
		cancel.focus_neighbor_top=cancel.get_path_to(controls[6]); cancel.focus_neighbor_left=cancel.get_path_to(ok)
	rotation_pick.item_selected.connect(refresh_rotation); refresh_rotation.call(0)
	label(column,"A / Croce: scegli · frecce / stick sinistro: naviga · B / Cerchio: annulla")
	formation_dialog.confirmed.connect(func(): match_rosters[side]=squad.duplicate(); match_rotations[side]=rotation_pick.selected; formation_return.grab_focus())
	formation_dialog.canceled.connect(func(): formation_return.grab_focus())
	formation_dialog.window_input.connect(func(event):
		if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_RIGHT_STICK: next_track())
	formation_dialog.popup_centered(Vector2i(1100,620)); rotation_pick.grab_focus()

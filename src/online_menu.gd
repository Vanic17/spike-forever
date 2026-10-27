extends Control
var host
var game
var session
var body: VBoxContainer
var info: Label
var code: LineEdit
var scope: OptionButton
var own_team: OptionButton
var own_kit: OptionButton
var format: OptionButton
var stats_pick: OptionButton
var target: OptionButton
var create: Button
var join: Button
var launch: Button
var confirm: Button
var formation: Button
var opponent: Label
var preview
var updating:=false
var focus_controls: Array[Control]=[]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=host.clubs.theme.duplicate(true); theme.default_font_size=18
	for type in ["Button","LineEdit","OptionButton"]:
		var style: StyleBox=theme.get_stylebox("normal",type).duplicate(); style.content_margin_top=8; style.content_margin_bottom=8; theme.set_stylebox("normal",type,style)
	var panel=PanelContainer.new(); add_child(panel); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface=StyleBoxFlat.new(); surface.bg_color=Color("081322"); surface.content_margin_left=38; surface.content_margin_right=38; surface.content_margin_top=22; surface.content_margin_bottom=22; panel.add_theme_stylebox_override("panel",surface)
	body=VBoxContainer.new(); body.add_theme_constant_override("separation",12); panel.add_child(body)
	var top=HBoxContainer.new(); body.add_child(top)
	var heading=Label.new(); heading.text="ONLINE / SPIKE FOREVER"; heading.add_theme_font_size_override("font_size",30); heading.size_flags_horizontal=SIZE_EXPAND_FILL; top.add_child(heading)
	host.clubs.button(top,"INDIETRO · B / CERCHIO",back)
	info=Label.new(); info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(info)
	var connection=HBoxContainer.new(); connection.add_theme_constant_override("separation",12); body.add_child(connection)
	create=host.clubs.button(connection,"CREA PARTITA",func(): session.host_room())
	code=LineEdit.new(); code.placeholder_text="Codice stanza SF-…"; code.size_flags_horizontal=SIZE_EXPAND_FILL; connection.add_child(code)
	code.gui_input.connect(func(event):
		if event.is_action_pressed("ui_accept") and code.editable: edit_code(); code.accept_event())
	host.clubs.button(connection,"INSERISCI CODICE",edit_code)
	join=host.clubs.button(connection,"UNISCITI",func(): session.join_room(code.text))
	var invitation=HBoxContainer.new(); body.add_child(invitation)
	scope=host.clubs.picker(invitation,["Internet","Stessa rete / VPN LAN"])
	scope.item_selected.connect(func(_index): if session.authority(): session.update_code(lan_mode()))
	host.clubs.button(invitation,"COPIA CODICE",func(): if not session.room_code.is_empty(): DisplayServer.clipboard_set(session.room_code))
	var settings=HBoxContainer.new(); settings.add_theme_constant_override("separation",16); body.add_child(settings)
	host.clubs.label(settings,"FORMATO (HOST)"); format=host.clubs.picker(settings,["1 set","Meglio dei 3","Meglio dei 5"]); format.select(2)
	host.clubs.label(settings,"PUNTI"); target=host.clubs.picker(settings,["25","15"])
	host.clubs.label(settings,"VALORI GIOCATORI"); stats_pick=host.clubs.picker(settings,["Disattivati · originale","Attivi · database V1"])
	format.item_selected.connect(settings_changed); target.item_selected.connect(settings_changed); stats_pick.item_selected.connect(settings_changed)
	var cards=HBoxContainer.new(); cards.size_flags_vertical=SIZE_EXPAND_FILL; cards.add_theme_constant_override("separation",22); body.add_child(cards)
	var own=VBoxContainer.new(); own.size_flags_horizontal=SIZE_EXPAND_FILL; cards.add_child(own)
	host.clubs.label(own,"LA TUA SQUADRA")
	own_team=host.clubs.picker(own,host.clubs.db.teams.map(func(t): return t.name))
	own_kit=host.clubs.picker(own,["Casa","Trasferta"])
	formation=host.clubs.button(own,"FORMAZIONE / SOSTITUZIONI",open_formation)
	preview=load("res://src/kit_preview.gd").new(); own.add_child(preview); preview.size_flags_vertical=SIZE_EXPAND_FILL; preview.image.custom_minimum_size=Vector2(200,0); preview.image.size_flags_vertical=SIZE_EXPAND_FILL
	var other=VBoxContainer.new(); other.size_flags_horizontal=SIZE_EXPAND_FILL; cards.add_child(other)
	host.clubs.label(other,"AVVERSARIO")
	opponent=Label.new(); opponent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; opponent.size_flags_vertical=SIZE_EXPAND_FILL; other.add_child(opponent)
	host.clubs.label(other,"Ogni giocatore vede il campo dal proprio lato.\nCamera frontale · comandi relativi alla tua squadra.")
	var buttons=HBoxContainer.new(); body.add_child(buttons)
	confirm=host.clubs.button(buttons,"CONFERMA / PRONTO",confirm_choice); confirm.size_flags_horizontal=SIZE_EXPAND_FILL
	launch=host.clubs.button(buttons,"INIZIA PARTITA (HOST)",func(): session.start_match()); launch.size_flags_horizontal=SIZE_EXPAND_FILL
	own_team.item_selected.connect(func(_value): host.clubs.match_rosters[0]=[]; changed_choice())
	own_kit.item_selected.connect(func(_value): changed_choice())
	for control in body.find_children("*","Control",true,false):
		if control is Button or control is LineEdit: focus_controls.append(control)
	changed_choice(); hide()

func open() -> void:
	host.clubs.hide(); host.overlay.hide(); show(); refresh(); create.grab_focus() if not session.active else own_team.grab_focus()

func lan_mode() -> bool: return scope.selected==1

func edit_code() -> void:
	if not code.editable: return
	host.clubs.open_keyboard(code); host.clubs.keyboard.title="CODICE STANZA"

func back() -> void:
	if session.active: session.leave("Stanza chiusa")
	hide(); host.online.grab_focus()

func open_formation() -> void:
	host.clubs.show_match_formation(0,host.clubs.db.teams[own_team.selected],formation)
	host.clubs.formation_dialog.confirmed.connect(changed_choice,CONNECT_ONE_SHOT)

func choice() -> Dictionary:
	var club: Dictionary=host.clubs.db.teams[own_team.selected]
	var roster: Array=host.clubs.match_rosters[0] if not host.clubs.match_rosters[0].is_empty() else host.clubs.db.lineup(club)
	return {"club":club.id,"kit":"home" if own_kit.selected==0 else "away","roster":roster,"rotation":host.clubs.match_rotations[0]}

func changed_choice() -> void:
	if updating: return
	preview.show_kit(host.clubs.db.teams[own_team.selected].id,"home" if own_kit.selected==0 else "away")
	if session.active: session.choose(choice(),false)

func settings_changed(_index: int) -> void:
	if updating or (session.active and not session.authority()): return
	session.best_of=[1,3,5][format.selected]; session.points=[25,15][target.selected]; session.use_player_stats=stats_pick.selected==1
	session.ready_flags=[false,false]
	if session.authority(): session.broadcast_lobby()

func confirm_choice() -> void: session.choose(choice(),not session.ready_flags[session.local_side])

func refresh() -> void:
	if info==null: return
	updating=true; info.text=session.info
	create.disabled=session.active or session.closing; join.disabled=session.active or session.closing; code.editable=not session.active
	if session.authority(): code.text=session.room_code
	format.disabled=session.active and not session.authority(); target.disabled=format.disabled; stats_pick.disabled=format.disabled
	format.select([1,3,5].find(session.best_of)); target.select([25,15].find(session.points)); stats_pick.select(1 if session.use_player_stats else 0)
	confirm.disabled=not session.active or (session.local_side==1 and session.guest==0)
	confirm.text="ANNULLA PRONTO" if session.ready_flags[session.local_side] else "CONFERMA / PRONTO"
	var locked: bool=session.active and session.ready_flags[session.local_side]
	own_team.disabled=locked; own_kit.disabled=locked; formation.disabled=locked
	launch.disabled=not session.authority() or session.guest==0 or not session.ready_flags[0] or not session.ready_flags[1]
	var remote: Dictionary=session.choices[1-session.local_side]
	opponent.text="In attesa dell'altro giocatore…" if remote.is_empty() else remote.name+"\n"+("Trasferta" if remote.kit=="away" else "Casa")+" · "+("PRONTO" if session.ready_flags[1-session.local_side] else "sta preparando la formazione")
	if not remote.is_empty():
		for p in remote.roster: opponent.text+="\n%d · %s · %s · GEN %d"%[int(p.jersey_number),{"outside_hitter":"OH","opposite":"OPP","middle_blocker":"MB","setter":"S","libero":"L"}.get(p.role,p.role),p.name,int(p.ratings.get("generale",50))]
	updating=false

func _input(event: InputEvent) -> void:
	if not visible: return
	if host.clubs.formation_dialog!=null and host.clubs.formation_dialog.visible:
		if event.is_action_pressed("ui_cancel"): host.clubs.formation_dialog.hide(); formation.grab_focus(); get_viewport().set_input_as_handled()
		return
	if host.clubs.keyboard!=null and host.clubs.keyboard.visible:
		if event.is_action_pressed("ui_cancel"): host.clubs.keyboard.hide(); code.grab_focus(); get_viewport().set_input_as_handled()
		return
	var owner=get_viewport().gui_get_focus_owner()
	if owner is OptionButton and owner.get_popup().visible: return
	var forward:=event.is_action_pressed("ui_down") or (not owner is LineEdit and event.is_action_pressed("ui_right"))
	var backward:=event.is_action_pressed("ui_up") or (not owner is LineEdit and event.is_action_pressed("ui_left"))
	if forward or backward:
		var available: Array=focus_controls.filter(func(c): return c.is_visible_in_tree() and not (c is Button and c.disabled))
		var at:=available.find(owner)
		if not available.is_empty(): available[clampi(at+(1 if forward else -1),0,available.size()-1)].grab_focus()
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_cancel"): back(); get_viewport().set_input_as_handled()

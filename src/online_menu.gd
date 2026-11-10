extends Control
var host
var game
var session
var body: VBoxContainer
var info: Label
var code: LineEdit
var scope: OptionButton
var team_emblem: TextureRect
var opponent_emblem: TextureRect
var own_team: OptionButton
var own_kit: OptionButton
var format: OptionButton
var stats_pick: OptionButton
var fatigue_pick: OptionButton
var target: OptionButton
var create: Button
var join: Button
var paste_join: Button
var launch: Button
var confirm: Button
var formation: Button
var pending_formation99:=false
var opponent: Label
var preview
var updating:=false
var focus_controls: Array[Control]=[]
var recent_pick108: OptionButton
var reconnect108: Button
var online_roster108: Array=[]
var online_rotation108:=0
var formation_backup108: Dictionary={}
var scroll108: ScrollContainer

func selection_db108():
	return session.catalog108 if session.catalog_ready108 else host.clubs.db

func catalog_changed108() -> void:
	if own_team==null:return
	updating=true;online_roster108=[]
	own_team.clear()
	for team in selection_db108().teams:own_team.add_item(str(team.name))
	own_team.select(0);updating=false;changed_choice()

func finish_formation108(accepted: bool) -> void:
	if formation_backup108.is_empty():return
	if accepted:online_roster108=host.clubs.match_rosters[0].duplicate(true);online_rotation108=host.clubs.match_rotations[0]
	host.clubs.match_rosters[0]=formation_backup108.roster
	host.clubs.match_rotations[0]=formation_backup108.rotation
	formation_backup108={}
	if accepted:changed_choice()

func refresh_recent108() -> void:
	if recent_pick108==null:return
	recent_pick108.clear()
	for entry in session.connections108.recent:recent_pick108.add_item(str(entry.label)+" · "+preload("res://src/room_code.gd").display(entry.code).right(5))
	if recent_pick108.item_count==0:recent_pick108.add_item("Nessuna stanza recente")
	reconnect108.disabled=session.active or session.closing or session.connections108.recent.is_empty()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=host.clubs.theme.duplicate(true); theme.default_font_size=18
	for type in ["Button","LineEdit","OptionButton"]:
		var style: StyleBox=theme.get_stylebox("normal",type).duplicate(); style.content_margin_top=8; style.content_margin_bottom=8; theme.set_stylebox("normal",type,style)
	var panel=PanelContainer.new(); add_child(panel); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface=StyleBoxFlat.new(); surface.bg_color=Color("081322"); surface.content_margin_left=38; surface.content_margin_right=38; surface.content_margin_top=22; surface.content_margin_bottom=22; panel.add_theme_stylebox_override("panel",surface)
	scroll108=ScrollContainer.new();scroll108.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll108)
	body=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.size_flags_vertical=SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",10); scroll108.add_child(body)
	var top=HBoxContainer.new(); body.add_child(top)
	var heading=Label.new(); heading.text="ONLINE / SPIKE FOREVER"; heading.add_theme_font_size_override("font_size",30); heading.size_flags_horizontal=SIZE_EXPAND_FILL; top.add_child(heading)
	host.clubs.button(top,"INDIETRO · B / CERCHIO",back)
	info=Label.new(); info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(info)
	var connection=HBoxContainer.new(); connection.add_theme_constant_override("separation",12); body.add_child(connection)
	create=host.clubs.button(connection,"CREA PARTITA",func(): session.host_room())
	code=LineEdit.new(); code.placeholder_text="Codice breve · 13 caratteri"; code.size_flags_horizontal=SIZE_EXPAND_FILL; connection.add_child(code)
	code.gui_input.connect(func(event):
		if event.is_action_pressed("ui_accept") and code.editable: edit_code(); code.accept_event())
	host.clubs.button(connection,"INSERISCI CODICE",edit_code)
	join=host.clubs.button(connection,"UNISCITI",func(): session.join_room(code.text))
	paste_join=host.clubs.button(connection,"INCOLLA E UNISCITI",func():
		code.text=DisplayServer.clipboard_get().strip_edges()
		session.join_room(code.text))
	var invitation=HBoxContainer.new(); body.add_child(invitation)
	scope=host.clubs.picker(invitation,["Internet","Stessa rete / VPN LAN"])
	scope.item_selected.connect(func(_index): if session.authority(): session.update_code(lan_mode()))
	host.clubs.button(invitation,"COPIA CODICE",func(): if not session.room_code.is_empty(): DisplayServer.clipboard_set(session.room_code))
	var saved108=HBoxContainer.new();body.add_child(saved108)
	recent_pick108=host.clubs.picker(saved108,[]);recent_pick108.size_flags_horizontal=SIZE_EXPAND_FILL
	reconnect108=host.clubs.button(saved108,"RICONNETTI ALLA STANZA",func():
		if recent_pick108.selected>=0 and recent_pick108.selected<session.connections108.recent.size():
			code.text=session.connections108.recent[recent_pick108.selected].code;session.join_room(code.text))
	refresh_recent108()
	var settings=HBoxContainer.new(); settings.add_theme_constant_override("separation",16); body.add_child(settings)
	var columns=[]
	for title in ["FORMATO (HOST)","PUNTI","VALORI GIOCATORI","AFFATICAMENTO"]:
		var column=VBoxContainer.new(); column.size_flags_horizontal=SIZE_EXPAND_FILL; settings.add_child(column); host.clubs.label(column,title); columns.append(column)
	format=host.clubs.picker(columns[0],["1 set","Meglio dei 3","Meglio dei 5"]); format.select(2)
	target=host.clubs.picker(columns[1],["25","15"])
	stats_pick=host.clubs.picker(columns[2],["Disattivati · originale","Attivi · database V1"])
	fatigue_pick=host.clubs.picker(columns[3],["OFF","ON"]); fatigue_pick.select(1)
	for field in [format,target,stats_pick,fatigue_pick]: field.item_selected.connect(settings_changed)
	var cards=HBoxContainer.new(); cards.size_flags_vertical=SIZE_EXPAND_FILL; cards.add_theme_constant_override("separation",22); body.add_child(cards)
	var own=VBoxContainer.new(); own.size_flags_horizontal=SIZE_EXPAND_FILL; cards.add_child(own)
	host.clubs.label(own,"LA TUA SQUADRA")
	var team_row=HBoxContainer.new(); own.add_child(team_row)
	team_emblem=host.clubs.Branding.emblem(team_row,host.clubs.db.teams[0].id,64,45)
	own_team=host.clubs.picker(team_row,host.clubs.db.teams.map(func(t): return t.name)); own_team.size_flags_horizontal=SIZE_EXPAND_FILL
	own_kit=host.clubs.picker(own,["Casa","Trasferta"])
	formation=host.clubs.button(own,"FORMAZIONE / SOSTITUZIONI",open_formation)
	preview=load("res://src/kit_preview.gd").new(); own.add_child(preview); preview.size_flags_vertical=SIZE_EXPAND_FILL; preview.image.custom_minimum_size=Vector2(200,0); preview.image.size_flags_vertical=SIZE_EXPAND_FILL
	var other=VBoxContainer.new(); other.size_flags_horizontal=SIZE_EXPAND_FILL; cards.add_child(other)
	host.clubs.label(other,"AVVERSARIO")
	opponent_emblem=host.clubs.Branding.emblem(other,"",76,56); opponent_emblem.hide()
	opponent=Label.new(); opponent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; opponent.size_flags_vertical=SIZE_EXPAND_FILL; other.add_child(opponent)
	host.clubs.label(other,"Ogni giocatore vede il campo dal proprio lato.\nCamera frontale · comandi relativi alla tua squadra.")
	var buttons=HBoxContainer.new(); body.add_child(buttons)
	confirm=host.clubs.button(buttons,"CONFERMA / PRONTO",confirm_choice); confirm.size_flags_horizontal=SIZE_EXPAND_FILL
	launch=host.clubs.button(buttons,"INIZIA PARTITA (HOST)",func(): session.start_match()); launch.size_flags_horizontal=SIZE_EXPAND_FILL
	own_team.item_selected.connect(func(_value): online_roster108=[]; changed_choice())
	own_kit.item_selected.connect(func(_value): changed_choice())
	for control in body.find_children("*","Control",true,false):
		if control is Button or control is LineEdit:
			focus_controls.append(control)
			control.focus_entered.connect(func():scroll108.ensure_control_visible(control))
	changed_choice(); hide()

func open() -> void:
	if not session.active:catalog_changed108()
	refresh_recent108()
	if not session.active and not session.connections108.recent.is_empty():code.text=preload("res://src/room_code.gd").display(session.connections108.recent[0].code)
	if host.get("play_hub")!=null: host.play_hub.hide()
	if host.get("career_menu")!=null: host.career_menu.hide()
	host.clubs.hide(); host.overlay.hide(); show(); refresh(); create.grab_focus() if not session.active else own_team.grab_focus()

func lan_mode() -> bool: return scope.selected==1

func edit_code() -> void:
	if not code.editable: return
	host.clubs.open_keyboard(code); host.clubs.keyboard.title="CODICE STANZA"

func back() -> void:
	finish_formation108(false)
	if session.active: session.leave("Stanza chiusa")
	hide()
	if host.get("play_hub")!=null: host.play_hub.show()
	host.online.grab_focus()

func open_formation() -> void:
	if not session.active:
		session.info="Crea una stanza o unisciti prima di confermare la formazione.";session.refresh();return
	pending_formation99=true
	var value99: Dictionary=choice();value99.open_formation99=true
	session.choose(value99,false)

func has_forms99() -> bool:
	var club: Dictionary=selection_db108().teams[own_team.selected]
	var selected: Dictionary=session.choices[session.local_side]
	if str(selected.get("club",""))!=str(club.id):return false
	var arrows: Dictionary=selected.get("condition99",{}).get("arrows",{})
	return club.roster.all(func(p):return arrows.has(str(p.id)))

func show_forms99() -> void:
	if not pending_formation99 or not has_forms99():return
	pending_formation99=false
	var selected: Dictionary=session.choices[session.local_side]
	formation_backup108={"roster":host.clubs.match_rosters[0],"rotation":host.clubs.match_rotations[0]}
	host.clubs.match_rosters[0]=online_roster108;host.clubs.match_rotations[0]=online_rotation108
	host.clubs.show_match_formation(0,selection_db108().teams[own_team.selected],formation,selected.condition99,-1,selection_db108())
	host.clubs.formation_dialog.confirmed.connect(func():finish_formation108(true),CONNECT_ONE_SHOT)
	host.clubs.formation_dialog.canceled.connect(func():finish_formation108(false),CONNECT_ONE_SHOT)

func choice() -> Dictionary:
	var club: Dictionary=selection_db108().teams[own_team.selected]
	var roster: Array=online_roster108 if not online_roster108.is_empty() else selection_db108().lineup(club)
	var ids: Array=roster.map(func(p): return str(p.id))
	return {"club":club.id,"kit":"home" if own_kit.selected==0 else "away","roster":roster,"bench":club.roster.filter(func(p): return not str(p.id) in ids),"rotation":online_rotation108}

func changed_choice() -> void:
	if updating: return
	team_emblem.texture=host.clubs.Branding.logo(selection_db108().teams[own_team.selected].id,true)
	preview.show_kit(selection_db108().teams[own_team.selected].id,"home" if own_kit.selected==0 else "away")
	if session.active: session.choose(choice(),false)

func settings_changed(_index: int) -> void:
	if updating or (session.active and not session.authority()): return
	session.best_of=[1,3,5][format.selected]; session.points=[25,15][target.selected]; session.use_player_stats=stats_pick.selected==1; session.use_fatigue=fatigue_pick.selected==1
	session.ready_flags=[false,false]
	if session.authority(): session.broadcast_lobby()

func confirm_choice() -> void:
	if not has_forms99():open_formation();return
	session.choose(choice(),not session.ready_flags[session.local_side])

func refresh() -> void:
	if recent_pick108!=null:reconnect108.disabled=session.active or session.closing or session.connections108.recent.is_empty()
	if pending_formation99 and has_forms99():call_deferred("show_forms99")
	if info==null: return
	updating=true; info.text=session.info
	if session.active and session.catalog_ready108:info.text+=" · Database host: "+session.catalog_hash108.left(8)
	create.disabled=session.active or session.closing; join.disabled=session.active or session.closing; code.editable=not session.active
	paste_join.disabled=session.active or session.closing
	if session.authority(): code.text=preload("res://src/room_code.gd").display(session.room_code)
	format.disabled=session.active and not session.authority(); target.disabled=format.disabled; stats_pick.disabled=format.disabled; fatigue_pick.disabled=format.disabled
	format.select([1,3,5].find(session.best_of)); target.select([25,15].find(session.points)); stats_pick.select(1 if session.use_player_stats else 0); fatigue_pick.select(1 if session.use_fatigue else 0)
	confirm.disabled=not session.active or not session.catalog_ready108 or (session.local_side==1 and session.guest==0)
	confirm.text="ANNULLA PRONTO" if session.ready_flags[session.local_side] else "CONFERMA / PRONTO"
	var locked: bool=session.active and session.ready_flags[session.local_side]
	own_team.disabled=locked; own_kit.disabled=locked; formation.disabled=locked
	launch.disabled=not session.authority() or not session.catalog_ack108 or session.guest==0 or not session.ready_flags[0] or not session.ready_flags[1]
	var remote: Dictionary=session.choices[1-session.local_side]
	opponent_emblem.texture=host.clubs.Branding.logo(remote.get("club",""),true)
	opponent_emblem.visible=not remote.is_empty()
	opponent.text="In attesa dell'altro giocatore…" if remote.is_empty() else remote.name+"\n"+("Trasferta" if remote.kit=="away" else "Casa")+" · "+("PRONTO" if session.ready_flags[1-session.local_side] else "sta preparando la formazione")
	if not remote.is_empty():
		for p in remote.roster: opponent.text+="\n%d · %s · %s · GEN %d"%[int(p.jersey_number),{"outside_hitter":"OH","opposite":"OPP","middle_blocker":"MB","setter":"S","libero":"L"}.get(p.role,p.role),p.name,int(p.ratings.get("generale",50))]
	updating=false

func _input(event: InputEvent) -> void:
	if not visible: return
	if is_instance_valid(host.clubs.formation_dialog) and host.clubs.formation_dialog.visible:
		if event.is_action_pressed("ui_cancel"):finish_formation108(false);host.clubs.formation_dialog.hide(); formation.grab_focus(); get_viewport().set_input_as_handled()
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

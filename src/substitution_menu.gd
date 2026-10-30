extends CanvasLayer
const UI=preload("res://src/career_widgets.gd")
var manager
var game
var surface: Control
var frame: Control
var court: VBoxContainer
var bench_list: VBoxContainer
var left_scroll: ScrollContainer
var right_scroll: ScrollContainer
var counter: Label
var detail: Label
var status: Label
var step: Label
var close_button: Button
var confirm_button: Button
var exception_button: Button
var selected_slot:=0
var incoming:=""
var side:=0
var zone:=0
var rows: Array=[]
var candidates: Array=[]
var repeat_left:=0.0
var opened:=false
var bench_cursor:=0

func _ready() -> void:
	layer=18; surface=Control.new(); add_child(surface); surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.theme=UI.theme()
	var shade=ColorRect.new(); shade.color=Color("091422"); surface.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new(); surface.add_child(frame); frame.size=Vector2(1920,1080)
	var margins=MarginContainer.new(); frame.add_child(margins); margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]: margins.add_theme_constant_override("margin_"+edge,42)
	for edge in ["top","bottom"]: margins.add_theme_constant_override("margin_"+edge,24)
	var body=VBoxContainer.new(); body.add_theme_constant_override("separation",12); margins.add_child(body)
	var heading=HBoxContainer.new(); body.add_child(heading)
	var title=UI.heading(heading,"GESTIONE PARTITA / SOSTITUZIONI",35); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	close_button=UI.button(heading,"INDIETRO · B / CERCHIO",close); close_button.size_flags_horizontal=Control.SIZE_SHRINK_END; close_button.custom_minimum_size.x=300
	counter=UI.label(body,"",21,UI.MUTED)
	step=UI.label(body,"",25,UI.GOLD); step.custom_minimum_size.y=36
	var grid=HBoxContainer.new(); grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("separation",24); body.add_child(grid)
	var left=UI.card(grid); UI.label(left,"IN CAMPO / CHI ESCE",23,UI.GOLD)
	left_scroll=ScrollContainer.new(); left_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; left_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; left.add_child(left_scroll)
	court=VBoxContainer.new(); court.size_flags_horizontal=Control.SIZE_EXPAND_FILL; court.add_theme_constant_override("separation",7); left_scroll.add_child(court)
	var right=UI.card(grid); UI.label(right,"PANCHINA / CHI ENTRA",23,UI.GOLD)
	right_scroll=ScrollContainer.new(); right_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; right_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; right.add_child(right_scroll)
	bench_list=VBoxContainer.new(); bench_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bench_list.add_theme_constant_override("separation",7); right_scroll.add_child(bench_list)
	detail=UI.wrap(body,"",21); detail.custom_minimum_size.y=88
	status=UI.label(body,"",20,UI.GOLD); status.custom_minimum_size.y=25
	var actions=HBoxContainer.new(); body.add_child(actions)
	confirm_button=UI.button(actions,"CONFERMA SOSTITUZIONE",func(): apply(false)); confirm_button.alignment=HORIZONTAL_ALIGNMENT_CENTER
	exception_button=UI.button(actions,"CAMBIO ECCEZIONALE / INFORTUNIO",func(): apply(true)); exception_button.alignment=HORIZONTAL_ALIGNMENT_CENTER
	UI.label(body,"A / Croce: seleziona e conferma · B / Cerchio: indietro · LS / D-pad: scorri senza selezionare",19,UI.MUTED)
	surface.resized.connect(layout); layout(); surface.hide()
func layout():
	if frame==null: return
	var factor=minf(surface.size.x/1920.0,surface.size.y/1080.0); frame.scale=Vector2.ONE*factor; frame.position=(surface.size-Vector2(1920,1080)*factor)*.5
func open() -> void:
	if not manager.active: return
	side=game.local_team(); zone=0; selected_slot=0; incoming=""; opened=true; surface.show(); layout(); refresh(); rows[0].grab_focus(); repeat_left=.25
func close() -> void:
	opened=false; surface.hide()
	if game.pause_menu!=null and game.pause_menu.substitution_button!=null: game.pause_menu.substitution_button.grab_focus()
func role_label(person: Dictionary) -> String:
	return {"outside_hitter":"OH","opposite":"OPP","middle_blocker":"MB","setter":"S","libero":"L"}.get(str(person.get("role","")),"–")
func text_for(person: Dictionary) -> String:
	var fitness=tr("RES %d%%")%roundi(100-manager.fatigue(str(person.id))) if manager.fatigue_enabled else tr("RES OFF")
	return "%d · %s · %s\nGEN %d   ·   %s   ·   %s %+.0f"%[int(person.get("jersey_number",0)),role_label(person),str(person.get("name","")),int(person.get("ratings",{}).get("generale",50)),fitness,tr("FORMA"),float(manager.conditions.get(person.id,{}).get("form",0))]
func player_row(parent: Node,person: Dictionary,callback: Callable) -> Button:
	var row=UI.button(parent,text_for(person),callback); row.custom_minimum_size.y=76; row.add_theme_font_size_override("font_size",20)
	if manager.fatigue_enabled:
		var bar=ProgressBar.new(); bar.show_percentage=false; bar.value=100-manager.fatigue(str(person.id)); bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(bar); bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); bar.offset_left=14; bar.offset_right=-14; bar.offset_top=-7; bar.offset_bottom=-4
		bar.add_theme_stylebox_override("background",UI.surface(Color("31435a"),2,0)); bar.add_theme_stylebox_override("fill",UI.surface(Color("4edc9c") if bar.value>50 else Color("e7bd68"),2,0))
	return row
func refresh() -> void:
	for list in [court,bench_list]:
		for child in list.get_children(): list.remove_child(child); child.queue_free()
	rows.clear(); candidates.clear()
	counter.text=tr("%s · SET %d · Sostituzioni ordinarie %d / 6 · Libero: ingressi separati")%[game.team_names[side],game.sets[0]+game.sets[1]+1,int(manager.counts[side])]
	if manager.between_sets: counter.text=tr("%s · FORMAZIONE NUOVO SET · Cambi liberi prima della prima battuta")%game.team_names[side]
	for slot in 6:
		var actual=slot; var person: Dictionary=manager.identity(str(manager.current[side][slot]))
		var row=player_row(court,person,func(): choose_slot(actual)); rows.append(row)
		row.focus_entered.connect(func(): left_scroll.ensure_control_visible(row))
	for person in manager.bench(side):
		if str(person.role)=="libero": continue
		var id: String=person.id
		var row=player_row(bench_list,person,func(): choose_reserve(id)); row.set_meta("player_id",id); candidates.append(row)
		row.focus_entered.connect(func(): right_scroll.ensure_control_visible(row))
	update_detail()
func update_detail() -> void:
	confirm_button.disabled=true; exception_button.disabled=true; exception_button.hide()
	for i in rows.size():
		rows[i].add_theme_stylebox_override("normal",UI.surface(Color("31465c") if zone>0 and selected_slot==i else Color("20334b"),12,14))
	for candidate in candidates:
		candidate.add_theme_stylebox_override("normal",UI.surface(Color("31465c") if candidate.get_meta("player_id")==incoming else Color("20334b"),12,14))
	if zone==0:
		step.text=tr("1  SCEGLI CHI ESCE     →     2  SCEGLI CHI ENTRA     →     3  CONFERMA")
		detail.text=tr("Scorri il sestetto e premi A / Croce sul giocatore da sostituire. Il solo scorrimento non effettua alcuna scelta.")
		status.text=tr("Massimo 6 cambi ordinari per set. Ogni titolare può uscire e rientrare una volta, con la stessa riserva."); return
	var old: Dictionary=manager.identity(str(manager.current[side][selected_slot]))
	if incoming.is_empty():
		step.text=tr("2  SCEGLI CHI ENTRA  /  Esce: ")+str(old.name)
		detail.text=tr("Ora scegli una riserva con A / Croce. B / Cerchio torna al sestetto. La sostituzione verrà applicata solo dopo la conferma finale.")
		status.text=tr("Nessuna riserva selezionata."); return
	var next: Dictionary=manager.identity(incoming)
	step.text=tr("3  CONFERMA IL CAMBIO")
	detail.text=tr("ESCE: %s (%s)     →     ENTRA: %s (%s)")%[old.name,role_label(old),next.name,role_label(next)]
	detail.text+="\n"+tr("GEN %d → %d · RES %d%% → %d%% · FORMA %+.0f → %+.0f")%[int(old.ratings.get("generale",50)),int(next.ratings.get("generale",50)),roundi(100-manager.fatigue(str(old.id))),roundi(100-manager.fatigue(incoming)),float(manager.conditions.get(old.id,{}).get("form",0)),float(manager.conditions.get(incoming,{}).get("form",0))]
	var values: Array=[]
	for key in ["battuta","ricezione","difesa","palleggio","schiacciata","muro"]: values.append(tr(key.capitalize())+" %d → %d"%[int(old.ratings.get(key,50)),int(next.ratings.get(key,50))])
	detail.text+="\n"+" · ".join(values)
	var reason: String=manager.eligibility(side,selected_slot,incoming)
	status.text=tr(reason) if not reason.is_empty() else tr("Cambio consentito. L'ordine di rotazione resta invariato. Premi CONFERMA per applicarlo.")
	confirm_button.disabled=not reason.is_empty()
	var exceptional=not manager.eligibility(side,selected_slot,incoming,true).is_empty()
	exception_button.disabled=exceptional; exception_button.visible=not exceptional and confirm_button.disabled
func choose_slot(slot: int) -> void:
	selected_slot=slot; zone=1; incoming=""; bench_cursor=0; update_detail()
	if not candidates.is_empty(): candidates[0].grab_focus()
func choose_reserve(id: String) -> void:
	if zone==0: return
	incoming=id; zone=2
	for i in candidates.size():
		if candidates[i].get_meta("player_id")==id: bench_cursor=i
	update_detail()
	if not confirm_button.disabled: confirm_button.grab_focus()
	elif not exception_button.disabled: exception_button.grab_focus()
func go_back() -> void:
	if zone==2:
		zone=1; incoming=""; update_detail()
		if not candidates.is_empty(): candidates[clampi(bench_cursor,0,candidates.size()-1)].grab_focus()
	elif zone==1: zone=0; incoming=""; update_detail(); rows[selected_slot].grab_focus()
	else: close()
func apply(exceptional: bool) -> void:
	if incoming.is_empty() or zone!=2: return
	if game.network_match() and not game.online_session.authority():
		game.online_session.request_substitution(selected_slot,incoming,exceptional); status.text=tr("Richiesta inviata all'host…"); return
	var reason: String=manager.substitute(side,selected_slot,incoming,exceptional)
	if not reason.is_empty(): status.text=tr(reason); return
	incoming=""; zone=0; refresh(); rows[selected_slot].grab_focus()
func navigate(direction: int) -> void:
	var focus=get_viewport().gui_get_focus_owner()
	var list=rows if zone==0 else candidates
	if zone==2:
		if direction<0 and not candidates.is_empty(): candidates[bench_cursor].grab_focus()
		elif direction>0 and not confirm_button.disabled: confirm_button.grab_focus()
		return
	var index=list.find(focus)
	if index<0:
		if not list.is_empty(): list[0].grab_focus()
	elif not list.is_empty(): list[clampi(index+direction,0,list.size()-1)].grab_focus()
func _process(dt: float) -> void:
	if not opened: return
	if not game.started or not game.paused: close(); return
	repeat_left=maxf(0,repeat_left-dt)
	var pad: int=game.pad()
	if pad<0: return
	var axis=Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y)
	if absf(axis)<.5 or repeat_left>0: return
	repeat_left=.18; navigate(1 if axis>0 else -1)
func _input(event: InputEvent) -> void:
	if not opened: return
	if event.is_action_pressed("ui_cancel"): go_back(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		navigate(1 if event.is_action_pressed("ui_down") else -1); repeat_left=.3; get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_left"):
		if zone>0: go_back()
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_right"): get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_accept"):
		var focus=get_viewport().gui_get_focus_owner()
		if focus is Button and not focus.disabled: focus.pressed.emit()
		get_viewport().set_input_as_handled()

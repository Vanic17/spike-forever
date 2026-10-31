extends Control
## The created player's complete career flow, independent from Master League.
const UI=preload("res://src/career_widgets.gd")
const Legend=preload("res://src/legend_career.gd")
const Locale=preload("res://src/legend_locale.gd")
const Kits=preload("res://src/club_kits.gd")
const Overall=preload("res://src/player_overall.gd")
const TABS=["HUB","PROFILO","CRESCITA","CALENDARIO","CLASSIFICA","MERCATO","STORICO","SALVATAGGI"]
const VIEWS=["home","profile","growth","calendar","standings","offers","history","saves"]
const ROLE_LABELS=["Banda / Schiacciatore","Opposto","Centrale","Palleggiatore","Libero"]
const ATTRIBUTE_LABELS={"battuta":"BATTUTA","ricezione":"RICEZIONE","difesa":"DIFESA","palleggio":"PALLEGGIO","schiacciata":"SCHIACCIATA","muro":"MURO"}
const COMPS={"regular":"SuperLega","playoff":"Playoff Scudetto","cup":"Coppa Italia","supercup":"Supercoppa","fifth":"Playoff 5° posto","playout":"Play Out"}
var host
var game
var manager=Legend.new()
var frame: Control
var page: VBoxContainer
var header: HBoxContainer
var nav: HBoxContainer
var hint: Label
var view:="entry"
var tab_index:=0
var draft: Dictionary={}
var chosen_club:=""
var chosen_slot:=1
var chosen_best_of:=5
var draft_options: Dictionary={"difficulty":1,"fatigue":true,"autosave":true}
var active_fixture: Dictionary={}
var pending_post: Dictionary={}
var calendar_comp:=""
var calendar_own:=true
var calendar_round:=0
var standings_comp:="regular"
var modal: AcceptDialog
var keyboard: ConfirmationDialog
var keyboard_text: LineEdit
var keyboard_target: LineEdit
var axis_wait:=0.0
var held_direction:=Vector2.ZERO
var preview
var budget_label: Label
var overall_label: Label
var name_input: LineEdit
var attribute_values: Dictionary={}
var attribute_buttons: Dictionary={}
var saved_focus:=""
var popup_owner: OptionButton

class PortraitRadar:
	extends Control
	var data: Dictionary={}
	func update_player(value: Dictionary): data=value; queue_redraw()
	func caption(at: Vector2,value: String,font_size: int,color: Color):
		var font:=ThemeDB.fallback_font
		draw_string(font,at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
	func _draw():
		if data.is_empty(): return
		var center:=Vector2(size.x*.5,130)
		var appearance: Dictionary=data.get("appearance",{})
		var skins={"rosa":"f2cbb6","chiara":"f6d6c1","olivastra":"cda98a","ambrata":"ad7953","scura":"805537","nero":"60422f","ebano":"493126"}
		var hair_colors={"nero":"191411","marrone":"493024","castano chiaro":"806041","biondo":"c5ad6a","rosso":"824827","grigio":"8a827b"}
		var skin:=Color(skins.get(appearance.get("skin_tone","olivastra"),"cda98a"))
		var hair:=Color(hair_colors.get(appearance.get("hair_color","marrone"),"493024"))
		draw_circle(center,106,Color("152c42")); draw_arc(center,106,-PI*.8,PI*.55,70,Color("c2a15e"),2,true)
		var jersey:=PackedVector2Array([center+Vector2(-77,88),center+Vector2(-61,45),center+Vector2(-25,29),center+Vector2(25,29),center+Vector2(61,45),center+Vector2(77,88)])
		draw_colored_polygon(jersey,Color("3c8295")); draw_rect(Rect2(center+Vector2(-14,17),Vector2(28,33)),skin)
		draw_circle(center-Vector2(0,9),43,skin)
		var style: String=str(appearance.get("hair_style","corti"))
		if style!="pelato":
			draw_arc(center-Vector2(0,11),40,-PI*.96,-PI*.04,35,hair,14 if style in ["corti","rasati","sfumati"] else 25,true)
			if style in ["afro","ricci"]:
				for i in 7: draw_circle(center+Vector2(-36+i*12,-43-absf(3-i)*-3),13,hair)
			if style in ["lunghi","treccine"]:
				draw_line(center+Vector2(-40,-30),center+Vector2(-40,32),hair,17,true); draw_line(center+Vector2(40,-30),center+Vector2(40,32),hair,17,true)
		if appearance.get("beard","nessuna")!="nessuna": draw_arc(center-Vector2(0,9),34,.2,PI-.2,25,hair,9 if appearance.beard=="corta" else 17,true)
		caption(center+Vector2(0,80),str(data.get("number",data.get("jersey_number",1))),31,Color.WHITE)
		caption(Vector2(size.x*.5,258),str(data.get("name","")),25,Color("f3f6fb"))
		var role_index:=Legend.ROLES.find(str(data.get("role","outside_hitter")))
		caption(Vector2(size.x*.5,286),Locale.text(ROLE_LABELS[maxi(0,role_index)]),17,UI.MUTED)
		var origin:=Vector2(size.x*.5,452); var radius:=98.0
		for ring in range(1,5):
			var points:=PackedVector2Array()
			for i in 7: points.append(origin+Vector2.from_angle(-PI/2+TAU*(i%6)/6)*radius*ring/4)
			draw_polyline(points,Color("35475b"),1,true)
		var values:=PackedVector2Array()
		for i in 6:
			var axis:=Vector2.from_angle(-PI/2+TAU*i/6); var key: String=Legend.STAT_KEYS[i]
			draw_line(origin,origin+axis*radius,Color("35475b"),1,true)
			var value:=int(data.get("ratings",{}).get(key,0)); values.append(origin+axis*radius*value/99.0)
			caption(origin+axis*(radius+35),Locale.text(ATTRIBUTE_LABELS[key]),13,UI.MUTED)
			caption(origin+axis*(radius+35)+Vector2(0,19),str(value),19,Color.WHITE)
		draw_colored_polygon(values,Color(.28,.78,.87,.3)); var outline:=values.duplicate(); outline.append(values[0]); draw_polyline(outline,Color("70d6e5"),2,true)
		for point in values: draw_circle(point,3,UI.GOLD)
		caption(Vector2(size.x*.5,650),"OVR  "+str(Overall.calculate(data.get("ratings",{}),str(data.get("role","outside_hitter")))),33,UI.GOLD)

func _ready():
	auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	ensure_controller_bindings()
	Locale.ensure(); set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=UI.theme()
	var bg:=ColorRect.new(); bg.color=Color("091422"); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new(); frame.size=Vector2(1920,1080); add_child(frame)
	header=HBoxContainer.new(); header.position=Vector2(48,26); header.size=Vector2(1824,100); frame.add_child(header)
	nav=HBoxContainer.new(); nav.position=Vector2(48,143); nav.size=Vector2(1824,58); nav.add_theme_constant_override("separation",10); frame.add_child(nav)
	page=VBoxContainer.new(); page.position=Vector2(48,225); page.size=Vector2(1824,780); frame.add_child(page)
	hint=UI.label(frame,"",20,UI.MUTED); hint.position=Vector2(48,1031); hint.size=Vector2(1824,30)
	resized.connect(layout); layout(); hide()

func layout():
	if frame==null: return
	var factor:=minf(size.x/1920.0,size.y/1080.0); frame.scale=Vector2.ONE*factor; frame.position=(size-Vector2(1920,1080)*factor)*.5

func _t(value: String) -> String: return Locale.text(value)
func label(parent: Node,value: String,px: int=21,color: Color=UI.INK) -> Label: return UI.label(parent,_t(value),px,color)
func text_block(parent: Node,value: String,px: int=21,color: Color=UI.INK) -> Label: return UI.wrap(parent,_t(value),px,color)
func heading(parent: Node,value: String,px: int=38) -> Label: return UI.heading(parent,_t(value),px)
func button(parent: Node,value: String,callback: Callable,key: String="") -> Button: return UI.button(parent,_t(value),callback,key)
func controller_controls(scope: Node) -> Array:
	var all: Array=UI.controls(scope)
	if scope==self and is_instance_valid(name_input) and name_input.is_visible_in_tree() and name_input.focus_mode==Control.FOCUS_ALL: all.append(name_input)
	if scope is ConfirmationDialog:
		var cancel=scope.get_cancel_button()
		if cancel.is_visible_in_tree() and not cancel.disabled and cancel not in all: all.append(cancel)
	return all
func ensure_controller_bindings():
	# These are UI actions only. Gameplay mappings remain unchanged.
	for binding in [["ui_accept",JOY_BUTTON_A],["ui_cancel",JOY_BUTTON_B],["ui_left",JOY_BUTTON_DPAD_LEFT],["ui_right",JOY_BUTTON_DPAD_RIGHT],["ui_up",JOY_BUTTON_DPAD_UP],["ui_down",JOY_BUTTON_DPAD_DOWN]]:
		if not InputMap.has_action(binding[0]): InputMap.add_action(binding[0])
		var button_event:=InputEventJoypadButton.new(); button_event.device=-1; button_event.button_index=binding[1]
		if not InputMap.action_has_event(binding[0],button_event): InputMap.action_add_event(binding[0],button_event)
	for binding in [["ui_left",JOY_AXIS_LEFT_X,-1.0],["ui_right",JOY_AXIS_LEFT_X,1.0],["ui_up",JOY_AXIS_LEFT_Y,-1.0],["ui_down",JOY_AXIS_LEFT_Y,1.0]]:
		var axis_event:=InputEventJoypadMotion.new(); axis_event.device=-1; axis_event.axis=binding[1]; axis_event.axis_value=binding[2]
		if not InputMap.action_has_event(binding[0],axis_event): InputMap.action_add_event(binding[0],axis_event)
func controller_scope() -> Node:
	if is_instance_valid(popup_owner) and popup_owner.get_popup().visible: return popup_owner.get_popup()
	if is_instance_valid(keyboard) and keyboard.visible: return keyboard
	if is_instance_valid(modal) and modal.visible: return modal
	return self
func repair_controller_focus(scope: Node) -> Control:
	var owner=scope.get_viewport().gui_get_focus_owner()
	var all:=controller_controls(scope)
	if owner in all or (owner is LineEdit and scope.is_ancestor_of(owner) and owner.focus_mode!=Control.FOCUS_NONE):
		return owner
	if all.is_empty(): return null
	var selected=all[0]; var distance:=INF
	if owner!=null and scope.is_ancestor_of(owner):
		var center: Vector2=owner.get_global_rect().get_center()
		for control in all:
			var score: float=control.get_global_rect().get_center().distance_squared_to(center)
			if score<distance: selected=control; distance=score
	selected.grab_focus(); return selected
func controller_navigate(scope: Node,direction: Vector2):
	if scope is PopupMenu:
		var item: int=scope.get_focused_item()
		if absf(direction.y)>.5 and scope.item_count>0: scope.set_focused_item(clampi(item+int(signf(direction.y)),0,scope.item_count-1))
		return
	var owner=repair_controller_focus(scope)
	if owner==null: return
	var best=null; var cost:=INF; var center: Vector2=owner.get_global_rect().get_center()
	for candidate in controller_controls(scope):
		if candidate==owner: continue
		var delta: Vector2=candidate.get_global_rect().get_center()-center; var forward: float=delta.dot(direction)
		if forward<3: continue
		var score: float=forward+absf(delta.cross(direction))*3.5
		if score<cost: best=candidate; cost=score
	if best!=null: best.grab_focus()
func controller_event(scope: Node,event: InputEvent) -> bool:
	# Dialogs and selectors have their own native viewport. Their explicit
	# focus graph below uses Godot's single GUI event path, avoiding doubles.
	if scope is Window: return false
	if event is InputEventJoypadMotion:
		if event.axis not in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]: return false
		if absf(event.axis_value)<.25 and ((event.axis==JOY_AXIS_LEFT_X and absf(held_direction.x)>.1) or (event.axis==JOY_AXIS_LEFT_Y and absf(held_direction.y)>.1)):
			held_direction=Vector2.ZERO; axis_wait=0.0
		if absf(event.axis_value)>.55 and axis_wait<=0:
			var direction:=Vector2(signf(event.axis_value),0) if event.axis==JOY_AXIS_LEFT_X else Vector2(0,signf(event.axis_value))
			controller_navigate(scope,direction); axis_wait=.32; held_direction=direction
		consume_controller_event(scope); return true
	if not event is InputEventJoypadButton: return false
	var directions: Dictionary={JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}
	if event.button_index in directions:
		if event.pressed: controller_navigate(scope,directions[event.button_index]); axis_wait=.32
		consume_controller_event(scope); return true
	if event.button_index==JOY_BUTTON_A:
		# Activate once on press. Depending on the native popup window and
		# focus, Godot's default release event could reach another viewport.
		consume_controller_event(scope)
		if not event.pressed: return true
		var owner=repair_controller_focus(scope)
		if owner is LineEdit and scope==self: open_keyboard(owner)
		elif owner is OptionButton: owner.show_popup(); owner.get_popup().set_focused_item(owner.selected)
		elif owner is BaseButton and not owner.disabled: owner.pressed.emit()
		return true
	if event.button_index==JOY_BUTTON_B:
		consume_controller_event(scope)
		if not event.pressed: return true
		back()
		return true
	return false
func consume_controller_event(scope: Node):
	get_viewport().set_input_as_handled()
	if is_instance_valid(scope): scope.get_viewport().set_input_as_handled()
func bind_controller_popups(node: Node):
	if node is OptionButton:
		var option: OptionButton=node; var popup:=option.get_popup()
		popup.about_to_popup.connect(func(): popup_owner=option; popup.set_focused_item(option.selected))
		popup.popup_hide.connect(func():
			if popup_owner==option: popup_owner=null
			if is_instance_valid(option) and option.is_visible_in_tree(): option.grab_focus())
	for child in node.get_children():
		if not child is Window: bind_controller_popups(child)
func wire_dialog_focus(dialog: Window):
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(dialog) or not dialog.visible: return
	var all:=controller_controls(dialog)
	for index in all.size():
		var control: Control=all[index]
		control.focus_next=control.get_path_to(all[(index+1)%all.size()])
		control.focus_previous=control.get_path_to(all[posmod(index-1,all.size())])
		for pair in [[Vector2.LEFT,"focus_neighbor_left"],[Vector2.RIGHT,"focus_neighbor_right"],[Vector2.UP,"focus_neighbor_top"],[Vector2.DOWN,"focus_neighbor_bottom"]]:
			var best: Control=control; var cost:=INF; var center: Vector2=control.get_global_rect().get_center()
			for candidate in all:
				if candidate==control: continue
				var delta: Vector2=candidate.get_global_rect().get_center()-center; var forward: float=delta.dot(pair[0])
				if forward<3: continue
				var score: float=forward+absf(delta.cross(pair[0]))*3.5
				if score<cost: best=candidate; cost=score
			control.set(pair[1],control.get_path_to(best))
func clear(node: Node):
	for child in node.get_children(): node.remove_child(child); child.queue_free()
func club_name(id: String) -> String:
	if manager.active():
		var club: Dictionary=manager.team(id)
		if not club.is_empty(): return str(club.name)
	for club in preload("res://src/league.gd").new().teams:
		if club.id==id: return str(club.name)
	return id
func role_label(role: String) -> String: return _t(ROLE_LABELS[maxi(0,Legend.ROLES.find(role))])

func open():
	ensure_controller_bindings()
	for key in ["play_hub","clubs","online_menu","career_menu","overlay"]:
		var node=host.get(key) if is_instance_valid(host) else null
		if is_instance_valid(node): node.hide()
	show_page("entry")

func focus_restore(key: String=""):
	var all:=UI.controls(page)
	if all.is_empty(): all=UI.controls(nav)
	if all.is_empty(): all=UI.controls(header)
	for control in all:
		if str(control.get_meta("focus_key",""))==key: control.grab_focus(); return
	if not all.is_empty(): all[0].grab_focus()

func focus_key() -> String:
	var owner:=get_viewport().gui_get_focus_owner()
	return str(owner.get_meta("focus_key","")) if owner!=null else ""

func back():
	if is_instance_valid(keyboard) and keyboard.visible: keyboard.hide(); return
	match view:
		"entry":
			hide()
			if is_instance_valid(host) and is_instance_valid(host.get("play_hub")):
				if host.play_hub.has_method("open"): host.play_hub.open()
				else: host.play_hub.show()
		"clubs": show_page("new")
		"new": show_page("entry")
		"home": show_page("entry")
		"saves": show_page("home" if manager.active() else "entry")
		_: show_page("home" if manager.active() else "entry")

func show_tab(index: int):
	if not manager.active(): return
	tab_index=posmod(index,TABS.size()); show_page(VIEWS[tab_index])

func show_page(next: String):
	axis_wait=0.0; held_direction=Vector2.ZERO
	var aliases={"create":"new","hub":"home","profilo":"profile","crescita":"growth","calendario":"calendar","classifica":"standings","mercato":"offers","offerte":"offers","storico":"history","salvataggi":"saves"}
	view=str(aliases.get(next,next)); clear(header); clear(nav); clear(page); attribute_values.clear(); attribute_buttons.clear(); preview=null; budget_label=null; overall_label=null; show()
	if manager.active() and view not in ["entry","new","clubs"]: UI.badge(header,str(manager.state.club_id),80)
	var titles:=VBoxContainer.new(); titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL; titles.add_theme_constant_override("separation",3); header.add_child(titles)
	heading(titles,"DIVENTA UN MITO",39)
	label(titles,_t("LA TUA CARRIERA, UN SOLO GIOCATORE") if not manager.active() else "%s  ·  %s  ·  %s"%[manager.state.profile.name,club_name(str(manager.state.club_id)),manager.state.season_label],20,UI.MUTED)
	if manager.active():
		var save_button:=button(header,"SALVA",func(): toast("Carriera salvata." if manager.save() else manager.error),"save"); save_button.custom_minimum_size.x=150; save_button.size_flags_horizontal=Control.SIZE_SHRINK_END; save_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var back_button:=button(header,"INDIETRO",back,"back"); back_button.custom_minimum_size.x=165; back_button.size_flags_horizontal=Control.SIZE_SHRINK_END; back_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	if manager.active() and view not in ["entry","new","clubs"]:
		for i in TABS.size():
			var index:=i; var b:=button(nav,TABS[i],func(): show_tab(index),"tab-"+str(i)); b.add_theme_font_size_override("font_size",20)
			if VIEWS[i]==view: tab_index=i; b.add_theme_stylebox_override("normal",UI.surface(Color("3b5369"),12,14))
	match view:
		"entry": entry_screen()
		"new": creation_screen()
		"clubs": clubs_screen()
		"home": home_screen()
		"profile": profile_screen()
		"growth": growth_screen()
		"calendar": calendar_screen()
		"standings": standings_screen()
		"offers": offers_screen()
		"history": history_screen()
		"saves": saves_screen()
		"result": result_screen()
		"help": help_screen()
	hint.text=_t("LS / FRECCE: scegli   A / INVIO: conferma   B / ESC: indietro   L1 / R1: schede   RS: scorri   MENU / F5: salva")
	bind_controller_popups(page)
	call_deferred("focus_restore")

func image(parent: Node,height: float=260):
	var artwork:=TextureRect.new(); artwork.texture=UI.Brand.texture("assets/ui/career66/arena.png"); artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; artwork.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; artwork.custom_minimum_size.y=height; artwork.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(artwork)

func entry_screen():
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var hero:=UI.card(row,1125); image(hero,335); label(hero,"DAL PRIMO ALLENAMENTO ALLA LEGGENDA",22,UI.GOLD); heading(hero,"IL TUO NOME.\nLA TUA STORIA.",66)
	text_block(hero,"Crea il tuo atleta, parti dal basso e conquista la SuperLega. In campo controlli solo te stesso: posizione, tempi e scelte fanno la differenza.",26,UI.MUTED)
	var choices:=UI.card(row,670); heading(choices,"DIVENTA UN MITO",45)
	button(choices,"CREA IL TUO GIOCATORE",func(): draft=manager.default_profile(); show_page("new"),"new")
	var saves: Array=manager.list_saves()
	var continue_button:=button(choices,"CONTINUA LA CARRIERA",func():
		if manager.active(): show_page("home")
		elif not saves.is_empty() and manager.load_career(int(saves[0].slot)): show_page("home")
		else: toast(manager.error),"continue")
	continue_button.disabled=not manager.active() and saves.is_empty()
	button(choices,"CARICA SALVATAGGIO",func(): show_page("saves"),"load")
	button(choices,"COMANDI E RUOLI",func(): show_page("help"),"help")
	var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; choices.add_child(spacer)
	label(choices,"UN SOLO ATLETA · UNDICI COMPAGNI E AVVERSARI",19,UI.GOLD)
	text_block(choices,"Ogni fondamentale migliora con i punti conquistati dalle tue azioni. Le prestazioni aprono le porte a club più forti.",23,UI.MUTED)

func portrait(parent: Node,profile: Dictionary,width: float=470):
	var card:=UI.card(parent,width); preview=PortraitRadar.new(); preview.custom_minimum_size=Vector2(width-46,680); preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL; card.add_child(preview); preview.update_player(profile)
	return card

func creation_screen():
	if draft.is_empty(): draft=manager.default_profile()
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var left=portrait(row,draft,475); label(left,"01 / IL TUO GIOCATORE",21,UI.GOLD)
	var identity:=UI.card(row,645); var form:=UI.scroll(identity); heading(form,"IDENTITÀ E ASPETTO",35)
	label(form,"NOME",19,UI.GOLD); var name_row:=HBoxContainer.new(); form.add_child(name_row)
	name_input=LineEdit.new(); name_input.text=str(draft.name); name_input.max_length=48; name_input.custom_minimum_size.y=49; name_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL; name_row.add_child(name_input)
	name_input.text_changed.connect(func(value): draft.name=value; refresh_draft())
	var keyboard_button:=button(name_row,"TASTIERA",func(): open_keyboard(name_input),"name"); keyboard_button.custom_minimum_size.x=150; keyboard_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	label(form,"NUMERO DI MAGLIA",19,UI.MUTED)
	var numbers: Array=[]
	for number in range(1,100): numbers.append(str(number))
	var number_pick:=UI.picker(form,numbers,int(draft.number)-1); number_pick.set_meta("focus_key","number")
	number_pick.item_selected.connect(func(index): draft.number=index+1; draft.jersey_number=index+1; refresh_draft())
	label(form,"RUOLO",19,UI.MUTED); var roles:=UI.picker(form,ROLE_LABELS.map(func(value): return _t(value)),maxi(0,Legend.ROLES.find(str(draft.role)))); roles.set_meta("focus_key","role")
	roles.item_selected.connect(func(index): draft.role=Legend.ROLES[index]; refresh_draft())
	label(form,"MANO DOMINANTE",19,UI.MUTED); var hands:=UI.picker(form,[_t("Destra"),_t("Sinistra")],1 if draft.dominant_hand=="left" else 0)
	hands.set_meta("focus_key","hand")
	hands.item_selected.connect(func(index): draft.dominant_hand="left" if index==1 else "right"; refresh_draft())
	label(form,"SERVIZIO PREFERITO",19,UI.MUTED); var serves:=UI.picker(form,[_t("Salto potente"),_t("Float")],1 if draft.get("serve_preference","jump")=="float" else 0)
	serves.set_meta("focus_key","serve")
	serves.item_selected.connect(func(index): draft.serve_preference="float" if index==1 else "jump")
	appearance_controls(form,draft,false)
	var skills:=UI.card(row,650); heading(skills,"IL TUO PUNTO DI PARTENZA",33); text_block(skills,"Distribuisci 300 punti. Ogni attributo parte da 30 e può arrivare a 65. Il ruolo determina il tuo OVR.",22,UI.MUTED)
	budget_label=label(skills,"",27,UI.GOLD); overall_label=label(skills,"",22,UI.MUTED)
	for key in Legend.STAT_KEYS:
		var stat_key: String=key; var line:=HBoxContainer.new(); skills.add_child(line); var title:=label(line,ATTRIBUTE_LABELS[key],21); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var minus:=button(line,"−",func(): adjust_attribute(stat_key,-1),"minus-"+key); minus.custom_minimum_size.x=55; minus.size_flags_horizontal=Control.SIZE_SHRINK_END
		var value:=label(line,"",26,UI.GOLD); value.custom_minimum_size.x=48; value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; attribute_values[key]=value
		var plus:=button(line,"+",func(): adjust_attribute(stat_key,1),"plus-"+key); plus.custom_minimum_size.x=55; plus.size_flags_horizontal=Control.SIZE_SHRINK_END; attribute_buttons[key]=[minus,plus]
	var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; skills.add_child(spacer)
	button(skills,"CONTINUA · SCEGLI IL CLUB",func():
		var validation: String=manager.validate_profile(draft)
		if validation.is_empty(): show_page("clubs")
		else: toast(validation),"next-club")
	refresh_draft()

func appearance_controls(parent: Node,target: Dictionary,apply_live: bool):
	for entry in [["hair_style","CAPELLI"],["hair_color","COLORE CAPELLI"],["skin_tone","CARNAGIONE"],["beard","BARBA"]]:
		var key: String=entry[0]; var choices: Array=Legend.APPEARANCE_OPTIONS[key]
		label(parent,entry[1],19,UI.MUTED); var pick:=UI.picker(parent,choices.map(func(value): return _t(str(value).capitalize())),maxi(0,choices.find(target.get("appearance",{}).get(key,""))))
		pick.set_meta("focus_key","appearance-"+key)
		pick.item_selected.connect(func(index):
			if apply_live:
				if not manager.update_appearance({key:choices[index]}): toast(manager.error)
			else: target.appearance[key]=choices[index]
			if is_instance_valid(preview): preview.update_player(target))

func refresh_draft():
	if not is_instance_valid(preview): return
	preview.update_player(draft)
	var total:=0
	for key in Legend.STAT_KEYS: total+=int(draft.ratings[key])
	if is_instance_valid(budget_label): budget_label.text=_t("PUNTI RIMANENTI: %d / 300")%[Legend.INITIAL_BUDGET-total]
	if is_instance_valid(overall_label): overall_label.text=_t("OVR %d · MASSIMO INIZIALE 65")%Overall.calculate(draft.ratings,str(draft.role))
	for key in attribute_values:
		attribute_values[key].text=str(draft.ratings[key]); attribute_buttons[key][0].disabled=int(draft.ratings[key])<=Legend.INITIAL_MIN; attribute_buttons[key][1].disabled=int(draft.ratings[key])>=Legend.INITIAL_CAP or total>=Legend.INITIAL_BUDGET

func adjust_attribute(key: String,delta: int):
	var total:=0
	for stat in Legend.STAT_KEYS: total+=int(draft.ratings[stat])
	var value: int=int(draft.ratings[key])+delta
	if value<Legend.INITIAL_MIN or value>Legend.INITIAL_CAP or total+delta>Legend.INITIAL_BUDGET: return
	draft.ratings[key]=value; refresh_draft()

func clubs_screen():
	if draft.is_empty(): draft=manager.default_profile()
	heading(page,"02 / IL PRIMO CONTRATTO",40); text_block(page,"La tua carriera comincia da uno dei tre club più deboli. La forza è calcolata sulle formazioni del database attuale.",24,UI.MUTED)
	var clubs: Array=manager.starter_clubs(); var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	if not clubs.any(func(club): return club.id==chosen_club): chosen_club=str(clubs[0].id)
	for club in clubs:
		var club_id: String=club.id; var card:=UI.card(row,595); card.add_theme_constant_override("separation",9); var badge:=UI.badge(card,club_id,88); badge.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		var title:=heading(card,str(club.name),32); title.custom_minimum_size.y=78; title.max_lines_visible=2
		label(card,_t("FORZA SQUADRA · OVR %d")%roundi(float(club.strength)),23,UI.GOLD)
		var kit=load("res://src/kit_preview.gd").new(); kit.custom_minimum_size.y=160; card.add_child(kit); kit.image.custom_minimum_size.y=110; kit.show_kit(club_id,"home")
		text_block(card,"Contratto da titolare nel ruolo scelto. La tua crescita può portarti verso nuove squadre.",21,UI.MUTED)
		var choose:=button(card,"CLUB SCELTO" if club_id==chosen_club else "SCEGLI QUESTO CLUB",func(): chosen_club=club_id; show_page("clubs"); call_deferred("focus_restore","club-"+club_id),"club-"+club_id)
		if club_id==chosen_club: choose.add_theme_stylebox_override("normal",UI.surface(Color("3b5369"),12,14))
	var settings:=HBoxContainer.new(); page.add_child(settings)
	label(settings,"FORMATO",19,UI.MUTED); var format:=UI.picker(settings,[_t("Meglio dei 5"),_t("Meglio dei 3")],1 if chosen_best_of==3 else 0); format.item_selected.connect(func(index): chosen_best_of=3 if index==1 else 5)
	format.set_meta("focus_key","match-format")
	label(settings,"DIFFICOLTÀ",19,UI.MUTED); var difficulty:=UI.picker(settings,[_t("Accessibile"),_t("Normale"),_t("Impegnativa")],int(draft_options.difficulty)); difficulty.item_selected.connect(func(index): draft_options.difficulty=index)
	difficulty.set_meta("focus_key","difficulty")
	label(settings,"SLOT",19,UI.MUTED); var slots: Array=[]
	for number in range(1,13): slots.append(_t("Slot %d")%number)
	var slot:=UI.picker(settings,slots,chosen_slot-1); slot.item_selected.connect(func(index): chosen_slot=index+1)
	slot.set_meta("focus_key","save-slot")
	button(settings,"FIRMA E INIZIA",create_career,"create")

func create_career():
	var action:=func():
		var options:=draft_options.duplicate(true); options.best_of=chosen_best_of
		if manager.new_career(draft,chosen_club,options,chosen_slot): show_page("home")
		else: toast(manager.error)
	if manager.list_saves().any(func(row): return int(row.slot)==chosen_slot): confirm("Questo slot contiene già una carriera Diventa un mito. Vuoi sostituirla?",action)
	else: action.call()

func home_screen():
	if not manager.active(): entry_screen(); return
	var next: Dictionary=manager.next_fixture(); var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var summary=portrait(row,manager.state.profile,475); label(summary,_t("REPUTAZIONE %.1f / 100")%float(manager.state.reputation),22,UI.GOLD)
	var center:=UI.card(row,780); center.add_theme_constant_override("separation",10); image(center,150); label(center,"MATCH CENTER",22,UI.GOLD)
	if next.is_empty():
		heading(center,"UNA STAGIONE NELLA STORIA",46); text_block(center,"Tutte le competizioni sono concluse. Conserva i tuoi progressi e preparati alla prossima stagione.",24,UI.MUTED)
		button(center,"INIZIA LA PROSSIMA STAGIONE",func():
			if manager.next_season(): show_page("home")
			else: toast(manager.error),"next-season")
	else:
		var opponent: String=next.away if next.home==manager.state.club_id else next.home
		label(center,"%s  ·  %s"%[next.scheduled_date,_t(COMPS.get(next.competition,next.competition))],22,UI.MUTED)
		var teams:=HBoxContainer.new(); center.add_child(teams); UI.badge(teams,str(manager.state.club_id),80); heading(teams,"VS",37); UI.badge(teams,opponent,80)
		heading(center,club_name(opponent),43); label(center,"IN CASA" if next.home==manager.state.club_id else "IN TRASFERTA",22,UI.GOLD)
		text_block(center,"Controlli solo il tuo atleta. Muoviti nello spazio del tuo ruolo, chiama l'alzata e cerca il contatto con il pallone.",24,UI.MUTED)
		button(center,"SCENDI IN CAMPO",launch_match,"launch")
	var career:=UI.card(row,515); heading(career,"LA TUA ASCESA",35)
	label(career,_t("LIVELLO %d")%int(manager.state.level),32,UI.GOLD); label(career,_t("PUNTI ABILITÀ: %d")%int(manager.state.skill_points),25)
	UI.meter(career,_t("ESPERIENZA AL PROSSIMO PUNTO"),float(manager.state.xp_bank)/Legend.XP_PER_POINT*100)
	button(career,"ALLENA I FONDAMENTALI",func(): show_page("growth"),"growth")
	var contract: Dictionary=manager.state.contract; label(career,"IL TUO CONTRATTO",20,UI.GOLD)
	text_block(career,club_name(str(manager.state.club_id)),27); label(career,_t("Scadenza: stagione %d/%s")%[int(contract.expires_season),str(int(contract.expires_season)+1).right(2)],22,UI.MUTED)
	var open_offers: int=manager.state.offers.filter(func(offer): return offer.status=="open").size()
	button(career,_t("OFFERTE RICEVUTE: %d")%open_offers,func(): show_page("offers"),"offers")
	if not manager.last_result.is_empty():
		label(career,"ULTIMA PRESTAZIONE",20,UI.GOLD); label(career,_t("VOTO %.1f · +%d XP")%[float(manager.last_result.rating),int(manager.last_result.xp)],29)
	button(career,"COMANDI E RUOLO",func(): show_page("help"),"controls")

func profile_screen():
	if not manager.active(): return
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row); portrait(row,manager.state.profile,550)
	var details:=UI.card(row,640); heading(details,"IDENTITÀ DEL GIOCATORE",36)
	label(details,str(manager.state.profile.name),32,UI.GOLD); label(details,role_label(str(manager.state.profile.role)),27)
	label(details,_t("MAGLIA NUMERO %d")%int(manager.state.profile.number),24,UI.MUTED)
	label(details,"MANO SINISTRA" if manager.state.profile.dominant_hand=="left" else "MANO DESTRA",24,UI.MUTED)
	label(details,"SERVIZIO FLOAT" if manager.state.profile.get("serve_preference","jump")=="float" else "SERVIZIO IN SALTO",24,UI.MUTED)
	heading(details,"TROFEI DEL CLUB",33)
	var trophies: Array=manager.state.get("trophies",{}).get(manager.state.club_id,[])
	if trophies.is_empty(): text_block(details,"La tua bacheca aspetta il primo trofeo.",23,UI.MUTED)
	else:
		var list:=UI.scroll(details)
		for trophy in trophies: label(list,"%s  ·  %s"%[trophy.season,_t(COMPS.get(trophy.competition,trophy.competition))],22,UI.GOLD)
	var appearance:=UI.card(row,605); var form:=UI.scroll(appearance); heading(form,"IL TUO STILE",36); appearance_controls(form,manager.state.profile,true); text_block(form,"Il tuo aspetto viene aggiornato anche in campo.",22,UI.MUTED)

func growth_screen():
	if not manager.active(): return
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row); portrait(row,manager.state.profile,550)
	var training:=UI.card(row,800); heading(training,"COSTRUISCI LA TUA CARRIERA",39); label(training,_t("PUNTI ABILITÀ DISPONIBILI: %d")%int(manager.state.skill_points),29,UI.GOLD)
	text_block(training,"Le tue azioni in partita assegnano voto, esperienza e reputazione. Spendi i punti abilità per aumentare i fondamentali. Il costo cresce oltre 70 e 85.",24,UI.MUTED)
	for key in Legend.STAT_KEYS:
		var stat_key: String=key; var row_skill:=HBoxContainer.new(); training.add_child(row_skill); var text:=label(row_skill,ATTRIBUTE_LABELS[key],23); text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		label(row_skill,str(manager.state.profile.ratings[key]),29,UI.GOLD).custom_minimum_size.x=65
		var cost: int=manager.attribute_cost(key); var upgrade:=button(row_skill,_t("+1 · %d PT")%cost,func():
			if manager.upgrade_attribute(stat_key): show_page("growth"); call_deferred("focus_restore","upgrade-"+stat_key)
			else: toast(manager.error),"upgrade-"+key)
		upgrade.custom_minimum_size.x=165; upgrade.size_flags_horizontal=Control.SIZE_SHRINK_END; upgrade.disabled=int(manager.state.skill_points)<cost or int(manager.state.profile.ratings[key])>=Legend.ATTRIBUTE_CAP
	var progress:=UI.card(row,445); heading(progress,"PROGRESSI",34); label(progress,_t("LIVELLO %d")%int(manager.state.level),34,UI.GOLD); label(progress,_t("ESPERIENZA TOTALE: %d")%int(manager.state.xp),23)
	UI.meter(progress,_t("AL PROSSIMO PUNTO ABILITÀ"),float(manager.state.xp_bank)/Legend.XP_PER_POINT*100)
	UI.meter(progress,_t("REPUTAZIONE"),float(manager.state.reputation),Color("70d6e5")); text_block(progress,"Gioca bene con continuità per ricevere offerte da squadre più forti.",23,UI.MUTED)
	button(progress,"TORNA AL MATCH CENTER",func(): show_page("home"),"growth-home")

func calendar_screen():
	if not manager.active(): return
	heading(page,"IL TUO CALENDARIO",39)
	var filters:=HBoxContainer.new(); page.add_child(filters)
	var own:=UI.picker(filters,[_t("Solo il mio club"),_t("Tutte le squadre")],0 if calendar_own else 1); own.item_selected.connect(func(index): calendar_own=index==0; show_page("calendar"))
	var keys: Array=[""]+COMPS.keys(); var labels: Array=[_t("Tutte le competizioni")]
	for key in COMPS: labels.append(_t(COMPS[key]))
	var comp:=UI.picker(filters,labels,maxi(0,keys.find(calendar_comp))); comp.item_selected.connect(func(index): calendar_comp=keys[index]; show_page("calendar"))
	var rounds: Array=[_t("Tutte le giornate")]
	for number in range(1,23): rounds.append(_t("Giornata %d")%number)
	var round_pick:=UI.picker(filters,rounds,calendar_round); round_pick.item_selected.connect(func(index): calendar_round=index; show_page("calendar"))
	var list:=UI.scroll(page); var rows: Array=manager.state.fixtures.duplicate(); rows.sort_custom(func(a,b): return a.scheduled_date<b.scheduled_date if a.scheduled_date!=b.scheduled_date else a.id<b.id)
	UI.table_header(list,[_t("DATA"),_t("INCONTRO"),_t("COMPETIZIONE"),_t("RISULTATO")],[140,800,310,180])
	var found:=0
	for fixture in rows:
		if calendar_own and manager.state.club_id not in [fixture.home,fixture.away]: continue
		if not calendar_comp.is_empty() and fixture.competition!=calendar_comp: continue
		if calendar_round>0 and int(fixture.round)!=calendar_round: continue
		found+=1
		var score: String="—" if fixture.result.is_empty() else "%d – %d"%[int(fixture.result.sets[0]),int(fixture.result.sets[1])]
		var selected: Dictionary=fixture
		UI.table_row(list,[fixture.scheduled_date,club_name(str(fixture.home))+"  /  "+club_name(str(fixture.away)),_t(COMPS.get(fixture.competition,fixture.competition)),score],[140,800,310,180],func(): fixture_details(selected),"fixture-"+str(fixture.id))
	if found==0: text_block(list,"Nessun incontro per questi filtri.",25,UI.MUTED)

func fixture_details(fixture: Dictionary):
	var text: String="%s\n%s – %s\n%s"%[fixture.scheduled_date,club_name(str(fixture.home)),club_name(str(fixture.away)),_t(COMPS.get(fixture.competition,fixture.competition))]
	if not fixture.result.is_empty(): text+="\n\n"+"  /  ".join(fixture.result.set_scores.map(func(score): return "%d–%d"%[int(score[0]),int(score[1])]))
	else: text+="\n\n"+_t("Incontro da disputare.")
	toast(text)

func standings_screen():
	if not manager.active(): return
	heading(page,"LA CORSA AL TITOLO",39); var filters:=HBoxContainer.new(); page.add_child(filters)
	var keys: Array=["regular","playout","fifth"]; var pick:=UI.picker(filters,keys.map(func(key): return _t(COMPS[key])),maxi(0,keys.find(standings_comp)))
	pick.item_selected.connect(func(index): standings_comp=keys[index]; show_page("standings"))
	var list:=UI.scroll(page); var widths: Array=[55,650,90,90,90,90,100,100,120]
	UI.table_header(list,["#",_t("SQUADRA"),_t("G"),_t("V"),_t("P"),_t("PT"),_t("SET +"),_t("SET −"),_t("FORMA")],widths)
	for row in manager.standings(standings_comp):
		var club_id: String=row.team_id
		var b:=UI.table_row(list,[row.position,club_name(club_id),row.played,row.wins,row.losses,row.points,row.sets_for,row.sets_against," ".join(row.form)],widths,func(): toast(club_name(club_id)),"standing-"+club_id)
		if club_id==manager.state.club_id: b.add_theme_stylebox_override("normal",UI.surface(Color("294258"),10,12))
	var summary:=HBoxContainer.new(); page.add_child(summary)
	for key in ["cup","supercup","playoff"]:
		var competition: Dictionary=manager.state.competitions[key]; var card:=UI.card(summary,590); label(card,_t(COMPS[key]).to_upper(),20,UI.GOLD)
		label(card,club_name(str(competition.champion)) if not str(competition.champion).is_empty() else _t("COMPETIZIONE IN CORSO"),22,UI.MUTED)

func offers_screen():
	if not manager.active(): return
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var contract:=UI.card(row,560); UI.badge(contract,str(manager.state.club_id),115); heading(contract,"IL TUO CONTRATTO",38); label(contract,club_name(str(manager.state.club_id)),29,UI.GOLD); label(contract,role_label(str(manager.state.profile.role)),24)
	label(contract,_t("Ingaggio: € %d / mese")%int(manager.state.contract.salary),25,UI.MUTED); label(contract,_t("Scadenza: stagione %d/%s")%[int(manager.state.contract.expires_season),str(int(manager.state.contract.expires_season)+1).right(2)],23,UI.MUTED)
	UI.meter(contract,_t("REPUTAZIONE"),float(manager.state.reputation)); text_block(contract,"Le offerte dipendono dal rendimento personale. Ogni trasferimento conserva identità, attributi e statistiche.",24,UI.MUTED)
	var market:=UI.card(row,1240); heading(market,"IL MERCATO TI OSSERVA",40); var list:=UI.scroll(market); var open_offers: Array=manager.state.offers.filter(func(offer): return offer.status=="open")
	if open_offers.is_empty():
		text_block(list,"Nessuna offerta disponibile. Mostra il tuo valore in partita: servono continuità e reputazione per attirare un club più forte.",27,UI.MUTED)
		button(list,"GIOCA PER MOSTRARE IL TUO VALORE",func(): show_page("home"),"offers-home")
	for offer in open_offers:
		var selected: Dictionary=offer; var item:=UI.card(list); var title:=HBoxContainer.new(); item.add_child(title); UI.badge(title,str(offer.club_id),80); heading(title,str(offer.club_name),34)
		label(item,_t("OVR %d · %d stagioni · € %d / mese")%[roundi(float(offer.strength)),int(offer.years),int(offer.salary)],25,UI.GOLD)
		text_block(item,"Contratto da titolare nel ruolo scelto",23,UI.MUTED)
		button(item,"ACCETTA IL CONTRATTO",func(): confirm(_t("Vuoi firmare per %s? Il trasferimento sarà immediato.")%str(selected.club_name),func():
			if manager.accept_offer(str(selected.id)): show_page("home")
			else: toast(manager.error)),"offer-"+str(offer.id))
	if not manager.state.transfer_history.is_empty():
		label(market,"ULTIMO TRASFERIMENTO",19,UI.GOLD); var transfer: Dictionary=manager.state.transfer_history[0]; label(market,"%s  →  %s"%[club_name(str(transfer.from)),club_name(str(transfer.to))],22,UI.MUTED)

func history_screen():
	if not manager.active(): return
	heading(page,"LA STORIA CHE STAI SCRIVENDO",40)
	var stats:=HBoxContainer.new(); page.add_child(stats); var total_rating:=0.0; var totals: Dictionary={"kills":0,"aces":0,"blocks":0,"digs":0,"assists":0}
	for match_row in manager.state.match_history:
		total_rating+=float(match_row.rating)
		for key in totals: totals[key]+=int(match_row.performance.get(key,0))
	for entry in [["PARTITE",str(manager.state.match_history.size())],["VOTO MEDIO","%.1f"%(total_rating/maxi(1,manager.state.match_history.size()))],["ATTACCHI VINCENTI",str(totals.kills)],["ACE",str(totals.aces)],["MURI",str(totals.blocks)],["DIFESE",str(totals.digs)]]:
		var card:=UI.card(stats); label(card,entry[0],17,UI.MUTED); label(card,entry[1],34,UI.GOLD)
	var list:=UI.scroll(page); UI.table_header(list,[_t("DATA"),_t("AVVERSARIO"),_t("ESITO"),_t("VOTO"),"XP",_t("PUNTI")],[145,730,100,100,110,110])
	if manager.state.match_history.is_empty(): text_block(list,"La prima pagina della tua storia si scrive in campo.",26,UI.MUTED)
	for match_row in manager.state.match_history:
		var selected: Dictionary=match_row
		UI.table_row(list,[match_row.date,club_name(str(match_row.opponent_id)),_t("VINTA") if match_row.won else _t("PERSA"),"%.1f"%float(match_row.rating),"+%d"%int(match_row.xp),"+%d"%int(match_row.skill_points)],[145,730,100,100,110,110],func(): performance_dialog(selected),"history-"+str(match_row.fixture_id))
	button(page,"TORNA ALLA CARRIERA",func(): show_page("home"),"history-home")

func performance_dialog(row: Dictionary):
	var p: Dictionary=row.performance
	toast(_t("Voto %.1f · +%d XP · +%d punti abilità\nAttacchi %d/%d · Ace %d · Muri %d\nDifese %d · Ricezioni %d · Assist %d\nErrori %d")%[float(row.rating),int(row.xp),int(row.skill_points),int(p.kills),int(p.attacks),int(p.aces),int(p.blocks),int(p.digs),int(p.receptions),int(p.assists),int(p.errors)])

func saves_screen():
	heading(page,"LE TUE CARRIERE",40); text_block(page,"Dodici slot dedicati a Diventa un mito. Ogni slot conserva giocatore, stagione e progressi.",24,UI.MUTED)
	var saves: Array=manager.list_saves(); var list:=UI.scroll(page)
	for slot in range(1,13):
		var chosen: int=slot; var matches: Array=saves.filter(func(row): return int(row.slot)==chosen)
		if matches.is_empty():
			button(list,_t("SLOT %02d · VUOTO · CREA UNA CARRIERA")%slot,func(): chosen_slot=chosen; draft=manager.default_profile(); show_page("new"),"slot-"+str(slot))
		else:
			var save: Dictionary=matches[0]
			button(list,_t("SLOT %02d · %s · %s · %s")%[slot,str(save.player_name),club_name(str(save.club_id)),str(save.season_label)],func():
				if manager.load_career(chosen): show_page("home")
				else: toast(manager.error),"slot-"+str(slot))

func result_screen():
	var result: Dictionary=manager.last_result
	if result.is_empty(): home_screen(); return
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var hero:=UI.card(row,890); image(hero,280); label(hero,"LA TUA PRESTAZIONE",23,UI.GOLD); heading(hero,"VITTORIA" if result.won else "SCONFITTA",65)
	heading(hero,_t("VOTO %.1f")%float(result.rating),55); label(hero,_t("+%d XP  ·  +%d PUNTI ABILITÀ")%[int(result.xp),int(result.skill_points)],31,UI.GOLD)
	var detail:=UI.card(row,910); heading(detail,"OGNI AZIONE CONTA",40); var p: Dictionary=result.performance
	for entry in [["ATTACCHI VINCENTI","%d / %d"%[int(p.kills),int(p.attacks)]],["ACE",str(p.aces)],["MURI",str(p.blocks)],["DIFESE",str(p.digs)],["RICEZIONI",str(p.receptions)],["ASSIST",str(p.assists)],["ERRORI",str(p.errors)]]:
		var line:=HBoxContainer.new(); detail.add_child(line); label(line,entry[0],23).size_flags_horizontal=Control.SIZE_EXPAND_FILL; label(line,entry[1],27,UI.GOLD)
	label(detail,_t("REPUTAZIONE: %+.2f")%float(result.reputation_gain),25,UI.MUTED)
	button(detail,"CONTINUA LA CARRIERA",func(): pending_post.clear(); show_page("home"),"continue-career")
	button(detail,"ALLENA I FONDAMENTALI",func(): pending_post.clear(); show_page("growth"),"train")

func help_screen():
	heading(page,"IL CAMPO È NELLE TUE MANI",43); var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var controls:=UI.card(row,1030); heading(controls,"CONTROLLI MANUALI",36)
	for entry in [["LS / WASD","Movimento libero del tuo giocatore"],["RS / FRECCE","Mira di battuta, alzata e attacco"],["R1 / RB / R","Salto in attacco e a muro"],["CROCE / A / SPAZIO","Bagher e alzata: premi. Servizio e attacco: tieni e rilascia."],["QUADRATO / X / Q","Float, alzata veloce e pallonetto"],["L1 / LB / F","Chiama la palla"],["L2 / LT / SHIFT","Scatto"],["R2 / RT / C","Tuffo difensivo"],["CERCHIO / B / E","Attacco di seconda"]]:
		var line:=HBoxContainer.new(); controls.add_child(line); label(line,entry[0],22,UI.GOLD).custom_minimum_size.x=320; text_block(line,entry[1],23,UI.MUTED)
	var role:=UI.card(row,770); heading(role,"GIOCA IL TUO RUOLO",37)
	text_block(role,"Banda: ricevi e attacca dalle antenne.\nOpposto: cerca il punto sul lato destro.\nCentrale: salta a muro e prepara il primo tempo.\nPalleggiatore: costruisci l'attacco dei compagni.\nLibero: difendi e ricevi nella seconda linea.",26,UI.MUTED)
	text_block(role,"Fisica, timing e animazioni sono quelli dell'esibizione. Il cerchietto indica la posizione assegnata dall'IA: sei tu a raggiungerla. R1/RB comanda il salto in attacco e a muro; la battuta usa la sequenza completa dell'esibizione.",25,UI.GOLD)
	button(role,"TORNA ALLA CARRIERA",func(): show_page("home" if manager.active() else "entry"),"help-back")

func launch_match():
	var config: Dictionary=manager.launch_config()
	if config.is_empty(): toast(manager.error); return
	if game==null or game.get("legend_match")==null: manager.cancel_match(); toast("Motore partita non disponibile."); return
	var motor=game.legend_match
	if not motor.match_finished.is_connected(on_match_finished): motor.match_finished.connect(on_match_finished)
	var players=game.get("players")
	if players is Array and players.size()==12:
		for side in 2:
			var club: Dictionary=config.club if side==0 else config.opponent
			var squad: Array=config.club_lineup if side==0 else config.opponent_lineup
			for i in 6: players[side*6+i].set_roster_identity(squad[i],squad[6],Kits.selection(str(club.id),"home" if side==0 else "away"),Kits.selection(str(club.id),"home" if side==0 else "away",true))
	var management=game.get("match_management")
	if management!=null and management.has_method("suspend"): management.suspend()
	if not motor.start(config): manager.cancel_match(); toast("Impossibile avviare la partita."); return
	if game.get("gallery")!=null: game.gallery=false
	if game.get("camera_mode")!=null: game.camera_mode=0
	if game.has_method("set_camera"): game.set_camera()
	active_fixture=config.fixture.duplicate(true); pending_post.clear(); hide()
	if is_instance_valid(host) and is_instance_valid(host.get("clubs")):
		var music=host.clubs.get("music")
		if is_instance_valid(music): music.stop()

func on_match_finished(input: Dictionary):
	if active_fixture.is_empty(): return
	var output:=input.duplicate(true); output.fixture_id=active_fixture.id
	if str(output.get("score_order",""))!="home_away" and active_fixture.home!=manager.state.club_id:
		output.sets=[input.sets[1],input.sets[0]]; output.set_scores=[]
		for score in input.set_scores: output.set_scores.append([score[1],score[0]])
	if not output.has("performance"): output.performance={}
	if not output.performance.has("minutes"): output.performance.minutes=float(output.get("duration",0))/60.0
	if manager.complete_match(output): pending_post={"fixture_id":active_fixture.id}
	elif manager.state.rewarded_ids.has(active_fixture.id) and str(manager.last_result.get("fixture_id",""))==str(active_fixture.id):
		# The result is already recorded in memory: an I/O failure must neither
		# hide the earned reward nor invite recording the fixture a second time.
		pending_post={"fixture_id":active_fixture.id,"warning":manager.error}
	else: pending_post={"error":manager.error}
	active_fixture.clear()
	if game!=null and game.has_method("return_to_main_menu"): game.call_deferred("return_to_main_menu")

func on_match_abandoned():
	manager.cancel_match(); active_fixture.clear()
	if not pending_post.is_empty():
		var post:=pending_post.duplicate(); pending_post.clear(); show_page("result" if not post.has("error") else "home")
		if post.has("error"): toast(str(post.error))
		elif post.has("warning"): toast(_t("Risultato conservato in memoria. Premi SALVA per riprovare prima di uscire.")+"\n"+str(post.warning))
	else: show_page("home" if manager.active() else "entry")

func toast(text: String):
	saved_focus=focus_key(); modal=AcceptDialog.new(); modal.title=_t("DIVENTA UN MITO"); modal.dialog_text=_t(text); modal.theme=theme; add_child(modal)
	var dialog:=modal; dialog.confirmed.connect(func(): dialog.queue_free(); modal=null; call_deferred("focus_restore",saved_focus)); dialog.canceled.connect(func(): dialog.queue_free(); modal=null; call_deferred("focus_restore",saved_focus))
	dialog.popup_centered(Vector2i(780,270)); dialog.get_ok_button().grab_focus(); wire_dialog_focus(dialog)

func confirm(text: String,action: Callable):
	saved_focus=focus_key(); var dialog:=ConfirmationDialog.new(); modal=dialog; dialog.title=_t("CONFERMA"); dialog.dialog_text=_t(text); dialog.ok_button_text=_t("CONFERMA"); dialog.cancel_button_text=_t("ANNULLA"); dialog.theme=theme; add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free(); modal=null; action.call()); dialog.canceled.connect(func(): dialog.queue_free(); modal=null; call_deferred("focus_restore",saved_focus))
	dialog.popup_centered(Vector2i(780,280)); dialog.get_cancel_button().grab_focus(); wire_dialog_focus(dialog)

func open_keyboard(target: LineEdit):
	keyboard_target=target
	if keyboard==null:
		keyboard=ConfirmationDialog.new(); keyboard.title=_t("IL TUO NOME"); keyboard.ok_button_text=_t("CONFERMA"); keyboard.cancel_button_text=_t("ANNULLA"); keyboard.theme=theme; add_child(keyboard)
		var box:=VBoxContainer.new(); keyboard.add_child(box); keyboard_text=LineEdit.new(); keyboard_text.max_length=48; keyboard_text.focus_mode=Control.FOCUS_CLICK; box.add_child(keyboard_text)
		var grid:=GridContainer.new(); grid.columns=10; box.add_child(grid)
		for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789àèéìòù'-":
			var key: String=character; var b:=button(grid,key,func():
				if keyboard_text.text.length()<48: keyboard_text.text+=key); b.custom_minimum_size=Vector2(58,44); b.alignment=HORIZONTAL_ALIGNMENT_CENTER
		var actions:=HBoxContainer.new(); box.add_child(actions); button(actions,"SPAZIO",func():
			if keyboard_text.text.length()<48: keyboard_text.text+=" ")
		button(actions,"CANCELLA",func(): keyboard_text.text=keyboard_text.text.left(maxi(0,keyboard_text.text.length()-1)))
		keyboard.confirmed.connect(func():
			if is_instance_valid(keyboard_target): keyboard_target.text=keyboard_text.text; keyboard_target.text_changed.emit(keyboard_text.text)
			call_deferred("focus_restore","name"))
		keyboard.canceled.connect(func(): call_deferred("focus_restore","name"))
	keyboard_text.text=target.text; keyboard.popup_centered(Vector2i(850,640)); keyboard_text.get_parent().get_child(1).get_child(0).grab_focus(); wire_dialog_focus(keyboard)

func _process(dt: float):
	if game!=null and game.get("started")==false:
		if not pending_post.is_empty(): on_match_abandoned()
		elif not active_fixture.is_empty(): on_match_abandoned()
	if not visible: return
	axis_wait=maxf(0,axis_wait-dt)
	var scope:=controller_scope()
	if scope is Window: return
	var owner=repair_controller_focus(scope) if not scope is PopupMenu else null
	var devices:=Input.get_connected_joypads()
	if not devices.is_empty():
		var device: int=devices[0]; var scroll_axis:=Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y)
		if scope==self and absf(scroll_axis)>.25:
			var scroll=owner
			while scroll!=null and not scroll is ScrollContainer: scroll=scroll.get_parent()
			if scroll==null:
				var all:=page.find_children("*","ScrollContainer",true,false)
				if not all.is_empty(): scroll=all[0]
			if scroll is ScrollContainer: scroll.scroll_vertical+=roundi(scroll_axis*700*dt)
		var axis:=Vector2(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_LEFT_Y))
		if axis.length()>.55 and axis_wait<=0:
			var direction:=Vector2(signf(axis.x),0) if absf(axis.x)>absf(axis.y) else Vector2(0,signf(axis.y))
			controller_navigate(scope,direction); axis_wait=.15 if direction==held_direction else .32; held_direction=direction
		elif axis.length()<.25: held_direction=Vector2.ZERO

func _input(event: InputEvent):
	if not visible: return
	if controller_event(controller_scope(),event): return
	if is_instance_valid(keyboard) and keyboard.visible:
		if event.is_action_pressed("ui_cancel"): keyboard.hide(); call_deferred("focus_restore","name"); get_viewport().set_input_as_handled()
		return
	if is_instance_valid(modal) and modal.visible: return
	var owner:=get_viewport().gui_get_focus_owner()
	if owner is OptionButton and owner.get_popup().visible: return
	# Axis events and held-stick repeat share the same throttle.
	if event.is_action_pressed("ui_cancel"): back(); get_viewport().set_input_as_handled(); return
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_F5:
		if manager.active(): toast("Carriera salvata." if manager.save() else manager.error)
		get_viewport().set_input_as_handled(); return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER] and manager.active() and view not in ["entry","new","clubs"]:
			show_tab(tab_index+(-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1)); get_viewport().set_input_as_handled(); return
		if event.button_index==JOY_BUTTON_START and manager.active(): toast("Carriera salvata." if manager.save() else manager.error); get_viewport().set_input_as_handled(); return
		if owner is LineEdit and event.button_index==JOY_BUTTON_A: open_keyboard(owner); get_viewport().set_input_as_handled(); return
	if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_PAGEUP,KEY_PAGEDOWN] and manager.active() and view not in ["entry","new","clubs"]:
		show_tab(tab_index+(-1 if event.physical_keycode==KEY_PAGEUP else 1)); get_viewport().set_input_as_handled(); return
	if owner is LineEdit and event is InputEventKey: return
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]): controller_navigate(self,pair[1]); axis_wait=.32; get_viewport().set_input_as_handled(); return

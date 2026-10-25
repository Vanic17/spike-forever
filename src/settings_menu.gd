extends Control
var host
var service
var fields: Dictionary={}
var scroll: ScrollContainer
var grid: GridContainer
var video_tab: Button
var graphics_tab: Button
var apply_button: Button
var reset_button: Button
var back_button: Button
var status: Label
var confirmation: ConfirmationDialog
var previous: Dictionary={}
var draft: Dictionary={}
var deadline:=0
var pending:=false
var busy:=false
var page:=0
const VIDEO=["language","mode","resolution","hz","fps","vsync"]
const GRAPHICS=["preset","textures","scale","scaling_mode","aa","taa","shadows","shadow_distance","ssao","ssil","ssr","exposure","glow","crowd","anisotropy"]
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=host.clubs.theme
	var bg=ColorRect.new(); bg.color=Color("09121ff8"); add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin=MarginContainer.new(); add_child(margin); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",12); margin.add_child(column)
	var top=HBoxContainer.new(); column.add_child(top)
	var title=Label.new(); title.text="IMPOSTAZIONI"; title.add_theme_font_size_override("font_size",32); title.add_theme_color_override("font_color",Color("e9c677")); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(title)
	back_button=button("INDIETRO · B / CERCHIO",top,close)
	back_button.size_flags_horizontal=Control.SIZE_SHRINK_END; back_button.custom_minimum_size.x=260
	var subtitle=Label.new(); subtitle.text="Preferenze locali · conservate dopo gli aggiornamenti"; subtitle.add_theme_color_override("font_color",Color("aab7c7")); column.add_child(subtitle)
	var tabs=HBoxContainer.new(); column.add_child(tabs)
	video_tab=button("LINGUA E VIDEO",tabs,func(): show_page(0)); graphics_tab=button("GRAFICA",tabs,func(): show_page(1))
	var panel=PanelContainer.new(); column.add_child(panel); panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus=true; panel.add_child(scroll)
	grid=GridContainer.new(); grid.columns=2; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation",24); grid.add_theme_constant_override("v_separation",8); scroll.add_child(grid)
	status=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.custom_minimum_size.y=42; status.add_theme_color_override("font_color",Color("aab7c7")); column.add_child(status)
	var footer=HBoxContainer.new(); footer.add_theme_constant_override("separation",16); column.add_child(footer)
	apply_button=button("APPLICA E SALVA",footer,apply_changes); reset_button=button("VALORI PREDEFINITI",footer,defaults)
	var hint=Label.new(); hint.text="A / Croce: scegli · frecce / stick sinistro: naviga · B / Cerchio: indietro"; hint.add_theme_font_size_override("font_size",14); column.add_child(hint)
	confirmation=ConfirmationDialog.new(); confirmation.title="Conferma modalità video"; confirmation.ok_button_text="MANTIENI"; confirmation.cancel_button_text="RIPRISTINA"; confirmation.exclusive=true; add_child(confirmation)
	confirmation.confirmed.connect(keep); confirmation.canceled.connect(revert)
	hide()
func button(text: String,parent: Node,action: Callable) -> Button:
	var b=Button.new(); b.text=text; b.custom_minimum_size.y=48; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(b); b.pressed.connect(action); return b
func open():
	if not service.dry_run: service.discover_displays()
	draft=service.data.duplicate(true); fields.clear(); show(); show_page(0); video_tab.grab_focus()
func show_page(index: int):
	if not fields.is_empty(): collect()
	page=index
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	fields.clear()
	if page==0:
		add_option("language","Lingua",[["Italiano","it"],["English","en"]])
		add_option("mode","Modalità schermo",[["Finestra",0],["Schermo intero senza bordi",1],["Schermo intero esclusivo",2]])
		add_option("resolution","Risoluzione",[]); add_option("hz","Frequenza monitor",[])
		add_option("fps","Limite FPS",[["Illimitati",0],["30 FPS",30],["60 FPS",60],["90 FPS",90],["120 FPS",120],["144 FPS",144],["165 FPS",165],["180 FPS",180],["240 FPS",240],["360 FPS",360]])
		add_option("vsync","Sincronizzazione verticale",[["Disattivato",0],["Attivato",1],["Adattivo",2],["Mailbox",3]])
		fields.mode.item_selected.connect(func(_i): draft.mode=fields.mode.get_selected_metadata(); resolutions())
		fields.resolution.item_selected.connect(func(_i): refresh_rates())
		resolutions()
		status.text="Hz regolabili in schermo intero esclusivo; senza bordi usa il desktop. FPS e Hz sono indipendenti."
	else:
		add_option("preset","Profilo grafico",[["Personalizzato",-1],["Basso",0],["Medio",1],["Alto",2],["Ultra",3]])
		add_option("textures","Qualità texture",[["Bassa / 512 px",512],["Media / 1024 px",1024],["Alta / 2048 px",2048],["Originale / massima",0]])
		add_option("scale","Risoluzione 3D",[["50%",.5],["67%",.67],["75%",.75],["85%",.85],["100%",1.0]])
		add_option("scaling_mode","Ricostruzione immagine",[["Bilineare",0],["AMD FSR",1]])
		add_option("aa","Antialiasing MSAA",[["Disattivato",0],["2×",1],["4×",2],["8×",3]])
		add_option("taa","Antialiasing temporale",[["Disattivato",false],["Attivato",true]])
		add_option("shadows","Qualità ombre",[["Disattivate",0],["Basse",1],["Alte",2],["Massime",3]])
		add_option("shadow_distance","Distanza ombre",[["30 m",30.0],["55 m",55.0],["80 m",80.0]])
		add_option("ssao","Occlusione ambientale",[["Disattivato",false],["Attivato",true]])
		add_option("ssil","Illuminazione indiretta",[["Disattivato",false],["Attivato",true]])
		add_option("ssr","Riflessi dello schermo",[["Disattivato",false],["Attivato",true]])
		add_option("exposure","Luminosità",[["80%",.8],["100%",1.0],["120%",1.2],["140%",1.4]])
		add_option("glow","Bagliore luci",[["Disattivato",false],["Attivato",true]])
		add_option("crowd","Densità pubblico",[["Ridotto",0],["Medio",1],["Completo",2]])
		add_option("anisotropy","Filtro anisotropico",[["Disattivato",0],["2×",1],["4×",2],["8×",3],["16×",4]])
		fields.preset.item_selected.connect(func(_i):
			var selected: int=fields.preset.get_selected_metadata()
			if selected<0: return
			collect(); draft.merge(service.PRESETS[selected],true); draft.preset=selected; fields.clear(); show_page(1); fields.preset.grab_focus())
		for key in GRAPHICS:
			if key!="preset": fields[key].item_selected.connect(func(_i): draft.preset=-1; fields.preset.select(0))
		status.text="Regola la qualità e le prestazioni. Le impostazioni vengono mantenute a ogni avvio."
	scroll.scroll_vertical=0; video_tab.modulate=Color("e9c677") if page==0 else Color.WHITE; graphics_tab.modulate=Color("e9c677") if page==1 else Color.WHITE
	wire_focus()
func add_option(key: String,label: String,options: Array):
	var cell=VBoxContainer.new(); cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_child(cell)
	var title=Label.new(); title.text=label; title.add_theme_font_size_override("font_size",17); title.add_theme_color_override("font_color",Color("bac8d9")); cell.add_child(title)
	var option=OptionButton.new(); option.custom_minimum_size=Vector2(0,46); option.size_flags_horizontal=Control.SIZE_EXPAND_FILL; cell.add_child(option)
	option.add_theme_font_size_override("font_size",18)
	var style=option.get_theme_stylebox("normal").duplicate(); style.content_margin_top=6; style.content_margin_bottom=6; option.add_theme_stylebox_override("normal",style)
	fields[key]=option
	for item in options: option.add_item(item[0]); option.set_item_metadata(option.item_count-1,item[1])
	select_value(option,draft.get(key))
	option.focus_entered.connect(func(): call_deferred("reveal",cell))
func reveal(cell: Control):
	if is_instance_valid(cell) and scroll.is_ancestor_of(cell): scroll.ensure_control_visible(cell)
func select_value(option: OptionButton,value):
	for i in option.item_count:
		if option.get_item_metadata(i)==value: option.select(i); return
func resolutions():
	var option: OptionButton=fields.resolution; option.clear()
	var info: Dictionary=service.display_info(); var choices: Array=[]
	if draft.mode==1:
		var desktop: Vector2i=DisplayServer.screen_get_size() if not service.dry_run else Vector2i(1920,1080)
		if not service.original_mode.is_empty(): desktop=Vector2i(service.original_mode.width,service.original_mode.height)
		choices.append(desktop)
	elif draft.mode==2 and not info.is_empty():
		for item in info.modes:
			var resolution:=Vector2i(item.width,item.height)
			if not resolution in choices: choices.append(resolution)
	else:
		choices=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
		var current:=Vector2i(draft.width,draft.height)
		if current not in choices: choices.append(current)
	choices.sort_custom(func(a,b): return a.x*a.y<b.x*b.y)
	var automatic: Vector2i=service.automatic_resolution(draft.mode)
	var category: String={Vector2i(1920,1080):" · Full HD",Vector2i(2560,1440):" · QHD / 2K",Vector2i(3840,2160):" · 4K UHD"}.get(automatic,"")
	option.add_item((tr("Automatica · desktop %d × %d") if draft.mode==1 else tr("Automatica · nativa %d × %d"))%[automatic.x,automatic.y]+category); option.set_item_metadata(0,Vector2i.ZERO)
	for resolution in choices: option.add_item("%d × %d"%[resolution.x,resolution.y]); option.set_item_metadata(option.item_count-1,resolution)
	select_value(option,Vector2i.ZERO if draft.native_resolution else Vector2i(draft.width,draft.height)); option.disabled=draft.mode==1
	refresh_rates(); wire_focus()
func refresh_rates():
	var option: OptionButton=fields.hz; option.clear()
	var choices: Array=[0]; var resolution: Vector2i=fields.resolution.get_selected_metadata(); var info: Dictionary=service.display_info()
	if resolution==Vector2i.ZERO: resolution=service.automatic_resolution(draft.mode)
	if draft.mode==2 and not info.is_empty():
		choices.clear()
		for item in info.modes:
			if item.width==resolution.x and item.height==resolution.y and int(item.hz) not in choices: choices.append(int(item.hz))
		choices.sort()
	var desktop_hz: int=int(service.original_mode.get("hz",0))
	for hz in choices: option.add_item(("Desktop / automatico"+(" · %d Hz"%desktop_hz if desktop_hz>0 else "")) if hz==0 else str(hz)+" Hz"); option.set_item_metadata(option.item_count-1,hz)
	select_value(option,draft.hz); option.disabled=draft.mode!=2 or choices==[0]
	if draft.hz==0 and not choices.is_empty(): option.select(choices.size()-1)
	wire_focus()
func collect():
	for key in fields:
		if fields[key].item_count==0: continue
		var value=fields[key].get_selected_metadata()
		if key=="resolution":
			draft.native_resolution=value==Vector2i.ZERO
			if draft.native_resolution: value=service.automatic_resolution(draft.mode)
			draft.width=value.x; draft.height=value.y
		else: draft[key]=value
func controls() -> Array:
	var result: Array=[video_tab,graphics_tab]
	for key in VIDEO if page==0 else GRAPHICS:
		if fields.has(key) and not fields[key].disabled: result.append(fields[key])
	result.append_array([apply_button,reset_button,back_button]); return result
func wire_focus():
	if apply_button==null: return
	var list=controls()
	for i in list.size():
		list[i].focus_neighbor_top=list[i].get_path_to(list[maxi(0,i-1)])
		list[i].focus_neighbor_bottom=list[i].get_path_to(list[mini(list.size()-1,i+1)])
		list[i].focus_neighbor_left=list[i].focus_neighbor_top; list[i].focus_neighbor_right=list[i].focus_neighbor_bottom
func defaults():
	draft=service.DEFAULTS.duplicate(); fields.clear(); show_page(page)
	status.text="Premi APPLICA E SALVA per confermare i valori predefiniti."
func apply_changes():
	if busy or pending: return
	collect(); previous=service.data.duplicate(true)
	var video_changed: bool=draft.mode!=previous.mode or draft.native_resolution!=previous.native_resolution or (not draft.native_resolution and draft.mode in [0,2] and (draft.width!=previous.width or draft.height!=previous.height)) or (draft.mode==2 and draft.hz!=previous.hz)
	busy=true; apply_button.disabled=true; reset_button.disabled=true; status.text="Applicazione impostazioni…"
	await get_tree().process_frame
	if not service.apply(draft,video_changed):
		var error: String=service.last_error; service.apply(previous,true); status.text=error
	elif video_changed:
		pending=true; deadline=Time.get_ticks_msec()+15000
		_process(0)
		confirmation.popup_centered(Vector2i(620,230)); confirmation.get_ok_button().grab_focus()
	else: commit()
	busy=false; apply_button.disabled=false; reset_button.disabled=false
func commit():
	var error: Error=service.save_config(); service.loaded=error==OK
	status.text="Impostazioni applicate e salvate." if error==OK else "Salvataggio impostazioni non riuscito."
func keep():
	if not pending: return
	pending=false; confirmation.hide(); commit(); apply_button.grab_focus()
func revert():
	if not pending: return
	pending=false; confirmation.hide(); service.apply(previous,true); draft=previous.duplicate(true); fields.clear(); show_page(page)
	status.text="Impostazioni precedenti ripristinate."; apply_button.grab_focus()
func close():
	if busy: return
	if pending: revert(); return
	hide(); host.settings_button.grab_focus()
func _process(_dt: float):
	if not pending: return
	var remaining:=maxi(0,ceili((deadline-Time.get_ticks_msec())/1000.0))
	confirmation.dialog_text=tr("Mantieni queste impostazioni? Ripristino automatico tra %d secondi.")%remaining
	if remaining==0: revert()
func _input(event: InputEvent):
	if not visible or busy: return
	if pending: return
	var owner=get_viewport().gui_get_focus_owner()
	if owner is OptionButton and owner.get_popup().visible:
		if event.is_action_pressed("ui_cancel"): owner.get_popup().hide(); get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"): close(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var list=controls(); var i=list.find(owner)
		if i>=0:
			list[clampi(i+(-1 if event.is_action_pressed("ui_up") else 1),0,list.size()-1)].grab_focus(); get_viewport().set_input_as_handled()

extends RefCounted
const Brand=preload("res://src/league_branding.gd")
const INK=Color("f3f6fb")
const MUTED=Color("a9b9ce")
const GOLD=Color("ebc36b")
const BLUE=Color("15263d")
static func surface(color: Color=BLUE, radius: int=18,margin: int=22) -> StyleBoxFlat:
	var box=StyleBoxFlat.new(); box.bg_color=color; box.set_corner_radius_all(radius)
	box.border_color=Color("30425b"); box.set_border_width_all(1)
	for edge in ["left","right","top","bottom"]: box.set("content_margin_"+edge,margin)
	return box
static func theme() -> Theme:
	preload("res://src/career_locale.gd").ensure()
	var t=Theme.new(); t.default_font_size=21
	for type in ["Button","OptionButton","LineEdit","SpinBox"]:
		t.set_stylebox("normal",type,surface(Color("20334b"),12,14))
		t.set_stylebox("hover",type,surface(Color("2e4967"),12,14))
		t.set_stylebox("pressed",type,surface(Color("e2bb70"),12,14))
		var focus=surface(Color("f5f4ef"),12,14); focus.border_color=GOLD; focus.set_border_width_all(3)
		t.set_stylebox("focus",type,focus)
		t.set_color("font_color",type,INK); t.set_color("font_focus_color",type,Color("0d1a2a")); t.set_color("font_pressed_color",type,Color("102039"))
	t.set_stylebox("panel","PanelContainer",surface())
	t.set_stylebox("panel","PopupMenu",surface(Color("16263d"),12,12))
	t.set_color("font_color","Label",INK); t.set_color("font_color","PopupMenu",INK)
	t.set_constant("v_separation","PopupMenu",14); t.set_font_size("font_size","PopupMenu",20)
	t.set_constant("separation","VBoxContainer",12); t.set_constant("separation","HBoxContainer",14)
	return t
static func label(parent: Node,value: String,px: int=21,color: Color=INK) -> Label:
	var l=Label.new(); l.text=preload("res://src/career_locale.gd").text(value); l.add_theme_font_size_override("font_size",px); l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l
static func wrap(parent: Node,value: String,px: int=21,color: Color=INK) -> Label:
	var l=label(parent,value,px,color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l
static func heading(parent: Node,value: String,px: int=37) -> Label:
	var l=label(parent,value,px); l.add_theme_font_override("font",Brand.font())
	if parent is Container: l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return l
static func button(parent: Node,value: String,callback: Callable,key: String="") -> Button:
	var b=Button.new(); b.text=preload("res://src/career_locale.gd").text(value); b.custom_minimum_size.y=49; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text=true; b.set_meta("focus_key",key if not key.is_empty() else value)
	parent.add_child(b); b.pressed.connect(callback)
	b.focus_entered.connect(func():
		var ancestor=b.get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(b)
			ancestor=ancestor.get_parent())
	return b
static func picker(parent: Node,items: Array,selected: int=0) -> OptionButton:
	var p=OptionButton.new(); p.custom_minimum_size.y=49; p.size_flags_horizontal=Control.SIZE_EXPAND_FILL; p.fit_to_longest_item=false; p.clip_text=true
	for item in items: p.add_item(preload("res://src/career_locale.gd").text(str(item)))
	p.select(clampi(selected,0,maxi(0,items.size()-1))); parent.add_child(p)
	p.focus_entered.connect(func():
		var ancestor=p.get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(p)
			ancestor=ancestor.get_parent())
	return p
static func compact(button: Button):
	button.custom_minimum_size.y=31; button.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","focus"]:
		var style=button.get_theme_stylebox(state,"Button").duplicate(); style.content_margin_top=3; style.content_margin_bottom=3; button.add_theme_stylebox_override(state,style)
static func card(parent: Node,width: float=0,height: float=0) -> VBoxContainer:
	var panel=PanelContainer.new(); panel.custom_minimum_size=Vector2(width,height); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(panel)
	var v=VBoxContainer.new(); v.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_child(v); return v
static func scroll(parent: Node) -> VBoxContainer:
	var sc=ScrollContainer.new(); sc.size_flags_horizontal=Control.SIZE_EXPAND_FILL; sc.size_flags_vertical=Control.SIZE_EXPAND_FILL; parent.add_child(sc)
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var v=VBoxContainer.new(); v.size_flags_horizontal=Control.SIZE_EXPAND_FILL; sc.add_child(v); return v
static func badge(parent: Node,id: String,size: float=72) -> TextureRect: return Brand.emblem(parent,id,size,size)
static func meter(parent: Node,title: String,value: float,color: Color=GOLD) -> ProgressBar:
	label(parent,title,19,MUTED)
	var meter=ProgressBar.new(); meter.value=value; meter.show_percentage=false; meter.custom_minimum_size.y=9
	meter.add_theme_stylebox_override("background",surface(Color("29384c"),4,0)); meter.add_theme_stylebox_override("fill",surface(color,4,0)); parent.add_child(meter); return meter
static func table_row(parent: Node,cells: Array,widths: Array,callback: Callable,key: String) -> Button:
	var b=button(parent,"",callback,key); b.custom_minimum_size.y=49
	table_cells(b,cells,widths)
	return b
static func table_header(parent: Node,cells: Array,widths: Array) -> Control:
	var header=Control.new(); header.custom_minimum_size.y=38; parent.add_child(header)
	header.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	table_cells(header,cells,widths,true)
	return header
static func table_cells(parent: Control,cells: Array,widths: Array,is_header: bool=false):
	var margin=MarginContainer.new(); parent.add_child(margin); margin.mouse_filter=Control.MOUSE_FILTER_IGNORE; margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",14); margin.add_theme_constant_override("margin_right",14)
	var row=HBoxContainer.new(); row.mouse_filter=Control.MOUSE_FILTER_IGNORE; margin.add_child(row); var labels=[]
	for i in cells.size():
		var l=label(row,str(cells[i]),20 if is_header else 22,MUTED if is_header else INK); l.custom_minimum_size.x=float(widths[i]); l.clip_text=true
		if i==1: l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		elif i>1: l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		labels.append(l)
	if not parent is Button: return
	parent.focus_entered.connect(func():
		for l in labels: l.add_theme_color_override("font_color",Color("102039")))
	parent.focus_exited.connect(func():
		for l in labels: l.add_theme_color_override("font_color",INK))
static func controls(node: Node) -> Array:
	var found: Array=[]
	for child in node.get_children():
		if child is Window: continue
		if child is BaseButton and child.is_visible_in_tree() and not child.disabled and child.focus_mode==Control.FOCUS_ALL: found.append(child)
		found.append_array(controls(child))
	if node is AcceptDialog and node.get_ok_button().is_visible_in_tree(): found.append(node.get_ok_button())
	return found
static func navigate(scope: Node,direction: Vector2) -> void:
	var all=controls(scope); if all.is_empty(): return
	var owner=scope.get_viewport().gui_get_focus_owner()
	if not owner in all: all[0].grab_focus(); return
	var center=owner.get_global_rect().get_center(); var best=null; var cost=INF
	for b in all:
		if b==owner: continue
		var delta=b.get_global_rect().get_center()-center; var forward=delta.dot(direction)
		if forward<3: continue
		var cross=absf(delta.cross(direction)); var score=forward+cross*3.5
		if score<cost: cost=score; best=b
	if best!=null: best.grab_focus()

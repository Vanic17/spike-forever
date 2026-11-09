extends RefCounted
const C=preload("res://src/condition99.gd")
static func names(person: Dictionary,ledger: Dictionary,enabled: bool) -> String:
	var role: String={"outside_hitter":"OH","middle_blocker":"MB","opposite":"OPP","setter":"S","libero":"L"}.get(str(person.get("role","")),"–")
	return role+" · "+C.summary(person,ledger,enabled)
static func decorate(pick: OptionButton,people: Array,ledger: Dictionary) -> void:
	pick.add_theme_constant_override("icon_max_width",24)
	for i in people.size():
		var p: Dictionary=people[i];var code: String=C.arrow(ledger,str(p.id))
		pick.set_item_icon(i,C.icon(code))
		pick.set_item_tooltip(i,C.summary(p,ledger)+" · "+str(TranslationServer.translate("Forma"))+" "+str(ledger.get("forms",{}).get(p.id,C.form(p)))+" · %+.0f%%"%(C.modifier(code)*100))
static func list(parent: Node,people: Array,ledger: Dictionary,enabled: bool=true) -> GridContainer:
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",5);parent.add_child(grid)
	for p in people:
		var row:=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(row)
		var icon:=TextureRect.new();icon.texture=C.icon(C.arrow(ledger,str(p.id)));icon.custom_minimum_size=Vector2(24,24);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
		var text:=Label.new();text.text=names(p,ledger,enabled);text.add_theme_font_size_override("font_size",13);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.clip_text=true;text.tooltip_text=text.text;row.add_child(text)
	return grid

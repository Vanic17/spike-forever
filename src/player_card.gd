extends Control
var player: Dictionary={}
var ratings: Dictionary={}
const KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
func update_player(data: Dictionary) -> void:
	player=data; ratings=data.get("ratings",{}).duplicate(); queue_redraw()
func caption(at: Vector2, text: String, font_size: int, color: Color,translate_value: bool=true) -> void:
	if translate_value: text=tr(text)
	var font=ThemeDB.fallback_font
	draw_string(font,at-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw() -> void:
	var gold=Color("e9c677"); var muted=Color("9daec3")
	draw_style_box(get_theme_stylebox("panel","PanelContainer"),Rect2(Vector2.ZERO,size))
	draw_set_transform(Vector2.ZERO,0,Vector2(1,minf(1,size.y/530.0)))
	caption(Vector2(size.x/2,32),"PLAYER PROFILE",13,gold)
	var name: String=str(player.get("name",""))
	caption(Vector2(size.x/2,65),name,20,Color.WHITE,false)
	var role: String={"setter":"S / PALLEGGIATORE","opposite":"OPP / OPPOSTO","outside_hitter":"OH / BANDA","middle_blocker":"MB / CENTRALE","libero":"L / LIBERO"}.get(player.get("role",""),"")
	caption(Vector2(size.x/2,91),role,12,muted)
	draw_circle(Vector2(size.x/2,145),35,Color("26374b"))
	draw_arc(Vector2(size.x/2,145),35,-PI/2,TAU-PI/2,64,gold,2,true)
	caption(Vector2(size.x/2,155),str(preload("res://src/player_overall.gd").calculate(ratings,str(player.get("role","outside_hitter")))),30,gold)
	var radius=minf(102,(size.x-130)/2)
	var centre=Vector2(size.x/2,340)
	for ring in range(1,5):
		var polygon=PackedVector2Array()
		for i in 7: polygon.append(centre+Vector2.from_angle(-PI/2+TAU*(i%6)/6)*radius*ring/4)
		draw_polyline(polygon,Color("35475b"),1,true)
	var values=PackedVector2Array()
	for i in 6:
		var axis=Vector2.from_angle(-PI/2+TAU*i/6)
		draw_line(centre,centre+axis*radius,Color("35475b"),1,true)
		var value=int(ratings.get(KEYS[i],0))
		values.append(centre+axis*radius*clampf(value/99.0,0,1))
		var at=centre+axis*(radius+32)
		caption(at,KEYS[i].capitalize(),12,muted)
		caption(at+Vector2(0,19),str(value),17,Color.WHITE)
	draw_colored_polygon(values,Color(0.28,0.78,0.87,0.28))
	var outline=values.duplicate(); outline.append(values[0]); draw_polyline(outline,Color("70d6e5"),2,true)
	for point in values: draw_circle(point,3,gold)
	caption(Vector2(size.x/2,510),"VALORI MODIFICABILI / GAMEPLAY OPZIONALE",10,muted)

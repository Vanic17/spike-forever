extends Control
var category:="serve"
var accent:=Color("edc46b")
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	var area:=Rect2(Vector2(30,16),Vector2(maxf(120,size.x-60),maxf(120,size.y-36)))
	var court_size:=Vector2((area.size.y-20)*.5,area.size.y-20)
	var court:=Rect2(area.get_center()-court_size*.5,court_size)
	draw_style_box(style(Color("13283a")),area)
	draw_rect(court,Color("c1a981"))
	draw_rect(court,Color("e6e9ec"),false,2)
	var centre:=court.get_center()
	for ratio in [.3333,.6667]: draw_line(Vector2(court.position.x,court.position.y+court.size.y*ratio),Vector2(court.end.x,court.position.y+court.size.y*ratio),Color("f0eee5"),1)
	draw_line(Vector2(court.position.x-10,centre.y),Vector2(court.end.x+10,centre.y),Color("ecce83"),4)
	var from:=Vector2(centre.x,court.end.y-12)
	var to:=Vector2(court.end.x-25,court.position.y+28)
	if category=="receive": from=Vector2(centre.x,court.position.y+10); to=Vector2(centre.x,court.end.y-30)
	if category=="set": from=Vector2(centre.x+25,centre.y+28); to=Vector2(court.position.x+23,centre.y+20)
	if category=="attack": from=Vector2(court.position.x+23,centre.y+20); to=Vector2(court.end.x-28,court.position.y+30)
	if category=="block": from=Vector2(court.end.x-28,centre.y-30); to=Vector2(court.end.x-28,centre.y+8)
	draw_circle(to,22,Color(accent,.20)); draw_arc(to,22,0,TAU,40,accent,2,true)
	for k in 9:
		var a:=from.lerp(to,float(k)/10)
		var b:=from.lerp(to,(float(k)+.55)/10)
		draw_line(a,b,accent,2,true)
	draw_circle(from,8,Color("f3f5f8")); draw_circle(to,5,accent)
	for x in [-.30,0,.30]: draw_circle(Vector2(centre.x+court.size.x*x,centre.y+18),5,Color("244966"))
	for x in [-.28,0,.28]:
		draw_circle(Vector2(centre.x+court.size.x*x,court.end.y-25),5,Color("244966"))
		draw_circle(Vector2(centre.x+court.size.x*x,centre.y-20),5,Color("83909b"))
	var font=ThemeDB.fallback_font
	var small:=area.size.y<160
	var left:=area.position+Vector2(20,30 if small else 42)
	var movement: String=preload("res://src/tutorial_lessons.gd").say("MOVIMENTO AUTOMATICO","AUTOMATIC MOVEMENT") if category=="receive" else preload("res://src/tutorial_lessons.gd").say("LEVETTA SINISTRA","LEFT STICK")
	var explanation: String=preload("res://src/tutorial_lessons.gd").say("Concentrati sul contatto","Focus on contact") if category=="receive" else (preload("res://src/tutorial_lessons.gd").say("Sposta il centrale","Move the middle") if category=="block" else preload("res://src/tutorial_lessons.gd").say("Mira / direzioni","Aim / direction"))
	draw_string(font,left,movement,HORIZONTAL_ALIGNMENT_LEFT,-1,14,accent)
	draw_string(font,left+Vector2(0,25),explanation,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a7becf"))
	var key:=area.position+Vector2(area.size.x-205,30 if small else 42)
	draw_string(font,key,preload("res://src/tutorial_lessons.gd").say("CROCE / A","CROSS / A"),HORIZONTAL_ALIGNMENT_LEFT,-1,15,accent)
	var primary: String={"serve":"Carica salto","receive":"Contatto","set":"Alzata normale","attack":"Carica attacco","block":"Salto"}.get(category,"")
	if TranslationServer.get_locale().begins_with("en"): primary={"serve":"Charge jump serve","receive":"Contact","set":"Normal set","attack":"Charge spike","block":"Jump"}.get(category,"")
	draw_string(font,key+Vector2(0,23),primary,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a7becf"))
	if category in ["serve","set","attack"] and not small:
		draw_string(font,key+Vector2(0,65),preload("res://src/tutorial_lessons.gd").say("QUADRATO / X","SQUARE / X"),HORIZONTAL_ALIGNMENT_LEFT,-1,15,accent)
		var alternate: String={"serve":"Float","set":"Alzata veloce / 7","attack":"Pallonetto"}[category]
		if TranslationServer.get_locale().begins_with("en"): alternate={"serve":"Float","set":"Quick set / wide 7","attack":"Wrist tip"}[category]
		draw_string(font,key+Vector2(0,88),alternate,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a7becf"))
func style(color: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new(); box.bg_color=color; box.set_corner_radius_all(12); return box

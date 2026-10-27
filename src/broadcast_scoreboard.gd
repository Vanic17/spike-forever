extends RefCounted
const Brand=preload("res://src/league_branding.gd")
static func pill(canvas: CanvasItem,rect: Rect2,color: Color,radius: int=36) -> void:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.set_corner_radius_all(radius); style.corner_detail=16
	canvas.draw_style_box(style,rect)
static func label(canvas: CanvasItem,at: Vector2,value: String,px: int,color: Color=Color.WHITE) -> void:
	var font:=Brand.font(); var width:=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	canvas.draw_string(font,at-Vector2(width*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
static func volleyball(canvas: CanvasItem,point: Vector2,radius: float) -> void:
	canvas.draw_circle(point,radius,Color("ffdf57"),true,-1,true)
	for i in 3:
		var angle:=i*TAU/3.0
		var polygon:=PackedVector2Array([point,point+Vector2.from_angle(angle)*radius*.9,point+Vector2.from_angle(angle+.7)*radius,point+Vector2.from_angle(angle+1.1)*radius*.4])
		canvas.draw_colored_polygon(polygon,Color("1b4695"))
	canvas.draw_arc(point,radius,0,TAU,32,Color("e5efff"),1.3,true)
static func draw(canvas: CanvasItem,game,viewport: Vector2) -> void:
	var scale:=clampf(minf(viewport.x/1920.0,viewport.y/1080.0),.5,2.5)
	var origin:=Vector2(30,30)*scale
	canvas.draw_set_transform(origin,0,Vector2.ONE*scale)
	pill(canvas,Rect2(0,8,760,72),Color("101b49"))
	pill(canvas,Rect2(0,4,760,72),Color("143dd0"))
	var a:=Brand.team(game,0); var b:=Brand.team(game,1)
	# Kit-coloured crescents peek around the two set-count ovals.
	pill(canvas,Rect2(204,4,86,72),a.color)
	pill(canvas,Rect2(470,4,86,72),b.color)
	pill(canvas,Rect2(212,4,83,72),Color("7d89f1"))
	pill(canvas,Rect2(465,4,83,72),Color("7d89f1"))
	pill(canvas,Rect2(283,6,194,68),Color("172459"))
	Brand.fit_image(canvas,Brand.logo(a.id,true),Rect2(12,12,56,54))
	Brand.fit_image(canvas,Brand.logo(b.id,true),Rect2(691,12,57,54))
	label(canvas,Vector2(117,57),a.abbreviation,44)
	label(canvas,Vector2(642,57),b.abbreviation,44)
	if game.server==0: volleyball(canvas,Vector2(181,40),11)
	else: volleyball(canvas,Vector2(578,40),11)
	label(canvas,Vector2(251,26),"SETS",14)
	label(canvas,Vector2(509,26),"SETS",14)
	label(canvas,Vector2(251,63),str(game.sets[0]),40)
	label(canvas,Vector2(509,63),str(game.sets[1]),40)
	label(canvas,Vector2(326,59),str(game.scores[0]),46)
	label(canvas,Vector2(434,59),str(game.scores[1]),46)
	Brand.fit_image(canvas,Brand.badge(),Rect2(367,16,27,48))
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	Brand.fit_image(canvas,Brand.badge(),Rect2(Vector2(viewport.x-114*scale,18*scale),Vector2(84,140)*scale))

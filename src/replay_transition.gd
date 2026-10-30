extends Control
var replay
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if replay==null or not replay.active: return
	var progress:=clampf(replay.elapsed/replay.TRANSITION_SECONDS,0,1)
	var settle:=smoothstep(0,.45,progress)
	var zoom:=smoothstep(.68,1.0,progress)
	var height:=lerpf(size.y*.24,size.y*.48,settle)*lerpf(1,20,zoom)
	var center:=Vector2(size.x*.5,lerpf(size.y*1.45,size.y*.5,settle))
	# Reference: tilted crest rises, turns front-on, then zooms through frame.
	var turn:=lerpf(-TAU*.7,0,settle)
	var width: float=height*replay.Brand.badge().get_width()/replay.Brand.badge().get_height()*maxf(.10,absf(cos(turn)))
	draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.12,.065,smoothstep(.88,.99,progress)))
	draw_set_transform(center,lerpf(-.18,0,settle),Vector2.ONE)
	draw_texture_rect(replay.Brand.badge(),Rect2(-Vector2(width,height)*.5,Vector2(width,height)),false)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

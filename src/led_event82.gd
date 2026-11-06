extends Control
const Brand=preload("res://src/league_branding.gd")
var club:=""
var caption:=""
var tint:=Color("17458a")
func _draw():
	draw_rect(Rect2(0,0,2048,256),tint.darkened(.62))
	for x in range(-256,2200,180):draw_line(Vector2(x,256),Vector2(x+200,0),Color(tint,.16),18)
	draw_line(Vector2(0,8),Vector2(2048,8),tint.lightened(.15),8)
	draw_line(Vector2(0,248),Vector2(2048,248),tint.lightened(.15),8)
	Brand.fit_image(self,Brand.logo(club),Rect2(1804,20,216,216))
	var font:=Brand.font();var px:=174
	while font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>1470:px-=2
	var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	draw_set_transform(Vector2(900-width*.5,184),-.025)
	draw_string_outline(font,Vector2.ZERO,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,px,5,tint.lightened(.05))
	var ink:=tint.lightened(.50)
	if tint.s>.15:ink=Color.from_hsv(tint.h,tint.s,.98).lightened(.08)
	draw_string(font,Vector2.ZERO,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,px,ink)

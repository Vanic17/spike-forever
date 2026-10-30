extends RefCounted
const INK=Color("102039")
const WHITE=Color("f0f3f5")
const MUTED=Color("aab7c7")
const GOLD=Color("e7bf62")
const GREEN=Color("5fdaa9")
static func text(canvas: CanvasItem,at: Vector2,value: String,px: int=22,color: Color=WHITE,width: float=-1):
	value=preload("res://src/legend_locale.gd").text(value)
	var font=preload("res://src/league_branding.gd").font()
	if width>0:px=mini(px,int(px*width/maxf(width,font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x)))
	canvas.draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
static func card(canvas: CanvasItem,bounds: Rect2):
	var box=StyleBoxFlat.new();box.bg_color=Color(.035,.065,.115,.94);box.border_color=Color("35506c");box.set_border_width_all(1);box.set_corner_radius_all(12)
	canvas.draw_style_box(box,bounds)
static func draw(canvas: CanvasItem,game,viewport: Vector2,pad: int,ps: bool):
	var state: Dictionary=game.legend_match.hud_state()
	var en=TranslationServer.get_locale().begins_with("en")
	var scale=minf(viewport.x/1920.0,viewport.y/1080.0)
	var offset=(viewport-Vector2(1920,1080)*scale)*.5
	canvas.draw_set_transform(offset,0,Vector2.ONE*scale)
	card(canvas,Rect2(36,860,520,184))
	text(canvas,Vector2(60,891),"BECOME A LEGEND" if en else "DIVENTA UN MITO",19,GOLD)
	text(canvas,Vector2(60,927),str(state.player_name)+"  /  "+str(state.role),30,WHITE,470)
	var p: Dictionary=state.performance
	text(canvas,Vector2(60,960),("PTS %d    DIG %d    AST %d" if en else "PUNTI %d    DIFESE %d    ASSIST %d")%[p.get("points",0),p.get("digs",0),p.get("assists",0)],22,MUTED)
	text(canvas,Vector2(60,993),("ENERGY  %d%%" if en else "ENERGIA  %d%%")%int(state.energy),19,GREEN)
	canvas.draw_rect(Rect2(60,1009,470,10),Color("30445b"))
	canvas.draw_rect(Rect2(60,1009,470*clampf(float(state.energy)/100,0,1),10),GREEN if state.energy>30 else Color("ed866a"))
	card(canvas,Rect2(1250,824,634,220))
	var rows: Array=[]
	if pad<0:
		rows=["WASD Move · Arrows Aim" if en else "WASD Muovi · Frecce Mira","R Jump · Shift Sprint" if en else "R Salta · Shift Sprint","Space Pass / set / attack" if en else "Spazio Bagher / alzata / attacco","Q Float / tip · C Dive" if en else "Q Float / pallonetto · C Tuffo","E Dump / save · F Request set" if en else "E Seconda / recupero · F Chiama alzata","Esc Pause · V Camera" if en else "Esc Pausa · V Telecamera"]
	else:
		rows=["LS Move · RS Aim" if en else "LS Muovi · RS Mira",("R1 Jump · L2 Sprint" if ps else "RB Jump · LT Sprint") if en else ("R1 Salta · L2 Sprint" if ps else "RB Salta · LT Sprint"),("Cross Pass / set / attack" if ps else "A Pass / set / attack") if en else ("Croce Bagher / alzata / attacco" if ps else "A Bagher / alzata / attacco"),("Square Float / tip · R2 Dive" if ps else "X Float / tip · RT Dive") if en else ("Quadrato Float / pallonetto · R2 Tuffo" if ps else "X Float / pallonetto · RT Tuffo"),("Circle Save / dump · L1 Request" if ps else "B Save / dump · LB Request") if en else ("Cerchio Recupero / seconda · L1 Chiama" if ps else "B Recupero / seconda · LB Chiama"),("Options Pause · Triangle Camera" if ps else "Menu Pause · Y Camera") if en else ("Options Pausa · Triangolo Telecamera" if ps else "Menu Pausa · Y Telecamera")]
	for i in rows.size():text(canvas,Vector2(1274,857+i*31),rows[i],21,WHITE if i==0 else MUTED,582)
	card(canvas,Rect2(594,936,612,108))
	var available: bool=bool(state.get("manual_available",true))
	var context: String=str(state.context)
	if not available:context="ON THE BENCH" if en else "IN PANCHINA · ATTENDI IL RIENTRO"
	text(canvas,Vector2(620,972),context,26,GOLD,560)
	if state.charging:
		canvas.draw_rect(Rect2(620,989,492,22),Color("30445b"))
		canvas.draw_rect(Rect2(620,989,492*clampf(float(state.power),0,1),22),GREEN)
		if float(state.power)>1:canvas.draw_rect(Rect2(1112,989,68*minf(1,(float(state.power)-1)/.35),22),Color("ec775f"))
		text(canvas,Vector2(620,1032),("RELEASE TO HIT · %d%%" if en else "RILASCIA PER COLPIRE · %d%%")%int(float(state.power)*100),19,MUTED)
	else:text(canvas,Vector2(620,1009),"YOU CONTROL POSITION, JUMP AND CONTACT" if en else "POSIZIONE, SALTO E CONTATTO DIPENDONO DA TE",19,MUTED,560)
	if float(state.feedback_left)>0 and not str(state.feedback).is_empty():
		card(canvas,Rect2(820,30,830,74))
		text(canvas,Vector2(846,76),str(state.feedback),29,WHITE,778)
	if not str(state.suggestion).is_empty():
		card(canvas,Rect2(594,874,612,48));text(canvas,Vector2(614,906),str(state.suggestion),21,GREEN,570)
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

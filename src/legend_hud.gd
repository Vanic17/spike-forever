extends RefCounted
## Athlete information only. Scoreboard, timing bars and timing feedback keep
## following hud.gd's standard exhibition rendering path.
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
	var box=StyleBoxFlat.new();box.bg_color=Color(.035,.065,.115,.88);box.border_color=Color("35506c");box.set_border_width_all(1);box.set_corner_radius_all(12)
	canvas.draw_style_box(box,bounds)
static func draw(canvas: CanvasItem,game,viewport: Vector2,pad: int,ps: bool):
	if game.paused or (game.replay!=null and game.replay.active): return
	var state: Dictionary=game.legend_match.hud_state()
	var en=TranslationServer.get_locale().begins_with("en")
	var scale=minf(viewport.x/1920.0,viewport.y/1080.0)
	var offset=(viewport-Vector2(1920,1080)*scale)*.5
	canvas.draw_set_transform(offset,0,Vector2.ONE*scale)
	card(canvas,Rect2(36,864,410,180))
	text(canvas,Vector2(58,892),"BECOME A LEGEND" if en else "DIVENTA UN MITO",18,GOLD)
	text(canvas,Vector2(58,924),str(state.get("player_name",""))+" / "+str(state.get("role","")),27,WHITE,366)
	var p: Dictionary=state.get("performance",{})
	var points:=int(p.get("kills",0))+int(p.get("aces",0))+int(p.get("blocks",0))
	text(canvas,Vector2(58,952),("PTS %d   DIG %d   AST %d" if en else "PUNTI %d   DIFESE %d   ASSIST %d")%[points,p.get("digs",0),p.get("assists",0)],20,MUTED,366)
	var energy:=clampf(float(state.get("energy",100)),0,100)
	text(canvas,Vector2(58,978),("ENERGY %d%%" if en else "ENERGIA %d%%")%int(energy),17,GREEN)
	canvas.draw_rect(Rect2(58,990,366,7),Color("30445b"))
	canvas.draw_rect(Rect2(58,990,366*energy/100,7),GREEN if energy>30 else Color("ed866a"))
	var available:=bool(state.get("manual_available",true))
	text(canvas,Vector2(58,1025),("Circle: AI position" if en else "Cerchietto: posizione IA") if available else ("ON THE BENCH" if en else "IN PANCHINA"),17,MUTED,366)
	card(canvas,Rect2(1410,822,474,222))
	var rows: Array=[]
	if pad<0:
		rows=["WASD Move · Arrows Aim" if en else "WASD Muovi · Frecce Mira","R Jump · Shift Sprint" if en else "R Salta · Shift Scatto","Space Pass / set / attack" if en else "Spazio Bagher / alzata / attacco","Q Float / quick set / tip" if en else "Q Float / veloce / pallonetto","C Dive · F Call · E Dump" if en else "C Tuffo · F Chiama · E Seconda","Esc Pause · V Camera" if en else "Esc Pausa · V Telecamera"]
	else:
		rows=["LS Move · RS Aim" if en else "LS Muovi · RS Mira",("R1 Jump · L2 Sprint" if ps else "RB Jump · LT Sprint") if en else ("R1 Salta · L2 Scatto" if ps else "RB Salta · LT Scatto"),("Cross Pass / set / attack" if ps else "A Pass / set / attack") if en else ("Croce Bagher / alzata / attacco" if ps else "A Bagher / alzata / attacco"),("Square Float / quick set / tip" if ps else "X Float / quick set / tip") if en else ("Quadrato Float / veloce / pallonetto" if ps else "X Float / veloce / pallonetto"),("R2 Dive · L1 Call · Circle Dump" if ps else "RT Dive · LB Call · B Dump") if en else ("R2 Tuffo · L1 Chiama · Cerchio Seconda" if ps else "RT Tuffo · LB Chiama · B Seconda"),("Options Pause · Triangle Camera" if ps else "Menu Pause · Y Camera") if en else ("Options Pausa · Triangolo Telecamera" if ps else "Menu Pausa · Y Telecamera")]
	for i in rows.size():text(canvas,Vector2(1432,855+i*31),rows[i],20,WHITE if i==0 else MUTED,430)
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

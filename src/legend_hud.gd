extends RefCounted
## Career information and read-only contact guidance. Exhibition power and
## timing results keep following hud.gd's shared rendering path.
const WHITE=Color("f0f3f5")
const MUTED=Color("aab7c7")
const GOLD=Color("e7bf62")
const GREEN=Color("5fdaa9")
const RED=Color("ed866a")
static func text(canvas: CanvasItem,at: Vector2,value: String,px: int=22,color: Color=WHITE,width: float=-1):
	value=preload("res://src/legend_locale.gd").text(value)
	var font=preload("res://src/league_branding.gd").font()
	if width>0:px=mini(px,int(px*width/maxf(width,font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x)))
	canvas.draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
static func card(canvas: CanvasItem,bounds: Rect2):
	var box=StyleBoxFlat.new();box.bg_color=Color(.035,.065,.115,.88);box.border_color=Color("35506c");box.set_border_width_all(1);box.set_corner_radius_all(12)
	canvas.draw_style_box(box,bounds)
static func controls(pad: int,ps: bool,en: bool) -> Array:
	if pad<0:
		return ["WASD Move / Arrows Aim" if en else "WASD Muovi / Frecce Mira","R Jump / Shift Sprint" if en else "R Salta / Shift Scatto","Space Bagher / set / attack" if en else "Spazio Bagher / alzata / attacco","Q Overhead / quick / float / tip" if en else "Q Palleggio / veloce / float / pallonetto","C Dive / F Call / E Dump" if en else "C Tuffo / F Chiama / E Seconda","Esc Pause / V Camera" if en else "Esc Pausa / V Telecamera"]
	return ["LS Move / RS Aim" if en else "LS Muovi / RS Mira",("R1 Jump / L2 Sprint" if ps else "RB Jump / LT Sprint") if en else ("R1 Salta / L2 Scatto" if ps else "RB Salta / LT Scatto"),("Cross Bagher / set / attack" if ps else "A Bagher / set / attack") if en else ("Croce Bagher / alzata / attacco" if ps else "A Bagher / alzata / attacco"),("Square Overhead / quick / float / tip" if ps else "X Overhead / quick / float / tip") if en else ("Quadrato Palleggio / veloce / float / pallonetto" if ps else "X Palleggio / veloce / float / pallonetto"),("R2 Dive / L1 Call / Circle Dump" if ps else "RT Dive / LB Call / B Dump") if en else ("R2 Tuffo / L1 Chiama / Cerchio Seconda" if ps else "RT Tuffo / LB Chiama / B Seconda"),("Options Pause / Triangle Camera" if ps else "Menu Pause / Y Camera") if en else ("Options Pausa / Triangolo Telecamera" if ps else "Menu Pausa / Y Telecamera")]
static func contact_button(action: String,pad: int,ps: bool,en: bool) -> String:
	if action=="dive": return "C" if pad<0 else ("R2" if ps else "RT")
	if action in ["overhead","quick"]: return "Q" if pad<0 else (("Square" if en else "Quadrato") if ps else "X")
	return ("Space" if en else "Spazio") if pad<0 else (("Cross" if en else "Croce") if ps else "A")
static func contact_label(action: String,en: bool) -> String:
	match action:
		"overhead": return "OVERHEAD / ABOVE THE HEAD" if en else "PALLEGGIO / SOPRA LA TESTA"
		"quick": return "QUICK SET / ABOVE THE HEAD" if en else "ALZATA VELOCE / SOPRA LA TESTA"
		"dive": return "DIVE / LOW DEFENCE" if en else "TUFFO / DIFESA BASSA"
		"set": return "SET / ABOVE THE HEAD" if en else "ALZATA / SOPRA LA TESTA"
		"receive": return "BAGHER / FOREARMS" if en else "BAGHER / AVAMBRACCI"
		"jump": return "JUMP" if en else "SALTO"
		"attack": return "ATTACK" if en else "ATTACCO"
		"dump": return "SECOND-TOUCH ATTACK" if en else "ATTACCO DI SECONDA"
		"request": return "CALL FOR THE BALL" if en else "CHIAMA LA PALLA"
	return "COMMAND" if en else "COMANDO"
static func draw_contact_cue(canvas: CanvasItem,cue: Dictionary,pad: int,ps: bool,en: bool):
	if not bool(cue.get("visible",false)): return
	var action:=str(cue.get("action","receive"))
	var status:=str(cue.get("status","move"))
	var result:=float(cue.get("feedback_left",0))>0
	var color:=GREEN if status in ["ready","armed","good"] else (RED if status in ["late","miss","unavailable"] else GOLD)
	card(canvas,Rect2(660,810,600,140))
	canvas.draw_rect(Rect2(660,826,4,108),color)
	text(canvas,Vector2(684,838),contact_label(action,en),20,MUTED,552)
	if result:
		var label: String={"early":"IN ANTICIPO","good":"BUON TEMPO","late":"IN RITARDO","miss":"NESSUN CONTATTO","unavailable":"AZIONE NON DISPONIBILE","armed":"TOCCO PREPARATO","ready":"RICHIESTA MEMORIZZATA"}.get(status,"TOCCO CONFERMATO")
		var detail:=str(cue.get("feedback",""))
		text(canvas,Vector2(684,878),label,31,color,552)
		if not detail.is_empty(): text(canvas,Vector2(684,920),detail,23,WHITE,552)
		elif status not in ["miss","unavailable"]: text(canvas,Vector2(684,920),("QUALITY %d%%" if en else "QUALITÀ %d%%")%roundi(clampf(float(cue.get("quality",0)),0,1)*100),23,WHITE,552)
		return
	var button:=contact_button(action,pad,ps,en)
	var instruction: String={"move":"AVVICINATI ALLA PALLA","ready":"PREMI ORA","good":"PREMI ORA","armed":"TOCCO PREPARATO","early":"ATTENDI LA PALLA","late":"PREMI ORA"}.get(status,"SEGUI LA PALLA")
	var command: String=preload("res://src/legend_locale.gd").text(instruction)
	if status!="move": command=button+" / "+command
	text(canvas,Vector2(684,878),command,30,color,552)
	var seconds:=maxf(0,float(cue.get("seconds",0)))
	var detail: String=("PREMI UNA VOLTA / NON TENERE PREMUTO" if status!="armed" else "RESTA VICINO AL PUNTO DI CONTATTO")
	if status=="move": detail=("WASD" if pad<0 else "LS")+" / "+("MOVE TO THE CONTACT POINT" if en else "RAGGIUNGI IL PUNTO DI CONTATTO")
	text(canvas,Vector2(684,912),detail,20,WHITE,438)
	text(canvas,Vector2(1144,912),"%.2f s"%seconds,22,color,92)
	# Guidance only: drawing never arms, moves or modifies a contact.
	canvas.draw_rect(Rect2(684,927,552,6),Color("30445b"))
	canvas.draw_rect(Rect2(684,927,552*(1-clampf(seconds/1.2,0,1)),6),color)
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
	text(canvas,Vector2(58,1025),("Ground marker: AI position" if en else "Cerchietto a terra: posizione IA") if available else ("ON THE BENCH" if en else "IN PANCHINA"),17,MUTED,366)
	card(canvas,Rect2(1410,822,474,222))
	var rows:=controls(pad,ps,en)
	for i in rows.size():text(canvas,Vector2(1432,855+i*31),rows[i],20,WHITE if i==0 else MUTED,430)
	if game.legend_match.has_method("contact_cue"): draw_contact_cue(canvas,game.legend_match.contact_cue(),pad,ps,en)
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

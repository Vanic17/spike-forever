extends Control
## Contextual commands and one-way charge bars. No oscillating timing widget.
var game: Node
var font := ThemeDB.fallback_font
const INK := Color(0.035, 0.055, 0.085, 0.90)
const WHITE := Color("f0f3f5")
const MUTED := Color("aab7c7")
const GOLD := Color("e9d5a7")
const GREEN := Color("54cf8e")
const RED := Color("ef795d")
var primary := "SPAZIO"
var alternate := "Q"
var dump_button := "E"
var wall_labels := "Z sinistra / B destra"

func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_dt: float) -> void: queue_redraw()

func text(at: Vector2, value: String, px: int = 16, color: Color = WHITE,translate_value: bool=true) -> void:
	draw_string(font, at, tr(value) if translate_value else value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func centered(y: float, value: String, px: int = 18, color: Color = WHITE) -> void:
	value=tr(value)
	text(Vector2((size.x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x) * 0.5, y), value, px, color)

func panel(rect: Rect2, color: Color = INK) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	draw_style_box(style, rect)

func point_result_visible() -> bool:
	return false

func _draw() -> void:
	if game==null or not game.started: return
	var w:=size.x; var h:=size.y
	var pad: int = game.pad()
	var pad_name := Input.get_joy_name(pad) if pad >= 0 else "Tastiera"
	var name_lower := pad_name.to_lower()
	var ps := "dualsense" in name_lower or "dualshock" in name_lower or "ps" in name_lower or "sony" in name_lower or "playstation" in name_lower or ("wireless controller" in name_lower and not "xbox" in name_lower)
	primary = "X / CROCE" if ps else ("A" if pad >= 0 else "SPAZIO")
	alternate = "QUADRATO" if ps else ("X" if pad >= 0 else "Q")
	dump_button = "CERCHIO" if ps else ("B" if pad >= 0 else "E")
	wall_labels="L2 sinistra / R2 destra" if ps else ("LT sinistra / RT destra" if pad>=0 else "Z sinistra / B destra")
	if game.camera_mode==2: wall_labels=wall_labels.replace("sinistra","alto").replace("destra","basso")
	if game.tutorial!=null and game.tutorial.active:
		if not game.paused and game.phase in ["SERVE","RECEIVE","SET","ATTACK","CPU_ATTACK"]: draw_contact(w*.5,h-92)
		return
	preload("res://src/broadcast_scoreboard.gd").draw(self,game,size)
	if game.legend_match!=null and game.legend_match.active:
		preload("res://src/legend_hud.gd").draw(self,game,size,pad,ps)
		return
	if game.replay!=null and game.replay.active: return
	draw_timing_result()
	var phase: String=game.display_phase()
	if (phase=="SERVE" and game.server==game.local_team()) or phase=="ATTACK": draw_power_bar()

func draw_timing_result() -> void:
	var result: Dictionary=game.timing_results[game.local_team()]
	if result.is_empty() or game.clock_time>float(result.until): return
	var scale:=clampf(minf(size.x/1920.0,size.y/1080.0),.5,2.5)
	var bounds:=Rect2(Vector2(size.x*.5-300*scale,145*scale),Vector2(600,58)*scale)
	panel(bounds,Color("102039"))
	var value: String=tr(result.get("kind",""))+" · "+tr(result.get("detail",""))+" · %.1f%%"%(float(result.quality)*100)
	var font_size:=int(26*scale)
	font_size=int(font_size*minf(1,(bounds.size.x-32*scale)/maxf(1,font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)))
	var color:=RED if float(result.quality)>1 else (GREEN if float(result.quality)>=.95 else GOLD)
	var width:=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	text(Vector2(bounds.get_center().x-width*.5,bounds.position.y+38*scale),value,font_size,color,false)

func draw_power_bar() -> void:
	var scale:=clampf(minf(size.x/1920.0,size.y/1080.0),.5,2.5)
	var origin:=Vector2(size.x*.5,size.y-92*scale)
	draw_set_transform(origin,0,Vector2.ONE*scale)
	var serve: bool=game.display_phase()=="SERVE"
	var power: float=game.current_charge()
	panel(Rect2(-282,-22,564,78),Color("102039"))
	text(Vector2(-258,2),"BATTUTA" if serve else ("PALLONETTO" if game.attack_tip else "ATTACCO"),20,GOLD)
	text(Vector2(174,2),("%.2f%%" if game.use_player_stats else "%.0f%%")%(power*100),22,RED if power>1 else GREEN)
	draw_rect(Rect2(-258,18,516,16),Color("43536c"))
	draw_rect(Rect2(-258,18,416*clampf(power,0,1),16),GREEN)
	var low: float=game.PlayerStats.green_low(game,serve) if game.use_player_stats else (.995 if serve else .97)
	draw_rect(Rect2(-258+416*low,15,416*(1-low),22),GOLD,false,2)
	draw_line(Vector2(158,13),Vector2(158,38),WHITE,2)
	if power>1: draw_rect(Rect2(158,18,minf(1,(power-1)/.4)*100,16),RED)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func draw_contact(cx: float, y: float) -> void:
	var serve: bool = game.display_phase() == "SERVE"
	var attack: bool = game.display_phase() == "ATTACK"
	panel(Rect2(cx - 248, y - 28, 496, 106))
	var label: String = {"SERVE":"BATTUTA", "RECEIVE":"RICEZIONE", "SET":"ALZATA", "ATTACK":"SCHIACCIATA", "CPU_ATTACK":"MURO"}.get(game.display_phase(), "")
	if game.ui_wall(): label="MURO"
	if attack and game.hitter_action=="receive": label = "TERZO TOCCO DI RECUPERO"
	text(Vector2(cx - 229, y - 5), label, 14, GOLD)
	if serve or attack:
		var power: float = game.current_charge()
		var fill: float = clampf(power, 0, 1)
		text(Vector2(cx + 137, y - 5), ("%.2f%%" % (power*100)) if game.use_player_stats else ("%d%%" % roundi(power * 100)), 17, RED if power > 1 else GREEN)
		draw_rect(Rect2(cx - 228, y + 9, 456, 14), Color("425063"))
		draw_rect(Rect2(cx - 228, y + 9, 364 * fill, 14), GREEN)
		draw_line(Vector2(cx + 136, y + 5), Vector2(cx + 136, y + 27), WHITE, 2)
		var low: float=game.PlayerStats.green_low(game,serve) if game.use_player_stats else (0.995 if serve else 0.97)
		draw_rect(Rect2(cx-228+364*low,y+6,364*(1.0-low),20),GOLD,false,2)
		if power > 1:
			draw_rect(Rect2(cx + 136, y + 9, minf(1, (power - 1) / 0.4) * 92, 14), RED)
		if game.use_player_stats:
			text(Vector2(cx-229,y+44),primary+" / "+alternate+" · tieni e rilascia · LS: mira",13)
			text(Vector2(cx-229,y+64),("Battuta" if serve else "Alzata "+game.PlayerStats.GRADE_NAMES[game.stats_set_grade])+" · verde %.2f–100%% · nessun punto automatico"%(low*100),11,GOLD)
		elif serve:
			var hint := primary + " · salto   " + alternate + " · float"
			if game.charging or game.toss_active: hint = ("JUMP FLOAT" if game.serve_type == 0 else "JUMP POWER") + " · tieni e rilascia · LS: mira"
			else: hint="LS: sposta il battitore · tieni X/A o Quadrato/X: carica e mira"
			text(Vector2(cx - 229, y + 44), hint, 13)
			text(Vector2(cx - 229, y + 64), "Rischio errore %d%%" % roundi(game.Timing.serve_risk(power) * 100) if power > 1 else ("100% · ACE" if game.Timing.ace_power(power) else "LS: mira · ace garantito solo al 100%"), 11, RED if power > 1 else GOLD if game.Timing.ace_power(power) else MUTED)
		else:
			text(Vector2(cx - 229, y + 44), primary + " attacco / " + alternate + " pallonetto · tieni e rilascia", 13)
			text(Vector2(cx - 229, y + 64), "Rischio errore %d%%"%roundi(game.Timing.attack_risk(power,game.attack_tip)*100) if power > 1 else ("97–100% · COLPO VINCENTE" if game.Timing.winning_power(power) else "Precisione %d%% · fascia oro 97–100%% vincente" % roundi(game.Timing.precision(power) * 100)), 11, RED if power > 1 else GOLD if game.Timing.winning_power(power) else MUTED)
	elif game.display_phase() == "RECEIVE":
		text(Vector2(cx - 229, y + 24), primary + " · premi quando arriva la palla", 15)
		text(Vector2(cx - 229, y + 53), ("CONFERMATA · %d%%" % roundi(game.input_quality * 100)) if game.armed else "Mira automatica in zona 3 · piccolo margine per il recupero tardivo", 12, GREEN if game.armed else MUTED)
	elif game.display_phase() == "SET":
		var target: String = ["ZONA 4", "CENTRO", "ZONA 2", "PIPE"][game.planned_direction]
		text(Vector2(cx - 229, y + 21), primary + " primo tempo   " + alternate + " 7   " + dump_button + " seconda" if game.planned_direction==1 else primary + " normale   " + alternate + " veloce   " + dump_button + " seconda", 13)
		text(Vector2(cx - 229, y + 48), "LS · " + target + ("  " + game.players[game.planned_hitter].role_label() if game.planned_hitter >= 0 else ""), 13, GREEN if game.armed else WHITE)
		text(Vector2(cx - 229, y + 66), "Qualità ricezione %d%%" % roundi(game.pass_quality * 100), 11, MUTED)
	else:
		if game.display_phase()=="CPU_ATTACK" and game.hitter_action=="receive":
			text(Vector2(cx - 229, y + 24), "PALLA ALTA · prepara la difesa", 15)
			text(Vector2(cx - 229, y + 53), primary + " · ricezione all'arrivo", 13, MUTED)
			return
		var count: int=game.block_count if game.network_match() else game.blocking_players(0).size()
		text(Vector2(cx - 229, y + 21), "LS · centrale / muro a %d" % count, 15)
		text(Vector2(cx - 229, y + 40), wall_labels, 12, MUTED)
		text(Vector2(cx - 229, y + 53), primary + " · salta" + ("   /   SALTO ESEGUITO" if game.block_commanded else ""), 13, MUTED)

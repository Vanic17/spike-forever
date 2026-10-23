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

func text(at: Vector2, value: String, px: int = 16, color: Color = WHITE) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func centered(y: float, value: String, px: int = 18, color: Color = WHITE) -> void:
	text(Vector2((size.x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x) * 0.5, y), value, px, color)

func panel(rect: Rect2, color: Color = INK) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	draw_style_box(style, rect)

func _draw() -> void:
	if game == null: return
	if game.started and game.receive_feedback_left>0:
		centered(size.y-215,game.receive_feedback,15,GOLD)
	var w := size.x
	var h := size.y
	var pad: int = game.pad()
	var pad_name := Input.get_joy_name(pad) if pad >= 0 else "Tastiera"
	var name_lower := pad_name.to_lower()
	var ps := "dualsense" in name_lower or "dualshock" in name_lower or "ps" in name_lower or "sony" in name_lower or "playstation" in name_lower or ("wireless controller" in name_lower and not "xbox" in name_lower)
	primary = "X / CROCE" if ps else ("A" if pad >= 0 else "SPAZIO")
	alternate = "QUADRATO" if ps else ("X" if pad >= 0 else "Q")
	dump_button = "CERCHIO" if ps else ("B" if pad >= 0 else "E")
	wall_labels="L2 sinistra / R2 destra" if ps else ("LT sinistra / RT destra" if pad>=0 else "Z sinistra / B destra")
	if game.camera_mode==2: wall_labels=wall_labels.replace("sinistra","alto").replace("destra","basso")
	if not game.started:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015,0.025,0.045,0.45))
		text(Vector2(75, h * 0.38), "SPIKE", 76)
		text(Vector2(75, h * 0.38 + 74), "FOREVER", 76, GOLD)
		text(Vector2(81, h * 0.38 + 111), "IL TUO GIOCO. IL TUO CAMPO.", 15, MUTED)
		text(Vector2(81, h * 0.38 + 155), "6 CONTRO 6  /  INDOOR VOLLEYBALL", 17)
		panel(Rect2(75, h - 183, 560, 120))
		text(Vector2(96, h - 145), "OPTIONS / START / INVIO PER GIOCARE", 21, GOLD)
		text(Vector2(96, h - 113), primary + " · azione   /   " + alternate + " · float / veloce", 14)
		text(Vector2(96, h - 88), "LS · mira e direzioni   F1 · tutti i comandi", 13, MUTED)
		return
	panel(Rect2(30, 27, 263, 85))
	draw_rect(Rect2(30, 27, 5, 42), Color("285a9c"))
	draw_rect(Rect2(30, 70, 5, 42), Color("e7e6e0"))
	text(Vector2(48, 56), game.team_names[0].left(18), 13)
	text(Vector2(48, 98), game.team_names[1].left(18), 13)
	text(Vector2(192, 58), "%02d" % game.scores[0], 25)
	text(Vector2(192, 100), "%02d" % game.scores[1], 25)
	draw_rect(Rect2(244, 27, 49, 85), Color("26364a"))
	text(Vector2(262, 56), str(game.sets[0]), 18, MUTED)
	text(Vector2(262, 98), str(game.sets[1]), 18, MUTED)
	draw_line(Vector2(35, 69), Vector2(293,69), Color("344154"), 1)
	text(Vector2(31, 133), "SET %d  /  BEST OF %d" % [game.sets[0] + game.sets[1] + 1,game.match_best_of], 11, MUTED)
	text(Vector2(w - 219, 43), "SPIKE / FOREVER", 20)
	text(Vector2(w - 218, 65), "CPU vs CPU" if game.demo else "6 vs 6  /  LIVE", 12, MUTED)
	if game.gallery:
		panel(Rect2(30, h - 109, w - 60, 77))
		var name: String = game.clips.keys()[game.gallery_index]
		text(Vector2(50, h - 77), "ANIMAZIONI / " + name.to_upper(), 20, GOLD)
		text(Vector2(50, h - 50), game.clips[name].source.get_file() + "    Frecce: cambia    F3: torna in campo", 13, MUTED)
		return
	if game.feedback_left > 0 and game.phase != "POINT":
		centered(105, game.feedback, 19, GOLD)
	if game.phase == "POINT":
		panel(Rect2(w * 0.5 - 218, h * 0.46 - 41, 436, 84))
		var point_px:=clampi(int(29*414/maxf(414,font.get_string_size(game.feedback,HORIZONTAL_ALIGNMENT_LEFT,-1,29).x)),14,29)
		centered(h * 0.46 - 3, game.feedback, point_px)
		centered(h * 0.46 + 25, game.point_reason, 14, MUTED)
	elif game.phase in ["RECEIVE", "SET", "ATTACK", "CPU_ATTACK"] or game.human_wall() or game.phase == "SERVE" and game.server == 0:
		draw_contact(w * 0.5, h - 92)
	text(Vector2(31, h - 22), "LS / WASD / Frecce · mira e direzioni", 12, MUTED)
	text(Vector2(w - 420, h - 22), "F1 aiuto   F2 demo   C / Triangolo / Y camera   Esc pausa", 12, MUTED)
	if game.camera_mode==2:
		text(Vector2(w-420,h-42),"TV: su Z4 / destra centro / giu Z2 / sinistra pipe",12,GOLD)
	if game.debug_visible:
		panel(Rect2(30, 157, 435, 269))
		var lines := [
			primary + " · ricezione / alzata / attacco / muro",
			alternate + " · float / veloce / pallonetto",
			dump_button + " · colpo di seconda",
			"Battuta / attacco: tieni e rilascia",
			"LS / WASD / frecce: mira e direzioni",
			"Muro: LS muove il centrale; "+wall_labels,
			"Ricezione: premi vicino all'arrivo della palla",
			"F3 animazioni   F5 difficoltà   R nuova partita",
			"L3 / LS / M · attiva o disattiva tutto l'audio"]
		for i in lines.size(): text(Vector2(45, 184 + i * 27), lines[i], 13, MUTED)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01,0.02,0.04,0.62))
		centered(h * 0.48, "PAUSA", 47)
		centered(h * 0.48 + 40, "Options / Start / Esc per riprendere", 17, MUTED)

func draw_contact(cx: float, y: float) -> void:
	var serve: bool = game.phase == "SERVE"
	var attack: bool = game.phase == "ATTACK"
	panel(Rect2(cx - 248, y - 28, 496, 106))
	var label: String = {"SERVE":"BATTUTA", "RECEIVE":"RICEZIONE", "SET":"ALZATA", "ATTACK":"SCHIACCIATA", "CPU_ATTACK":"MURO"}.get(game.phase, "")
	if game.human_wall(): label="MURO"
	if attack and game.hitter_action=="receive": label = "TERZO TOCCO DI RECUPERO"
	text(Vector2(cx - 229, y - 5), label, 14, GOLD)
	if serve or attack:
		var power: float = game.current_charge()
		var fill: float = clampf(power, 0, 1)
		text(Vector2(cx + 137, y - 5), "%d%%" % roundi(power * 100), 17, RED if power > 1 else GREEN)
		draw_rect(Rect2(cx - 228, y + 9, 456, 14), Color("425063"))
		draw_rect(Rect2(cx - 228, y + 9, 364 * fill, 14), GREEN)
		draw_line(Vector2(cx + 136, y + 5), Vector2(cx + 136, y + 27), WHITE, 2)
		draw_rect(Rect2(cx-228+364*0.97,y+6,364*0.03,20),GOLD,false,2)
		if power > 1:
			draw_rect(Rect2(cx + 136, y + 9, minf(1, (power - 1) / 0.4) * 92, 14), RED)
		if serve:
			var hint := primary + " · salto   " + alternate + " · float"
			if game.charging or game.toss_active: hint = ("JUMP FLOAT" if game.serve_type == 0 else "JUMP POWER") + " · tieni e rilascia"
			text(Vector2(cx - 229, y + 44), hint, 13)
			text(Vector2(cx - 229, y + 64), "Rischio errore %d%%" % roundi(game.Timing.serve_risk(power) * 100) if power > 1 else ("97–100% · COLPO VINCENTE" if game.Timing.winning_power(power) else "LS: mira · fascia oro 97–100% vincente"), 11, RED if power > 1 else GOLD if game.Timing.winning_power(power) else MUTED)
		else:
			text(Vector2(cx - 229, y + 44), primary + " attacco / " + alternate + " pallonetto · tieni e rilascia", 13)
			text(Vector2(cx - 229, y + 64), "Rischio errore %d%%"%roundi(game.Timing.attack_risk(power,game.attack_tip)*100) if power > 1 else ("97–100% · COLPO VINCENTE" if game.Timing.winning_power(power) else "Precisione %d%% · fascia oro 97–100%% vincente" % roundi(game.Timing.precision(power) * 100)), 11, RED if power > 1 else GOLD if game.Timing.winning_power(power) else MUTED)
	elif game.phase == "RECEIVE":
		text(Vector2(cx - 229, y + 24), primary + " · premi quando arriva la palla", 15)
		text(Vector2(cx - 229, y + 53), ("CONFERMATA · %d%%" % roundi(game.input_quality * 100)) if game.armed else "Mira automatica in zona 3 · piccolo margine per il recupero tardivo", 12, GREEN if game.armed else MUTED)
	elif game.phase == "SET":
		var target: String = ["ZONA 4", "CENTRO", "ZONA 2", "PIPE"][game.planned_direction]
		text(Vector2(cx - 229, y + 21), primary + " normale   " + alternate + " veloce   " + dump_button + " seconda", 13)
		text(Vector2(cx - 229, y + 48), "LS · " + target + ("  " + game.players[game.planned_hitter].role_label() if game.planned_hitter >= 0 else ""), 13, GREEN if game.armed else WHITE)
		text(Vector2(cx - 229, y + 66), "Qualità ricezione %d%%" % roundi(game.pass_quality * 100), 11, MUTED)
	else:
		if game.phase=="CPU_ATTACK" and game.hitter_action=="receive":
			text(Vector2(cx - 229, y + 24), "PALLA ALTA · prepara la difesa", 15)
			text(Vector2(cx - 229, y + 53), primary + " · ricezione all'arrivo", 13, MUTED)
			return
		var count: int=game.blocking_players(0).size()
		text(Vector2(cx - 229, y + 21), "LS · centrale / muro a %d" % count, 15)
		text(Vector2(cx - 229, y + 40), wall_labels, 12, MUTED)
		text(Vector2(cx - 229, y + 53), primary + " · salta" + ("   /   SALTO ESEGUITO" if game.block_commanded else ""), 13, MUTED)

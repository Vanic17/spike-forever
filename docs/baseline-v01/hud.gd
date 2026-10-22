extends Control
var game: Node
var font := ThemeDB.fallback_font
const WHITE := Color("e6eff4")
const MUTED := Color("91aaba")
const CYAN := Color("34d5df")
const ORANGE := Color("ff825e")
const BG := Color("0c1929")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	queue_redraw()

func text(at: Vector2, value: String, size_px: int = 18, color: Color = WHITE) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func panel(rect: Rect2, color: Color = BG) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	draw_style_box(style, rect)

func center(y: float, value: String, size_px: int = 18, color: Color = WHITE) -> void:
	text(Vector2((size.x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x) * 0.5, y), value, size_px, color)

func _draw() -> void:
	if game == null: return
	var w := size.x
	var h := size.y
	text(Vector2(32, 39), "SPIKE / FOREVER", 24, WHITE)
	text(Vector2(33, 60), "INDOOR VOLLEYBALL   /   6 vs 6", 11, MUTED)
	panel(Rect2(w * 0.5 - 234, 21, 468, 73))
	draw_rect(Rect2(w * 0.5 - 234, 35, 4, 44), CYAN)
	draw_rect(Rect2(w * 0.5 + 230, 35, 4, 44), ORANGE)
	text(Vector2(w * 0.5 - 214, 47), "AURORA", 15, CYAN)
	text(Vector2(w * 0.5 + 138, 47), "EMBER", 15, ORANGE)
	text(Vector2(w * 0.5 - 93, 72), "%02d    :    %02d" % [game.scores[0], game.scores[1]], 36)
	text(Vector2(w * 0.5 - 213, 76), "SET %d" % game.sets[0], 12, MUTED)
	text(Vector2(w * 0.5 + 154, 76), "SET %d" % game.sets[1], 12, MUTED)
	var pad: int = game.pad()
	var controller := Input.get_joy_name(pad) if pad >= 0 else "TASTIERA"
	if controller.length() > 27: controller = controller.substr(0, 27)
	text(Vector2(w - 285, 36), controller, 13, MUTED)
	text(Vector2(w - 285, 58), ["ASSISTITO", "STANDARD", "ESPERTO"][game.difficulty] + "  /  F5", 12, MUTED)
	if game.demo:
		text(Vector2(w - 285, 80), "DEMO CPU vs CPU · F2", 13, CYAN)
	if not game.started:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.07, 0.72))
		panel(Rect2(w * 0.5 - 335, h * 0.5 - 238, 670, 480))
		center(h * 0.5 - 170, "IL CAMPO È TUO.", 42)
		center(h * 0.5 - 136, "Una prima versione 3D di Spike Forever", 16, MUTED)
		var x := w * 0.5 - 270
		text(Vector2(x, h * 0.5 - 87), "X / QUADRATO", 19, CYAN)
		text(Vector2(x + 205, h * 0.5 - 87), "Ricevi, alza e salta a muro", 17)
		text(Vector2(x, h * 0.5 - 44), "TIENI E RILASCIA", 17, CYAN)
		text(Vector2(x + 205, h * 0.5 - 44), "Carica servizio e schiacciata", 17)
		text(Vector2(x, h * 0.5 - 1), "STICK DESTRO", 17, CYAN)
		text(Vector2(x + 205, h * 0.5 - 1), "Mira, alzata e lettura del muro", 17)
		text(Vector2(x, h * 0.5 + 42), "LB / L1", 17, CYAN)
		text(Vector2(x + 205, h * 0.5 + 42), "Alzata veloce", 17)
		center(h * 0.5 + 95, "Tastiera: WASD · Frecce · Spazio · Q · Tab", 15, MUTED)
		center(h * 0.5 + 147, "INVIO / START PER GIOCARE", 23, CYAN)
		center(h * 0.5 + 184, "F2 demo   ·   F3 animazioni estratte   ·   C telecamera", 14, MUTED)
		return
	if game.gallery:
		panel(Rect2(28, h - 147, w - 56, 118))
		text(Vector2(48, h - 116), "ARCHIVIO ANIMAZIONI / SPIKE VOLLEYBALL", 18, CYAN)
		var clip_name: String = game.clips.keys()[game.gallery_index]
		var clip = game.clips[clip_name]
		text(Vector2(48, h - 81), clip_name.to_upper() + " · " + clip.source.get_file(), 21)
		text(Vector2(48, h - 51), "%d ossa · %d fotogrammi · %.2f secondi / Frecce: cambia · F3: torna alla partita" % [clip.names.size(), clip.frames, clip.duration], 14, MUTED)
		return
	if game.feedback_left > 0:
		var width := maxf(240, font.get_string_size(game.feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 44)
		panel(Rect2((w - width) * 0.5, 112, width, 42))
		center(140, game.feedback, 18, Color("ffdf94"))
	if game.phase == "POINT":
		panel(Rect2(w * 0.5 - 250, h * 0.5 - 35, 500, 90))
		center(h * 0.5 + 2, game.feedback, 30, CYAN if game.server == 0 else ORANGE)
		center(h * 0.5 + 33, game.point_reason, 15, MUTED)
	var context := "COPERTURA / PREPARATI"
	match game.phase:
		"SERVE": context = "SERVIZIO · " + ("JUMP FLOAT" if game.serve_type == 0 else "JUMP POWER") if game.server == 0 else "SERVIZIO AVVERSARIO"
		"RECEIVE": context = "RICEZIONE · FERMA IL CURSORE AL CONTATTO"
		"SET": context = "ALZATA " + ("VELOCE" if game.fast_set else "NORMALE") + " · " + ["ZONA 4", "CENTRO", "ZONA 2", "PIPE"][game.set_dir]
		"ATTACK": context = "ATTACCO · CARICA E RILASCIA AL CONTATTO"
		"CPU_ATTACK": context = "MURO · LEGGI LA FRECCIA, POI SALTA"
	panel(Rect2(28, h - 140, 392, 110))
	text(Vector2(47, h - 111), "X / QUADRATO     [ SPAZIO ]", 17, CYAN)
	text(Vector2(47, h - 84), context, 12)
	text(Vector2(47, h - 57), "WASD / LS: muovi    Frecce / RS: mira", 13, MUTED)
	text(Vector2(47, h - 38), "Tab / Y / Triangolo: tipo servizio (provvisorio)", 11, MUTED)
	text(Vector2(w - 304, h - 47), "F1 debug · F2 demo · F3 clip", 13, MUTED)
	text(Vector2(w - 304, h - 27), "C camera · R nuova · Esc pausa", 13, MUTED)
	if game.phase in ["RECEIVE", "SET", "ATTACK", "CPU_ATTACK"] or game.phase == "SERVE" and game.server == 0:
		draw_timing(w * 0.5, h - 104)
	if game.phase == "CPU_ATTACK" and game.cue_left > 0:
		var arrow: String = ["←", "↑", "→", "PIPE"][game.committed_destination]
		panel(Rect2(w * 0.5 - 67, 177, 134, 93))
		center(231, arrow, 40, ORANGE)
		center(256, "LEGGI CON RS", 11, MUTED)
	if game.debug_visible:
		panel(Rect2(28, 112, 355, 201))
		var lines := ["STATE " + game.phase, "CONTACT %.3fs / BALL %.2fm" % [game.flight_left, game.ball_pos.y], "PASS %.2f · SET %.2f" % [game.pass_quality, game.set_quality], "BLOCK %d · PREDICT %s" % [game.block_count, str(game.prediction)], "POWER %.2f · PRECISION %.2f" % [game.charge, game.Timing.precision(game.charge)], "TOUCHES %d / %d · ROT %d / %d" % [game.touches[0], game.touches[1], game.rotations[0], game.rotations[1]], "ANIM: Spike Volleyball / PSA / 145 bones"]
		for i in lines.size(): text(Vector2(43, 140 + i * 24), lines[i], 13, CYAN if i == 0 else MUTED)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.07, 0.7))
		center(h * 0.5, "PAUSA", 48)
		center(h * 0.5 + 40, "Start / Esc per riprendere", 18, MUTED)

func draw_timing(cx: float, y: float) -> void:
	var serve: bool = game.phase == "SERVE"
	var fast: bool = game.phase == "SET" and game.fast_set
	var rem: float = game.flight_left - (0.12 if game.phase == "CPU_ATTACK" else 0.0)
	var cursor: float = game.timing.cursor(rem, fast, game.pass_quality)
	var label := "TEMPO DI CONTATTO"
	if serve:
		var elapsed: float = game.clock_time - game.charge_start if game.charging else 0.0
		cursor = game.timing.cursor(elapsed - 0.92)
		label = "TIENI / RILASCIA · LIMITE VERDE 100%"
	var width := 300.0
	panel(Rect2(cx - 170, y - 30, 340, 93))
	text(Vector2(cx - 150, y - 7), label, 12, MUTED)
	draw_rect(Rect2(cx - width / 2, y + 8, width, 14), Color("344354"))
	var perfect: float = game.timing.perfect_zone_width * game.difficulty_scale() * (0.62 + game.pass_quality * 0.2 if fast else 1.0)
	draw_rect(Rect2(cx - perfect * width / 2, y + 5, perfect * width, 20), Color("42d4a5"))
	draw_line(Vector2(cx, y + 4), Vector2(cx, y + 24), WHITE, 2)
	draw_line(Vector2(cx - width / 2 + cursor * width, y + 2), Vector2(cx - width / 2 + cursor * width, y + 27), Color("fff4bc"), 4)
	if game.charging or game.phase == "ATTACK":
		var charge: float = (game.clock_time - game.charge_start) / (1.05 if serve else 0.75) if game.charging else game.charge
		draw_rect(Rect2(cx - 150, y + 36, 300, 6), Color("344354"))
		draw_rect(Rect2(cx - 150, y + 36, minf(charge / (1.3 if serve else 1.0), 1) * 300, 6), ORANGE if charge > 1 else CYAN)
		if serve:
			draw_line(Vector2(cx - 150 + 300 / 1.3, y + 32), Vector2(cx - 150 + 300 / 1.3, y + 46), Color("42d4a5"), 3)
		else:
			text(Vector2(cx - 150, y + 57), "POTENZA %d%%   PRECISIONE %d%%" % [clampf(charge, 0, 1) * 100, game.Timing.precision(charge) * 100], 10, MUTED)

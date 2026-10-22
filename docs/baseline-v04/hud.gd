extends Control
## End-line broadcast HUD with a single contextual timing and power interaction.
var game: Node
var font := ThemeDB.fallback_font
const INK := Color(0.035, 0.055, 0.085, 0.90)
const WHITE := Color("f0f3f5")
const MUTED := Color("aab7c7")
const BLUE := Color("7cb3ef")
const GOLD := Color("e9d5a7")

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
	var w := size.x
	var h := size.y
	var pad: int = game.pad()
	var pad_name := Input.get_joy_name(pad) if pad >= 0 else "Tastiera"
	var playstation := "dualsense" in pad_name.to_lower() or "dualshock" in pad_name.to_lower() or "ps" in pad_name.to_lower()
	var action_button := "QUADRATO" if playstation else ("X" if pad >= 0 else "SPAZIO")
	if not game.started:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015,0.025,0.045,0.45))
		text(Vector2(75, h * 0.38), "SPIKE", 76)
		text(Vector2(75, h * 0.38 + 74), "FOREVER", 76, GOLD)
		text(Vector2(81, h * 0.38 + 111), "IL TUO GIOCO. IL TUO CAMPO.", 15, MUTED)
		text(Vector2(81, h * 0.38 + 155), "6 CONTRO 6  /  INDOOR VOLLEYBALL", 17)
		panel(Rect2(75, h - 183, 480, 120))
		text(Vector2(96, h - 145), "OPTIONS / START / INVIO PER GIOCARE", 21, GOLD)
		text(Vector2(96, h - 113), "X / Quadrato · azione     LS · movimento     RS · mira", 14)
		text(Vector2(96, h - 88), "F2 demo partita     F3 animazioni     F1 dettagli", 13, MUTED)
		text(Vector2(w - 310, h - 49), pad_name.substr(0, 32), 13, MUTED)
		return
	# Two-row broadcast score keeps the middle of the court visible.
	panel(Rect2(30, 27, 263, 85))
	draw_rect(Rect2(30, 27, 5, 42), Color("285a9c"))
	draw_rect(Rect2(30, 70, 5, 42), Color("e7e6e0"))
	text(Vector2(48, 56), "AURORA", 18)
	text(Vector2(48, 98), "EMBER", 18)
	text(Vector2(192, 58), "%02d" % game.scores[0], 25)
	text(Vector2(192, 100), "%02d" % game.scores[1], 25)
	draw_rect(Rect2(244, 27, 49, 85), Color("26364a"))
	text(Vector2(262, 56), str(game.sets[0]), 18, MUTED)
	text(Vector2(262, 98), str(game.sets[1]), 18, MUTED)
	draw_line(Vector2(35, 69), Vector2(293,69), Color("344154"), 1)
	text(Vector2(31, 133), "SET %d  /  BEST OF FIVE" % (game.sets[0] + game.sets[1] + 1), 11, MUTED)
	text(Vector2(w - 219, 43), "SPIKE / FOREVER", 20)
	text(Vector2(w - 218, 65), "CPU vs CPU" if game.demo else "6 vs 6  /  LIVE", 12, GOLD if game.demo else MUTED)
	if game.gallery:
		panel(Rect2(30, h - 109, w - 60, 77))
		var name: String = game.clips.keys()[game.gallery_index]
		text(Vector2(50, h - 77), "ANIMAZIONI / " + name.to_upper(), 20, GOLD)
		text(Vector2(50, h - 50), game.clips[name].source.get_file() + "    ← → cambia    F3 torna in campo", 13, MUTED)
		return
	if game.feedback_left > 0 and game.phase != "POINT":
		centered(105, game.feedback, 19, GOLD)
	if game.phase == "POINT":
		panel(Rect2(w * 0.5 - 218, h * 0.46 - 41, 436, 84))
		centered(h * 0.46 - 3, game.feedback, 29)
		centered(h * 0.46 + 25, game.point_reason, 14, MUTED)
	elif game.phase in ["RECEIVE", "SET", "ATTACK", "CPU_ATTACK"] or game.phase == "SERVE" and game.server == 0:
		draw_contact(w * 0.5, h - 77, action_button)
	if game.phase == "CPU_ATTACK" and game.cue_left > 0:
		var cue: String = ["←", "↑", "→", "PIPE"][game.committed_destination]
		panel(Rect2(w * 0.5 - 48, h * 0.26, 96, 70))
		centered(h * 0.26 + 39, cue, 34, GOLD)
		centered(h * 0.26 + 58, "LEGGI / RS", 10, MUTED)
	text(Vector2(31, h - 29), "LS / WASD · muovi    RS / Frecce · mira", 12, MUTED)
	text(Vector2(w - 300, h - 29), "F1 aiuto   F2 demo   C camera   Esc pausa", 12, MUTED)
	if game.debug_visible:
		panel(Rect2(30, 157, 342, 250))
		var lines := [game.phase + " / contatto %.2fs" % game.flight_left, "Ricezione %.2f / alzata %.2f" % [game.pass_quality, game.set_quality], "Muro %d / lettura %s" % [game.block_count, str(game.prediction)], "Distanza mani-palla max %.3fm" % game.max_contact_gap, "X / Quadrato / Spazio: azione contestuale", "Tieni / rilascia: servizio e attacco", "LB / L1 / Q: alzata veloce", "Y / Triangolo / Tab: cambia servizio", "F3: animazioni / F5: difficoltà / R: nuova"]
		for i in lines.size(): text(Vector2(45, 183 + i * 24), lines[i], 12, MUTED if i > 3 else WHITE)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01,0.02,0.04,0.62))
		centered(h * 0.48, "PAUSA", 47)
		centered(h * 0.48 + 40, "Options / Start / Esc per riprendere", 17, MUTED)

func draw_contact(cx: float, y: float, action_button: String) -> void:
	var serve: bool = game.phase == "SERVE"
	var fast: bool = game.phase == "SET" and game.fast_set
	var remaining: float = game.flight_left - (0.12 if game.phase == "CPU_ATTACK" else 0.0)
	var cursor: float = game.timing.cursor(remaining, fast, game.pass_quality)
	if game.armed: cursor = game.locked_cursor
	if game.phase == "CPU_ATTACK" and game.clock_time - game.block_time < 0.75: cursor = game.locked_cursor
	var label: String = {"SERVE":"SERVIZIO", "RECEIVE":"RICEZIONE", "SET":"ALZATA", "ATTACK":"ATTACCO", "CPU_ATTACK":"MURO"}.get(game.phase, "")
	if fast: label += " VELOCE"
	if game.phase == "SET": label += " / " + ["ZONA 4", "CENTRO", "ZONA 2", "PIPE"][game.set_dir]
	var charging: bool = game.charging
	var charge: float = (game.clock_time - game.charge_start) / (1.05 if serve else 0.75) if charging else game.charge
	if serve:
		var elapsed: float = game.clock_time - game.charge_start if game.toss_active else 0.0
		cursor = game.timing.cursor(elapsed - 1.02)
		if game.serve_pending: cursor = game.locked_cursor
		label += " / " + ("JUMP FLOAT" if game.serve_type == 0 else "JUMP POWER")
	panel(Rect2(cx - 174, y - 32, 348, 89))
	text(Vector2(cx - 157, y - 9), label, 12, GOLD)
	text(Vector2(cx + 80, y - 9), action_button, 11)
	draw_rect(Rect2(cx - 156, y + 5, 312, 12), Color("425063"))
	var zone: float = game.timing.perfect_zone_width * game.difficulty_scale() * (0.62 + game.pass_quality * 0.2 if fast else 1.0)
	draw_rect(Rect2(cx - zone * 156, y + 2, zone * 312, 18), Color("54ba99"))
	draw_line(Vector2(cx, y + 1), Vector2(cx, y + 21), WHITE, 1.5)
	draw_line(Vector2(cx - 156 + cursor * 312, y - 1), Vector2(cx - 156 + cursor * 312, y + 23), GOLD, 3)
	if serve or game.phase == "ATTACK":
		draw_rect(Rect2(cx - 156, y + 32, 312, 4), Color("425063"))
		draw_rect(Rect2(cx - 156, y + 32, minf(1, maxf(0, charge) / (1.2 if serve else 1.0)) * 312, 4), BLUE if charge <= 1 else Color("ef795d"))
		if serve: draw_line(Vector2(cx + 104, y + 28), Vector2(cx + 104, y + 40), Color("54ba99"), 2)
		text(Vector2(cx - 156, y + 50), "TIENI E RILASCIA  /  POTENZA %d%%" % (clampf(charge,0,1.2)*100), 10, MUTED)
	else:
		text(Vector2(cx - 156, y + 43), "CONFERMATO" if game.armed else "PREMI AL CONTATTO CON LA PALLA", 10, MUTED)

extends RefCounted
## Optional V1 modifiers. Callers gate all gameplay calls with use_player_stats.
## No RNG or baseline replacement is used when the feature is disabled.
const KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
const GRADE_NAMES=["DIFFICILE","BUONA","PERFETTA"]
static var config: Dictionary={}

static func settings() -> Dictionary:
	if config.is_empty(): config=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/player_stats_v1.json"))
	return config

static func curve(key: String,value: float) -> float:
	var points: Array=settings()[key]
	if value<=float(points[0][0]): return float(points[0][1])
	for i in range(1,points.size()):
		if value<=float(points[i][0]): return lerpf(float(points[i-1][1]),float(points[i][1]),inverse_lerp(float(points[i-1][0]),float(points[i][0]),value))
	return float(points[-1][1])

static func rating(game,index: int,key: String) -> float:
	if index<0 or index>=game.players.size(): return float(settings().baseline)
	var p=game.players[index]
	var identity: Dictionary=p.libero_identity if p.libero_active else p.roster_identity
	return clampf(float(identity.get("ratings",{}).get(key,settings().baseline)),0,99)

static func touch_quality(original: float,value: float) -> float:
	var bonus: float=(value-float(settings().baseline))*float(settings().touch_bonus)
	# Preserve the explicit excellent-timing exception even for a 55 player.
	# A severe timing error cannot be repaired by the positive stat bonus.
	bonus*=1.0-smoothstep(float(settings().excellent_timing_start),1.0,original)
	if bonus>0: bonus*=smoothstep(0,.16,original)
	return clampf(original+bonus,0,1)

static func set_grade(pass_q: float,value: float,penalty: float=0.0) -> int:
	var effective:=clampf(pass_q*100.0-penalty,0,100)
	if effective+0.00001>=curve("setting_perfect",value): return 2
	if effective+0.00001>=curve("setting_good",value): return 1
	return 0

static func charge_seconds(game,kind: String) -> float:
	var serve:=kind=="serve"
	var index: int=game.server_index(game.server) if serve else game.hitter
	var speed:=curve("serve_speed" if serve else "attack_speed",rating(game,index,"battuta" if serve else "schiacciata"))
	var base: float=game.Timing.SERVE_CHARGE_SECONDS if serve else game.Timing.ATTACK_CHARGE_SECONDS
	if not serve and game.destination==1:
		speed=lerpf(1.0,speed,float(settings().central_speed_blend))
		# The bar starts at set release. A genuine first tempo has a shorter
		# available flight; do not require charging before the actual set.
		if game.stats_release_flight>0: base=minf(base,game.stats_release_flight*float(settings().central_charge_flight_fraction))
	return base/speed

static func green_low(game,serve: bool) -> float:
	return curve("serve_green_low",rating(game,game.server_index(game.server),"battuta")) if serve else float(settings().attack_green_low[game.stats_set_grade])

static func perfect(power: float,low: float) -> bool:
	return power>=low and power<=1.0

static func ai_power(game,index: int,key: String) -> float:
	var value:=rating(game,index,key)
	var sigma:=lerpf(float(settings().ai_sigma_low),float(settings().ai_sigma_high),value/99.0)
	return clampf(game.rng.randfn(.97,sigma),.35,1.18)

static func block(incoming: Vector3,defender: int,strength: float,quality: float,edge: float,variation: Vector3,value: float,roll: float) -> Dictionary:
	var original=preload("res://src/block_response.gd")
	# Physical contact is validated by main before entering this function.
	# Glancing fingertips and poor seals cannot become a monster by rating.
	if absf(edge)>.91 or strength<.55 or quality<.35: return original.solve(incoming,defender,strength,quality,edge,variation)
	var stuff:=curve("block_stuff",value)
	if roll<stuff: return original.solve(incoming,defender,1.0,1.0,edge*.4,variation)
	if roll<stuff+float(settings().block_touch): return original.solve(incoming,defender,.5,quality,edge*.8,variation)
	return original.solve(incoming,defender,.5,quality,(-1.05 if edge<0 else 1.05),variation)

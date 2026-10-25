extends RefCounted
## Physical arrival accuracy only. No periodic cursor or repeated perfect windows.
const SERVE_CHARGE_SECONDS := 0.46
const ATTACK_CHARGE_SECONDS := 0.55

static func winning_power(power: float) -> bool:
	return power>=0.97-0.000001 and power<=1.000001

static func ace_power(power: float) -> bool:
	# Exactly the displayed 100%; overcharge never earns a guaranteed ace.
	return roundi(power*100)==100 and power<=1.000001
const LATE_RECEIVE_SECONDS := 0.12
func quality(remaining: float, difficulty: float = 1.0) -> float:
	var window := 0.62 * difficulty
	if remaining < 0:
		return clampf(0.84 * (1.0 + remaining / LATE_RECEIVE_SECONDS), 0, 0.84)
	return clampf(1.0 - maxf(0, remaining - 0.040 * difficulty) / window, 0, 1)

static func precision(charge: float) -> float:
	# 90% power -> 80% accuracy; 100% power -> 70% accuracy.
	return clampf(1.70 - clampf(charge, 0, 1), 0.70, 1.0)

static func serve_risk(power: float) -> float:
	return clampf((power - 1.0) * 2.5, 0, 1)

static func attack_risk(power: float, tip: bool=false) -> float:
	return clampf((power-1.0)*(4.5 if tip else 4.0),0,1)

static func blockers(correct: bool, fast: bool, set_quality: float, pipe: bool) -> int:
	if not fast and set_quality < 0.94:
		return 3
	if pipe:
		return 1
	return 2 if correct else 1

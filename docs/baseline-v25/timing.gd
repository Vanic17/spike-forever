extends RefCounted
## Physical arrival accuracy only. No periodic cursor or repeated perfect windows.
const SERVE_CHARGE_SECONDS := 0.70
const ATTACK_CHARGE_SECONDS := 0.75
const LATE_RECEIVE_SECONDS := 0.10
func quality(remaining: float, difficulty: float = 1.0) -> float:
	var window := 0.52 * difficulty
	if remaining < 0:
		return clampf(0.80 * (1.0 + remaining / LATE_RECEIVE_SECONDS), 0, 0.80)
	return clampf(1.0 - maxf(0, remaining - 0.025 * difficulty) / window, 0, 1)

static func precision(charge: float) -> float:
	# 90% power -> 80% accuracy; 100% power -> 70% accuracy.
	return clampf(1.70 - clampf(charge, 0, 1), 0.70, 1.0)

static func serve_risk(power: float) -> float:
	return clampf((power - 1.0) * 2.5, 0, 1)

static func blockers(correct: bool, fast: bool, set_quality: float, pipe: bool) -> int:
	if not fast and set_quality < 0.94:
		return 3
	if pipe:
		return 1
	return 2 if correct else 1

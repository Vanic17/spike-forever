extends RefCounted
## The cursor reaches its centre at the physical interception deadline.
var cursor_speed := 1.2
var perfect_zone_width := 0.12
var quality_falloff := 0.65
var perfect_pass_fast_set_mitigation := 0.25
var cue_duration_normal := 0.5
var cue_duration_fast := 0.28

func cursor(remaining: float, fast: bool = false, pass_quality: float = 0.5) -> float:
	var multiplier := 1.65 - pass_quality * perfect_pass_fast_set_mitigation if fast else 1.0
	return absf(fposmod(remaining * cursor_speed * multiplier + 0.5, 2.0) - 1.0)

func quality(remaining: float, fast: bool = false, pass_quality: float = 0.5, difficulty: float = 1.0) -> float:
	var distance := absf(cursor(remaining, fast, pass_quality) - 0.5)
	var width := perfect_zone_width * (0.62 + pass_quality * 0.20 if fast else 1.0) * difficulty
	# Confirmation buffers the stroke until interception. The visible bar is
	# authoritative: an earlier green crossing must not secretly become a miss.
	return clampf(1.0 - maxf(0, distance - width * 0.5) / quality_falloff, 0, 1)

static func precision(charge: float) -> float:
	return 1.0 - 0.3 * clampf(charge, 0, 1)

static func blockers(correct: bool, fast: bool, set_quality: float, pipe: bool) -> int:
	if not fast and set_quality < 0.94:
		return 3
	if pipe:
		return 1
	return 2 if correct else 1

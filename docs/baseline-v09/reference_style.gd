extends RefCounted
## Measured reference data; rendering and input bindings belong to Spike Forever.
static var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/killer_aces_reference.json"))

static func formation(index: int, rotation: int, serving: bool) -> Vector3:
	var p: Array = data["serve" if serving else "receive"][posmod(rotation,6)][index % 6]
	return Vector3(p[0], 0, p[2])

static func run_speed() -> float:
	return float(data.movement_speed)*float(data.movement_curve[-1].value)

static func base(index: int) -> Vector3:
	var p: Array = data.base[index]
	return Vector3(p[0], 0, p[2])

static func receive_seconds(quality: float, emergency: bool = false) -> float:
	return (1.0 / (float(data.ball.spdReceive) * lerpf(1.0, 0.8, quality))) * (0.82 if not emergency else 0.96)

static func serve_seconds(power: float, floating: bool) -> float:
	var multiplier := lerpf(0.60, 0.70, power) * 0.89 if floating else lerpf(0.63, 1.08, power)
	return 1.0 / (float(data.ball.spdServe) * multiplier)

static func set_seconds(direction: int, quick: bool, quality: float, distance: float, emergency: bool) -> float:
	var speed: float = data.ball.spdSet
	if emergency: return 0.86 / (speed * 0.63)
	if quick and direction == 1: return 0.68 / (speed * 1.16)
	if quick: return 0.74 / (speed * 1.26)
	if direction == 3: return 0.78 / (speed * 0.82)
	return 0.82 / (speed * lerpf(1.08, 0.90, clampf(distance / 6.3,0,1))) + (1-quality)*0.26

static func attack_seconds(power: float, angle: float, back_row: bool, soft: bool) -> float:
	var speed: float = data.ball.spdOffspeedSpike if soft else data.ball.spdSpike
	var multiplier := lerpf(0.8, 1.0, power) * lerpf(1.0, 1.52, angle)
	if back_row: multiplier *= 0.78
	return clampf(1.0 / (speed * multiplier), 0.24, 0.76)

static func attack_arc(back_row: bool, soft: bool) -> float:
	if soft: return float(data.ball.maxSpike)+(1.5 if back_row else 1.1)
	return (0.63+1.26)*0.5 if back_row else float(data.ball.maxSpike)

static func arc_gravity(seconds: float, extra_height: float) -> float:
	# Keep one ballistic solver, while matching the reference's independent
	# arc height and duration for high sets, quicks and emergency balls.
	return maxf(9.81, 8.0 * extra_height / maxf(0.04, seconds * seconds))

static func receive_quality(distance: float, difficulty: float) -> float:
	# The reference samples a spatial curve. Keep its approach side and its
	# plateau through actual hand contact to retain the current arrival control.
	var u := clampf(inverse_lerp(8.0 * difficulty, 1.0, distance), 0, 0.65)
	var keys: Array = data.receive_curve
	for i in range(keys.size()-1):
		var a: Dictionary = keys[i]
		var b: Dictionary = keys[i+1]
		if u <= float(b.time):
			var span: float = b.time - a.time
			var t := clampf((u - float(a.time)) / span,0,1)
			return clampf((2*t*t*t-3*t*t+1)*float(a.value)+(t*t*t-2*t*t+t)*span*float(a.outSlope)+(-2*t*t*t+3*t*t)*float(b.value)+(t*t*t-t*t)*span*float(b.inSlope),0,1)
	return 1.0

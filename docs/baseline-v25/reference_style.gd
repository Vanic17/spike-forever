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

static func receive_seconds(quality: float, _emergency: bool = false) -> float:
	return 1.05 + (1.0 - quality) * 0.45

static func serve_seconds(power: float, floating: bool) -> float:
	# Full charge is faster; beyond it the actual horizontal speed continues
	# to increase in proportion to charge (110% => 1.10 times full speed).
	var full_seconds:=0.92 if floating else 0.76
	return (full_seconds+(1.0-maxf(power,0))*0.30) if power<=1 else full_seconds/power

static func set_seconds(direction: int, quick: bool, quality: float, _distance: float, emergency: bool) -> float:
	var base:=1.02
	match direction:
		1: base=0.42 if quick else 0.62
		3: base=0.88 if quick else 0.92
		_: base=0.82 if quick else 1.02
	return base+(1.0-quality)*1.25

static func attack_seconds(power: float, _angle: float, _back_row: bool, soft: bool) -> float:
	# Retain the existing response through controlled/medium attacks. Only a
	# well-charged hard hit gets the extra pace, with a continuous onset rather
	# than a threshold jump. At full power: .480 -> .456 s (+5.3% floor speed).
	var hard_hit := 0.0 if soft else smoothstep(0.75, 1.0, power)
	return 0.72 - power * 0.24 - hard_hit * 0.024

static func attack_arc(_back_row: bool, _soft: bool) -> float:
	return 0.0

static func arc_gravity(_seconds: float, _extra_height: float) -> float:
	# Formations still use the reference; ball flight retains revision 08 physics.
	return 9.81

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

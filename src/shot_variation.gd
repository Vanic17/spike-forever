extends RefCounted
static func reception_label(offset: float) -> String:
	if offset>0.45: return "MOLTO IN ANTICIPO"
	if offset>0.18: return "IN ANTICIPO"
	if offset>0.06: return "LEGGERMENTE IN ANTICIPO"
	if offset>=-0.025: return "PERFETTA"
	if offset>=-0.06: return "LEGGERMENTE IN RITARDO"
	return "MOLTO IN RITARDO"

static func pass_target(game, target: Vector3, quality: float) -> Vector3:
	if game.possession!=0: return target
	var side:=1.0 if game.possession==0 else -1.0
	var error: float=1.0-quality
	# Early closed platforms send the pass tight; late platforms send it off.
	var early: bool=game.receive_offset>0.06
	target.z=side*clampf(1.5+(-1.2 if early else 4.3)*error+game.rng.randf_range(-0.35,0.35)*error,0.55,6.5)
	return target

static func tip_variant(aim: Vector2, serial: int) -> String:
	if absf(aim.x)>0.3: return "attack_tip_0" if aim.x<0 else "attack_tip_1"
	var choices: Array=[2,3,4,5,6]
	return "attack_tip_"+str(choices[posmod(serial,choices.size())])

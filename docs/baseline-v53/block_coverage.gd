extends "res://docs/baseline-v53/cpu_defense.gd"
func prepare(game) -> void:
	if game.incoming_kind=="block": reset(); return
	super.prepare(game)
func quality(value: float, _pressure: float) -> float: return value

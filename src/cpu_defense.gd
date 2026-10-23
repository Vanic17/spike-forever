extends RefCounted
var timing_quality:=1.0
var outcome:="clean"
var frozen:=false
func reset() -> void:
	timing_quality=1.0; outcome="clean"; frozen=false
func prepare(game) -> void:
	reset()
	if game.possession!=1: return
	var pressure:=clampf(game.incoming_power,0,1)
	var offset: float=game.rng.randf_range(-0.07,0.19)*(0.6+pressure)
	timing_quality=clampf(1.0-absf(offset)*1.2,0.55,0.99)
	var roll: float=game.rng.randf()
	if pressure>0.85 and roll<0.075:
		frozen=true; outcome="hesitation"
	elif roll<0.075+pressure*0.14: outcome="shank"
	elif roll<0.15+pressure*0.17: outcome="overpass"
	elif roll<0.32+pressure*0.12: outcome="loose"
	var delay: float=game.flight_left+0.02 if frozen else game.rng.randf_range(0.025,0.08)+pressure*0.035
	game.scramble_ready[game.receiver]=game.clock_time+delay
func quality(value: float, pressure: float) -> float:
	if outcome=="shank": return 0.05
	if outcome=="loose": return minf(value,0.35)
	return clampf(value*timing_quality-0.025-pressure*0.045,0,1)

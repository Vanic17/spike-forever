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
	var offset: float=game.rng.randf_range(-0.065,0.13)*(0.6+pressure)
	timing_quality=clampf(1.0-absf(offset)*0.85,0.65,0.995)
	var roll: float=game.rng.randf()
	if pressure>0.88 and roll<0.035:
		frozen=true; outcome="hesitation"
	elif roll<0.045+pressure*0.08: outcome="shank"
	elif roll<0.09+pressure*0.10: outcome="overpass"
	elif roll<0.19+pressure*0.10: outcome="loose"
	elif roll<0.29+pressure*0.10: outcome="stretched"
	elif pressure>0.8 and roll>0.93: outcome="reflex"
	var delay: float=game.flight_left+0.02 if frozen else game.rng.randf_range(0.012,0.05)+pressure*0.018
	if outcome=="reflex": delay*=0.65
	game.scramble_ready[game.receiver]=game.clock_time+delay
func quality(value: float, pressure: float) -> float:
	if outcome=="shank": return 0.05
	if outcome=="loose": return minf(value,0.35)
	if outcome=="stretched": return minf(value*timing_quality,0.72)
	if outcome=="reflex": return minf(value*timing_quality,0.80)
	return clampf(value*timing_quality-0.01-pressure*0.02,0,1)

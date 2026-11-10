extends RefCounted
var timing_quality:=1.0
var outcome:="clean"
var frozen:=false
func reset() -> void:
	timing_quality=1.0; outcome="clean"; frozen=false
func prepare(game) -> void:
	reset()
	if not game.cpu_team(game.possession): return
	if game.incoming_out: return
	if game.winner_team>=0 and game.incoming_kind=="serve" and game.rng.randf()<float(preload("res://src/serve_target106.gd").settings().failure.untouched_chance):
		frozen=true;outcome="hesitation"
		game.scramble_ready[game.receiver]=game.clock_time+game.flight_left+.1
		return
	var pressure:=clampf(game.incoming_power,0,1)
	if game.incoming_kind=="block":
		# Attack coverage reacts to the actual rebound after landing. Keep
		# saves possible, but remove the old perfect/instant block exception.
		timing_quality=game.rng.randf_range(.85,.98)
		var read: float=game.rng.randf()
		if read<.035+pressure*.035: outcome="stretched"
		elif read<.15+pressure*.04: outcome="loose"
		game.scramble_ready[game.receiver]=maxf(game.scramble_ready[game.receiver],game.clock_time)+.025+pressure*.025
		return
	var offset: float=game.rng.randf_range(-0.065,0.13)*(0.6+pressure)
	var tuning: Dictionary=preload("res://src/serve_target106.gd").settings().cpu
	timing_quality=clampf((1.0-absf(offset)*0.85)*float(tuning.timing_scale),0.65,0.995)
	var roll: float=game.rng.randf()
	if pressure>0.88 and roll<float(tuning.hesitation_chance):
		frozen=true; outcome="hesitation"
	elif roll<0.045+pressure*0.08: outcome="shank"
	elif roll<0.063+pressure*0.088: outcome="overpass"
	elif roll<0.19+pressure*0.10: outcome="loose"
	elif roll<0.29+pressure*0.10: outcome="stretched"
	elif pressure>0.8 and roll>0.93: outcome="reflex"
	var delay: float=game.flight_left+0.02 if frozen else game.rng.randf_range(0.012,0.05)+pressure*0.018
	if outcome=="reflex": delay*=0.65
	if not frozen:delay+=float(tuning.extra_reaction_seconds)
	game.scramble_ready[game.receiver]=game.clock_time+delay
func quality(value: float, pressure: float) -> float:
	if outcome=="shank": return 0.05
	if outcome=="loose": return minf(value,0.35)
	if outcome=="stretched": return minf(value*timing_quality,0.72)
	if outcome=="reflex": return minf(value*timing_quality,0.80)
	return clampf(value*timing_quality-0.01-pressure*0.02,0,1)

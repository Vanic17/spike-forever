extends RefCounted
static func put(game,team: int,kind: String,value: float,detail: String="") -> void:
	if team<0 or team>1: return
	if detail.is_empty():
		if value>1: detail="SOVRACCARICO"
		else:
			var perfect: bool=value>=.97
			if kind=="BATTUTA": perfect=game.PlayerStats.perfect(value,game.PlayerStats.green_low(game,true)) if game.use_player_stats else game.Timing.ace_power(value)
			elif kind in ["ATTACCO","PALLONETTO"]: perfect=game.PlayerStats.perfect(value,game.PlayerStats.green_low(game,false)) if game.use_player_stats else game.Timing.winning_power(value)
			detail="PERFETTO" if perfect else ("OTTIMO" if value>=.9 else ("BUONO" if value>=.7 else "IMPRECISO"))
	game.timing_results[team]={"text":kind+" · "+detail+" · %.1f%%"%(value*100),"kind":kind,"detail":detail,"until":game.clock_time+2.2,"quality":value}

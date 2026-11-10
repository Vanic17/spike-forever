extends RefCounted
## Winning precision band: keep a real legal flight and a visible failed save.
static func flight_seconds(game, landing: Vector3, requested: float, clearance: float=2.70) -> float:
	var fraction: float=absf(game.ball_pos.z)/maxf(0.01,absf(game.ball_pos.z)+absf(landing.z))
	var linear_height: float=lerpf(game.ball_pos.y,landing.y,fraction)
	var required: float=maxf(0,clearance-linear_height)
	return maxf(requested,sqrt(2.0*required/maxf(0.01,game.flight_gravity*fraction*(1-fraction))))

static func failed_save(game) -> void:
	if game.incoming_kind=="spike" and not game.attack_tip:
		# Preserve the original hard shot right to the floor. An attempted
		# reception may miss, but must never replace it with a slower lob.
		game.finish_contact_attempt(game.receiver)
		game.log_rally_event("winning_shot_floor",{"defender":game.receiver,"winner":game.winner_team})
		game.phase="LOOSE";game.flight_left=100;game.marker.visible=false
		return
	var action: String=game.recovery_action if game.late_receive else "receive"
	var player=game.players[game.receiver]
	var clean_miss: bool=game.cpu_defense.frozen or player.current_hand(false).distance_to(game.ball_pos)>1.25
	var touched: bool=not clean_miss and game.validate_contact(game.receiver,action)
	if touched:
		preload("res://src/defense_failure106.gd").shank(game)
	# Do not restart a forearm pass after the missed contact. The previous
	# attempt already owns its follow-through; a restart looked like a second
	# backward bagher while the root continued chasing the obsolete marker.
	game.finish_contact_attempt(game.receiver)
	if not touched:preload("res://src/defense_visual77.gd").extreme_attempt(game,game.receiver)
	game.log_rally_event("winning_shot_failed_save",{"defender":game.receiver,"touched":touched,"winner":game.winner_team})
	game.phase="LOOSE"; game.flight_left=100; game.marker.visible=false

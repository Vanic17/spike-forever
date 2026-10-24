extends RefCounted
## Winning precision band: keep a real legal flight and a visible failed save.
static func flight_seconds(game, landing: Vector3, requested: float, clearance: float=2.70) -> float:
	var fraction: float=absf(game.ball_pos.z)/maxf(0.01,absf(game.ball_pos.z)+absf(landing.z))
	var linear_height: float=lerpf(game.ball_pos.y,landing.y,fraction)
	var required: float=maxf(0,clearance-linear_height)
	return maxf(requested,sqrt(2.0*required/maxf(0.01,game.flight_gravity*fraction*(1-fraction))))

static func failed_save(game) -> void:
	var action: String=game.recovery_action if game.late_receive else "receive"
	var player=game.players[game.receiver]
	var touched: bool=game.validate_contact(game.receiver,action)
	if touched:
		# The hard ball breaks the platform: visible touch, then floor nearby.
		var side:=1.0 if game.possession==0 else -1.0
		var mishit: int=game.rng.randi_range(0,2)
		var lateral: float=game.rng.randf_range(0.35,1.8)*(-1 if game.rng.randf()<0.5 else 1)
		var landing:=Vector3(clampf(game.ball_pos.x+lateral,-4.25,4.25),0.105,side*clampf(absf(game.ball_pos.z)+game.rng.randf_range(-1.0,1.8),1.0,8.6))
		game.ball_vel=game.BallFlight.velocity_to(game.ball_pos,landing,[0.19,0.34,0.48][mishit],game.flight_spin,game.flight_gravity)
		game.last_touch=game.possession
	# Do not restart a forearm pass after the missed contact. The previous
	# attempt already owns its follow-through; a restart looked like a second
	# backward bagher while the root continued chasing the obsolete marker.
	game.finish_contact_attempt(game.receiver)
	game.log_rally_event("winning_shot_failed_save",{"defender":game.receiver,"touched":touched,"winner":game.winner_team})
	game.phase="LOOSE"; game.flight_left=100; game.marker.visible=false

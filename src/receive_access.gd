extends RefCounted
## A received shot keeps its physical flight. Its chosen performance owns
## the hand height and therefore the interception time, not the bank default.
static func sync_performance(game, force: bool = false) -> bool:
	if game.phase not in ["RECEIVE","CPU_RECEIVE"] or not game.airborne or game.late_receive: return false
	var player=game.players[game.receiver]
	var key: String=game.phase+":"+str(game.shot_serial)+":"+str(game.possession)+":"+str(player.variant_names.get("receive","receive"))
	if not force and player.get_meta("receive_clock_key","")==key: return false
	player.set_meta("receive_clock_key",key)
	var height: float=player.contact_local("receive").y
	if absf(height-game.flight_target.y)<.003: return false
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,height,game.flight_gravity)
	if hit.is_empty() or hit.seconds<=.001: return false
	game.flight_target=hit.point
	game.flight_left=hit.seconds
	game.receive_deadline=game.clock_time+hit.seconds
	player.target=player.stance_for_contact("receive",hit.point)
	game.log_rally_event("receive_performance_sync",{"actor":game.receiver,"variant":player.variant_names.get("receive","receive"),"height":height,"remaining":hit.seconds})
	return true

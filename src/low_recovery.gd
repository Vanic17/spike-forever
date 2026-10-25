extends RefCounted
## The source clock owns the low save, its root travel and recovery.
static func plan(game, index: int, maximum: float = 1.2) -> Dictionary:
	var player=game.players[index]
	if game.player_recovery_seconds(index)>.10: return {}
	player.select_variant("dive","dive_short")
	var clip=player.clips.dive
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,player.contact_local("dive").y,game.flight_gravity)
	if hit.is_empty() or hit.seconds<=.005 or hit.seconds>maximum: return {}
	var toward: Vector3=hit.point-player.position
	var offset: Vector3=player.contact_local("dive")
	var yaw:=atan2(toward.x,toward.z)-atan2(offset.x,offset.z)
	if hit.seconds<.25 and absf(wrapf(yaw-player.rotation.y,-PI,PI))>deg_to_rad(110): return {}
	player.dive_yaw=yaw
	var stance: Vector3=player.stance_for_contact("dive",hit.point)
	if player.position.distance_to(stance)>hit.seconds*4.8+.52: return {}
	var begin: float=clip.contact_time-hit.seconds*1.15
	game.dive_motions[index]={"origin":player.position,"stance":stance,"start_time":begin,"source_time":begin,"duration":hit.seconds,"elapsed":0.0,"yaw":yaw,"initial_yaw":player.rotation.y,"action":"dive","committed":begin>=0}
	if begin>=0: player.prepare_contact("dive",hit.seconds)
	return hit

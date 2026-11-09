extends RefCounted
const Flight=preload("res://src/ball_flight.gd")
const Rescue=preload("res://src/contact_rescue.gd")
static func eligible(game) -> bool:
	return game.incoming_short_tip96 and game.incoming_kind=="soft" and game.phase in ["RECEIVE","CPU_RECEIVE"] and game.winner_team<0
static func proposal(game,index: int) -> Dictionary:
	var p=game.players[index]
	if game.dive_motions.has(index) or game.player_recovery_seconds(index)>.10:return {}
	var clip=p.source_clips.get("dive_pancake80")
	if clip==null:return {}
	var offset: Vector3=clip.contact_offset*p.height_scale90
	var hit:=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,offset.y,game.flight_gravity)
	if hit.is_empty() or hit.seconds<.12 or hit.seconds>1.10:return {}
	var toward: Vector3=hit.point-p.position
	var yaw: float=atan2(toward.x,toward.z)-atan2(offset.x,offset.z)
	if absf(wrapf(yaw-p.rotation.y,-PI,PI))>minf(deg_to_rad(110),hit.seconds*7.0):return {}
	var stance: Vector3=hit.point-Basis(Vector3.UP,yaw)*offset;stance.y=0
	if stance.z*(1 if index<6 else -1)<.30 or absf(stance.x)>6 or absf(stance.z)>10:return {}
	var gap: float=p.position.distance_to(stance)
	if gap>hit.seconds*6.0+.25:return {}
	var obstacles: Array[Vector3]=[]
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other!=index:obstacles.append_array(game.compute_footprint_points(other))
	var begin: float=clip.contact_time-hit.seconds*1.15
	var path:=Rescue.forecast(p,clip,stance,yaw,begin,hit.seconds,obstacles)
	if not path.free or path.peak>7.2:return {}
	return {"index":index,"variant":"dive_pancake80","point":hit.point,"seconds":hit.seconds,"stance":stance,"yaw":yaw,"begin":begin,"cost":gap+path.peak*.05}
static func try_save(game) -> bool:
	if not eligible(game) or game.late_receive or (game.human_team(game.possession) and not game.armed):return false
	if game.clock_time<game.short_tip_next96:return false
	game.short_tip_next96=game.clock_time+.07
	var best: Dictionary={}
	for index in range(game.possession*6,game.possession*6+6):
		if game.legend_controls(index) and not game.legend_match.allow_requested_recovery:continue
		var plan:=proposal(game,index)
		if not plan.is_empty() and (best.is_empty() or plan.cost<best.cost):best=plan
	if best.is_empty():return false
	game.receiver=best.index;Rescue.commit(game,best,false)
	game.late_receive=true;game.recovery_action="dive";game.receive_deadline=game.clock_time+best.seconds
	game.players[game.receiver].target=best.stance
	if game.possession==0:game.selected=game.receiver
	game.log_rally_event("short_tip_pancake",{"actor":game.receiver,"seconds":best.seconds})
	return true

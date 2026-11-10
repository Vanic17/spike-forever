extends RefCounted
## Feasibility from the real incoming flight, never charge percentage.
## A read is made at impact and cannot be redeemed by later assisted movement.
static func travel(seconds: float,initial: float,acceleration: float,maximum: float) -> float:
	if seconds<=0:return 0
	var v:=clampf(initial,0,maximum)
	var ramp:=minf(seconds,(maximum-v)/acceleration)
	return v*ramp+.5*acceleration*ramp*ramp+maximum*(seconds-ramp)
static func assess(game) -> Dictionary:
	if game.incoming_kind!="spike" or game.attack_tip:return {"miss":false,"reaction":0.0}
	var speed: float=game.ball_vel.length()
	var steep: float=-game.ball_vel.y/maxf(1,Vector2(game.ball_vel.x,game.ball_vel.z).length())
	if speed<19 or steep<.30:return {"miss":false,"reaction":0.0}
	var floor_hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,.105)
	if floor_hit.is_empty():return {"miss":false,"reaction":0.0}
	var landing: Vector3=floor_hit.point
	if absf(landing.x)>4.605 or absf(landing.z)>9.105:return {"miss":false,"reaction":0.0}
	if absf(landing.z)>4.6 or floor_hit.seconds>.48:return {"miss":false,"reaction":0.0}
	var best_margin:=-INF
	var reads: Array=[]
	var heights: Dictionary={}
	for index in range(game.possession*6,game.possession*6+6):
		var p=game.players[index]
		var height: float=p.contact_local("receive").y
		var key:=roundi(height*1000)
		if not heights.has(key):heights[key]=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,height)
		var hit: Dictionary=heights[key]
		if hit.is_empty():continue
		var stance: Vector3=p.stance_for_contact("receive",hit.point)
		var delta: Vector3=stance-p.position;delta.y=0
		var gap: float=delta.length()
		var forward: float=maxf(0,p.velocity.dot(delta.normalized()))
		var delay:=.065 if gap<.45 else .12
		var recovery: float=game.player_recovery_seconds(index)
		if game.block_pose_locked(index):recovery=maxf(recovery,.22)
		var budget:=maxf(0,float(hit.seconds)-delay-recovery)
		# Existing momentum is retained; a stationary defender cannot instantly
		# reach sprint speed or turn a short, downward ball into a long dive.
		var allowed:=forward*minf(delay,float(hit.seconds))+travel(budget,forward,22,game.Reference.run_speed()*1.10)+.25
		if hit.seconds>.28:allowed+=.35
		var margin: float=allowed-gap
		best_margin=maxf(best_margin,margin)
		reads.append({"actor":index,"gap":gap,"seconds":hit.seconds,"allowed":allowed,"margin":margin,"landing_lock":recovery})
	return {"miss":best_margin<-.10,"reaction":.12,"speed":speed,"steepness":steep,"landing":landing,"floor_seconds":floor_hit.seconds,"reads":reads}
static func chase(game,index: int) -> bool:
	# Recover only a touched rebound going out after OUR touch. An opponent's
	# ball already heading out must still be left alone.
	return game.phase in ["RECEIVE","CPU_RECEIVE"] and index==game.receiver and game.incoming_kind in ["block","tip","net","shank"] and game.last_touch==game.possession and game.flight_left>.18 and game.flight_left<1.4 and (absf(game.flight_target.x)>4.2 or absf(game.flight_target.z)>8.4) and absf(game.flight_target.x)<7 and absf(game.flight_target.z)<11.5

extends RefCounted
const Approach=preload("res://src/approach_planner.gd")
static func pass_seconds(game, point: Vector3, ordinary: float, contact_index: int = -1, action: String = "set") -> float:
	var index: int=game.possession*6+5 if contact_index<0 else contact_index
	if index==game.receiver: return ordinary
	var player=game.players[index]
	var yaw: float=-PI/2 if game.possession==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw if action in ["set","fast_set"] else (PI if game.possession==0 else 0.0))*player.contact_local(action)
	var stance:=Vector3(point.x-offset.x,0,point.z-offset.z)
	if player.position.distance_to(stance)>5.26: return ordinary
	var landing:=0.0
	if player.clip_name=="block" and not player.looping:
		landing=maxf(0,(player.clips.block.recovery_end-player.animation_time)/player.animation_speed)
	# A first pass can be lifted while the setter lands and plants. Plan this
	# before launch: never pause the ball or stretch a flight already underway.
	var speed: float=game.Reference.run_speed()*1.10
	var route_length: float=game.contact_navigation.length_for(game,index,stance)
	var detour: float=maxf(0,route_length-player.position.distance_to(stance)) if is_finite(route_length) else 0.0
	var arrival:=Approach.seconds(player,stance,speed)+detour/speed+landing
	return maxf(ordinary,minf(ordinary+0.85,arrival))

static func clear_target(game, point: Vector3, contact_index: int = -1, action: String = "set") -> Vector3:
	var bodies: Dictionary=game.court_shape.recovering_bodies(game)
	var team: int=game.possession
	var actor: int=team*6+5 if contact_index<0 else contact_index
	bodies.erase(actor)
	# Standing passers and landing blockers also occupy the contact footprint.
	# Reserve a free endpoint before launch, rather than asking the setter to
	# finish inside them and hoping their support movement clears in time.
	for index in range(team*6,team*6+6):
		if index==actor or bodies.has(index): continue
		bodies[index]=game.compute_footprint_points(index)
	var player=game.players[actor]
	var yaw: float=-PI/2 if team==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw if action in ["set","fast_set"] else (PI if team==0 else 0.0))*player.contact_local(action)
	var best:=point
	var score:=INF
	for radius in [0.0,0.65,1.1,1.5,2.0,2.5]:
		for step in (1 if radius==0 else 12):
			var candidate: Vector3=point+Vector3(cos(step*TAU/12),0,sin(step*TAU/12))*radius
			if absf(candidate.x)>5.0 or candidate.z*(1 if team==0 else -1)<0.65: continue
			var stance:=Vector3(candidate.x-offset.x,0,candidate.z-offset.z)
			var free:=true
			for body in bodies:
				if int(body/6)!=team: continue
				for sample in bodies[body]:
					if stance.distance_to(sample)<1.12: free=false
			if not free: continue
			# Prefer a reachable contact on this side of a fallen passer.
			var blocked:=false
			for body in bodies:
				if int(body/6)!=team: continue
				if not game.court_shape.clear_recovery_route(player.position,stance,bodies[body],1.05): blocked=true
			var cost: float=radius*3.0+player.position.distance_to(stance)*0.1+(12.0 if blocked else 0.0)
			if cost<score: score=cost; best=candidate
	return best

static func try_low_contact(game) -> bool:
	if game.setter_dump or game.out_of_system<0 or game.flight_left>0.48 or game.flight_left<=0.015: return false
	if game.clock_time<game.next_second_touch_read: return false
	game.next_second_touch_read=game.clock_time+0.12
	var player=game.players[game.setter]
	var overhead: String="fast_set" if game.fast_set else "set"
	var stance: Vector3=player.stance_for_contact(overhead,game.flight_target)
	var distance: float=game.contact_navigation.length_for(game,game.setter,stance)
	var speed: float=game.Reference.run_speed()*1.10
	if distance<=maxf(0.14,game.flight_left*speed-0.06): return false
	# Intercept the SAME flight at forearm height. No relaunch, teleport or
	# timing forgiveness: the hands must still physically meet the ball.
	player.select_variant("receive","receive_step")
	var intercept: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,player.contact_local("receive").y,game.flight_gravity)
	if intercept.is_empty() or intercept.seconds<=game.flight_left+0.06 or intercept.seconds>1.2: return false
	var low_stance: Vector3=player.stance_for_contact("receive",intercept.point)
	var low_distance: float=game.contact_navigation.length_for(game,game.setter,low_stance)
	if low_distance>intercept.seconds*speed-0.08: return false
	game.out_of_system=-1
	game.setter_action="receive"
	game.fast_set=false; game.planned_fast=false
	game.flight_target=intercept.point; game.flight_left=intercept.seconds
	game.contact_navigation.reset()
	game.log_rally_event("second_touch_forearm",{"setter":game.setter,"remaining":intercept.seconds,"overhead_distance":distance,"forearm_distance":low_distance})
	return true

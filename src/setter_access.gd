extends RefCounted
const Approach=preload("res://src/approach_planner.gd")
static func pass_seconds(game, point: Vector3, ordinary: float) -> float:
	var index: int=game.possession*6+5
	if index==game.receiver: return ordinary
	var player=game.players[index]
	var yaw: float=-PI/2 if game.possession==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw)*player.contact_local("set")
	var stance:=Vector3(point.x-offset.x,0,point.z-offset.z)
	if player.position.distance_to(stance)>5.26: return ordinary
	var landing:=0.0
	if player.clip_name=="block" and not player.looping:
		landing=maxf(0,(player.clips.block.recovery_end-player.animation_time)/player.animation_speed)
	# A first pass can be lifted while the setter lands and plants. Plan this
	# before launch: never pause the ball or stretch a flight already underway.
	var speed: float=game.Reference.run_speed()*1.10
	var bodies: Dictionary=game.court_shape.recovering_bodies(game)
	var waypoint: Vector3=game.court_shape.route_around_recovery(game,index,stance,bodies)
	var detour: float=maxf(0,player.position.distance_to(waypoint)+waypoint.distance_to(stance)-player.position.distance_to(stance))
	var arrival:=Approach.seconds(player,stance,speed)+detour/speed+landing
	return maxf(ordinary,minf(ordinary+0.85,arrival))

static func clear_target(game, point: Vector3) -> Vector3:
	var bodies: Dictionary=game.court_shape.recovering_bodies(game)
	var team: int=game.possession
	# Standing passers and landing blockers also occupy the contact footprint.
	# Reserve a free endpoint before launch, rather than asking the setter to
	# finish inside them and hoping their support movement clears in time.
	for index in range(team*6,team*6+6):
		if index==team*6+5 or bodies.has(index): continue
		bodies[index]=game.compute_footprint_points(index)
	var player=game.players[team*6+5]
	var yaw: float=-PI/2 if team==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw)*player.contact_local("set")
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

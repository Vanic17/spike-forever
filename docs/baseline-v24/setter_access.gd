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
	var arrival:=Approach.seconds(player,stance,game.Reference.run_speed()*1.10)-0.26+landing
	return maxf(ordinary,minf(ordinary+0.30,arrival))

static func clear_target(game, point: Vector3) -> Vector3:
	var bodies: Dictionary=game.court_shape.recovering_bodies(game)
	if bodies.is_empty(): return point
	var team: int=game.possession
	var player=game.players[team*6+5]
	var yaw: float=-PI/2 if team==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw)*player.contact_local("set")
	var best:=point
	var score:=INF
	for radius in [0.0,0.65,1.1,1.5]:
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
			var cost: float=radius*3.0+player.position.distance_to(stance)*0.1
			if cost<score: score=cost; best=candidate
	return best

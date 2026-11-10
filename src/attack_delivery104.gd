extends RefCounted
## Solve the outgoing hand velocity with the same physical integrator used in play.
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_spec94.gd")
static func crossing(origin: Vector3,target: Vector3,seconds: float,spin: Vector3) -> float:
	var velocity:=Flight.velocity_to(origin,target,seconds,spin)
	var point:=origin
	for i in ceili(seconds*120)+2:
		var state:=Flight.advance(point,velocity,spin,1.0/120);velocity=state[1]
		if point.z*state[0].z<=0:
			return point.lerp(state[0],absf(point.z)/maxf(.000001,absf(point.z-state[0].z))).y
		point=state[0]
	return -INF
static func solve(game,target: Vector3,seconds: float,power: float,soft: bool) -> Dictionary:
	var result: Dictionary={"seconds":seconds}
	if soft or game.attack_tip or game.hitter_action!="attack" or game.incoming_kind!="spike":return result
	var origin: Vector3=game.ball_pos
	var gain:=smoothstep(.40,.98,clampf(power,0,1))
	if gain<=0:return result
	var near:=1.0-smoothstep(.65,2.8,absf(origin.z))
	var spin:=Vector3(signf(target.z-origin.z)*lerpf(12,7,near),game.aim.x*.7,.25)
	var horizontal:=Vector2(target.x-origin.x,target.z-origin.z).length()
	var closed: bool=(game.human_team(game.possession) and game.aim.y>.3) or (game.cpu_team(game.possession) and absf(target.z)<3.9)
	var speed:=lerpf(19,31 if closed else 28,gain)
	# Fixed power and geometry select the same speed, independent of which
	# source performance or older duration clamp preceded this planner.
	var desired:=maxf(.145,horizontal/speed)
	if gain<1:desired=lerpf(seconds,desired,gain)
	if game.out_of_system<0:desired=lerpf(seconds,desired,.45)
	var clearance: float=Net.TOP+Net.BALL_RADIUS+.018
	var low:=desired;var high:=maxf(seconds,desired)
	# A low or distant contact may need a legal arc. Never fake a downward
	# spike by passing through the tape, moving its target or increasing gravity.
	if crossing(origin,target,high,spin)<clearance:
		for trial in 6:
			high+=.08
			if crossing(origin,target,high,spin)>=clearance:break
		if crossing(origin,target,high,spin)<clearance:return result
	if crossing(origin,target,low,spin)<clearance:
		for iteration in 6:
			var middle: float=(low+high)*.5
			if crossing(origin,target,middle,spin)>=clearance:high=middle
			else:low=middle
		desired=high
	result.seconds=desired;result.spin=spin
	return result

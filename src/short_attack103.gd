extends RefCounted
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_spec94.gd")
static func clear(origin: Vector3,target: Vector3,seconds: float,spin: Vector3) -> bool:
	var velocity:=Flight.velocity_to(origin,target,seconds,spin)
	var point:=origin
	for i in ceili(seconds*120)+2:
		var state:=Flight.advance(point,velocity,spin,1.0/120);velocity=state[1]
		if point.z*state[0].z<=0:
			var hit:=point.lerp(state[0],absf(point.z)/maxf(.000001,absf(point.z-state[0].z)))
			return hit.y>=Net.TOP+Net.BALL_RADIUS+.018
		point=state[0]
	return false
static func solve(game,target: Vector3,seconds: float,power: float) -> Dictionary:
	var result: Dictionary={"seconds":seconds}
	if game.attack_tip or game.hitter_action!="attack" or game.incoming_kind!="spike" or game.out_of_system<0:return result
	if not ((game.human_team(game.possession) and game.aim.y>.3) or (game.cpu_team(game.possession) and absf(target.z)<3.9)):return result
	var gain:=smoothstep(.40,1.0,clampf(power,0,1))
	if gain<=0:return result
	# A stronger downward wrist hit adds topspin. The same integrator and
	# net collision remain authoritative; neither contact nor aim is moved.
	var spin:=Vector3(signf(target.z-game.ball_pos.z)*lerpf(24,34,gain),game.aim.x*2.0,.5)
	for scale in [1.0-.05556*gain,1.0-.02778*gain]:
		var requested: float=seconds*scale
		if clear(game.ball_pos,target,requested,spin):return {"seconds":requested,"spin":spin}
	return result

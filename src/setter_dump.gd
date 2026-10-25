extends RefCounted
const Flight=preload("res://src/ball_flight.gd")
static func can_request(game) -> bool:
	var p=game.players[game.setter]
	if not p.source_clips.has("dump_push54"): return false
	var height: float=p.source_clips.dump_push54.contact_offset.y
	var contact:=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,height,game.flight_gravity)
	return not contact.is_empty() and contact.seconds>.005 and available(game,contact.point)
static func available(game, point: Vector3) -> bool:
	return game.Tactics.front(game.setter,game.rotations[game.possession]) and not game.Tactics.libero(game.setter,game.rotations[game.possession],game.possession==game.server) and absf(point.z)<=1.25 and absf(point.x)<4.25 and point.y>=2.65 and game.out_of_system>=0
static func trajectory(origin: Vector3, aim: Vector2, team: int, spin: Vector3) -> Dictionary:
	var side:=1.0 if team==0 else -1.0
	var target:=Vector3(clampf(origin.x+aim.x*1.25,-4.1,4.1),.105,-side*(1.65 if aim.y>=0 else 2.5))
	# Fastest physical trajectory that actually clears the tape. A generic
	# fixed .83s lob from any position could hit the net on the setter's side.
	for step in 36:
		var seconds:=.40+step*.02
		var velocity:=Flight.velocity_to(origin,target,seconds,spin)
		var point:=origin; var v:=velocity
		for tick in int(ceil(seconds*120)):
			var next:=Flight.advance(point,v,spin,1.0/120)
			if point.z*side>=0 and next[0].z*side<=0:
				var fraction:=absf(point.z)/maxf(.00001,absf(point.z-next[0].z))
				if lerpf(point.y,next[0].y,fraction)>2.43+.105+.07: return {"target":target,"seconds":seconds,"velocity":velocity}
				break
			point=next[0]; v=next[1]
	return {}

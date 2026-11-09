extends RefCounted
const Net=preload("res://src/net_spec94.gd")
static func solve(game,target: Vector3,power: float) -> Dictionary:
	var side: float=-1 if game.possession==0 else 1
	var depth:=absf(target.z)
	if game.aim.y>.3:depth=lerpf(2.55,1.85,power)+(depth-3.3)*.18
	elif game.aim.y<-.3:depth=clampf(depth*.88,5.5,8.0)
	else:depth=clampf(depth*.80,3.2,4.8)
	target.z=side*clampf(depth,1.7,8.0);target.x=clampf(target.x,-4.20,4.20)
	var requested: float=lerpf(.82,.73,power) if game.aim.y>.3 else lerpf(.80,.64,power)
	var seconds: float=preload("res://src/winning_shot.gd").flight_seconds(game,target,requested,Net.TOP+Net.BALL_RADIUS+(.10 if game.aim.y>.3 else .065))
	return {"target":target,"seconds":seconds,"pressure":lerpf(.18,.75,power)}

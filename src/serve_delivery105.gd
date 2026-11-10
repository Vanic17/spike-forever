extends RefCounted
const Flight=preload("res://src/attack_delivery104.gd")
const Ref=preload("res://src/reference_style.gd")
static func full(game,target: Vector3,floating: bool) -> Dictionary:
	var spin:=Vector3(signf(target.z-game.ball_pos.z)*(.3 if floating else 60.0),game.aim.x*2,.5)
	var low:=Ref.serve_seconds(1,floating)
	var high:=maxf(low,preload("res://src/winning_shot.gd").flight_seconds(game,target,low,2.60))
	for trial in 8:
		if Flight.crossing(game.ball_pos,target,high,spin)>=2.543:break
		high+=.08
	if Flight.crossing(game.ball_pos,target,low,spin)>=2.543:return {"seconds":low,"spin":spin}
	for iteration in 8:
		var middle: float=(low+high)*.5
		if Flight.crossing(game.ball_pos,target,middle,spin)>=2.543:high=middle
		else:low=middle
	return {"seconds":high,"spin":spin}

static func charged_spin(game,target: Vector3,seconds: float,spin: Vector3,power: float) -> Vector3:
	if power<=1.0:return spin
	# A legal overcharge keeps its real extra speed. Correct its curvature
	# instead of letting a minimum-clearance full serve become an automatic
	# net fault at every value over 100%; the existing risk roll still applies.
	var direction:=signf(target.z-game.ball_pos.z)
	for trial in 12:
		if Flight.crossing(game.ball_pos,target,seconds,spin)>=2.543:break
		spin.x+=direction*15
	return spin

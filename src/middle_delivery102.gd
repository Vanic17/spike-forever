extends RefCounted
const Net=preload("res://src/net_spec94.gd")
static func solve(game,target: Vector3,seconds: float,power: float,soft: bool=false) -> Dictionary:
	var result: Dictionary={"target":target,"seconds":seconds,"boost":0.0}
	if game.destination!=1 or game.hitter_action!="attack" or game.attack_tip or soft or game.out_of_system<0:return result
	if not game.Tactics.role_for(game,game.hitter).begins_with("MB"):return result
	var gain:=smoothstep(.78,1.0,clampf(power,0,1))
	if gain<=0:return result
	var short: bool=game.aim.y>.3
	var lateral: bool=absf(game.aim.x)>.3
	var requested: float=seconds*(1-gain*(.20+(.10 if short or lateral else 0.0)))
	# Harder means less flight time, never altered gravity or a ball below
	# the tape. A distant/bad contact retains the shortest legal trajectory.
	result.target=target
	result.seconds=preload("res://src/winning_shot.gd").flight_seconds(game,target,requested,Net.TOP+Net.BALL_RADIUS+.05)
	result.boost=gain
	return result

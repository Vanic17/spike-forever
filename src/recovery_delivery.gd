extends RefCounted
## Select a playable third touch from its height, performer and available space.
static func can_spike(game,index: int,quality: float,origin: Vector3) -> bool:
	var role: String=game.Tactics.role(index,game.rotations[game.possession],game.possession==game.server)
	if role=="L" or quality<.25: return false
	if game.use_player_stats and game.PlayerStats.rating(game,index,"schiacciata")<45: return false
	if role=="S" and quality<.60: return false
	return absf(origin.x)<7.5 and absf(origin.z)<10.5

static func contact(game,index: int,target: Vector3,origin: Vector3) -> Vector3:
	if game.out_of_system>=0: return target
	# A high forearm set from deep court stays near the available attacker.
	# Never ask him to cross the entire court to a nominal front-row anchor.
	if absf(origin.z)>6.0 or absf(origin.x)>5.0:
		var side:=1.0 if game.possession==0 else -1.0
		target.x=clampf(game.players[index].position.x,-4.1,4.1)
		target.z=side*clampf(absf(game.players[index].position.z),3.9,6.8)
	return target

static func free_ball(game,attacker: int) -> Dictionary:
	# Choose different safe spaces, not a permanent centre/depth-five target.
	var best:=-INF
	var landing:=Vector3.ZERO
	for trial in 4:
		var point: Vector3=game.Tactics.world(1-attacker,game.rng.randf_range(-3.7,3.7),game.rng.randf_range(3.0,8.3))
		point.y=.105
		var gap:=INF
		for i in range((1-attacker)*6,(1-attacker)*6+6):
			gap=minf(gap,Vector2(game.players[i].position.x-point.x,game.players[i].position.z-point.z).length())
		var score: float=gap+game.rng.randf_range(-.7,.7)
		if score>best: best=score; landing=point
	var requested: float=game.rng.randf_range(1.25,1.68)+clampf(absf(game.ball_pos.z)-5,0,5)*.045
	var seconds: float=preload("res://src/winning_shot.gd").flight_seconds(game,landing,requested,2.62)+game.rng.randf_range(.025,.16)
	return {"target":landing,"seconds":seconds}

static func spike(game,landing: Vector3,seconds: float,power: float) -> Dictionary:
	# A back-row hard swing cannot be a short lob: select a deeper legal
	# landing when the straight line from these hands would cross the tape.
	# The integrator, gravity, spin and collisions remain unchanged.
	var fraction: float=absf(game.ball_pos.z)/maxf(.01,absf(game.ball_pos.z)+absf(landing.z))
	var line: float=lerpf(game.ball_pos.y,landing.y,fraction)
	if power>=.48 and line<2.46 and absf(game.ball_pos.z)>1.65:
		var depth: float=clampf(absf(game.ball_pos.z)*2.46/maxf(.45,game.ball_pos.y-2.46),6.5,8.65)
		landing.z=signf(landing.z)*maxf(absf(landing.z),depth)
	# Minimum tape clearance, rather than a compulsory .27m cushion followed
	# by multiplying the entire legal arc again for a lower-power swing.
	seconds=preload("res://src/winning_shot.gd").flight_seconds(game,landing,seconds,2.565)
	return {"target":landing,"seconds":seconds}

static func cpu_blockers(game,correct: bool,seconds: float,target: Vector3) -> int:
	var count: int=game.Timing.blockers(correct,game.fast_set,game.set_quality,game.destination==3)
	# Three only on an out-of-system recovery and genuinely towering set.
	var up: float=(target.y-game.ball_pos.y)/maxf(.01,seconds)+4.905*seconds
	var rise: float=game.ball_pos.y+maxf(0,up)*maxf(0,up)/19.62
	if not game.fast_set and game.out_of_system<1 and seconds>=1.65 and rise>=4.7:
		var team: int=1-game.possession
		var available:=0
		for i in range(team*6,team*6+6):
			if game.Tactics.front(i,game.rotations[team]):
				var distance: float=Vector2(game.players[i].position.x-target.x*.88,game.players[i].position.z).length()
				if distance/5.4+.32<=seconds: available+=1
		if available==3: return 3
	return mini(2,count)

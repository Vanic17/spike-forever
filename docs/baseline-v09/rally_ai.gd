extends RefCounted
## Role and phase decisions reconstructed from the inspected local reference.
const Tactics = preload("res://src/tactics.gd")
const Reference = preload("res://src/reference_style.gd")

static func reception_quality(game, timing_quality: float) -> float:
	var power: float = game.incoming_power
	var quality := timing_quality
	if game.possession == 1:
		if game.incoming_kind == "serve":
			quality = game.rng.randf_range(lerpf(1.0,game.rng.randf_range(0.26,0.90),power),1.0)
		elif game.incoming_kind == "spike":
			quality = game.rng.randf_range(lerpf(0.90,game.rng.randf_range(0.26,0.46),power),0.90)
		elif game.incoming_kind in ["block", "net", "tip"]:
			quality = game.rng.randf_range(0.55,0.92)
		else: quality = game.rng.randf_range(0.85,1.0)
	elif game.incoming_kind == "spike":
		quality = lerpf(quality,0.38,lerpf(0.10,0.22,power))
	var fatigue: float = clampf(float(game.test_rallies - 3) / 7.0,0,1)
	quality -= game.rng.randf_range(0.0,0.13) * fatigue * (1.0 if quality < 0.97 else 0.25)
	if game.late_receive: quality *= 0.76
	return clampf(quality,0,1)

static func system_quality(point: Vector3, setter_is_specialist: bool) -> int:
	var quality := clampf(inverse_lerp(5.0,2.0,absf(point.z)),0,1) * clampf(inverse_lerp(6.0,4.0,absf(point.x)),0,1)
	if not setter_is_specialist: quality *= 0.5
	return 1 if quality >= 0.70 else (0 if quality > 0.4 else -1)

static func attack_choice(game, team: int, power: float) -> Dictionary:
	var best := -INF
	var result: Dictionary = {}
	for sector in 8:
		var direction := Vector2.from_angle(float(sector)*PI/4)
		var soft := sector % 3 == 0 and absf(game.ball_pos.z) < 3.5
		var x := signf(direction.x)*3.75 if absf(direction.x)>0.3 else 0.0
		var depth := 2.1 if soft else (7.5 if direction.y < -0.3 else 5.4)
		var point := Tactics.world(1-team,x,depth)
		point.y = 0.105
		var nearest := INF
		for defender in range((1-team)*6,(1-team)*6+6):
			var distance: float = Vector2(game.players[defender].position.x-point.x,game.players[defender].position.z-point.z).length()
			if game.players[defender].clip_name == "block": distance += 1.0
			nearest = minf(nearest,distance)
		# A readable opening is a preference, not perfect knowledge of the best
		# landing point. Bounded variation lets defenders dig ordinary attacks.
		var score: float = nearest*0.55 + game.rng.randf_range(-1.5,1.5)
		if sector == game.last_shots[team]: score -= 1.4
		if soft and game.block_count >= 2: score += 0.65
		if game.out_of_system < 0 and soft: score -= 1.0
		if score > best:
			best = score
			result = {"target":point,"soft":soft,"sector":sector,"power":minf(power,0.35) if soft else power}
	game.last_shots[team] = result.sector
	return result

static func target(game, index: int, team: int) -> Vector3:
	var rotation: int = game.rotations[team]
	var front := Tactics.front(index,rotation)
	var role := Tactics.role(index,rotation,team==game.server)
	var own: bool = team == game.possession
	var side := 1.0 if team == 0 else -1.0
	var receiving: bool = game.phase in ["RECEIVE","CPU_RECEIVE"]
	var setting: bool = game.phase in ["SET","CPU_SET"]
	var attacking: bool = game.phase in ["ATTACK","CPU_ATTACK"]
	var home := Tactics.home(index,team,rotation,team==game.server,own)
	var selected: bool = index == game.planned_hitter
	if own and receiving:
		if game.incoming_kind == "serve":
			if role=="S": return Tactics.world(team,0.7,1.75 if front else 2.6)
			return Tactics.serve_position(index,team,rotation,false)
		# The passer owns the ball. Others keep their defensive lane, then open
		# a route for the setter instead of chasing the same interception point.
		if role == "S": return Tactics.world(team,0,1.75)
		if front:
			home.z = side * (2.5 if role.begins_with("MB") else 3.0)
		return home
	if own and setting:
		if role == "S": return Tactics.world(team,3.52 if front else 3.0,1.0 if front else 4.26)
		if role == "L":
			var pipe_x: float = game.players[game.planned_hitter].position.x * side if game.planned_hitter>=0 else 0.0
			return Tactics.world(team,-1.0 if pipe_x>0 else 1.0,6.0)
		if front and role.begins_with("MB"):
			var setter_x: float = game.flight_target.x * side
			var offset := -1.52 if setter_x >= -0.2 else 1.52
			var depth := 3.52
			if game.out_of_system < 1: return Tactics.world(team,signf(setter_x)*0.26,2.7)
			if game.flight_left < 0.42: depth = 2.45
			return Tactics.world(team,clampf(setter_x+offset,-2.9,2.9),depth)
		if front:
			# Both wings open outside the sideline; only the selected hitter
			# commits after the setter releases. This also creates real decoys.
			var wing := -1.0 if role.begins_with("OH") else 1.0
			return Tactics.world(team,wing*(4.75 if not game.fast_set else 4.3),4.0)
		if role.begins_with("OH"):
			return Tactics.world(team,0.0 if rotation < 3 else -1.6,5.7 if selected else 6.4)
		if role == "OPP": return Tactics.world(team,3.6,5.8 if selected else 6.8)
		return home
	if own and attacking:
		var hit_x: float = game.flight_target.x * side
		if role == "S": return Tactics.world(team,clampf(hit_x*0.4+1.0,-2.4,2.8),4.26 if not front else 2.4)
		if not front: return Tactics.world(team,home.x*side,4.26 if role=="L" else 5.0)
		if role.begins_with("MB"):
			return Tactics.world(team,signf(hit_x)*0.52,2.0 if game.phase_time < 0.35 else 2.6)
		return Tactics.world(team,-3.0 if role.begins_with("OH") else 3.0,2.0)
	if not own and (setting or receiving):
		# Read potential attackers before the set, without moving the whole
		# block to a destination which has not been revealed yet.
		if front and role.begins_with("MB"):
			var opposing_middle := Tactics.attacker(1-team,game.rotations[1-team],1,game.setter)
			var read_x: float = game.players[opposing_middle].position.x if opposing_middle>=0 else 0.0
			home.x = clampf(read_x + side*0.46,-2.9,2.9)
		elif front: home.x = side * (-4.0 if home.x*side<0 else 4.0)
		return home
	if not own and attacking:
		var hit_x: float = game.flight_target.x * side
		if front:
			home.z = side * 3.1 # Wing outside the active block covers tips.
			return home
		var same_lane := signf(home.x*side)==signf(hit_x)
		var read := float(posmod(index*7+game.attack_serial*3,11))/10.0
		if game.destination == 1:
			home.z -= side * (0.8 + read*0.4)
			home.x += side * (read-0.5)*1.5
		elif not Tactics.front(game.hitter,game.rotations[1-team]): home.z += side*1.5
		elif same_lane:
			home.z += side*(0.8+read*0.9)
			home.x += side*signf(hit_x)*0.5
		else:
			home.z += side*(0.4+read*0.6) if not role.begins_with("OH") else -side*(0.8+read*0.7)
			home.x += side*signf(hit_x)*0.45
		return home
	return home

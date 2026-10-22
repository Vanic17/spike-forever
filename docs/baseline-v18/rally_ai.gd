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
	var own: bool = team == game.possession
	var receiving: bool = game.phase in ["RECEIVE","CPU_RECEIVE"]
	var setting: bool = game.phase in ["SET","CPU_SET"]
	var attacking: bool = game.phase in ["ATTACK","CPU_ATTACK"]
	if own and receiving:
		if game.incoming_kind == "serve":
			if _role(game,index,team)=="S": return Tactics.setter_position(team)
			# The receiver has a separate contact assignment in main.gd. All
			# other passers retain the actual six-rotation reception formation.
			return Tactics.serve_position(index,team,game.rotations[team],false)
		if _role(game,index,team)=="S": return Tactics.setter_position(team)
		return defensive_base(game,index,team)
	if own and setting: return opening(game,index,team)
	if own and attacking:
		# Only the movement target is eased between opening and coverage. This
		# neither delays a touch nor changes a ball/animation contact schedule.
		var individual := float(posmod(index*5+team*3,11))/10.0
		var progress := smoothstep(0.025+individual*0.045,0.30+individual*0.12,game.phase_time)
		return opening(game,index,team).lerp(coverage(game,index,team),progress)
	if not own and (setting or receiving or attacking): return defensive_read(game,index,team)
	return defensive_base(game,index,team)

static func _role(game, index: int, team: int) -> String:
	return Tactics.role(index,game.rotations[team],team==game.server)

static func _destination(game, index: int) -> Vector3:
	var destination = game.players[index].get("target")
	return destination if destination is Vector3 else game.players[index].position

static func defensive_base(game, index: int, team: int) -> Vector3:
	return Tactics.home(index,team,game.rotations[team],team==game.server,false)

static func attack_contact(game, direction: int, attacker: int, set_contact: Vector3) -> Vector3:
	# Change only the spatial lane. Main retains its contact height, quality
	# spread, input choice and pre-existing flight-time calculation.
	var team: int = game.possession
	var side := 1.0 if team==0 else -1.0
	var back := not Tactics.front(attacker,game.rotations[team])
	var width := -3.4
	match direction:
		1:
			var setter_x := set_contact.x*side
			var away := -1.0 if setter_x>=-0.2 else 1.0
			var off_net := clampf(inverse_lerp(0.5,3.0,absf(set_contact.z)),0,1)
			var spacing := lerpf(float(Tactics.positioning.middle_offset_near),float(Tactics.positioning.middle_offset_far),off_net)
			width = clampf(setter_x+away*spacing,-3.0,3.0)
		2: width = float(Tactics.positioning.d_width) if back else 3.4
		3: width = float(Tactics.positioning.pipe_width)
	return Tactics.world(team,width,3.65 if back else 1.05)

static func opening(game, index: int, team: int) -> Vector3:
	var p: Dictionary = Tactics.positioning
	var side := 1.0 if team==0 else -1.0
	var rotation: int = game.rotations[team]
	var front := Tactics.front(index,rotation)
	var role := _role(game,index,team)
	var base := defensive_base(game,index,team)
	var setting: bool = game.phase in ["SET","CPU_SET"]
	var setter_point: Vector3 = game.flight_target if setting else _destination(game,game.setter)
	var set_origin = game.get("set_origin")
	if not setting and set_origin is Vector3:
		# Preserve the actual set's spatial reference while the hitter travels.
		# A small difference between setter feet and hands must not reverse the
		# middle's assigned side halfway through the same approach.
		setter_point = set_origin
	var setter_x := setter_point.x*side
	var commit := 1.0-smoothstep(0.20,0.45,maxf(0.0,game.flight_left)) if setting else 1.0
	if role=="S":
		if index==game.setter: return Tactics.setter_position(team)
		return Tactics.world(team,3.52,1.0) if front else base
	if role=="L":
		# JobMover gives the pipe runner a separate lane. Use its committed
		# opening side, so merely crossing centre cannot reverse the libero.
		var local_x: float = game.players[index].position.x*side
		if local_x>0: return Tactics.world(team,1.0,float(p.court_depth)-3.0)
		return Tactics.world(team,-1.0,float(p.court_depth)-2.0)
	if front and role.begins_with("MB"):
		if game.out_of_system<1: return Tactics.world(team,signf(setter_x)*0.26,1.0)
		var away := -1.0 if setter_x>=-0.2 else 1.0
		var off_net := clampf(inverse_lerp(0.5,3.0,absf(setter_point.z)),0,1)
		var spacing := lerpf(float(p.middle_offset_near),float(p.middle_offset_far),off_net)
		# Men's first tempo remains beside/in front of the setter. The source
		# modeGender==1 slide towards the right antenna is deliberately absent.
		return Tactics.world(team,clampf(setter_x+away*spacing,-3.0,3.0),lerpf(float(p.middle_wait_depth),float(p.middle_commit_depth),commit))
	if front:
		var wing := Tactics.attack_wing(index,rotation,Tactics.first_ball(game))
		var width := float(p.wing_quick_width) if game.fast_set and wing<0 else float(p.wing_width)
		return Tactics.world(team,wing*width,float(p.wing_depth))
	if role.begins_with("OH"):
		return Tactics.world(team,float(p.pipe_width),lerpf(float(p.back_wait_depth),float(p.back_commit_depth),commit))
	if role=="OPP":
		# D is a back-row opposite lane in the men's rotations with a front-row
		# setter. It is not the central's one-foot slide behind the setter.
		return Tactics.world(team,float(p.d_width),lerpf(float(p.back_wait_depth),float(p.back_commit_depth),commit))
	return base

static func coverage(game, index: int, team: int) -> Vector3:
	var p: Dictionary = Tactics.positioning
	var side := 1.0 if team==0 else -1.0
	var front := Tactics.front(index,game.rotations[team])
	var role := _role(game,index,team)
	var base := defensive_base(game,index,team)
	if role=="S" and index==game.setter: return Tactics.setter_position(team)
	if not front: return Tactics.world(team,base.x*side,float(p.cover_back_depth))
	if role.begins_with("MB"):
		return Tactics.world(team,signf(game.flight_target.x*side)*float(p.cover_middle_width),float(p.cover_front_depth))
	var wing := Tactics.attack_wing(index,game.rotations[team],Tactics.first_ball(game))
	if is_zero_approx(wing): wing=1.0 # A front-row setter covering an emergency backup set retains his right lane.
	return Tactics.world(team,wing*float(p.cover_pin_width),float(p.cover_front_depth))

static func defensive_read(game, index: int, team: int) -> Vector3:
	var p: Dictionary = Tactics.positioning
	var side := 1.0 if team==0 else -1.0
	var rotation: int = game.rotations[team]
	var front := Tactics.front(index,rotation)
	var role := _role(game,index,team)
	var point := defensive_base(game,index,team)
	var attacking: bool = game.phase in ["ATTACK","CPU_ATTACK"]
	var hit_x: float = game.flight_target.x*side
	if front:
		var pin_width := float(p.defensive_pin_inside_width) if attacking and hit_x<0 else float(p.defensive_pin_width)
		if role.begins_with("MB"):
			var opposing_middle := Tactics.attacker(1-team,game.rotations[1-team],1,game.setter)
			var read_x: float = _destination(game,opposing_middle).x*side if opposing_middle>=0 else 0.0
			point.x = side*clampf(read_x-float(p.defensive_middle_offset),-pin_width+1.0,pin_width-1.0)
		else: point.x = side*(-pin_width if role.begins_with("OH") else pin_width)
		return point
	# The source chooses each floor read once for the current set, rather than
	# adding a fresh random offset each frame. Stable per-player samples retain
	# that positional variation without perturbing our gameplay RNG/timing.
	var read := float(posmod(index*7+game.attack_serial*3,23))/22.0
	var second := float(posmod(index*11+game.attack_serial*7,19))/18.0
	var local_x := point.x*side
	var depth := point.z*side
	if not attacking:
		if game.setter>=0 and Tactics.front(game.setter,game.rotations[1-team]) and absf(local_x)>0.1:
			var setter_x: float = _destination(game,game.setter).x*side
			var same_lane := signf(local_x)==signf(setter_x)
			depth -= read*(0.52 if same_lane else 0.16)
			local_x -= signf(local_x)*(second if same_lane else lerpf(0.52,1.0,second))
		return Tactics.world(team,local_x,depth)
	var back_attack: bool = game.hitter>=0 and not Tactics.front(game.hitter,game.rotations[1-team])
	var quick_middle: bool = game.destination==1 and game.fast_set
	var block_value = game.get("block_count")
	var block_closed: bool = block_value==null or int(block_value)>=2
	if absf(local_x)<0.1:
		if back_attack: depth += 0.26
		else:
			depth += -1.0 if quick_middle else lerpf(-1.52,0.2,read)
			local_x += (-1.0 if second<0.5 else 1.0)*lerpf(1.0,2.0,absf(second-0.5)*2.0)
	elif quick_middle:
		depth += read*1.52
		local_x += signf(local_x)
	elif back_attack: depth += 2.0
	elif signf(local_x)==signf(hit_x):
		if block_closed: depth += lerpf(1.52,3.0,read)
		depth += lerpf(0.26,1.0,second)
		local_x += signf(local_x)*0.8
	else: depth += lerpf(0.0,-2.0 if block_closed else 2.0,read)
	return Tactics.world(team,local_x,depth)

static func attack_opening(game, index: int, team: int, _role_name: String, _front: bool, _rotation: int) -> Vector3:
	return opening(game,index,team)

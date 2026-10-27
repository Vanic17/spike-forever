extends RefCounted
## Stable 5-1 roster. Rotation slot and tactical role are separate concepts.
const Reference = preload("res://src/reference_style.gd")
const Rotation=preload("res://src/rotation_model.gd")
const ServeLayout=preload("res://src/serve_layout.gd")
const Layout=preload("res://src/rotation_layout.gd")
const ROLES=Rotation.ROLES
const INITIAL_SLOTS=Rotation.INITIAL_SLOTS
const ZONES=Rotation.ZONES
const BODY_SPACE := 0.78
const BLOCK_SPACE := 0.90
## Positions only: none of the reference's input, ball flight or animations.
static var positioning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/killer_aces_positioning.json"))

static func slot(index: int, rotation: int) -> int:
	return Rotation.slot(index,rotation)

static func front(index: int, rotation: int) -> bool:
	return Rotation.front(index,rotation)

static func world(team: int, x: float, depth: float) -> Vector3:
	var side := 1.0 if team == 0 else -1.0
	return Vector3(x * side, 0, depth * side)

static func server(team: int, rotation: int) -> int:
	for i in 6:
		if slot(i, rotation) == 3: return team * 6 + i
	return team * 6 + 5

static func libero(index: int, rotation: int, serving: bool) -> bool:
	return Rotation.libero(index,rotation,serving)

static func role(index: int, rotation: int, serving: bool) -> String:
	return "L" if libero(index, rotation, serving) else ROLES[index % 6]

static func serve_position(index: int, team: int, rotation: int, serving: bool = true) -> Vector3:
	# Receiving overlap constrains only the ready layout. The serving side
	# starts in its defensive roles, except the actual Z1 server outside court.
	if serving:
		if slot(index,rotation)==3: return world(team,2.8,11.9)
		return home(index,team,rotation,true,false)
	var p:=ServeLayout.receive(index,rotation)
	return world(team, p.x, p.z)

static func setter_position(team: int) -> Vector3:
	var p: Array = positioning.setter_target
	return world(team, float(p[0]), float(p[2]))

static func home(index: int, team: int, rotation: int, serving: bool, attack: bool) -> Vector3:
	if role(index,rotation,serving)=="S" and attack: return setter_position(team)
	var p:=Layout.defense(index,rotation)
	return world(team,p.x,p.z)

static func first_ball(game) -> bool:
	# The serve kind persists throughout reception, set and the first attack.
	# This describes the shot only. Live pin responsibilities are committed
	# separately in rally_lanes and do not change when this becomes false.
	return game.incoming_kind == "serve" and game.possession != game.server

static func wing_for(game, index: int) -> float:
	var team:=int(index/6)
	var lanes=game.get("rally_lanes")
	var mirrored: bool=lanes.mirrored(team) if lanes!=null else (first_ball(game) and team==game.possession)
	return attack_wing(index,game.rotations[team],mirrored)

static func attacker_for(game, team: int, direction: int, exclude: int) -> int:
	var lanes=game.get("rally_lanes")
	var mirrored: bool=lanes.mirrored(team) if lanes!=null else (first_ball(game) and team==game.possession)
	var primary:=attacker(team,game.rotations[team],direction,exclude,mirrored)
	if primary>=0 or direction not in [0,2,3]: return primary
	# An emergency second touch can be played by the normal opposite. Keep
	# the requested pin/D lane with another eligible hitter, never silently
	# reinterpret a back set as a middle quick.
	var best:=-1; var cost:=INF
	for i in range(team*6,team*6+6):
		if i==exclude or libero(i,game.rotations[team],team==game.server): continue
		if not (ROLES[i%6].begins_with("OH") or ROLES[i%6]=="OPP"): continue
		if direction==0 and not front(i,game.rotations[team]): continue
		if direction==3 and front(i,game.rotations[team]): continue
		var point:=world(team,-3.4 if direction==0 else (3.4 if direction==2 else 0),3.4)
		var distance: float=game.players[i].position.distance_to(point)
		if distance<cost: best=i; cost=distance
	return best

static func attack_wing(index: int, rotation: int, _service_reception: bool = false) -> float:
	if not front(index, rotation): return 0.0
	var r: String = ROLES[index % 6]
	if not r.begins_with("OH") and r != "OPP": return 0.0
	var wing := -1.0 if r.begins_with("OH") else 1.0
	# The user's P1 diagrams keep O on Z4 and B1 on Z2 in attack AND defense.
	# Preserve these pins for both serving teams and through the whole rally.
	if posmod(rotation,6)==0: wing=-wing
	return wing

static func attacker(team: int, rotation: int, direction: int, exclude: int, service_reception: bool = false) -> int:
	for i in range(team * 6, team * 6 + 6):
		if i == exclude: continue
		var r: String = ROLES[i % 6]
		if direction == 0 and attack_wing(i, rotation, service_reception) == -1.0: return i
		if direction == 1 and r.begins_with("MB") and front(i, rotation): return i
		if direction == 2 and (attack_wing(i, rotation, service_reception) == 1.0 or (r == "OPP" and not front(i, rotation))): return i
		if direction == 3 and r.begins_with("OH") and not front(i, rotation): return i
	return -1

static func block_target(index: int, order: Array[int], attack_x: float, team: int) -> Vector3:
	var half_span := (order.size() - 1) * BLOCK_SPACE * 0.5
	# Clamp the entire formation before adding offsets; clamping each player
	# individually collapses the outside blockers onto the same sideline.
	var centre := clampf(attack_x, -4.12 + half_span, 4.12 - half_span)
	return Vector3(centre + (order.find(index) - (order.size() - 1) * 0.5) * BLOCK_SPACE, 0, 0.68 if team == 0 else -0.68)

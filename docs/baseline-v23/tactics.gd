extends RefCounted
## Stable 5-1 roster. Rotation slot and tactical role are separate concepts.
const Reference = preload("res://src/reference_style.gd")
const Rotation=preload("res://src/rotation_model.gd")
const ServeLayout=preload("res://src/serve_layout.gd")
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
	var r := role(index, rotation, serving)
	var is_front := front(index, rotation)
	var base_index := 0
	if r == "L": base_index = 1
	elif r.begins_with("OH"): base_index = 3 if is_front else 2
	elif r.begins_with("MB"): base_index = 4 if is_front else 1
	elif r in ["OPP", "S"]: base_index = 5 if is_front else 0
	if r == "S" and attack: return setter_position(team)
	var p := Reference.base(base_index)
	return world(team,p.x,p.z)

static func first_ball(game) -> bool:
	# The serve kind persists throughout reception, set and the first attack.
	# It changes when that attack crosses the net, so no extra rally state is
	# needed and later transition plays return to the usual specialist lanes.
	return game.incoming_kind == "serve" and game.possession != game.server

static func attack_wing(index: int, rotation: int, service_reception: bool = false) -> float:
	if not front(index, rotation): return 0.0
	var r: String = ROLES[index % 6]
	if not r.begins_with("OH") and r != "OPP": return 0.0
	var wing := -1.0 if r.begins_with("OH") else 1.0
	# R1 receives with OH1 on the right and OPP already on the left.
	# Play the first ball on these pins; do not cross both behind the passer
	# before the first set. Identities and rotation slots remain unchanged.
	if service_reception and posmod(rotation,6)==0: wing=-wing
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

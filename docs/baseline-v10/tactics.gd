extends RefCounted
## Stable 5-1 roster. Rotation slot and tactical role are separate concepts.
const Reference = preload("res://src/reference_style.gd")
const ROLES := ["OH1", "MB1", "OPP", "OH2", "MB2", "S"]
const INITIAL_SLOTS := [2, 1, 0, 5, 4, 3]
const ZONES := [4, 3, 2, 1, 6, 5]
const BODY_SPACE := 0.78
const BLOCK_SPACE := 0.90

static func slot(index: int, rotation: int) -> int:
	return posmod(INITIAL_SLOTS[index % 6] + rotation, 6)

static func front(index: int, rotation: int) -> bool:
	return slot(index, rotation) < 3

static func world(team: int, x: float, depth: float) -> Vector3:
	var side := 1.0 if team == 0 else -1.0
	return Vector3(x * side, 0, depth * side)

static func server(team: int, rotation: int) -> int:
	for i in 6:
		if slot(i, rotation) == 3: return team * 6 + i
	return team * 6 + 5

static func libero(index: int, rotation: int, serving: bool) -> bool:
	return ROLES[index % 6].begins_with("MB") and not front(index, rotation) and not (serving and slot(index, rotation) == 3)

static func role(index: int, rotation: int, serving: bool) -> String:
	return "L" if libero(index, rotation, serving) else ROLES[index % 6]

static func serve_position(index: int, team: int, rotation: int, serving: bool = true) -> Vector3:
	var p := Reference.formation(index, rotation, serving)
	return world(team, p.x, p.z)

static func home(index: int, team: int, rotation: int, serving: bool, attack: bool) -> Vector3:
	var r := role(index, rotation, serving)
	var is_front := front(index, rotation)
	var base_index := 0
	if r == "L": base_index = 1
	elif r.begins_with("OH"): base_index = 3 if is_front else 2
	elif r.begins_with("MB"): base_index = 4 if is_front else 1
	elif r == "OPP": base_index = 5 if is_front else 0
	if r == "S" and attack: return world(team, 0.0, 1.75)
	var p := Reference.base(base_index)
	return world(team,p.x,p.z)

static func attacker(team: int, rotation: int, direction: int, exclude: int) -> int:
	for i in range(team * 6, team * 6 + 6):
		if i == exclude: continue
		var r: String = ROLES[i % 6]
		if direction == 0 and r.begins_with("OH") and front(i, rotation): return i
		if direction == 1 and r.begins_with("MB") and front(i, rotation): return i
		if direction == 2 and r == "OPP": return i
		if direction == 3 and r.begins_with("OH") and not front(i, rotation): return i
	return -1

static func block_target(index: int, order: Array[int], attack_x: float, team: int) -> Vector3:
	var half_span := (order.size() - 1) * BLOCK_SPACE * 0.5
	# Clamp the entire formation before adding offsets; clamping each player
	# individually collapses the outside blockers onto the same sideline.
	var centre := clampf(attack_x, -4.12 + half_span, 4.12 - half_span)
	return Vector3(centre + (order.find(index) - (order.size() - 1) * 0.5) * BLOCK_SPACE, 0, 0.68 if team == 0 else -0.68)

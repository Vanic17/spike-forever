extends RefCounted
## Tactical pin identity is committed at rally setup, independently from
## the incoming shot kind and from the legal rotation slots.
const Rotation=preload("res://src/rotation_model.gd")
var mirrors: Array[bool]=[false,false]
var rows: Dictionary={}
func reset(rotations: Array, _serving_team: int) -> void:
	rows.clear()
	for team in 2:
		mirrors[team]=posmod(rotations[team],6)==0
		var middle:=-1
		var pins: Array[int]=[]
		for index in range(team*6,team*6+6):
			if not Rotation.front(index,rotations[team]): continue
			if Rotation.ROLES[index%6].begins_with("MB"): middle=index
			else: pins.append(index)
		pins.sort_custom(func(a,b): return wing(a)*(1 if team==0 else -1)<wing(b)*(1 if team==0 else -1))
		rows[team]=[pins[0],middle,pins[1]]
func mirrored(team: int) -> bool:
	return mirrors[team]
func wing(index: int) -> float:
	var value: float=-1.0 if Rotation.ROLES[index%6].begins_with("OH") else 1.0
	return -value if mirrors[int(index/6)] else value
func line(team: int) -> Array[int]:
	var result: Array[int]=[]
	if rows.has(team): result.assign(rows[team])
	return result

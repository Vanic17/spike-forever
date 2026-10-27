extends RefCounted
## Coordinates in metres, own half viewed towards the net. Rows R1..R6;
## columns OH1, MB1, OPP, OH2, MB2, S. These are ready positions, not attack jobs.
const RECEIVE=preload("res://src/rotation_layout.gd").RECEIVE

static func receive(index: int, rotation: int) -> Vector3:
	var p: Array=RECEIVE[posmod(rotation,6)][index%6]
	return Vector3(p[0],0,p[1])

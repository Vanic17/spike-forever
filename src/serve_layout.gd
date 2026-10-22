extends RefCounted
## Coordinates in metres, own half viewed towards the net. Rows R1..R6;
## columns OH1, MB1, OPP, OH2, MB2, S. These are ready positions, not attack jobs.
const RECEIVE := [
	[[2.5,5.0],[0.0,1.0],[-3.0,0.8],[-2.8,6.6],[0.0,6.4],[3.2,5.9]],
	[[3.0,6.4],[3.2,0.8],[1.2,0.7],[-2.8,5.0],[-2.6,6.8],[1.2,2.1]],
	[[0.0,6.6],[3.0,6.4],[3.0,0.8],[-2.2,5.0],[-3.6,0.8],[-3.5,2.3]],
	[[-2.8,6.6],[0.0,6.4],[3.5,5.9],[2.5,5.0],[0.0,1.0],[-3.0,0.8]],
	[[-2.8,5.0],[-2.6,6.8],[0.6,4.1],[3.0,6.4],[3.2,0.8],[1.2,0.7]],
	[[-2.2,5.0],[-3.6,0.8],[-3.5,4.2],[0.0,6.6],[3.0,6.4],[1.8,0.8]]
]

static func receive(index: int, rotation: int) -> Vector3:
	var p: Array=RECEIVE[posmod(rotation,6)][index%6]
	return Vector3(p[0],0,p[1])

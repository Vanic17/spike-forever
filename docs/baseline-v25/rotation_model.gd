extends RefCounted
## Regulatory identity never depends on the avatar's current coordinates.
const ROLES := ["OH1","MB1","OPP","OH2","MB2","S"]
const INITIAL_SLOTS := [2,1,0,5,4,3]
const ZONES := [4,3,2,1,6,5]

static func slot(index: int, rotation: int) -> int:
	return posmod(INITIAL_SLOTS[index%6]+rotation,6)

static func front(index: int, rotation: int) -> bool:
	return slot(index,rotation)<3

static func libero(index: int, rotation: int, serving: bool) -> bool:
	return ROLES[index%6].begins_with("MB") and not front(index,rotation) and not (serving and slot(index,rotation)==3)

static func state(index: int, rotation: int, serving: bool) -> Dictionary:
	var team:=int(index/6)
	var replaced:=libero(index,rotation,serving)
	var starter: String="T"+str(team)+":"+ROLES[index%6]
	return {"starter_id":starter,"player_id":"T"+str(team)+":L" if replaced else starter,
		"role":"L" if replaced else ROLES[index%6],"rotation_slot":ZONES[slot(index,rotation)],
		"is_front_row":front(index,rotation),"is_on_court":true,"is_libero":replaced,
		"replaces_player_id":starter if replaced else "","is_server":serving and slot(index,rotation)==3}

static func receiving_checks(by_zone: Dictionary, feet: Dictionary, team: int, tolerance: float=0.015) -> Array:
	# Compare each side player with both teammates in its row, plus the
	# three front/back pairs. Foot overlap is not a transitive centre ordering.
	# Foot regions may overlap; unlike centre ordering, this accepts legal stacks.
	var result: Array=[]
	for pair in [[4,3],[3,2],[4,2],[5,6],[6,1],[5,1]]:
		var a:=bounds(feet[by_zone[pair[0]]],team)
		var b:=bounds(feet[by_zone[pair[1]]],team)
		result.append({"zones":pair,"axis":"width","legal":a[0]<=b[1]+tolerance})
	for pair in [[4,5],[3,6],[2,1]]:
		var a:=bounds(feet[by_zone[pair[0]]],team)
		var b:=bounds(feet[by_zone[pair[1]]],team)
		result.append({"zones":pair,"axis":"depth","legal":b[3]+tolerance>=a[2]})
	return result

static func bounds(points: Array, team: int) -> Array[float]:
	var side:=1.0 if team==0 else -1.0
	var result: Array[float]=[INF,-INF,INF,-INF]
	for point in points:
		result[0]=minf(result[0],point.x*side)
		result[1]=maxf(result[1],point.x*side)
		result[2]=minf(result[2],point.z*side)
		result[3]=maxf(result[3],point.z*side)
	return result

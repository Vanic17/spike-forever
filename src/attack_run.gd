extends RefCounted
## Physical opening and curved approach for the front-row pins.
const Tactics = preload("res://src/tactics.gd")
var cue := ""
var runner := -1
var corner := Vector3.ZERO
var goal := Vector3.ZERO
var planted := false
var start := Vector3.ZERO
var landings: Dictionary={}

func reset() -> void:
	cue=""; runner=-1; planted=false
	landings.clear()

static func is_pin(game, index: int, direction: int) -> bool:
	return index>=0 and direction in [0,2] and Tactics.front(index,game.rotations[game.possession])

static func opening(game, index: int, stance: Vector3) -> Vector3:
	var side := 1.0 if game.possession==0 else -1.0
	var wing := Tactics.wing_for(game,index)
	var depth := 2.0 if game.planned_fast else 3.25
	return Vector3(side*wing*5.05,0,side*maxf(3.8,stance.z*side+depth))

func target(game, index: int, contact_stance: Vector3) -> Vector3:
	var back_row: bool=index>=0 and not Tactics.front(index,game.rotations[game.possession]) and game.destination in [2,3]
	if game.hitter_action!="attack" or not (is_pin(game,index,game.destination) or back_row):
		cue=""; runner=-1; planted=false
		return contact_stance
	var key := str(game.shot_serial)+":"+str(index)
	if key!=cue:
		cue=key; runner=index; goal=contact_stance; start=game.players[index].position; planted=false
		var side := 1.0 if index<6 else -1.0
		var wing := signf(contact_stance.x)
		corner=contact_stance+Vector3(wing*0.30,0,side*0.95)
		# A hitter who has already passed the penultimate step must not reverse.
		planted=start.z*side<=corner.z*side+0.12
	if game.players[index].position.distance_to(corner)<0.32 or game.flight_left<0.32: planted=true
	return goal if planted else corner

func remaining(index: int, position: Vector3, ordinary: float) -> float:
	if runner!=index or planted: return ordinary
	return position.distance_to(corner)+corner.distance_to(goal)

func finish(game, index: int) -> void:
	if game.hitter_action!="attack" or game.destination==1: return
	var side:=1.0 if index<6 else -1.0
	var p=game.players[index]
	var back:=not Tactics.front(index,game.rotations[int(index/6)])
	var point: Vector3=p.position+Vector3(0,0,-side*(0.75 if back else 0.45))
	point.z=side*maxf(0.42,point.z*side)
	landings[index]={"target":point,"until":game.clock_time+minf(0.65,p.contact_recovery_remaining())}

func landing(index: int, clock: float) -> bool:
	if not landings.has(index): return false
	if clock>=landings[index].until: landings.erase(index); return false
	return true

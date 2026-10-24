extends RefCounted
## Physical opening and curved approach for the front-row pins.
const Tactics = preload("res://src/tactics.gd")
var cue := ""
var runner := -1
var corner := Vector3.ZERO
var goal := Vector3.ZERO
var planted := false
var start := Vector3.ZERO

func reset() -> void:
	cue=""; runner=-1; planted=false

static func is_pin(game, index: int, direction: int) -> bool:
	return index>=0 and direction in [0,2] and Tactics.front(index,game.rotations[game.possession])

static func opening(game, index: int, stance: Vector3) -> Vector3:
	var side := 1.0 if game.possession==0 else -1.0
	var wing := Tactics.wing_for(game,index)
	var depth := 2.0 if game.planned_fast else 3.25
	return Vector3(side*wing*5.05,0,side*maxf(3.8,stance.z*side+depth))

func target(game, index: int, contact_stance: Vector3) -> Vector3:
	if game.hitter_action!="attack" or not is_pin(game,index,game.destination):
		reset()
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

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
var airborne:=false
var air_start:=Vector3.ZERO
var air_target:=Vector3.ZERO
var air_duration:=0.0

func reset() -> void:
	cue=""; runner=-1; planted=false; airborne=false
	landings.clear()

static func is_pin(game, index: int, direction: int) -> bool:
	return index>=0 and direction in [0,2] and Tactics.front(index,game.rotations[game.possession])

static func opening(game, index: int, stance: Vector3) -> Vector3:
	var side := 1.0 if game.possession==0 else -1.0
	var wing := Tactics.wing_for(game,index)
	var depth := 1.35 if game.planned_fast else 2.0
	return Vector3(side*wing*5.05,0,side*maxf(3.5,stance.z*side+depth))

static func air_seconds(player) -> float:
	return player.attack_clock_seconds(player.clips.attack.contact_time-player.clips.attack.takeoff_time)

static func run_seconds(player, target: Vector3, speed: float) -> float:
	var delta: Vector3=target-player.position; delta.y=0
	var distance:=delta.length()
	if distance<.05: return 0.0
	var initial:=clampf(player.velocity.dot(delta.normalized()),0,speed)
	var accelerating: float=(speed*speed-initial*initial)/44.0
	if distance<=accelerating: return (sqrt(initial*initial+44.0*distance)-initial)/22.0
	return (speed-initial)/22.0+(distance-accelerating)/speed

static func takeoff_stance(game, index: int, contact: Vector3) -> Vector3:
	var side:=1.0 if index<6 else -1.0
	var back:=not Tactics.front(index,game.rotations[int(index/6)])
	var result:=contact+Vector3(0,0,side*(1.05 if back else 0.55))
	if back: result.z=side*maxf(3.18,result.z*side)
	return result

func flying(index: int) -> bool:
	return runner==index and airborne

func target(game, index: int, contact_stance: Vector3) -> Vector3:
	var back_row: bool=index>=0 and not Tactics.front(index,game.rotations[game.possession]) and game.destination in [2,3]
	if game.hitter_action!="attack" or not (is_pin(game,index,game.destination) or back_row):
		cue=""; runner=-1; planted=false; airborne=false
		return contact_stance
	var key := str(game.shot_serial)+":"+str(index)
	if key!=cue:
		cue=key; runner=index; goal=contact_stance; start=game.players[index].position; planted=false; airborne=false
		var side := 1.0 if index<6 else -1.0
		var wing := signf(contact_stance.x)
		corner=contact_stance+Vector3(wing*0.30,0,side*0.95)
		# A hitter who has already passed the penultimate step must not reverse.
		planted=start.z*side<=corner.z*side+0.12
	elif goal.distance_to(contact_stance)>0.03:
		# A wrist tip changes the interception height after the approach
		# was planned. Keep the runner attached to the new contact rather
		# than the cached spike endpoint; never restart a planted run-up.
		goal=contact_stance
		var side := 1.0 if index<6 else -1.0
		corner=contact_stance+Vector3(signf(contact_stance.x)*0.30,0,side*0.95)
	var launch:=takeoff_stance(game,index,goal)
	if not airborne and game.flight_left<=air_seconds(game.players[index]):
		airborne=true; air_start=game.players[index].position; air_duration=maxf(.001,game.flight_left)
	if airborne:
		air_target=air_start.lerp(goal,clampf(1.0-game.flight_left/air_duration,0,1))
		return air_target
	# A continuous run to the plant, without a second corner/braking stop.
	planted=true
	return launch

func remaining(index: int, position: Vector3, ordinary: float) -> float:
	if runner!=index or planted: return ordinary
	return position.distance_to(corner)+corner.distance_to(goal)

func finish(game, index: int) -> void:
	if runner==index: airborne=false
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

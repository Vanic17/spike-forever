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
var yielding: Dictionary={}

func reset() -> void:
	cue=""; runner=-1; planted=false; airborne=false
	landings.clear()
	yielding.clear()

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

static func emergency_contact(game, index: int, target: Vector3) -> Vector3:
	# A second-touch ground save may carry S sideways AFTER contact. A middle
	# set at the usual net lane can then land inside that recovery's body. Read
	# the source travel before launch and keep this emergency ball off the net;
	# ordinary standing sets and their first-tempo lanes remain unchanged.
	if game.out_of_system>=0 or not game.dive_motions.has(game.setter): return target
	var motion: Dictionary=game.dive_motions[game.setter]
	var setter=game.players[game.setter]
	var clip=setter.clips[motion.action]
	var basis:=Basis(Vector3.UP,motion.yaw)
	var root_start: Vector3=setter.action_root_motion(motion.action,motion.start_time)
	var correction: Vector3=motion.stance-motion.origin-basis*(setter.action_root_motion(motion.action,clip.contact_time)-root_start)
	var forward:=Vector3(sin(motion.yaw),0,cos(motion.yaw))
	var bodies: Array[Vector3]=[]
	for future in [0.0,.2,.4,.6,.8,1.0,1.2,1.4,1.6]:
		var time: float=motion.source_time+future*1.15
		if time>clip.recovery_end-.25: break
		var point: Vector3=motion.origin+basis*(setter.action_root_motion(motion.action,time)-root_start)+correction
		bodies.append(point); bodies.append(point+forward*.9); bodies.append(point-forward*.6)
	var player=game.players[index]
	var stance: Vector3=player.stance_for_contact(game.hitter_action,target)
	var blocked:=false
	for body in bodies:
		if stance.distance_to(body)<1.15: blocked=true; break
	if not game.contact_navigation.segment_clear(player.position,stance,bodies,1.005): blocked=true
	if not blocked: return target
	var side:=1.0 if index<6 else -1.0
	var fallback:=target
	for shift in [.65,1.1,1.5,2.0,2.5]:
		var candidate:=target+Vector3(0,0,side*shift)
		if absf(candidate.z)>4.8: break
		var feet: Vector3=player.stance_for_contact(game.hitter_action,candidate)
		var free:=true
		for body in bodies:
			if feet.distance_to(body)<1.35: free=false; break
		if not free: continue
		# Future source samples reserve the destination. They must not pretend
		# the recovering body already occupies every future position at once:
		# a runner can leave that region before S's follow-through reaches it.
		if fallback==target and game.contact_navigation.segment_clear(player.position,feet,bodies.slice(0,3),1.005): fallback=candidate
		if not game.contact_navigation.segment_clear(player.position,feet,bodies,1.20): continue
		game.log_rally_event("emergency_attack_spacing",{"setter":game.setter,"hitter":index,"original":target,"target":candidate})
		return candidate
	if fallback!=target:
		game.log_rally_event("emergency_attack_spacing",{"setter":game.setter,"hitter":index,"original":target,"target":fallback})
		return fallback
	return target

func flying(index: int) -> bool:
	return runner==index and airborne

func target(game, index: int, contact_stance: Vector3) -> Vector3:
	if game.hitter_action=="attack" and game.destination==1 and game.out_of_system<0 and game.dive_motions.has(game.setter):
		# A high emergency ball to the middle needs a protected ground approach
		# too. His ordinary quick/feint controller is inactive off-system, so
		# otherwise no controller asks the nearby cover players to clear it.
		var emergency_key:=str(game.shot_serial)+":"+str(index)
		if cue!=emergency_key:
			cue=emergency_key; runner=index; start=game.players[index].position
			yielding.clear(); airborne=false; planted=true
		goal=contact_stance
		corner=goal
		return contact_stance
	var back_row: bool=index>=0 and not Tactics.front(index,game.rotations[game.possession]) and game.destination in [2,3]
	if game.hitter_action!="attack" or not (is_pin(game,index,game.destination) or back_row):
		cue=""; runner=-1; planted=false; airborne=false
		return contact_stance
	var key := str(game.shot_serial)+":"+str(index)
	if key!=cue:
		cue=key; runner=index; goal=contact_stance; start=game.players[index].position; planted=false; airborne=false
		yielding.clear()
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

func clear_lane(game, targets: Array[Vector3], index: int) -> void:
	if runner!=index: return
	var direction:=goal-start; direction.y=0
	if direction.length()<.1: return
	direction=direction.normalized()
	var normal:=Vector3(direction.z,0,-direction.x)
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other==index or game.middle_decoy.holds(other): continue
		if game.phase in ["SET","CPU_SET"] and (other==game.setter or game.court_shape.setter_yields.has(other)): continue
		if game.dive_motions.has(other): continue
		if yielding.has(other):
			var cached: Vector3=yielding[other]
			if Geometry3D.get_closest_point_to_segment(cached,start,goal).distance_to(cached)>=1.35:
				targets[other]=cached
				continue
			yielding.erase(other)
		var p: Vector3=game.players[other].position
		var nearest:=Geometry3D.get_closest_point_to_segment(p,start,goal)
		var target_nearest:=Geometry3D.get_closest_point_to_segment(targets[other],start,goal)
		if p.distance_to(nearest)>1.35 and targets[other].distance_to(target_nearest)>1.35: continue
		var offset: float=(p-nearest).dot(normal)
		if absf(offset)<.1: offset=(targets[other]-target_nearest).dot(normal)
		if absf(offset)<.1: offset=1 if other%2==0 else -1
		var free:=nearest+normal*signf(offset)*1.5
		free.x=clampf(free.x,-5.45,5.45)
		free.z=(1 if index<6 else -1)*clampf(absf(free.z),.45,9.8)
		# Net/sideline clamping can move an otherwise clear sidestep BACK
		# into the final contact footprint. Recheck after bounds, especially
		# the middle landing next to a right-pin/pipe attack.
		if Geometry3D.get_closest_point_to_segment(free,start,goal).distance_to(free)<1.35:
			var away:=free-goal; away.y=0
			if away.length()<.1: away=normal*signf(offset)
			free=goal+away.normalized()*1.55
			free.x=clampf(free.x,-5.45,5.45)
			free.z=(1 if index<6 else -1)*clampf(absf(free.z),.45,9.8)
		yielding[other]=free; targets[other]=free

func prepare_pipe(game, targets: Array[Vector3]) -> void:
	var index: int=game.planned_hitter
	if index<0: return
	var key:="pre:"+str(game.shot_serial)+":"+str(index)
	if cue!=key:
		cue=key; runner=index; start=game.players[index].position; yielding.clear(); airborne=false
	var contact: Vector3=preload("res://src/rally_ai.gd").attack_contact(game,3,index,game.flight_target)
	contact.y=game.players[index].contact_local("attack").y
	goal=game.players[index].stance_for_contact("attack",contact)
	clear_lane(game,targets,index)

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

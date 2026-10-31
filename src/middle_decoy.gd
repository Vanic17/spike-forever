extends RefCounted
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
const PERFORMANCE:="attack_v26_01"
const QUICK_DELAY:=0.16
const NORMAL_DELAY:=0.17
var index:=-1
var team:=-1
var cue:=""
var target:=Vector3.ZERO
var jump_at:=0.0
var finish_at:=0.0
var jumped:=false
var source_time:=0.0
var motion_origin:=Vector3.ZERO
var motion_yaw:=0.0
var source_begin:=0.0
var events: Array[Dictionary]=[]
var real_attack:=false
var real_started:=false
var prepared:=false
var waypoint:=Vector3.ZERO
var has_waypoint:=false
var route_at:=-1.0
var route_clear:=false
var approach_goal:=Vector3.ZERO
var late_recipient:=-1

func reset() -> void:
	index=-1
	team=-1
	cue=""
	jumped=false
	real_attack=false
	real_started=false
	prepared=false
	has_waypoint=false; route_at=-1.0
	route_clear=false
	late_recipient=-1

func obstacles(game) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for other in range(team*6,team*6+6):
		if other!=index: result.append_array(game.compute_footprint_points(other))
	if game.phase in ["SET","CPU_SET"] and game.out_of_system>=0 and game.setter!=index:
		# The live setter and his still-reserved contact spot remain obstacles
		# when a curved middle approach replaces an obsolete straight yield.
		var setter=game.players[game.setter]
		var contact: Vector3=setter.stance_for_contact(game.second_touch_contact_action(),game.flight_target)
		var steps:=maxi(1,ceili(setter.position.distance_to(contact)/.4))
		for sample in range(1,steps+1): result.append(setter.position.lerp(contact,float(sample)/steps))
	return result

func clear_segment(game, start: Vector3, finish: Vector3) -> bool:
	return clear_points(start,finish,obstacles(game))

func clear_points(start: Vector3, finish: Vector3, bodies: Array[Vector3]) -> bool:
	for body in bodies:
		if start.distance_to(body)<1.025:
			if (start-body).dot(finish-start)<-.0001: return false
			continue
		if Geometry3D.get_closest_point_to_segment(body,start,finish).distance_to(body)<1.025: return false
	return true

func route(game, goal: Vector3) -> Vector3:
	var start: Vector3=game.players[index].position
	approach_goal=goal
	var bodies:=obstacles(game)
	route_clear=false
	if clear_points(start,goal,bodies): has_waypoint=false; route_clear=true; return goal
	if has_waypoint and start.distance_to(waypoint)>.20 and clear_points(start,waypoint,bodies): route_clear=true; return waypoint
	route_at=game.clock_time+.12; has_waypoint=false
	var best:=INF
	for body in bodies:
		if Geometry3D.get_closest_point_to_segment(body,start,goal).distance_to(body)>1.1: continue
		for step in 8:
			var angle:=step*PI/4
			var candidate:=body+Vector3(cos(angle)*1.45,0,sin(angle)*1.45)
			# Cross behind the setting lane while opening for a quick. The
			# shortest geometric corner used to run along the net, then send
			# the middle back into S on the next step.
			if candidate.z*(1 if team==0 else -1)<2.35: continue
			if start.distance_to(candidate)<.25 or not clear_points(start,candidate,bodies): continue
			# Two adjacent teammates can form a barrier requiring two corners.
			# Requiring a clear second leg too returned the blocked straight line.
			var cost:=start.distance_to(candidate)+candidate.distance_to(goal)+(0.0 if clear_points(candidate,goal,bodies) else 2.0)
			if cost<best: best=cost; waypoint=candidate; has_waypoint=true
	route_clear=has_waypoint
	return waypoint if has_waypoint else goal

func preparation_route(game, assigned: Vector3) -> Vector3:
	var preferred:=target if game.phase in ["RECEIVE","CPU_RECEIVE"] else assigned
	var release_yield:=false
	if game.phase in ["SET","CPU_SET"] and game.court_shape.setter_yields.has(index) and game.out_of_system>=0:
		# A bent route that clears the entire REMAINING setter approach can
		# start now. Waiting for S to finish his run consumed the quick's run-up.
		preferred=target
		if real_attack:
			var side:=1.0 if team==0 else -1.0
			var staging:=Vector3(target.x,0,side*maxf(2.35,target.z*side+.95))
			preferred=staging.lerp(target,1.0-smoothstep(.32,1.05,game.flight_left))
		release_yield=true
	var next:=route(game,preferred)
	# A blocked ideal is not a valid replacement for the teammate's yielding
	# assignment. Keep S's priority until a genuinely clear corner exists.
	if release_yield and not route_clear:
		approach_goal=assigned
		return assigned
	if release_yield and route_clear: game.court_shape.setter_yields.erase(index)
	return next

func update(game) -> void:
	if game.phase in ["RECEIVE","CPU_RECEIVE"]:
		var pre_cue: String="pre:"+str(game.possession)+":"+str(game.shot_serial)
		if pre_cue!=cue: reset(); cue=pre_cue
		team=game.possession
		var candidate:=Tactics.attacker(team,game.rotations[team],1,team*6+5)
		if candidate==game.receiver or game.dive_motions.has(candidate): index=-1; return
		index=candidate
		if index>=0:
			# Reception is aimed at zone 3 (x=0), not at the setter's
			# service waiting position. Open on the front-quick side of
			# that expected pass before its exact final offset is known.
			# Prepare the expected zone-3 first tempo before the set choice;
			# the actual first/7 input then commits its existing contact lane.
			var expected: Vector3=AI.attack_contact(game,1,index,Tactics.world(team,0,1.5))
			target=Tactics.world(team,expected.x*(1 if team==0 else -1),2.35)
		return
	if jumped and game.phase in ["SET","CPU_SET"] and game.planned_hitter==index:
		if late_recipient==index: return
		var player=game.players[index]
		if source_time>=player.clips.attack.contact_time-.025:
			# The feint has already passed its hitting instant. Do not rewind
			# a descending/recovering jumper into a second first-tempo takeoff.
			late_recipient=index
			return
		# A changed set choice transfers ownership to the actual attack clock.
		# Never keep a real recipient locked inside a no-contact fake.
		jumped=false; prepared=false; real_started=true
	if game.phase in ["SET","CPU_SET"]:
		var next: String=str(game.possession)+":"+str(game.shot_serial)
		if next!=cue:
			reset()
			cue=next
	if jumped:
		if game.clock_time>=finish_at:
			index=-1
		return
	if game.phase not in ["SET","CPU_SET"]: return
	# Depth and actual recoverability govern the threat. A percentage gate
	# wrongly cancelled first-tempo preparation on ordinary playable passes.
	if game.out_of_system<0 or absf(game.flight_target.z)>=2.85 or game.planned_hitter<0 or game.setter_dump:
		index=-1
		return
	team=game.possession
	var middle:=Tactics.attacker(team,game.rotations[team],1,game.setter)
	if middle<0 or game.dive_motions.has(middle):
		index=-1
		return
	index=middle
	var next_real: bool=middle==game.planned_hitter
	if next_real!=real_attack: prepared=false
	real_attack=next_real
	var point:=AI.attack_contact(game,1,middle,game.flight_target)
	point.y=game.contact_height("attack")
	target=game.players[index].stance_for_contact("attack",point)
	if real_attack:
		prepared=true
		return
	# Use a real one-arm quick attack, not the two-handed decoy pose.
	# Its hypothetical hit is 160ms after the setter: the plant and
	# takeoff therefore happen BEFORE the setter touches the pass.
	var clip=game.clips[PERFORMANCE]
	if not prepared: source_begin=.03; prepared=true
	var side:=1.0 if team==0 else -1.0
	var root: Vector3=point-Basis(Vector3.UP,PI if team==0 else 0.0)*clip.contact_offset
	root.y=0
	var staging:=Vector3(root.x,0,side*maxf(2.35,root.z*side+.95))
	target=staging.lerp(root,1.0-smoothstep(.32,1.05,game.flight_left))
	var preparation: float=(clip.contact_time-source_begin)/1.15
	jump_at=game.clock_time+game.flight_left+QUICK_DELAY-preparation

func prepare_real(game, dt: float) -> void:
	if index<0 or not real_attack or game.phase not in ["SET","CPU_SET"]: return
	if game.possession==0 and not game.armed and game.human_team(0): return
	var player=game.players[index]
	var point: Vector3=AI.attack_contact(game,1,index,game.flight_target)
	point.y=player.contact_local("attack").y
	var stance: Vector3=player.stance_for_contact("attack",point)
	var delay:=QUICK_DELAY if game.planned_fast else NORMAL_DELAY
	var remaining: float=maxf(0,game.flight_left-dt)+delay
	if remaining>player.preparation_lead("attack",1): return
	# Do not launch a jump that would require crossing another athlete in air.
	# The ordinary high-ball construction remains available when far away.
	if not real_started and (player.position.distance_to(stance)>.55 or not clear_segment(game,player.position,stance)): return
	var fresh:=not real_started
	real_started=true
	if not fresh and player.clip_name=="attack" and player.animation_time>=player.clips.attack.takeoff_time:
		remaining=minf(remaining,player.attack_clock_seconds(maxf(0,player.clips.attack.contact_time-player.animation_time)))
	player.prepare_contact("attack",remaining)
	if fresh:
		player.blend_duration=.11; player.blend_left=minf(player.blend_left,.11)
	player.reach_action="attack"; player.reach_weight=0

func release_seconds(game, player_index: int, stance: Vector3) -> float:
	if not real_started or index!=player_index or not real_attack: return -1.0
	var player=game.players[index]
	var distance: float=player.position.distance_to(stance)
	if distance>.75 or not clear_segment(game,player.position,stance): return -1.0
	var remaining: float=player.attack_clock_seconds(maxf(0,player.clips.attack.contact_time-player.animation_time))
	# A nearby root can still be braking in the wrong direction after a
	# crossing. Test its existing acceleration/arrival law before committing
	# the short shared flight; distance alone released unreachable quicks.
	if not preload("res://src/setter_access.gd").grounded_arrival(game,index,stance,remaining,game.Reference.run_speed()*1.10,distance): return -1.0
	# The same source clock crosses SET -> ATTACK, with no restart at release.
	return remaining

func committed_contact(game, player_index: int, proposed: Vector3) -> Vector3:
	if not real_started or not real_attack or index!=player_index: return proposed
	var player=game.players[index]
	if player.clip_name!="attack" or player.animation_time<player.clips.attack.takeoff_time: return proposed
	# Once airborne, set to the already committed jumper's actual contact
	# stance. Replanning a new ideal across S could reject the short clock,
	# choose a long high-ball flight and rewind the same jump to frame zero.
	var remaining: float=player.attack_clock_seconds(maxf(0,player.clips.attack.contact_time-player.animation_time))
	if remaining<.025 or remaining>.55: return proposed
	var point: Vector3=player.position+Basis(Vector3.UP,player.rotation.y)*player.contact_local("attack")
	return point if point.distance_to(proposed)<2.0 else proposed

func recovery_contact(game) -> Vector3:
	var player=game.players[late_recipient]
	var clip=player.clips.attack
	var landing: Vector3=motion_origin+Basis(Vector3.UP,motion_yaw)*(clip.root_motion(clip.recovery_end+.12)-clip.root_motion(source_begin))
	landing.z=maxf(.40,landing.z) if team==0 else minf(-.40,landing.z)
	return landing+Basis(Vector3.UP,PI if team==0 else 0.0)*player.contact_local("receive")

func holds(player: int) -> bool:
	return index==player and jumped

func try_jump(game) -> void:
	if index<0 or real_attack or jumped or game.clock_time<jump_at: return
	if game.phase not in ["SET","CPU_SET","ATTACK","CPU_ATTACK"] or game.possession!=team: return
	# A blocked approach must return to coverage, never launch a stale fake
	# beside a pin who is already hitting the ball.
	if game.phase in ["ATTACK","CPU_ATTACK"] or game.flight_left<0.035:
		index=-1
		return
	if game.planned_hitter==index: index=-1; return
	# The first-tempo threat is read from the pass, not from the user's
	# eventual confirmation of the set. A feint cannot touch the ball.
	var player=game.players[index]
	if player.position.distance_to(target)>0.55: return
	if player.clip_name=="block" and player.clips.has("block") and not player.looping and player.animation_time<player.clips.block.recovery_end: return
	player.select_variant("attack",PERFORMANCE)
	player.play("attack",1.15,false)
	player.contact_scheduled=true
	player.reach_weight=0
	player.acceleration=Vector3.ZERO
	player.rotation.y=PI if team==0 else 0.0
	motion_yaw=player.rotation.y
	motion_origin=player.position
	source_time=maxf(source_begin,player.clips.attack.contact_time-(game.flight_left+QUICK_DELAY)*1.15)
	# A slightly late plant starts on the current shared clock. Root travel
	# and recovery must use that same source frame, not the nominal prefix.
	source_begin=source_time
	player.animation_time=source_time
	if source_begin>0:
		player.blend_duration=0.12; player.blend_left=minf(player.blend_left,0.12)
	target=player.position
	jumped=true
	finish_at=game.clock_time+((player.clips.attack.recovery_end+0.12-source_begin)/1.15 if player.clips.has("attack") else 0.9)
	events.append({"player":index,"team":team,"rotation":game.rotations[team],"quality":game.pass_quality,"time":game.clock_time,"apex_at":game.clock_time+((player.clips.attack.contact_time-source_begin)/1.15 if player.clips.has("attack") else 0.45),"shot":game.shot_serial,"compact":source_begin>0})
	game.log_rally_event("middle_decoy",events[-1])
	if events.size()>512: events.pop_front()

func advance_body(game, dt: float) -> void:
	var player=game.players[index]
	if not player.clips.has("attack"): return
	var clip=player.clips.attack
	source_time=minf(clip.recovery_end+0.12,source_time+dt*1.15)
	var previous: Vector3=player.position
	var destination: Vector3=motion_origin+Basis(Vector3.UP,motion_yaw)*(clip.root_motion(source_time)-clip.root_motion(source_begin))
	destination.z=maxf(0.40,destination.z) if team==0 else minf(-0.40,destination.z)
	player.position+=game.collision_safe_step(index,destination-player.position)
	player.velocity=(player.position-previous)/maxf(0.00001,dt)
	player.acceleration=Vector3.ZERO
	player.rotation.y=motion_yaw
	player.target=player.position
	player.animation_time=source_time
	player.contact_scheduled=true
	game.travel[index]+=player.position.distance_to(previous)

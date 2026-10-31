extends RefCounted
const Approach=preload("res://src/approach_planner.gd")
static func contact_offsets(player, action: String, yaw: float) -> Array[Vector3]:
	var offsets: Array[Vector3]=[Vector3.ZERO]
	# Reserve the platform that will exist once the forearm pose starts, not
	# merely the idle root that happened to be visible during pass planning.
	if action=="receive":
		var platform: Vector3=Basis(Vector3.UP,yaw)*player.contact_local(action); platform.y=0
		offsets.append(platform*.4)
	return offsets

static func arrival_seconds(game, index: int, stance: Vector3, speed: float, known_route: float = -1.0) -> float:
	var player=game.players[index]
	var route: float=game.contact_navigation.length_for(game,index,stance) if known_route<0 else known_route
	if not is_finite(route): return INF
	return Approach.seconds(player,stance,speed)+maxf(0,route-player.position.distance_to(stance))/speed+game.player_recovery_seconds(index)

static func grounded_arrival(game, index: int, stance: Vector3, seconds: float, speed: float, known_route: float = -1.0) -> bool:
	# A grounded moving pass does not need the full stop + .38s jump plant
	# used by the overhead approach estimator. Forecast the existing steering,
	# acceleration and braking law instead of a distance/max-speed shortcut.
	var player=game.players[index]
	var route: float=game.contact_navigation.length_for(game,index,stance) if known_route<0 else known_route
	if not is_finite(route) or game.player_recovery_seconds(index)>0.10: return false
	var goal: Vector3=stance
	var direction: Vector3=stance-player.position; direction.y=0
	if direction.length()>.001: goal+=direction.normalized()*maxf(0,route-direction.length())
	var position: Vector3=player.position
	var velocity: Vector3=player.velocity
	var elapsed:=0.0
	while elapsed<seconds-.000001:
		var dt:=minf(1.0/120.0,seconds-elapsed)
		var remaining:=seconds-elapsed
		var movement:=goal-position; movement.y=0
		var pace:=minf(speed,movement.length()/maxf(.055,remaining-.12))
		pace=minf(pace,sqrt(44.0*movement.length())*.72)
		var desired: Vector3=movement.normalized()*pace if movement.length()>=.045 else Vector3.ZERO
		var acceleration: Vector3=((desired-velocity)/.055).limit_length(28.0)
		velocity=(velocity+acceleration*dt).limit_length(maxf(speed,velocity.length()))
		position+=velocity*dt
		elapsed+=dt
	return position.distance_to(goal)<=.14

static func current_contact_reachable(game, action: String, known_route: float = -1.0) -> bool:
	var player=game.players[game.setter]
	var stance: Vector3=player.stance_for_contact(action,game.flight_target)
	var yaw: float=player.setting_yaw if action in ["set","fast_set"] else (PI if game.possession==0 else 0.0)
	# Low-pose selection and one-hand rescue share one perception read. Reuse
	# its route/steering forecast at this exact state; any movement, pose or
	# deadline change invalidates it, including the post-movement contact check.
	var state: Array=[game.clock_time,game.phase,game.shot_serial,game.setter,action,game.flight_target,game.flight_left,player.position,player.velocity,player.rotation.y,yaw,player.variant_names.get(action,action)]
	for other in range(game.possession*6,game.possession*6+6):
		var p=game.players[other]
		state.append([p.position,p.rotation.y,p.clip_name,p.animation_time])
	var key:=hash(state)
	var cached: Dictionary=game.get_meta("second_touch_arrival57",{})
	if cached.get("key",-1)==key: return cached.reachable
	var angle: float=absf(wrapf(yaw-player.rotation.y,-PI,PI))
	var reachable:=false
	if angle<=.08 or angle/7.0+.04<=game.flight_left:
		reachable=grounded_arrival(game,game.setter,stance,game.flight_left,game.Reference.run_speed()*1.10,known_route)
	game.set_meta("second_touch_arrival57",{"key":key,"reachable":reachable})
	return reachable
static func pass_seconds(game, point: Vector3, ordinary: float, contact_index: int = -1, action: String = "set") -> float:
	var index: int=game.Tactics.designated_setter(game,game.possession) if contact_index<0 else contact_index
	if index==game.receiver: return ordinary
	var player=game.players[index]
	var yaw: float=-PI/2 if game.possession==0 else PI/2
	var offset: Vector3=Basis(Vector3.UP,yaw if action in ["set","fast_set"] else (PI if game.possession==0 else 0.0))*player.contact_local(action)
	var stance:=Vector3(point.x-offset.x,0,point.z-offset.z)
	# Keep the initial specialist/backup choice unchanged. Once the actual
	# setter and performance are selected, a long route still needs the same
	# bounded arrival allowance as a short route, before the pass leaves hands.
	if contact_index<0 and player.position.distance_to(stance)>5.26: return ordinary
	var landing:=0.0
	if player.clip_name=="block" and not player.looping:
		landing=maxf(0,(player.clips.block.recovery_end-player.animation_time)/player.animation_speed)
	# A first pass can be lifted while the setter lands and plants. Plan this
	# before launch: never pause the ball or stretch a flight already underway.
	var speed: float=game.Reference.run_speed()*1.10
	var route_length: float=game.contact_navigation.length_for(game,index,stance)
	var detour: float=maxf(0,route_length-player.position.distance_to(stance)) if is_finite(route_length) else 0.0
	var arrival:=Approach.seconds(player,stance,speed)+detour/speed+landing
	return maxf(ordinary,minf(ordinary+0.85,arrival))

static func clear_target(game, point: Vector3, contact_index: int = -1, action: String = "set") -> Vector3:
	var bodies: Dictionary=game.court_shape.recovering_bodies(game)
	var team: int=game.possession
	var actor: int=game.Tactics.designated_setter(game,team) if contact_index<0 else contact_index
	bodies.erase(actor)
	# Standing passers and landing blockers also occupy the contact footprint.
	# Reserve a free endpoint before launch, rather than asking the setter to
	# finish inside them and hoping their support movement clears in time.
	for index in range(team*6,team*6+6):
		if index==actor or bodies.has(index): continue
		bodies[index]=game.compute_footprint_points(index)
	var player=game.players[actor]
	var yaw: float=-PI/2 if team==0 else PI/2
	var contact_yaw: float=yaw if action in ["set","fast_set"] else (PI if team==0 else 0.0)
	var offset: Vector3=Basis(Vector3.UP,contact_yaw)*player.contact_local(action)
	var footprint:=contact_offsets(player,action,contact_yaw)
	var best:=point
	var score:=INF
	for radius in [0.0,0.65,1.1,1.5,2.0,2.5]:
		for step in (1 if radius==0 else 12):
			var candidate: Vector3=point+Vector3(cos(step*TAU/12),0,sin(step*TAU/12))*radius
			if absf(candidate.x)>5.0 or candidate.z*(1 if team==0 else -1)<0.65: continue
			var stance:=Vector3(candidate.x-offset.x,0,candidate.z-offset.z)
			var free:=true
			for body in bodies:
				if int(body/6)!=team: continue
				for sample in bodies[body]:
					for foot in footprint:
						if (stance+foot).distance_to(sample)<1.12: free=false
			if not free: continue
			# Prefer a reachable contact on this side of a fallen passer.
			var blocked:=false
			for body in bodies:
				if int(body/6)!=team: continue
				for foot in footprint:
					if not game.court_shape.clear_recovery_route(player.position+foot,stance+foot,bodies[body],1.05): blocked=true
			var cost: float=radius*3.0+player.position.distance_to(stance)*0.1+(12.0 if blocked else 0.0)
			if cost<score: score=cost; best=candidate
	return best

static func try_low_contact(game) -> bool:
	if game.setter_action=="dive" and game.dive_motions.has(game.setter): return false
	if game.setter_dump or game.flight_left>0.70 or game.ball_pos.y<0.8: return false
	if game.clock_time<game.next_second_touch_read: return false
	game.next_second_touch_read=game.clock_time+0.12
	var player=game.players[game.setter]
	var overhead: String="receive" if game.out_of_system<0 else ("fast_set" if game.fast_set else "set")
	var stance: Vector3=player.stance_for_contact(overhead,game.flight_target)
	var distance: float=game.contact_navigation.length_for(game,game.setter,stance)
	var speed: float=game.Reference.run_speed()*1.10
	var arrival:=arrival_seconds(game,game.setter,stance,speed,distance)
	if current_contact_reachable(game,overhead,distance): return false
	if arrival<=maxf(.025,game.flight_left-.025): return false
	# Intercept the SAME flight at forearm height. No relaunch, teleport or
	# timing forgiveness: the hands must still physically meet the ball.
	var intercept: Dictionary={}
	var low_stance:=Vector3.ZERO
	var low_distance:=INF
	var selected:=""
	var yaw: float=PI if game.possession==0 else 0.0
	for variant in ["receive_step","receive_low","receive_squat"]:
		if not player.source_clips.has(variant): continue
		var offset: Vector3=player.source_clips[variant].contact_offset
		var candidate: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,offset.y,game.flight_gravity)
		if candidate.is_empty() or candidate.seconds<=game.flight_left+.06 or candidate.seconds>1.2: continue
		var side:=1.0 if game.possession==0 else -1.0
		if candidate.point.z*side<.15: continue # The same flight would already have crossed the net.
		var local_stance: Vector3=candidate.point-Basis(Vector3.UP,yaw)*offset; local_stance.y=0
		if local_stance.z*side<.25 or absf(local_stance.x)>7 or absf(local_stance.z)>11.5: continue
		var route: float=game.contact_navigation.length_for(game,game.setter,local_stance)
		var turn: float=absf(wrapf(yaw-player.rotation.y,-PI,PI))/7.0
		if turn+.04>candidate.seconds or not grounded_arrival(game,game.setter,local_stance,candidate.seconds,speed,route): continue
		var footprint_free:=true
		var platform: Vector3=Basis(Vector3.UP,yaw)*offset; platform.y=0
		for other in range(game.possession*6,game.possession*6+6):
			if other==game.setter: continue
			for sample in game.compute_footprint_points(other):
				if local_stance.distance_to(sample)<1.025 or (local_stance+platform*.4).distance_to(sample)<1.025: footprint_free=false
		if not footprint_free: continue
		intercept=candidate; low_stance=local_stance; selected=variant
		low_distance=route
		break
	if selected.is_empty(): return false
	player.select_variant("receive",selected)
	game.out_of_system=-1
	game.setter_action="receive"
	game.fast_set=false; game.planned_fast=false
	game.flight_target=intercept.point; game.flight_left=intercept.seconds
	game.contact_navigation.reset()
	game.log_rally_event("second_touch_forearm",{"setter":game.setter,"remaining":intercept.seconds,"overhead_distance":distance,"forearm_distance":low_distance})
	return true

static func sync_performance(game) -> void:
	# Direction/quick choices can replace a PSA performance after the pass was
	# launched. Its hands need not be at the previous performance's height.
	# Intercept the existing flight; never rewrite its velocity or spin.
	if game.phase not in ["SET","CPU_SET"] or not game.airborne: return
	if game.setter_action=="dive" and game.dive_motions.has(game.setter): return
	var action: String="dump" if game.setter_dump else ("receive" if game.out_of_system<0 else ("fast_set" if game.fast_set else "set"))
	var player=game.players[game.setter]
	var height: float=player.contact_local(action).y
	if absf(height-game.flight_target.y)<0.003: return
	var contact: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,height,game.flight_gravity)
	if contact.is_empty() or contact.seconds<=0.001: return
	game.flight_target=contact.point; game.flight_left=contact.seconds
	game.setter_action=action
	game.contact_navigation.reset()

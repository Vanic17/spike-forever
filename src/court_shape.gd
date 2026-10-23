extends RefCounted
## One team plan per flight. Reserve the setter's space before choosing routes.
const Tactics = preload("res://src/tactics.gd")
const RallyAI = preload("res://src/rally_ai.gd")
var cue := ""
var bypass: Dictionary = {}
var lane_sides: Dictionary = {}
var target_corrections := 0
var setter_yields: Dictionary = {}
var setter_route_origin:=Vector3.ZERO
var recovery_bypass: Dictionary = {}
var pin_routes: Dictionary={}
var pin_team:=-1
var middle_sides: Dictionary={}

func reset() -> void:
	cue = ""
	bypass.clear()
	lane_sides.clear()
	setter_yields.clear()
	recovery_bypass.clear()
	pin_routes.clear()
	pin_team=-1
	middle_sides.clear()

func arrange(game, nominal: Array[Vector3], actor: int, action: String, blockers: Array) -> Array[Vector3]:
	var result: Array[Vector3] = nominal.duplicate()
	if game.phase in ["SERVE","POINT","LOOSE"]:
		reset()
		return result
	var floor_bodies := recovering_bodies(game)
	var key: String = game.phase+":"+str(game.shot_serial)+":"+str(actor)+":"+action+":"+str(game.planned_hitter if game.phase in ["SET","CPU_SET"] else -1)+":"+str(floor_bodies.keys())
	var fresh := key != cue
	if fresh:
		cue = key
		bypass.clear()
		lane_sides.clear()
		setter_yields.clear()
		recovery_bypass.clear()
		if actor>=0: setter_route_origin=game.players[actor].position
	# After a dig, front-row players must already be leaving their blocking
	# bases. Sending them to the net until SET caused the late mass retreat.
	if game.phase in ["RECEIVE","CPU_RECEIVE"]:
		var team: int = game.possession
		var side := 1.0 if team==0 else -1.0
		for i in range(team*6,team*6+6):
			if i==actor or not Tactics.front(i,game.rotations[team]): continue
			var role := Tactics.role(i,game.rotations[team],team==game.server)
			if role=="S": continue
			# The middle opens for his first-tempo steps while the serve is
			# already travelling; otherwise he has to retreat after the pass.
			var individual := float(posmod((i%6+1)*5+team*3,11))/10.0
			var readiness := smoothstep(0.025+individual*0.04,0.20+individual*0.10,game.phase_time)
			var preparation := Tactics.world(team,0.0,2.6)
			if role.begins_with("MB"): preparation=Tactics.world(team,0.0,1.95)
			if not role.begins_with("MB"):
				var wing := Tactics.wing_for(game,i)
				preparation = Tactics.world(team,wing*4.65,3.2)
			result[i] = result[i].lerp(preparation,readiness)
	# Read the already observed incoming flight, without guessing its next
	# recipient. Non-receivers keep their lanes and make bounded cover steps.
	if game.phase in ["RECEIVE","CPU_RECEIVE"] and game.incoming_kind!="serve":
		for i in range(game.possession*6,game.possession*6+6):
			if i==actor or i in blockers or Tactics.front(i,game.rotations[game.possession]): continue
			if Tactics.ROLES[i%6]=="S": continue
			var read := 1.0-smoothstep(0.20,0.85,game.flight_left)
			var offset: Vector3=game.flight_target-result[i]
			result[i]+=Vector3(clampf(offset.x*0.12,-0.28,0.28),0,clampf(offset.z*0.08,-0.20,0.20))*read
	# A short set may arrive before the ordinary opening-to-cover transition
	# finishes. Start closing the existing cover lanes while the hitter runs.
	if game.phase in ["ATTACK","CPU_ATTACK"]:
		var feint=game.get("middle_decoy")
		for i in range(game.possession*6,game.possession*6+6):
			if i==actor or (feint!=null and i==feint.index): continue
			var read := 1.0-smoothstep(0.08,0.35,game.flight_left)
			result[i]=result[i].lerp(RallyAI.coverage(game,i,game.possession),read)
	# Fix a libero's lane for this flight; crossing x=0 cannot reverse the
	# assignment from +1/depth6 to -1/depth7 in consecutive frames.
	for team in 2:
		for i in range(team*6,team*6+6):
			if i==actor or i in blockers: continue
			if game.phase in ["ATTACK","CPU_ATTACK"] and team!=game.possession and Tactics.front(i,game.rotations[team]):
				# The front-row player outside the chosen wall drops into tip
				# coverage, instead of crowding a third body into the net lane.
				# Only actual wall members stay at the net. Preserve the shared
				# coverage plan for every free front-row defender.
				result[i].z=(1.0 if team==0 else -1.0)*3.05
			if Tactics.role(i,game.rotations[team],team==game.server)=="L" and team==game.possession and game.phase in ["SET","CPU_SET"]:
				result[i] = Tactics.world(team,-2.6,6.25)
	# Reserve the entire setter approach, not only the final hand-contact spot.
	# A support player already at his own destination otherwise never yielded,
	# leaving the setter stopped against the body guard while his arms played.
	if actor>=0 and game.phase in ["SET","CPU_SET","ATTACK","CPU_ATTACK"]:
		var route: Vector3=result[actor]-setter_route_origin
		route.y=0
		# At the contact spot, endpoint separation is sufficient. Treating a
		# small pose/setting-yaw correction as a new penetration unnecessarily
		# sent the middle out of his first-tempo preparation lane.
		if route.length()>0.65 or game.phase in ["SET","CPU_SET"]:
			# A short pass at the setter's feet still needs a free contact
			# footprint. The old length gate skipped the passer in this case.
			var forward:=route.normalized() if route.length()>0.65 else Vector3(0,0,1 if game.possession==0 else -1)
			var normal:=Vector3(forward.z,0,-forward.x)
			for i in range(game.possession*6,game.possession*6+6):
				if i==actor: continue
				if game.phase in ["ATTACK","CPU_ATTACK"] and i!=game.setter: continue
				if floor_bodies.has(i): continue # A prone passer cannot sidestep out of the setter's way.
				# For a stationary setter reserve only an existing obstruction.
				# Re-scanning every frame would pull a middle preparing his quick
				# out of a lane that the team target separation already keeps clear.
				if route.length()<=0.65 and not fresh and not setter_yields.has(i): continue
				var jumping=game.get("middle_decoy")
				if jumping!=null and jumping.holds(i): continue
				var start: Vector3=game.players[i].position
				var nearest:=Geometry3D.get_closest_point_to_segment(start,setter_route_origin,result[actor])
				if not setter_yields.has(i) and start.distance_to(nearest)<(1.28 if route.length()>0.65 else 1.04):
					var offset: float=(start-nearest).dot(normal)
					if absf(offset)<0.08: offset=(result[i]-nearest).dot(normal)
					if absf(offset)<0.08: offset=-1.0 if i%2==0 else 1.0
					setter_yields[i]=nearest+normal*signf(offset)*1.42
				if setter_yields.has(i):
					var free: Vector3=setter_yields[i]
					free.x=clampf(free.x,-5.4,5.4)
					free.z=(1 if game.possession==0 else -1)*clampf(absf(free.z),0.5,9.8)
					# Yield ends once the real approach is clear. It is not a
					# replacement destination for the remainder of the pass.
					var remaining_nearest:=Geometry3D.get_closest_point_to_segment(start,game.players[actor].position,result[actor])
					if start.distance_to(remaining_nearest)>=1.30:
						setter_yields.erase(i)
					else: result[i]=free
	# Once selected, prepare the actual takeoff lane, not the generic wide
	# opening. This also avoids opening farther as the set is released.
	if game.phase in ["SET","CPU_SET"] and game.planned_hitter>=0:
		var runner: int=game.planned_hitter
		if not setter_yields.has(runner):
			var point:=RallyAI.attack_contact(game,game.planned_direction,runner,game.flight_target)
			point.y=game.contact_height("attack")
			var stance: Vector3=game.players[runner].stance_for_contact("attack",point)
			var run_depth:=0.20 if game.planned_direction==1 and game.fast_set else 0.65
			result[runner]=stance+Vector3(0,0,run_depth if game.possession==0 else -run_depth)
	# Assign destinations in priority order. Separation is solved for all six
	# targets together, before any athlete has moved in this physics tick.
	if game.phase in ["SET","CPU_SET"] and game.fast_set and game.planned_hitter>=0:
		var hitter: int=game.planned_hitter
		var direction=game.get("planned_direction")
		var contact:=RallyAI.attack_contact(game,int(direction) if direction!=null else game.destination,hitter,game.flight_target)
		var ready: Vector3=game.players[hitter].stance_for_contact("attack",contact)
		# A quick recipient already in his takeoff lane must not first retreat
		# to the full high-ball opening, then be declared late for the quick.
		if game.players[hitter].position.distance_to(ready)<1.5 and not setter_yields.has(hitter): result[hitter]=ready
	route_specialist_pins(game,result,actor,blockers)
	var order: Array[int] = []
	if actor>=0: order.append(actor)
	for i in blockers:
		if not i in order: order.append(i)
	var decoy_plan=game.get("middle_decoy")
	if decoy_plan!=null and decoy_plan.index>=0 and not decoy_plan.index in order: order.append(decoy_plan.index)
	if game.planned_hitter>=0 and game.phase in ["SET","CPU_SET"] and not game.planned_hitter in order: order.append(game.planned_hitter)
	for i in 12:
		if not i in order: order.append(i)
	var assigned: Array[int] = []
	for i in order:
		if i!=actor and not i in blockers:
			var team := int(i/6)
			var side := 1.0 if team==0 else -1.0
			var candidate := result[i]
			for iteration in 4:
				for other in assigned:
					if int(other/6)!=team: continue
					var clearance := 1.35 if other==actor and action in ["set","fast_set","dump","receive"] else 1.12
					var delta: Vector3 = candidate-result[other]
					delta.y=0
					if delta.length()>=clearance: continue
					if delta.length()<0.01:
						var base := Tactics.home(i,team,game.rotations[team],team==game.server,false)
						delta=Vector3(-1.0 if base.x-result[other].x<0 else 1.0,0,side*0.5)
					candidate = result[other]+delta.normalized()*clearance
					candidate.x=clampf(candidate.x,-5.45,5.45)
					candidate.z=side*clampf(candidate.z*side,0.45,9.8)
			if candidate.distance_to(result[i])>0.02: target_corrections+=1
			result[i]=candidate
		assigned.append(i)
	if actor<0: return result
	var actor_team := int(actor/6)
	var anchor := result[actor]
	for i in range(actor_team*6,actor_team*6+6):
		if i==actor or i in blockers: continue
		if floor_bodies.has(i): continue
		if setter_yields.has(i): continue
		if game.phase in ["SET","CPU_SET"] and i==game.planned_hitter: continue
		var decoy=game.get("middle_decoy")
		if decoy!=null and decoy.index==i:
			# Its first-tempo lane has already been separated from the setter's
			# endpoint above. A generic bypass would send the middle backwards
			# and turn the quick threat into a late jump far from the net.
			continue
		var start: Vector3 = game.players[i].position
		var destination := result[i]
		if fresh:
			var nearest := Geometry3D.get_closest_point_to_segment(anchor,start,destination)
			var near_route := nearest.distance_to(anchor)<1.25
			var near_actor := Geometry3D.get_closest_point_to_segment(start,game.players[actor].position,anchor).distance_to(start)<1.05
			if (near_route or near_actor) and start.distance_to(destination)>0.6:
				var side := 1.0 if actor_team==0 else -1.0
				var lateral := destination.x-anchor.x
				if absf(lateral)<0.25: lateral=start.x-anchor.x
				if absf(lateral)<0.1: lateral=-1.0 if i%6 in [0,1,3,4] else 1.0
				lane_sides[i]=signf(lateral)
				var depth := maxf(anchor.z*side+0.85,minf(start.z*side,destination.z*side))
				var waypoint := Vector3(anchor.x+signf(lateral)*maxf(1.6,minf(absf(destination.x-anchor.x),3.6)),0,side*depth)
				if game.phase in ["RECEIVE","CPU_RECEIVE"] and Tactics.ROLES[i%6]=="S":
					# Clear the passer sideways first. A diagonal shortcut from
					# behind the passer could push the setter into his back and
					# leave a perfect reception to an emergency middle setter.
					var passer_x: float=game.players[actor].position.x
					# Leave on the side the setter actually occupies. Choosing by
					# his eventual destination sent him THROUGH the right passer.
					if absf(start.x-passer_x)>0.2: lateral=signf(start.x-passer_x)
					waypoint.x=maxf(passer_x,anchor.x)+1.45 if lateral>0 else minf(passer_x,anchor.x)-1.45
					waypoint.z=start.z
				waypoint.x=clampf(waypoint.x,-5.45,5.45)
				for other in bypass:
					if waypoint.distance_to(bypass[other])<1.1:
						waypoint.x=clampf(waypoint.x+signf(lateral)*1.15,-5.45,5.45)
						if waypoint.distance_to(bypass[other])<1.1: waypoint.z+=side*1.15
				bypass[i]=waypoint
		if bypass.has(i):
			var waypoint: Vector3 = bypass[i]
			if start.distance_to(waypoint)<0.32 or start.distance_to(destination)<0.4:
				bypass.erase(i)
			else:
				# A route corner is a passing point, not a place to plant both feet.
				# Round it only after clearing the contact corridor; body collision
				# checks still guard every actual step in main.gd.
				var lead := (destination-waypoint).limit_length(0.65)*smoothstep(1.1,0.32,start.distance_to(waypoint))
				var rounded := waypoint+lead
				var closest := Geometry3D.get_closest_point_to_segment(anchor,start,rounded)
				result[i]=rounded if closest.distance_to(anchor)>=1.35 else waypoint
	# Body volume matters during the transition from dig to set. Reserve it
	# before the setter reaches the collision guard; never ask the prone libero
	# to clear a lane or displace the scheduled ball-contact endpoint itself.
	for i in range(actor_team*6,actor_team*6+6):
		if i in blockers or floor_bodies.has(i): continue
		result[i] = route_around_recovery(game,i,result[i],floor_bodies)
	return result

func route_specialist_pins(game, result: Array[Vector3], actor: int, blockers: Array) -> void:
	if game.possession!=pin_team:
		pin_routes.clear()
		pin_team=game.possession
	if game.phase not in ["RECEIVE","CPU_RECEIVE","SET","CPU_SET"]:
		pin_routes.clear()
		return
	var team: int=game.possession
	var side:=1.0 if team==0 else -1.0
	for i in range(team*6,team*6+6):
		if i==actor or i in blockers: continue
		# Contact priority beats the specialist's opening/crossing assignment.
		if setter_yields.has(i): continue
		var wing:=Tactics.wing_for(game,i)
		if is_zero_approx(wing): continue
		var start: Vector3=game.players[i].position
		if not pin_routes.has(i) and start.x*side*wing< -0.6:
			# OH crosses behind the passers; OPP uses the shallower 4.4m lane.
			# Neither cuts through the setter/first-tempo takeoff corridor.
			pin_routes[i]={"stage":0,"x":start.x,"depth":maxf(start.z*side,6.0 if wing<0 else 4.4)}
		if not pin_routes.has(i): continue
		var route: Dictionary=pin_routes[i]
		if route.stage==0:
			if absf(start.z*side-float(route.depth))<0.22: route.stage=1
			else:
				result[i]=Vector3(route.x,0,side*route.depth)
				continue
		if route.stage==1:
			if absf(start.x-result[i].x)<0.25: route.stage=2
			else: result[i].z=side*route.depth
		if route.stage==2: pin_routes.erase(i)

func recovering_bodies(game) -> Dictionary:
	var result: Dictionary = {}
	var motions=game.get("dive_motions")
	if not motions is Dictionary: return result
	for index in motions:
		var player=game.players[index]
		var motion: Dictionary=motions[index]
		var clip=player.clips[motion.action]
		if motion.source_time<clip.contact_time-0.12 or motion.source_time>clip.recovery_end-0.25: continue
		var forward:=Vector3(sin(player.rotation.y),0,cos(player.rotation.y))
		result[index]=[player.position,player.position+forward*0.9,player.position-forward*0.6]
	return result

func clear_recovery_route(start: Vector3, destination: Vector3, points: Array, clearance: float) -> bool:
	for point in points:
		if Geometry3D.get_closest_point_to_segment(point,start,destination).distance_to(point)<clearance: return false
	return true

func route_around_recovery(game, index: int, destination: Vector3, bodies: Dictionary) -> Vector3:
	var start: Vector3=game.players[index].position
	var team:=int(index/6)
	# A route belongs to one live body, never to a former recovery obstacle.
	if recovery_bypass.has(index) and not bodies.has(recovery_bypass[index].body):
		recovery_bypass.erase(index)
		bypass.erase(index)
	for body in bodies:
		if int(body/6)!=team or body==index: continue
		var points: Array=bodies[body]
		if recovery_bypass.has(index) and recovery_bypass[index].body!=body:
			recovery_bypass.erase(index)
		if clear_recovery_route(start,destination,points,1.005):
			if recovery_bypass.has(index) and recovery_bypass[index].body==body:
				recovery_bypass.erase(index)
				bypass.erase(index)
			continue
		if not recovery_bypass.has(index):
			var forward: Vector3=(destination-start).normalized()
			if forward.length()<0.1: continue
			var normal:=Vector3(forward.z,0,-forward.x)
			var centre: Vector3=points[0]
			var offset: float=(start-centre).dot(normal)
			if absf(offset)<0.15: offset=(destination-centre).dot(normal)
			var side:=signf(offset) if absf(offset)>0.15 else (-1.0 if index%2==0 else 1.0)
			var span:=0.0
			for point in points: span=maxf(span,absf((point-centre).dot(normal)))
			# Begin the sidestep before the torso, rather than steering directly
			# at a waypoint abeam of it and clipping the near shoulder on approach.
			var waypoint:=centre-forward*0.8+normal*side*(span+1.30)
			waypoint.x=clampf(waypoint.x,-6.3,6.3)
			waypoint.z=(1.0 if team==0 else -1.0)*clampf(absf(waypoint.z),0.5,10.5)
			recovery_bypass[index]={"body":body,"waypoint":waypoint,"forward":forward,"normal":normal,"side":side,"span":span,"stage":0}
		var route: Dictionary=recovery_bypass[index]
		if start.distance_to(route.waypoint)<0.35 and route.stage==0:
			route.stage=1
			route.waypoint=points[0]+route.forward*1.1+route.normal*float(route.side)*(float(route.span)+1.30)
		bypass[index]=route.waypoint
		# Round the second corner as soon as the contact corridor becomes
		# visible. Running all the way to a square corner leaves too much lateral
		# momentum and forces a last-second reversal away from the ball.
		if route.stage==1:
			for step in range(10,0,-1):
				var rounded: Vector3=route.waypoint.lerp(destination,float(step)/10.0)
				if clear_recovery_route(start,rounded,points,1.005): return rounded
		return route.waypoint
	return destination

extends RefCounted
## One team plan per flight. Reserve the setter's space before choosing routes.
const Tactics = preload("res://src/tactics.gd")
var cue := ""
var bypass: Dictionary = {}
var lane_sides: Dictionary = {}
var target_corrections := 0

func reset() -> void:
	cue = ""
	bypass.clear()
	lane_sides.clear()

func arrange(game, nominal: Array[Vector3], actor: int, action: String, blockers: Array) -> Array[Vector3]:
	var result: Array[Vector3] = nominal.duplicate()
	if game.phase in ["SERVE","POINT","LOOSE"]:
		reset()
		return result
	var key: String = game.phase+":"+str(game.shot_serial)+":"+str(game.planned_hitter if game.phase in ["SET","CPU_SET"] else -1)
	var fresh := key != cue
	if fresh:
		cue = key
		bypass.clear()
		lane_sides.clear()
	# After a dig, front-row players must already be leaving their blocking
	# bases. Sending them to the net until SET caused the late mass retreat.
	if game.phase in ["RECEIVE","CPU_RECEIVE"] and game.incoming_kind!="serve":
		var team: int = game.possession
		var side := 1.0 if team==0 else -1.0
		var readiness := smoothstep(0.04,0.24,game.phase_time)
		for i in range(team*6,team*6+6):
			if i==actor or not Tactics.front(i,game.rotations[team]): continue
			var role := Tactics.role(i,game.rotations[team],team==game.server)
			if role=="S": continue
			var preparation := Tactics.world(team,0.0,2.6)
			if not role.begins_with("MB"):
				preparation = Tactics.world(team,-4.65 if role.begins_with("OH") else 4.65,3.2)
			result[i] = result[i].lerp(preparation,readiness)
	# Fix a libero's lane for this flight; crossing x=0 cannot reverse the
	# assignment from +1/depth6 to -1/depth7 in consecutive frames.
	for team in 2:
		for i in range(team*6,team*6+6):
			if i==actor or i in blockers: continue
			if game.phase in ["ATTACK","CPU_ATTACK"] and team!=game.possession and Tactics.front(i,game.rotations[team]):
				# The front-row player outside the chosen wall drops into tip
				# coverage, instead of crowding a third body into the net lane.
				result[i].z=(1.0 if team==0 else -1.0)*2.7
			if Tactics.role(i,game.rotations[team],team==game.server)=="L" and team==game.possession and game.phase in ["SET","CPU_SET"]:
				result[i] = Tactics.world(team,-2.6,6.25)
	# Assign destinations in priority order. Separation is solved for all six
	# targets together, before any athlete has moved in this physics tick.
	var order: Array[int] = []
	if actor>=0: order.append(actor)
	for i in blockers:
		if not i in order: order.append(i)
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
			else: result[i]=waypoint
	return result

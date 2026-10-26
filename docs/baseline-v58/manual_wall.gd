extends RefCounted
const Tactics=preload("res://src/tactics.gd")
var left_joined:=false
var right_joined:=false
var jumped: Array[int]=[]
var routes: Dictionary={}
var helper_x:=0.0

func reset() -> void:
	left_joined=false
	right_joined=false
	jumped.clear()
	routes.clear()
	helper_x=0

func line(game) -> Array[int]:
	var team: int=game.wall_team()
	var plan=game.get("defensive_lanes")
	if plan!=null:
		var physical: Array[int]=plan.line(game,team)
		if physical.size()==3:
			if team==1: physical.reverse()
			return physical
	var middle:=-1
	var pins: Array[int]=[]
	for i in range(team*6,team*6+6):
		if not Tactics.front(i,game.rotations[team]): continue
		if Tactics.ROLES[i%6].begins_with("MB"): middle=i
		else: pins.append(i)
	pins.sort_custom(func(a,b): return Tactics.home(a,team,game.rotations[team],game.server==team,false).x*(1 if team==0 else -1)<Tactics.home(b,team,game.rotations[team],game.server==team,false).x*(1 if team==0 else -1))
	return [pins[0],middle,pins[1]]

func members(game) -> Array[int]:
	if not jumped.is_empty(): return jumped.duplicate()
	var row:=line(game)
	var result: Array[int]=[row[1]]
	var pin:=automatic_pin(game)
	if pin>=0: result.append(pin)
	if left_joined and not row[0] in result: result.append(row[0])
	if right_joined and not row[2] in result: result.append(row[2])
	return result

func attack_position(game) -> Vector3:
	if game.phase in ["ATTACK","CPU_ATTACK"]: return game.flight_target
	if game.phase in ["SET","CPU_SET"] and game.planned_hitter>=0:
		return preload("res://src/rally_ai.gd").attack_contact(game,game.planned_direction,game.planned_hitter,game.flight_target)
	return Vector3.ZERO

func automatic_pin(game) -> int:
	if game.phase not in ["SET","ATTACK","CPU_SET","CPU_ATTACK"]: return -1
	if game.phase in ["SET","CPU_SET"] and game.setter_dump: return -1
	if game.phase in ["ATTACK","CPU_ATTACK"] and game.hitter_action!="attack": return -1
	var point:=attack_position(game)*(1 if game.wall_team()==0 else -1)
	if absf(point.x)<1.5: return -1
	var row:=line(game)
	return row[0] if point.x<0 else row[2]

func pin_x(game) -> float:
	return clampf(attack_position(game).x*(1 if game.wall_team()==0 else -1),-3.9,3.9)

func read(game, direction: Vector2, dt: float) -> void:
	if game.network_match(): game.block_helper_x=helper_x
	if not jumped.is_empty():
		var airborne:=false
		for index in jumped:
			var player=game.players[index]
			if player.clip_name=="block" and not player.looping and player.animation_time<player.clips.block.recovery_end: airborne=true
		if not airborne:
			for index in jumped: game.block_jumps.erase(index)
			jumped.clear(); game.block_commanded=false
	# Release the previous attack's selection after every jumper has landed.
	if not jumped.is_empty() and not game.block_commanded:
		jumped.clear()
	if jumped.is_empty():
		left_joined=game.wall_strength("block_left")>0.35
		right_joined=game.wall_strength("block_right")>0.35
		var minimum:=-4.12+(Tactics.BLOCK_SPACE if left_joined else 0.0)
		var maximum:=4.12-(Tactics.BLOCK_SPACE if right_joined else 0.0)
		var pin:=automatic_pin(game)
		var row:=line(game)
		if pin==row[0] and not left_joined: minimum=maxf(minimum,pin_x(game)+Tactics.BLOCK_SPACE)
		if pin==row[2] and not right_joined: maximum=minf(maximum,pin_x(game)-Tactics.BLOCK_SPACE)
		game.block_helper_x=clampf(game.block_helper_x+direction.x*3.8*dt,minimum,maximum)
	game.selected=line(game)[1]
	game.block_count=members(game).size()
	if game.network_match(): helper_x=game.block_helper_x

func target(game,index: int) -> Vector3:
	var row:=line(game)
	if index==automatic_pin(game) and not (left_joined if index==row[0] else right_joined):
		return Tactics.world(game.wall_team(),pin_x(game),0.68)
	var x: float=helper_x if game.network_match() else game.block_helper_x
	if index==row[0]: x-=Tactics.BLOCK_SPACE
	if index==row[2]: x+=Tactics.BLOCK_SPACE
	return Tactics.world(game.wall_team(),x,0.68)

func waiting(game,index: int) -> Vector3:
	var row:=line(game)
	var center: float=helper_x if game.network_match() else game.block_helper_x
	var x: float=minf(-3.4,center-1.35) if index==row[0] else maxf(3.4,center+1.35)
	if game.phase in ["ATTACK","CPU_ATTACK"] and absf(game.flight_target.x)>1.5:
		var far_pin: int=row[0] if game.flight_target.x*(1 if game.wall_team()==0 else -1)>0 else row[2]
		if index==far_pin and not index in members(game): return Tactics.world(game.wall_team(),-3.0 if index==row[0] else 3.0,3.15)
	return Tactics.world(game.wall_team(),clampf(x,-5.4,5.4),0.68)

func route(game,index: int,destination: Vector3) -> Vector3:
	var side:=1 if game.wall_team()==0 else -1
	return local_route(game,index,destination*side)*side

func local_route(game,index: int,destination: Vector3) -> Vector3:
	var row:=line(game)
	if index==row[1] or not jumped.is_empty(): return destination
	var side:=1 if game.wall_team()==0 else -1
	var p: Vector3=game.players[index].position*side
	var middle: Vector3=game.players[row[1]].position*side
	if index==automatic_pin(game) and absf(p.x-destination.x)<0.7 and p.z<1.2: return destination
	var left:=index==row[0]
	var wrong_side:=p.x>middle.x-0.75 if left else p.x<middle.x+0.75
	# Once role order has been established, close along the net. Cached
	# crossing lanes must not drag an already ordered pin backwards again.
	var clear: bool=Geometry3D.get_closest_point_to_segment(middle,p,destination).distance_to(middle)>=1.02
	if not wrong_side and clear:
		routes.erase(index)
		return destination
	if not routes.has(index) and wrong_side and absf(p.x-destination.x)>1.0:
		# Rotation stacks may put the opposite on the left of the middle.
		# Establish role order BEFORE closing: two different rear corridors
		# prevent pins crossing each other or trying to pass inside the net.
		routes[index]={"stage":0,"depth":2.9 if left else 1.75,"start_x":p.x}
	if not routes.has(index): return destination
	var lane: Dictionary=routes[index]
	if lane.stage==0:
		if absf(p.z-float(lane.depth))<0.16: lane.stage=1
		else: return Vector3(lane.start_x,0,lane.depth)
	if lane.stage==1:
		if absf(p.x-destination.x)<0.18: lane.stage=2
		else: return Vector3(destination.x,0,lane.depth)
	if p.distance_to(destination)<0.15: routes.erase(index)
	return destination

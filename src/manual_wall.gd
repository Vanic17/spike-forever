extends RefCounted
const Tactics=preload("res://src/tactics.gd")
var left_joined:=false
var right_joined:=false
var jumped: Array[int]=[]
var routes: Dictionary={}

func reset() -> void:
	left_joined=false
	right_joined=false
	jumped.clear()
	routes.clear()

func line(game) -> Array[int]:
	var plan=game.get("defensive_lanes")
	if plan!=null:
		var physical: Array[int]=plan.line(game,0)
		if physical.size()==3: return physical
	var middle:=-1
	var pins: Array[int]=[]
	for i in 6:
		if not Tactics.front(i,game.rotations[0]): continue
		if Tactics.ROLES[i].begins_with("MB"): middle=i
		else: pins.append(i)
	pins.sort_custom(func(a,b): return Tactics.home(a,0,game.rotations[0],game.server==0,false).x<Tactics.home(b,0,game.rotations[0],game.server==0,false).x)
	return [pins[0],middle,pins[1]]

func members(game) -> Array[int]:
	if not jumped.is_empty(): return jumped.duplicate()
	var row:=line(game)
	var result: Array[int]=[row[1]]
	if left_joined: result.append(row[0])
	if right_joined: result.append(row[2])
	return result

func read(game, direction: Vector2, dt: float) -> void:
	if jumped.is_empty():
		left_joined=Input.get_action_strength("block_left")>0.35
		right_joined=Input.get_action_strength("block_right")>0.35
		var minimum:=-4.12+(Tactics.BLOCK_SPACE if left_joined else 0.0)
		var maximum:=4.12-(Tactics.BLOCK_SPACE if right_joined else 0.0)
		game.block_helper_x=clampf(game.block_helper_x+direction.x*3.8*dt,minimum,maximum)
	game.selected=line(game)[1]
	game.block_count=members(game).size()

func target(game,index: int) -> Vector3:
	var row:=line(game)
	var x: float=game.block_helper_x
	if index==row[0]: x-=Tactics.BLOCK_SPACE
	if index==row[2]: x+=Tactics.BLOCK_SPACE
	return Vector3(x,0,0.68)

func waiting(game,index: int) -> Vector3:
	var row:=line(game)
	var x: float=minf(-3.4,game.block_helper_x-1.35) if index==row[0] else maxf(3.4,game.block_helper_x+1.35)
	return Vector3(clampf(x,-5.4,5.4),0,0.68)

func route(game,index: int,destination: Vector3) -> Vector3:
	var row:=line(game)
	if index==row[1] or not jumped.is_empty(): return destination
	var p: Vector3=game.players[index].position
	var middle: Vector3=game.players[row[1]].position
	var left:=index==row[0]
	var wrong_side:=p.x>middle.x-0.75 if left else p.x<middle.x+0.75
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

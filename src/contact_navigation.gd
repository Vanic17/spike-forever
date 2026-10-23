extends RefCounted
## Short, deterministic routes for the athlete who must contact the ball.
## Movement and the final collision sweep remain owned by main.gd.
const CELL := 0.25
const CLEARANCE := 1.025
const X_MIN := -7.0
const Z_MIN := 0.25
const WIDTH := 57
const DEPTH := 48
var routes: Dictionary = {}

func reset() -> void:
	routes.clear()

func samples(game, index: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var origin: Vector3 = game.players[index].position
	var offsets: Array[Vector3] = []
	for point in game.compute_footprint_points(index):
		offsets.append(point-origin)
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other==index: continue
		for point in game.compute_footprint_points(other):
			for offset in offsets:
				var obstacle: Vector3 = point-offset
				obstacle.y=0
				result.append(obstacle)
	return result

func segment_clear(start: Vector3, goal: Vector3, obstacles: Array[Vector3], clearance: float = CLEARANCE) -> bool:
	var delta := goal-start
	delta.y=0
	for obstacle in obstacles:
		var relative := start-obstacle
		relative.y=0
		# An existing overlap must be allowed to escape, without moving farther
		# into the body. The actual swept collision guard enforces this too.
		if relative.length()<clearance:
			if relative.dot(delta)<-0.00001: return false
			continue
		if Geometry3D.get_closest_point_to_segment(obstacle,start,goal).distance_to(obstacle)<clearance: return false
	return true

func world(cell: Vector2i, side: float) -> Vector3:
	return Vector3(X_MIN+cell.x*CELL,0,side*(Z_MIN+cell.y*CELL))

func cell_for(point: Vector3, side: float) -> Vector2i:
	return Vector2i(clampi(roundi((point.x-X_MIN)/CELL),0,WIDTH-1),clampi(roundi((point.z*side-Z_MIN)/CELL),0,DEPTH-1))

func nearest_visible(grid: AStarGrid2D, point: Vector3, side: float, obstacles: Array[Vector3]) -> Vector2i:
	var centre := cell_for(point,side)
	var best := Vector2i(-1,-1)
	var distance := INF
	for dx in range(-5,6):
		for dz in range(-5,6):
			var cell := centre+Vector2i(dx,dz)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell): continue
			var candidate := world(cell,side)
			var gap := point.distance_squared_to(candidate)
			if gap>=distance: continue
			if segment_clear(point,candidate,obstacles): best=cell; distance=gap
	return best

func forecast_samples(game, index: int, obstacles: Array[Vector3]) -> Array[Vector3]:
	var result: Array[Vector3]=obstacles.duplicate()
	var motions=game.get("dive_motions")
	if not motions is Dictionary or motions.is_empty(): return result
	var origin: Vector3=game.players[index].position
	var offsets: Array[Vector3]=[]
	for point in game.compute_footprint_points(index): offsets.append(point-origin)
	for other in motions:
		if other==index or int(other/6)!=int(index/6): continue
		var player=game.players[other]
		var motion: Dictionary=motions[other]
		var clip=player.clips[motion.action]
		var basis:=Basis(Vector3.UP,motion.yaw)
		var root_start: Vector3=player.action_root_motion(motion.action,motion.start_time)
		var contact_delta: Vector3=basis*(player.action_root_motion(motion.action,clip.contact_time)-root_start)
		var correction: Vector3=motion.stance-motion.origin-contact_delta
		for future in [0.06,0.12,0.18]:
			var time: float=minf(clip.duration,motion.source_time+future*1.15)
			var progress: float=clampf((motion.elapsed+future)/maxf(0.001,motion.duration),0,1)
			var destination: Vector3=motion.origin+basis*(player.action_root_motion(motion.action,time)-root_start)+correction*smoothstep(0,1,progress)
			destination.z=maxf(0.25,destination.z) if other<6 else minf(-0.25,destination.z)
			var delta: Vector3=(destination-player.position).limit_length(1.0)
			delta.y=0
			for point in game.compute_footprint_points(other):
				for offset in offsets:
					var sample: Vector3=point+delta-offset
					sample.y=0
					result.append(sample)
	return result

func build(game, index: int, destination: Vector3, obstacles: Array[Vector3]) -> Dictionary:
	var start: Vector3=game.players[index].position
	var side := 1.0 if index<6 else -1.0
	var grid := AStarGrid2D.new()
	grid.region=Rect2i(0,0,WIDTH,DEPTH)
	grid.cell_size=Vector2(CELL,CELL)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var planning_obstacles:=forecast_samples(game,index,obstacles)
	for obstacle in planning_obstacles:
		var centre := cell_for(obstacle,side)
		for dx in range(-5,6):
			for dz in range(-5,6):
				var cell := centre+Vector2i(dx,dz)
				if grid.is_in_boundsv(cell) and world(cell,side).distance_to(obstacle)<CLEARANCE+0.04:
					grid.set_point_solid(cell)
	var from := nearest_visible(grid,start,side,planning_obstacles)
	var to := nearest_visible(grid,destination,side,obstacles)
	var path: Array[Vector3]=[]
	# A final endpoint inside a body is not made reachable by snapping it to
	# the grid. Endpoint selection must reserve a genuine contact footprint.
	var endpoint_free := true
	for obstacle in obstacles:
		if destination.distance_to(obstacle)<CLEARANCE: endpoint_free=false
	if from.x>=0 and to.x>=0 and endpoint_free:
		var cells := grid.get_id_path(from,to)
		for cell in cells: path.append(world(cell,side))
		if not path.is_empty(): path.append(destination)
	return {"path":path,"goal":destination,"shot":game.shot_serial,"phase":game.phase,"time":game.clock_time,"distance":INF}

func route(game, index: int, destination: Vector3) -> Vector3:
	var start: Vector3=game.players[index].position
	var obstacles := samples(game,index)
	if segment_clear(start,destination,obstacles):
		routes.erase(index)
		return destination
	var stale := not routes.has(index)
	if not stale:
		var cached: Dictionary=routes[index]
		stale=cached.shot!=game.shot_serial or cached.phase!=game.phase or cached.goal.distance_to(destination)>0.12 or game.clock_time-cached.time>=0.12
	if stale: routes[index]=build(game,index,destination,obstacles)
	var entry: Dictionary=routes[index]
	var path: Array[Vector3]=entry.path
	if path.is_empty(): return start
	# Every shortcut is checked against every live footprint, including the
	# final leg past a fallen player. No corner permits cutting through a body.
	var next := -1
	for point_index in range(path.size()-1,-1,-1):
		if segment_clear(start,path[point_index],obstacles): next=point_index; break
	if next<0:
		# A recovering player can move across every remaining cached corner.
		# Repair promptly, with a strict budget rather than waiting 0.12s or
		# rebuilding the grid at the physics frequency.
		if game.clock_time-entry.time<0.03: return start
		routes[index]=build(game,index,destination,obstacles)
		entry=routes[index]
		path=entry.path
		for point_index in range(path.size()-1,-1,-1):
			if segment_clear(start,path[point_index],obstacles): next=point_index; break
		if next<0: return start
	if next>0: path=path.slice(next); entry.path=path
	return path[0]

func length_for(game, index: int, destination: Vector3) -> float:
	var start: Vector3=game.players[index].position
	var obstacles := samples(game,index)
	if segment_clear(start,destination,obstacles): return start.distance_to(destination)
	var entry := build(game,index,destination,obstacles)
	var path: Array[Vector3]=entry.path
	if path.is_empty(): return INF
	var length := 0.0
	var cursor := start
	var next := 0
	while next<path.size():
		var visible := next
		for j in range(path.size()-1,next-1,-1):
			if segment_clear(cursor,path[j],obstacles): visible=j; break
		if not segment_clear(cursor,path[visible],obstacles): return INF
		length+=cursor.distance_to(path[visible])
		cursor=path[visible]
		next=visible+1
	return length

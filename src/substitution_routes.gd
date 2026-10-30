extends RefCounted
## Presentation-only clearance map. No changes to tactical navigation.
const CELL:=.25
var circles: Array[Vector3]=[]
var rectangles: Array[Rect2]=[]
var grid: AStarGrid2D
func configure(game,index: int,bench_slot: int,side: int) -> void:
	circles.clear()
	rectangles=[Rect2(-7.05,-1.10,2.0,2.20),Rect2(-8.75,-2.55,1.95,5.10),Rect2(-5.7,-.55,11.4,1.10)]
	for i in game.players.size():
		if i!=index: circles.append(Vector3(game.players[i].position.x,game.players[i].position.z,.59))
	var benches=game.arena_visuals.get_node("TeamBenches")
	for entry in benches.actors:
		if entry.team==side and entry.slot==bench_slot: continue
		if not entry.actor.visible: continue
		var rig: Skeleton3D=entry.actor.skeleton
		var at: Vector3=rig.to_global(rig.get_bone_global_pose(rig.find_bone("Hips")).origin)
		circles.append(Vector3(at.x+(.18 if not entry.coach else 0),at.z,.66 if entry.coach else .48))
	grid=AStarGrid2D.new(); grid.region=Rect2i(-34,-68,57,137); grid.cell_size=Vector2.ONE*CELL
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; grid.update()
	for x in range(-34,23):
		for y in range(-68,69):
			if not clear_point(Vector2(x,y)*CELL): grid.set_point_solid(Vector2i(x,y),true)
func clear_point(point: Vector2,extra: Variant=null) -> bool:
	for area in rectangles:
		if area.has_point(point): return false
	for circle in circles:
		if point.distance_to(Vector2(circle.x,circle.y))<circle.z: return false
	if extra is Vector3 and point.distance_to(Vector2(extra.x,extra.z))<.78: return false
	return true
func clear_segment(a: Vector3,b: Vector3,extra: Variant=null) -> bool:
	var samples:=maxi(1,ceili(a.distance_to(b)/.075))
	for i in samples+1:
		var point:=a.lerp(b,float(i)/samples)
		if not clear_point(Vector2(point.x,point.z),extra): return false
	return true
func route(from: Vector3,to: Vector3,extra: Variant=null) -> Array[Vector3]:
	var modified: Dictionary={}
	if extra is Vector3:
		var center:=Vector2i(roundi(extra.x/CELL),roundi(extra.z/CELL))
		for x in range(center.x-4,center.x+5):
			for y in range(center.y-4,center.y+5):
				var point:=Vector2i(x,y)
				if grid.region.has_point(point) and Vector2(x*CELL-extra.x,y*CELL-extra.z).length()<.78 and not grid.is_point_solid(point):
					modified[point]=false; grid.set_point_solid(point,true)
	var start:=Vector2i(roundi(from.x/CELL),roundi(from.z/CELL)); var finish:=Vector2i(roundi(to.x/CELL),roundi(to.z/CELL))
	if not grid.region.has_point(start) or not grid.region.has_point(finish):
		for point in modified: grid.set_point_solid(point,modified[point])
		return []
	for point in [start,finish]:
		if not modified.has(point): modified[point]=grid.is_point_solid(point)
	grid.set_point_solid(start,false); grid.set_point_solid(finish,false)
	var raw: PackedVector2Array=grid.get_point_path(start,finish)
	for point in modified: grid.set_point_solid(point,modified[point])
	if raw.is_empty(): return []
	var points: Array[Vector3]=[from]
	for point in raw: points.append(Vector3(point.x,0,point.y))
	points.append(to)
	var result: Array[Vector3]=[from]; var cursor:=0
	while cursor<points.size()-1:
		var next:=cursor+1
		for j in range(points.size()-1,cursor,-1):
			if clear_segment(points[cursor],points[j],extra): next=j; break
		if not clear_segment(points[cursor],points[next],extra): return []
		if points[next].distance_to(result[-1])>.005: result.append(points[next])
		cursor=next
	return result
static func length(path: Array) -> float:
	var result:=0.0
	for i in range(1,path.size()): result+=path[i-1].distance_to(path[i])
	return result
static func at_distance(path: Array,distance: float) -> Vector3:
	for i in range(1,path.size()):
		var segment: float=path[i-1].distance_to(path[i])
		if distance<=segment: return path[i-1].lerp(path[i],clampf(distance/maxf(.001,segment),0,1))
		distance-=segment
	return path[-1]
static func timed(path: Array,time: float,duration: float) -> Vector3:
	return at_distance(path,length(path)*smoothstep(0,1,clampf(time/duration,0,1)))
static func safe_delay(first: Array,first_time: float,second: Array,second_time: float) -> float:
	for trial in ceili(first_time*10)+11:
		var delay:=trial*.1; var safe:=true
		for frame in ceili(maxf(first_time,second_time+delay)*20)+1:
			var time:=frame*.05
			if timed(first,time,first_time).distance_to(timed(second,time-delay,second_time))<.75: safe=false; break
		if safe: return delay
	return first_time+.3

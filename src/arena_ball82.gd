extends Node
## Swept sphere/proxy contacts for scenery. It does not handle players on court,
## net, floor, scoring, or reachable volleyball contacts.
const CELL:=4.0
const RADIUS:=.105
var game
var grid: Dictionary={}
var shapes: Array=[]
var benches
var queries:=0
func _ready():call_deferred("build")
func add_bounds(box: AABB,kind: String,bounce: float):
	var expanded:=box.grow(RADIUS)
	var index:=shapes.size();shapes.append({"bounds":expanded,"kind":kind,"bounce":bounce})
	var first:=cell(expanded.position);var last:=cell(expanded.end)
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			for z in range(first.z,last.z+1):
				var key:=Vector3i(x,y,z)
				if not grid.has(key):grid[key]=[]
				grid[key].append(index)
func cell(point: Vector3) -> Vector3i:return Vector3i(floori(point.x/CELL),floori(point.y/CELL),floori(point.z/CELL))
func build():
	grid.clear();shapes.clear()
	var arena=game.arena_visuals;benches=arena.get_node_or_null("TeamBenches")
	for node in arena.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or node.skin!=null or node==game.ball:continue
		if benches!=null and benches.is_ancestor_of(node):continue
		var box: AABB=node.global_transform*node.mesh.get_aabb()
		if box.size.y<.05:continue
		if box.position.x<5.0 and box.end.x>-5.0 and box.position.z<9.6 and box.end.z>-9.6:continue
		add_bounds(box,"arredo",.42)
	for seat in arena.crowd_positions:
		add_bounds(AABB(seat+Vector3(-.26,.38,-.25),Vector3(.52,.85,.50)),"pubblico",.16)
	print("ARENA82 COLLIDERS ",shapes.size()," spatial cells ",grid.size())
static func ray_box(from: Vector3,to: Vector3,box: AABB) -> Dictionary:
	if box.has_point(from):return {}
	var direction:=to-from;var enter:=0.0;var leave:=1.0;var normal:=Vector3.ZERO
	for axis in 3:
		if absf(direction[axis])<.0000001:
			if from[axis]<box.position[axis] or from[axis]>box.end[axis]:return {}
			continue
		var near: float=(box.position[axis]-from[axis])/direction[axis]
		var far: float=(box.end[axis]-from[axis])/direction[axis]
		var sign_axis: float=-1 if direction[axis]>0 else 1
		if near>far:var swap:=near;near=far;far=swap
		if near>enter:enter=near;normal=Vector3.ZERO;normal[axis]=sign_axis
		leave=minf(leave,far)
		if enter>leave:return {}
	if enter<0 or enter>1 or normal==Vector3.ZERO:return {}
	return {"t":enter,"normal":normal}
func resolve(from: Vector3,to: Vector3,velocity: Vector3,dt: float) -> Dictionary:
	if maxf(absf(from.x),absf(to.x))<4.90 and maxf(absf(from.z),absf(to.z))<9.40:return {}
	queries+=1
	var region:=AABB(from,Vector3.ZERO).expand(to);var first:=cell(region.position);var last:=cell(region.end)
	var candidates: Dictionary={}
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			for z in range(first.z,last.z+1):
				for index in grid.get(Vector3i(x,y,z),[]):candidates[index]=shapes[index]
	var list: Array=candidates.values()
	if benches!=null and minf(from.x,to.x)<-5.7 and maxf(from.x,to.x)>-9.3:
		for entry in benches.actors:
			if entry.actor.visible:
				var p: Vector3=entry.actor.global_position
				list.append({"bounds":AABB(p+Vector3(-.30,.30,-.28),Vector3(.60,1.55 if entry.coach else 1.0,.56)).grow(RADIUS),"kind":"persona","bounce":.20})
		for actor in benches.officials:
			list.append({"bounds":AABB(actor.global_position+Vector3(-.28,.36,-.28),Vector3(.56,.95,.56)).grow(RADIUS),"kind":"segnapunti","bounce":.20})
	var best: Dictionary={};var earliest:=2.0
	for item in list:
		var hit:=ray_box(from,to,item.bounds)
		if hit.is_empty() or hit.t>=earliest:continue
		earliest=hit.t;best=hit;best.kind=item.kind;best.bounce=item.bounce
	if best.is_empty():return {}
	var normal: Vector3=best.normal
	var rebound: Vector3=velocity-normal*(1+float(best.bounce))*minf(0,velocity.dot(normal))
	var tail: float=dt*(1-float(best.t))
	return {"position":from.lerp(to,best.t)+normal*.003+rebound*tail,"velocity":rebound,"kind":best.kind,"normal":normal}

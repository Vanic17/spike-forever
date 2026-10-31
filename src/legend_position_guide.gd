extends Node3D
## Visual-only copy of the shared match AI target. Never evaluates tactics,
## ball trajectories, avatar poses, or player movement on its own.
const RADIUS := 0.39
const INNER_RADIUS := 0.36
const FLOOR_HEIGHT := 0.045 # Above painted sponsor decals, below shoes/ball.
const SEGMENTS := 64
var game
var ring: MeshInstance3D
var surface: StandardMaterial3D

func _ready() -> void:
	name="LegendPositionGuide"
	ring=MeshInstance3D.new(); ring.name="RecommendedCourtPosition"
	ring.mesh=make_ring()
	surface=StandardMaterial3D.new()
	surface.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.vertex_color_use_as_albedo=true
	surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	surface.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	surface.no_depth_test=false
	surface.render_priority=1
	ring.material_override=surface
	ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	visible=false

static func make_ring() -> ArrayMesh:
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var colors:=PackedColorArray()
	var band:=Color(.78,.94,1.0,.34)
	var centre:=Color(.78,.94,1.0,.055)
	for index in SEGMENTS:
		var angle:=TAU*float(index)/SEGMENTS
		var next_angle:=TAU*float(index+1)/SEGMENTS
		var inner_a:=Vector3(cos(angle)*INNER_RADIUS,0,sin(angle)*INNER_RADIUS)
		var inner_b:=Vector3(cos(next_angle)*INNER_RADIUS,0,sin(next_angle)*INNER_RADIUS)
		var outer_a:=Vector3(cos(angle)*RADIUS,0,sin(angle)*RADIUS)
		var outer_b:=Vector3(cos(next_angle)*RADIUS,0,sin(next_angle)*RADIUS)
		for vertex in [inner_a,outer_a,outer_b,inner_a,outer_b,inner_b]:
			vertices.append(vertex); normals.append(Vector3.UP); colors.append(band)
		for vertex in [Vector3.ZERO,inner_a,inner_b]:
			vertices.append(vertex); normals.append(Vector3.UP); colors.append(centre)
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_COLOR]=colors
	var result:=ArrayMesh.new(); result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _process(_dt: float) -> void: sync_from_game()

func sync_from_game() -> void:
	var target=live_target()
	visible=target is Vector3
	if not visible: return
	# AI targets can have contact height; this overlay always stays on court.
	global_position=Vector3(target.x,FLOOR_HEIGHT,target.z)

func live_target():
	if not is_instance_valid(game) or not bool(game.get("started")) or bool(game.get("paused")) or bool(game.get("match_finished")): return null
	if str(game.get("phase"))=="POINT": return null
	for field in ["replay","substitution_scene"]:
		var scene=game.get(field)
		if is_instance_valid(scene) and bool(scene.get("active")): return null
	var adapter=game.get("legend_match")
	if not is_instance_valid(adapter) or not bool(adapter.get("active")) or not bool(adapter.get("manual_available")): return null
	var target=adapter.get("recommended_position")
	return target if target is Vector3 and target.is_finite() else null

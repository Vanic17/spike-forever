extends MeshInstance3D
const Spec=preload("res://src/net_spec94.gd")
var elapsed:=10.0
var amplitude:=0.0
var material:=ShaderMaterial.new()
var hits: Array[Vector4]=[Vector4(0,2,0,10),Vector4(0,2,0,10),Vector4(0,2,0,10),Vector4(0,2,0,10)]
var cursor:=0
var detail:=-1
var cords: MeshInstance3D
var cord_material: ShaderMaterial
func _ready() -> void:
	name="FlexibleNet94"
	var plane:=PlaneMesh.new();plane.orientation=PlaneMesh.FACE_Z;plane.size=Vector2(Spec.WIDTH,Spec.DEPTH);mesh=plane
	position.y=Spec.TOP-Spec.DEPTH*.5
	material.shader=preload("res://src/net_surface85.gdshader");material_override=material;extra_cull_margin=.6
	build_cords()
	update_detail()
func build_cords():
	cords=MeshInstance3D.new();cords.name="ThreeDimensionalNetCords94";add_child(cords);cords.extra_cull_margin=.6
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for column in 96:
		var x: float=-Spec.WIDTH*.5+column*Spec.CELL
		cord(tool,Vector3(x,-.5,0),Vector3(x,.5,0),14)
	for row in 11:
		var y: float=-.5+row*Spec.CELL
		cord(tool,Vector3(-Spec.WIDTH*.5,y,.0015),Vector3(Spec.WIDTH*.5,y,.0015),95)
	tool.index();cords.mesh=tool.commit()
	cord_material=ShaderMaterial.new();var shader:=Shader.new()
	var code: String=preload("res://src/net_surface85.gdshader").code
	shader.code=code.left(code.find("void fragment()"))+"void fragment(){ ALBEDO=vec3(.022,.025,.030); ROUGHNESS=.78; SPECULAR=.20; }"
	cord_material.shader=shader;cords.material_override=cord_material
func cord(tool: SurfaceTool,from: Vector3,to: Vector3,segments: int):
	var axis: Vector3=(to-from).normalized();var first:=axis.cross(Vector3.FORWARD).normalized();var second:=axis.cross(first).normalized()
	for segment in segments:
		for side in 6:
			for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var t: float=float(segment+corner.x)/segments;var angle: float=float(side+corner.y)*TAU/6
				var normal:=first*cos(angle)+second*sin(angle);var point:=from.lerp(to,t)+normal*.0018
				tool.set_normal(normal);tool.set_uv(Vector2(point.x/Spec.WIDTH+.5,.5-point.y));tool.add_vertex(point)
func update_detail():
	var next: int=preload("res://src/visual_materials85.gd").detail
	if next==detail:return
	detail=next;mesh.subdivide_width=[48,95,190,190][clampi(detail,0,3)];mesh.subdivide_depth=[8,12,20,30][clampi(detail,0,3)]
	material.set_shader_parameter("visual_detail",float(detail))
	cords.visible=detail>=2;material.set_shader_parameter("geometry_cords",cords.visible)
func impact(point: Vector3,velocity: Vector3) -> void:
	elapsed=0;amplitude=clampf(absf(velocity.z)*.012,.025,.32)
	hits[cursor]=Vector4(point.x,point.y,amplitude*signf(velocity.z),0);cursor=posmod(cursor+1,4)
	for i in 4:
		material.set_shader_parameter("hit"+str(i),hits[i]);cord_material.set_shader_parameter("hit"+str(i),hits[i])
func _process(dt: float) -> void:
	elapsed+=dt;update_detail()
	for i in 4:
		hits[i].w=minf(10,hits[i].w+dt);material.set_shader_parameter("hit"+str(i),hits[i]);cord_material.set_shader_parameter("hit"+str(i),hits[i])
static func response(velocity: Vector3,height: float,point: Vector3=Vector3.ZERO) -> Vector3:
	var normal_speed:=absf(velocity.z);var result:=velocity
	if height>=Spec.TOP and normal_speed>4:
		var rim:=clampf((height-Spec.TOP)/Spec.BALL_RADIUS,0,1)
		result.z*=lerpf(.48,.60,rim);result.x*=.78;result.y=clampf(velocity.y*.28+rim*1.2,-1.8,2.0)
	else:
		# Absorb normal momentum; retain some tangential sliding motion.
		var restitution:=lerpf(.085,.14,clampf(normal_speed/35,0,1))
		result.z*=-restitution;result.x*=.73;result.x-=point.x/Spec.WIDTH*normal_speed*.025
		result.y=velocity.y*.58-normal_speed*.025
	if result.length()>velocity.length():result=result.limit_length(velocity.length())
	return result

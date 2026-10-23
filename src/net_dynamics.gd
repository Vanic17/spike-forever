extends MeshInstance3D
var elapsed:=10.0
var amplitude:=0.0
var material:=ShaderMaterial.new()
func _ready() -> void:
	var plane:=PlaneMesh.new(); plane.orientation=PlaneMesh.FACE_Z; plane.size=Vector2(10.4,1.0); plane.subdivide_width=80; plane.subdivide_depth=16; mesh=plane
	position.y=1.93
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode cull_disabled; uniform float elapsed=10.0; uniform float amplitude=0.0; uniform vec2 impact=vec2(0.0,2.0); void vertex(){ vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; float d=length((w.xy-impact)*vec2(0.75,1.5)); float pin=clamp((5.2-abs(w.x))*2.0,0.0,1.0); float wave=amplitude*exp(-elapsed*5.0)*exp(-d*d*1.3)*sin(elapsed*23.0-d*3.0)*pin; VERTEX+=(inverse(MODEL_MATRIX)*vec4(0.0,0.0,wave,0.0)).xyz; } void fragment(){ vec2 grid=fract(UV*vec2(85.0,12.0)); float line=max(step(grid.x,0.07),step(grid.y,0.07)); float tape=step(UV.y,0.045); ALBEDO=mix(vec3(0.07,0.11,0.14),vec3(0.92),tape); ALPHA=max(line,tape); ALPHA_SCISSOR_THRESHOLD=0.5; ROUGHNESS=0.85; }"
	material.shader=shader; material_override=material
func impact(point: Vector3, velocity: Vector3) -> void:
	elapsed=0; amplitude=clampf(absf(velocity.z)*0.015,0.035,0.38)
	material.set_shader_parameter("impact",Vector2(point.x,point.y)); material.set_shader_parameter("amplitude",amplitude)
func _process(dt: float) -> void:
	elapsed+=dt; material.set_shader_parameter("elapsed",elapsed)
static func response(velocity: Vector3, height: float) -> Vector3:
	var result:=velocity
	var over:=height>=2.43 and absf(velocity.z)>4.0
	result.z*=0.48 if over else -lerpf(0.08,0.15,clampf(absf(velocity.z)/30.0,0,1))
	result.x*=0.72
	result.y=maxf(0.25,velocity.y*0.15) if over else minf(-0.35,velocity.y*0.40-absf(velocity.z)*0.035)
	return result

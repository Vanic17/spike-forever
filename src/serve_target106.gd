extends RefCounted
## Desired target locks at type selection; dispersion freezes once at release.
## Only the authority samples. The local guest predicts the cursor, not the ball.
const Condition=preload("res://src/condition99.gd")
static var config: Dictionary={}
var sample: Dictionary={}
var local_target:=Vector3.ZERO
var local_rally:=-1
var local_locked:=false
var cursor: Node3D
var ring: MeshInstance3D
var centre: MeshInstance3D

static func settings() -> Dictionary:
	if config.is_empty():config=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/serve_target106.json"))
	return config
static func enabled() -> bool:return bool(settings().enabled)
static func clamp_target(value: Vector3,team: int) -> Vector3:
	var s:=1.0 if team==1 else -1.0
	return Vector3(clampf(value.x,-settings().court_half_width,settings().court_half_width),.105,s*clampf(value.z*s,0,settings().court_half_length))
static func power_coefficient(power: float) -> float:
	var p: Dictionary=settings().power
	var percent:=maxf(0,power)*100
	var full: float=p.low_coefficient+p.linear_slope*(100-p.low_percent)
	if percent<=p.low_percent:return float(p.low_coefficient)
	if percent<=100:return p.low_coefficient+p.linear_slope*(percent-p.low_percent)
	return full+p.overcharge_gain*pow((percent-100)/p.overcharge_span,p.overcharge_exponent)
static func radius(skill: float,arrow: String,power: float,floating: bool) -> float:
	var c:=settings()
	return (c.base_radius+c.missing_skill_radius*(99-clampf(skill,0,99)))*c.type["float" if floating else "jump"]*c.arrows.get(arrow,1.0)*power_coefficient(power)
static func draw(random: RandomNumberGenerator,r90: float) -> Vector2:
	var sigma:=r90/sqrt(-2*log(1-float(settings().percentile)))
	var magnitude:=sigma*sqrt(-2*log(maxf(random.randf(),0.0000001)))
	return Vector2.from_angle(random.randf()*TAU)*magnitude
func reset(game) -> void:
	sample.clear();game.serve_locked106=false
	game.serve_aim106=Vector3(0,.105,-4.5 if game.server==0 else 4.5)
	local_rally=-1
func owns(game) -> bool:
	return game.started and game.phase=="SERVE" and game.server==game.local_team() and not game.demo and (not game.legend_controls_enabled() or game.legend_match.owns(game.server_index(game.server)))
func desired(game) -> Vector3:
	if game.network_match() and not game.online_session.authority() and owns(game):
		if local_rally!=game.rally_serial:local_rally=game.rally_serial;local_target=game.serve_aim106;local_locked=false
		return local_target
	return game.serve_aim106
func input_tick(game,dt: float) -> void:
	if not enabled() or not owns(game) or game.paused or game.serve_locked106 or game.charging or game.toss_active or game.serve_adjusting:return
	if game.network_match() and not game.online_session.authority() and local_locked:return
	var axes:=Vector2(float(Input.is_physical_key_pressed(KEY_L))-float(Input.is_physical_key_pressed(KEY_J)),float(Input.is_physical_key_pressed(KEY_K))-float(Input.is_physical_key_pressed(KEY_I)))
	var id: int=game.pad()
	if id>=0:
		var stick:=Vector2(Input.get_joy_axis(id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(id,JOY_AXIS_RIGHT_Y))
		var length:=stick.length()
		if length>settings().deadzone:axes=stick.normalized()*clampf((length-settings().deadzone)/(1-settings().deadzone),0,1)
	var right:=Vector3(game.camera.global_basis.x.x,0,game.camera.global_basis.x.z).normalized()
	var down:=-Vector3(game.camera.global_basis.y.x,0,game.camera.global_basis.y.z).normalized()
	var value:=clamp_target(desired(game)+(right*axes.x+down*axes.y)*dt*float(settings().sensitivity_metres_per_second),game.server)
	if game.network_match() and not game.online_session.authority():local_target=value
	else:game.serve_aim106=value
func accept(game,value,side: int) -> void:
	if enabled() and game.phase=="SERVE" and side==game.server and not game.serve_locked106 and value is Vector3 and value.is_finite():game.serve_aim106=clamp_target(value,side)
func parameters(game,power: float) -> Dictionary:
	var player=game.players[game.server_index(game.server)]
	var identity: Dictionary=player.libero_identity if player.libero_active else player.roster_identity
	var skill: float=identity.get("ratings",{}).get("battuta",settings().baseline_skill) if game.use_player_stats else settings().baseline_skill
	var arrow: String=Condition.arrow(game.form99,str(identity.get("id",""))) if game.use_player_stats else "NEUTRAL"
	return {"skill":skill,"arrow":arrow,"power":power,"floating":game.serve_type==0,"r90":radius(skill,arrow,power,game.serve_type==0)}
func freeze(game,power: float) -> void:
	if not enabled() or not sample.is_empty():return
	game.serve_locked106=true
	sample=parameters(game,power)
	var seed_value: int=game.rng.randi()
	var random:=RandomNumberGenerator.new();random.seed=seed_value
	var offset:=draw(random,sample.r90)
	sample.merge({"seed":str(seed_value),"desired":game.serve_aim106,"sampled":game.serve_aim106+Vector3(offset.x,0,offset.y),"offset":offset,"schema":1})
	game.log_rally_event("serve_target106_release",sample.duplicate(true))
func cpu_lock(game,power: float) -> void:
	if not enabled() or not sample.is_empty():return
	var s: float=-1 if game.server==0 else 1
	game.serve_aim106=Vector3(game.rng.randf_range(-3.3,3.3),.105,s*game.rng.randf_range(4.6,8.1))
	freeze(game,power)
func setup_cursor(game) -> void:
	cursor=Node3D.new();cursor.name="ServeTarget106";game.add_child(cursor)
	ring=MeshInstance3D.new();var mesh:=PlaneMesh.new();mesh.size=Vector2(2.2,2.2);ring.mesh=mesh;cursor.add_child(ring)
	centre=MeshInstance3D.new();var disk:=CylinderMesh.new();disk.top_radius=.085;disk.bottom_radius=.085;disk.height=.006;centre.mesh=disk;cursor.add_child(centre)
	for instance in [ring,centre]:
		var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_color=Color(1,1,1,.65);material.no_depth_test=false;instance.material_override=material;instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; uniform vec4 tint : source_color = vec4(0.4,1.0,0.85,0.8); void fragment(){float r=length((UV-0.5)*2.2);float width=max(fwidth(r)*1.2,0.008);ALBEDO=tint.rgb;ALPHA=tint.a*(1.0-smoothstep(width,width*1.8,abs(r-1.0)));}"
	var ring_material:=ShaderMaterial.new();ring_material.shader=shader;ring.material_override=ring_material
func visual(game) -> void:
	if cursor==null:setup_cursor(game)
	cursor.visible=enabled() and owns(game) and not game.paused and not game.toss_active and not game.serve_adjusting and not (game.replay!=null and game.replay.active)
	if not cursor.visible:return
	cursor.position=desired(game);cursor.position.y=.065
	var power: float=game.current_charge() if game.charging else 0
	var r: float=parameters(game,power).r90
	ring.scale=Vector3(r,1,r)
	ring.material_override.set_shader_parameter("tint",Color(1,.32,.08,.85) if power>1 else Color(.4,1,.85,.8))

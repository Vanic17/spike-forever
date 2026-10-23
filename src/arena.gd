extends Node3D
const Assets = preload("res://src/source_assets.gd")
const Crowd = preload("res://src/crowd.gd")
var ball: MeshInstance3D
var shadow: MeshInstance3D
var marker: MeshInstance3D
var camera: Camera3D
var dynamic_net
var sponsors
var crowd_materials: Array[ShaderMaterial] = []
var crowd_excitement := 0.0
var crowd_instance_count := 0
var crowd_positions: Array[Vector3] = []

func solid(color: Color, roughness: float = 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func box(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)
	return node

func descendants(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): result.append_array(descendants(child))
	return result

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101722")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8e3ee")
	env.ambient_light_energy = 0.43
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 0.7
	env.ssao_intensity = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color("28364a")
	env.fog_density = 0.0018
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-72, -24, 0)
	light.light_color = Color("fff2df")
	light.light_energy = 1.15
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 55
	light.shadow_bias = 0.03
	add_child(light)
	for x in [-5.0, 5.0]:
		for z in [-5.5, 5.5]:
			var overhead := SpotLight3D.new()
			overhead.position = Vector3(x, 11, z)
			overhead.spot_range = 23
			overhead.spot_angle = 62
			overhead.light_energy = 1.35
			overhead.light_color = Color("f2f5ff")
			add_child(overhead)
			overhead.look_at(Vector3(x * 0.3, 0, z * 0.3))
	# Full indoor backdrop replaces the isolated miniature platform.
	var stadium := Assets.scene("SM_STA01_Test.gltf")
	if stadium:
		stadium.scale = Vector3.ONE * 0.55
		stadium.position.y = -0.15
		add_child(stadium)
		# The imported arena has its own lower tiers at a different scale.
		# Those intersected our spectator rows, cutting through heads and LEDs.
		# Keep its upper shell and replace only the occupied lower bowl.
		var shell_shader:=Shader.new()
		shell_shader.code="""shader_type spatial;
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	if(abs(world_position.x)<22.5 && abs(world_position.z)<28.0 && world_position.y<6.6) discard;
	ALBEDO=vec3(0.116,0.150,0.198); ROUGHNESS=0.85;
}"""
		var shell_material:=ShaderMaterial.new(); shell_material.shader=shell_shader
		for node in descendants(stadium):
			node.material_override = shell_material
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(Vector3(0, -0.16, 0), Vector3(85, 0.25, 90), solid(Color("1b2530")))
	# Broadcast reference: muted wood/beige and a deeper blue free zone.
	# Adjust the surface pigments, retaining the lighting on players and logos.
	var free_zone := Assets.material("", "T_Ground_Taraflex_Normal.png", Color("07518f"), 0.38)
	free_zone.uv1_scale = Vector3(8, 8, 8)
	box(Vector3(0, -0.014, 0), Vector3(20.5, 0.03, 29), free_zone)
	var court := Assets.material("", "T_Ground_Taraflex_Normal.png", Color("b09a79"), 0.37)
	court.uv1_scale = Vector3(5, 8, 5)
	box(Vector3(0, 0.008, 0), Vector3(9, 0.015, 18), court)
	var attack_zone:=Assets.material("", "T_Ground_Taraflex_Normal.png", Color("b19f77"),0.37)
	attack_zone.uv1_scale=Vector3(5,3,5)
	box(Vector3(0,0.017,0),Vector3(9,0.004,6),attack_zone)
	var white := solid(Color("efeee6"), 0.45)
	for x in [-4.5, 4.5]: box(Vector3(x, 0.022, 0), Vector3(0.05, 0.006, 18.05), white)
	for z in [-9, -3, 0, 3, 9]: box(Vector3(0, 0.023, z), Vector3(9.04, 0.006, 0.05), white)
	# Regulation attack-line extensions leave the free zone visually readable.
	for side in [-1,1]:
		for z in [-3,3]:
			for dash in 5:
				box(Vector3(side*(4.8+dash*0.35),0.022,z),Vector3(0.15,0.005,0.05),white)
	var net := Assets.scene("SM_Furn_VolleyNet01A.gltf")
	if net:
		net.rotation.y = PI / 2
		add_child(net)
		for part in descendants(net):
			for surface in part.mesh.get_surface_count():
				var existing := part.mesh.surface_get_material(surface)
				var name := existing.resource_name.to_lower() if existing else ""
				var m: StandardMaterial3D
				if "net" in name and not "pad" in name and not "pole" in name:
					m = Assets.material("T_Furn_VolleyNet_BaseColor.png", "T_Furn_VolleyNet_Normal.png")
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					m.alpha_scissor_threshold = 0.45
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
					m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
					m.albedo_color=Color(1,1,1,0)
				else:
					m = Assets.material("T_Furn_VolleyNetPad01A_BaseColor.png", "T_Furn_VolleyNetPad01A_Normal.png", Color("285d43"))
				part.set_surface_override_material(surface, m)
	else:
		for x in [-5.2, 5.2]: box(Vector3(x, 1.35, 0), Vector3(0.15, 2.7, 0.15), white)
		box(Vector3(0, 2.43, 0), Vector3(10.4, 0.075, 0.03), white)
	dynamic_net=preload("res://src/net_dynamics.gd").new(); add_child(dynamic_net)
	build_seating()
	build_crowd()
	build_branding()
	ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.105
	sphere.height = 0.21
	sphere.radial_segments = 32
	sphere.rings = 16
	ball.mesh = sphere
	var ball_shader := Shader.new()
	ball_shader.code = "shader_type spatial; uniform sampler2D diffuse_map : source_color, filter_linear_mipmap_anisotropic; uniform sampler2D color_mask : filter_linear_mipmap; uniform sampler2D normal_map : hint_normal; void fragment(){ vec3 mask=texture(color_mask,UV).rgb; vec3 tint=mask.r*vec3(0.92,0.68,0.06)+mask.g*vec3(0.045,0.13,0.40)+max(0.0,1.0-mask.r-mask.g)*vec3(0.9); ALBEDO=texture(diffuse_map,UV).rgb*tint; NORMAL_MAP=texture(normal_map,UV).rgb; NORMAL_MAP_DEPTH=0.5; ROUGHNESS=0.5; }"
	var ball_material := ShaderMaterial.new()
	ball_material.shader = ball_shader
	ball_material.set_shader_parameter("diffuse_map", Assets.texture("T_Acc_VolleyBallB_BaseColor.png"))
	ball_material.set_shader_parameter("color_mask", Assets.texture("T_Acc_VolleyBallB_Mask.png"))
	ball_material.set_shader_parameter("normal_map", Assets.texture("T_Acc_VolleyBallB_Normal.png"))
	ball.material_override = ball_material
	add_child(ball)
	# The source mesh has the panel UVs; use it instead of spherical UVs when available.
	var ball_model := Assets.scene("SM_Acc_VolleyBallB.gltf")
	if ball_model:
		var meshes := descendants(ball_model)
		if not meshes.is_empty(): ball.mesh = meshes[0].mesh
		ball_model.free()
	shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.13
	disc.bottom_radius = 0.13
	disc.height = 0.003
	shadow.mesh = disc
	shadow.position.y = 0.026
	shadow.material_override = solid(Color("655b51"))
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.23
	ring.outer_radius = 0.255
	ring.rings = 32
	ring.ring_segments = 6
	marker.mesh = ring
	marker.material_override = solid(Color("f2ddb0"))
	add_child(marker)
	camera = Camera3D.new()
	camera.fov = 56
	camera.near = 0.15
	camera.far = 160
	camera.position = Vector3(0, 7.7, 20.2)
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, -0.7))

func build_seating() -> void:
	var seat_scene := Assets.scene("Furn_PublicChairA_LOD0.gltf")
	var seat_mesh: Mesh
	if seat_scene:
		var meshes := descendants(seat_scene)
		if not meshes.is_empty(): seat_mesh = meshes[0].mesh
	var concrete := solid(Color("505968"), 0.92)
	var seat_material := Assets.material("T_Furn_PublicChairC_BaseColor.png", "T_Furn_PublicChairC_Normal.png", Color("6b849a"))
	var stair_material:=solid(Color("9ba3aa"),0.88)
	var rail_material:=solid(Color("b3b9b9"),0.28)
	for side in [-1, 1]:
		var seating := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = seat_mesh if seat_mesh else SphereMesh.new()
		instances.instance_count = 10 * 58
		seating.multimesh = instances
		seating.material_override = seat_material
		add_child(seating)
		for row in 10:
			box(Vector3(side * (11.7 + row * 0.9), row * 0.48 + 0.07, 0), Vector3(0.95, 0.45, 37), concrete)
			for column in 58:
				var index := row * 58 + column
				var position := Vector3(side * (11.7 + row * 0.9), row * 0.48 + 0.35, (column - 28.5) * 0.62)
				var aisle:=column%15<2
				instances.set_instance_transform(index, Transform3D(Basis(Vector3.UP, -side * PI / 2).scaled(Vector3.ONE*(0.0 if aisle else 1.0)), position))
				instances.set_instance_color(index, Color("b2b9c2") if column % 13 < 2 else Color.WHITE)
				if not aisle and (column + row * 3) % 17 != 0: crowd_positions.append(position)
			for aisle in 4:
				var z: float=(aisle*15-28.0)*0.62
				box(Vector3(side*(11.7+row*0.9),row*0.48+0.31,z),Vector3(0.94,0.04,1.12),stair_material)
		# Low rail separates spectators from the LED ring.
		box(Vector3(side*11.05,1.0,0),Vector3(0.045,0.045,36),rail_material)
		for z in [-17,-11,-5,1,7,13,17]:
			box(Vector3(side*11.05,0.64,z),Vector3(0.045,0.75,0.045),rail_material)
	if seat_scene: seat_scene.free()
	# Far-end tier stays visible from the requested end-line camera.
	var end_seats:=MultiMeshInstance3D.new()
	var end_instances:=MultiMesh.new()
	end_instances.transform_format=MultiMesh.TRANSFORM_3D
	end_instances.mesh=seat_mesh if seat_mesh else SphereMesh.new()
	end_instances.instance_count=9*43
	end_seats.multimesh=end_instances; end_seats.material_override=seat_material
	add_child(end_seats)
	for row in 9:
		box(Vector3(0, row * 0.52, -18.5 - row * 0.9), Vector3(24 + row * 1.5, 0.48, 0.92), concrete)
		for column in 43:
			if not seat_mesh: continue
			var position:=Vector3((column-21)*0.62,row*0.52+0.25,-18.5-row*0.9)
			var aisle:=column in [10,11,31,32]
			end_instances.set_instance_transform(row*43+column,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(0.0 if aisle else 1.0)),position))
			if not aisle and (column+row)%17!=0: crowd_positions.append(position)
		for x in [-6.5,6.5]: box(Vector3(x,row*0.52+0.25,-18.5-row*0.9),Vector3(1.15,0.035,0.95),stair_material)

func build_crowd() -> void:
	if build_source_crowd(): return
	var random := RandomNumberGenerator.new()
	random.seed = 500012
	var torso := CapsuleMesh.new()
	torso.radius = 0.17
	torso.height = 0.55
	torso.radial_segments = 10
	torso.rings = 3
	var head := SphereMesh.new()
	head.radius = 0.105
	head.height = 0.23
	head.radial_segments = 10
	head.rings = 6
	var hair := SphereMesh.new()
	hair.radius = 0.109
	hair.height = 0.125
	hair.radial_segments = 10
	hair.rings = 5
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_back; void vertex(){ VERTEX.x += sin(TIME*1.4 + INSTANCE_CUSTOM.x*6.283)*0.015; } void fragment(){ ALBEDO = COLOR.rgb; ROUGHNESS=0.92; }"
	var m := ShaderMaterial.new()
	m.shader = shader
	var palette := [Color("354f7a"), Color("b8b3a9"), Color("45434e"), Color("6d3735"), Color("264b52"), Color("c5bfae"), Color("161f2d")]
	for part in 3:
		var node := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.use_custom_data = true
		instances.mesh = [torso, head, hair][part]
		instances.instance_count = crowd_positions.size()
		node.multimesh = instances
		node.material_override = m
		add_child(node)
		for i in crowd_positions.size():
			var p := crowd_positions[i] + Vector3(0, [0.74, 1.12, 1.22][part], 0.11)
			var scale := random.randf_range(0.94, 1.06)
			instances.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), p))
			var color: Color = palette[i % palette.size()] if part == 0 else (Color("c59b7a") if part == 1 else Color("30241e"))
			instances.set_instance_color(i, color * random.randf_range(0.8, 1.1))
			instances.set_instance_custom_data(i, Color(random.randf(), 0, 0, 1))

func build_source_crowd() -> bool:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D diffuse_map : source_color, filter_linear_mipmap_anisotropic;
uniform float clothing=0.0;
uniform float excitement=0.0;
varying vec4 person;
void vertex(){
	person=INSTANCE_CUSTOM;
	float phase=person.x*6.283;
	float upper=smoothstep(0.35,1.4,VERTEX.y);
	float sway=sin(TIME*(0.55+person.y*0.65)+phase);
	VERTEX.x+=sway*0.021*upper;
	VERTEX.z+=cos(TIME*0.7+phase)*0.012*upper;
	float hands=smoothstep(0.28,0.55,abs(VERTEX.x))*smoothstep(0.5,1.0,VERTEX.y);
	VERTEX.x+=sin(TIME*(3.1+person.y)+phase)*hands*(0.012+excitement*0.025);
	VERTEX.y+=max(0.0,sin(TIME*(3.0+person.y)+phase))*upper*excitement*0.055;
}
void fragment(){
	vec3 tex=texture(diffuse_map,UV).rgb;
	float lightness=dot(tex,vec3(0.299,0.587,0.114));
	vec3 shirt=COLOR.rgb*(0.45+lightness*0.65);
	vec3 skin=tex*mix(vec3(0.72,0.60,0.51),vec3(1.0),person.z);
	ALBEDO=mix(skin,shirt,clothing);
	ROUGHNESS=0.88;
}"""
	var palette: Array[Color]=[Color("e5ddcc"),Color("dbc34a"),Color("1c4a85"),Color("daebeb"),Color("ab2f36"),Color("2f765b"),Color("777a81"),Color("e9a251"),Color("383e51"),Color("c2d2df")]
	const VARIANTS:=8
	var groups: Array=[]
	for variant in VARIANTS: groups.append([])
	for i in crowd_positions.size():
		var distribution:=fposmod(sin(float(i)*7.141)*5317.13,1.0)
		var gender:=4 if fposmod(sin(float(i)*3.51)*1531.1,1.0)>.5 else 0
		var pose:=0 if distribution<0.43 else (1 if distribution<0.77 else (2 if distribution<0.93 else 3))
		groups[gender+pose].append(i)
	for variant in VARIANTS:
		var source_mesh := Crowd.create(variant)
		if source_mesh == null: return false
		var mesh: ArrayMesh=source_mesh.duplicate()
		for surface in mesh.get_surface_count():
			var original: StandardMaterial3D = mesh.surface_get_material(surface)
			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("diffuse_map", original.albedo_texture)
			material.set_shader_parameter("clothing",0.0 if surface==0 else 1.0)
			crowd_materials.append(material)
			mesh.surface_set_material(surface, material)
		var node := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.use_custom_data = true
		instances.mesh = mesh
		instances.instance_count = groups[variant].size()
		var instance := 0
		for spectator in groups[variant]:
			var i: int=spectator
			var p: Vector3 = crowd_positions[i]
			var angle := 0.0 if p.z < -18 else (-PI / 2 if p.x > 0 else PI / 2)
			var phase:=fposmod(sin(float(i)*19.17)*1453.71,1.0)
			var diversity:=fposmod(sin(float(i)*4.731)*7531.21,1.0)
			var orientation := Basis(Vector3.UP, angle+(phase-0.5)*0.21)
			var size:=Vector3(0.91+diversity*0.15,0.92+phase*0.16,0.94+diversity*0.12)
			instances.set_instance_transform(instance, Transform3D(orientation.scaled(size), p + orientation * Vector3(0, 0, 0.09)))
			instances.set_instance_color(instance,palette[mini(palette.size()-1,int(diversity*palette.size()))])
			instances.set_instance_custom_data(instance,Color(phase,diversity,0.45+phase*0.55,1))
			instance += 1
		crowd_instance_count+=instance
		node.multimesh = instances
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	return true

func build_branding() -> void:
	var board := solid(Color("0d1723"), 0.45)
	var illuminated := solid(Color("b8def4"))
	illuminated.emission_enabled = true
	illuminated.emission = Color("3984a9")
	illuminated.emission_energy_multiplier = 0.65
	for x in [-9.37, 9.37]:
		box(Vector3(x, 0.57, 0), Vector3(0.12, 1.0, 24), board)
	for z in [-14.57,14.57]:
		box(Vector3(0,0.57,z),Vector3(18.3,1.0,0.12),board)
	sponsors=preload("res://src/sponsor_displays.gd").new()
	add_child(sponsors)
	for x in [-6.5, 6.5]:
		for z in [-8, 0, 8]:
			box(Vector3(x, 12.5, z), Vector3(1.8, 0.05, 0.18), illuminated)
	# A real scorers' table and team benches fill the former empty sidelines.
	for side in [-1,1]:
		box(Vector3(-7.4,0.42,side*6.6),Vector3(0.65,0.11,4.5),solid(Color("244b6c"),0.58))
		box(Vector3(-7.72,0.82,side*6.6),Vector3(0.08,0.65,4.5),solid(Color("244b6c"),0.58))
		for z_offset in [-1.8,0.0,1.8]:
			box(Vector3(-7.4,0.21,side*6.6+z_offset),Vector3(0.48,0.42,0.06),board)
	box(Vector3(-7.8,0.55,0),Vector3(0.85,1.1,4.3),board)
	box(Vector3(-7.8,1.12,0),Vector3(1.05,0.06,4.4),solid(Color("909ba7"),0.38))
	for z in [-1.2,0.0,1.2]:
		box(Vector3(-7.45,1.38,z),Vector3(0.06,0.43,0.52),board)

func crowd_react() -> void:
	crowd_excitement=1.0

func _process(dt: float) -> void:
	if crowd_excitement<=0.0: return
	crowd_excitement=maxf(0.0,crowd_excitement-dt*0.30)
	for material in crowd_materials: material.set_shader_parameter("excitement",crowd_excitement)

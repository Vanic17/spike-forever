extends Node3D
const Assets = preload("res://src/source_assets.gd")
const Crowd = preload("res://src/crowd.gd")
var ball: MeshInstance3D
var shadow: MeshInstance3D
var marker: MeshInstance3D
var camera: Camera3D
var dynamic_net
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
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.ssao_enabled = true
	env.ssao_radius = 0.7
	env.ssao_intensity = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color("28364a")
	env.fog_density = 0.003
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
		for node in descendants(stadium):
			node.material_override = solid(Color("303b4b"), 0.85)
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(Vector3(0, -0.16, 0), Vector3(85, 0.25, 90), solid(Color("1b2530")))
	var free_zone := Assets.material("", "T_Ground_Taraflex_Normal.png", Color("215e68"), 0.42)
	free_zone.uv1_scale = Vector3(8, 8, 8)
	box(Vector3(0, -0.014, 0), Vector3(19, 0.03, 28), free_zone)
	var court := Assets.material("", "T_Ground_Taraflex_Normal.png", Color("bb6a4b"), 0.40)
	court.uv1_scale = Vector3(5, 8, 5)
	box(Vector3(0, 0.008, 0), Vector3(9, 0.015, 18), court)
	var white := solid(Color("efeee6"), 0.45)
	for x in [-4.5, 4.5]: box(Vector3(x, 0.022, 0), Vector3(0.05, 0.006, 18.05), white)
	for z in [-9, -3, 0, 3, 9]: box(Vector3(0, 0.023, z), Vector3(9.04, 0.006, 0.05), white)
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
					m = Assets.material("T_Furn_VolleyNetPad01A_BaseColor.png", "T_Furn_VolleyNetPad01A_Normal.png", Color("315ca8"))
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
	var concrete := solid(Color("58616a"), 0.92)
	var seat_material := Assets.material("T_Furn_PublicChairC_BaseColor.png", "T_Furn_PublicChairC_Normal.png", Color("476a94"))
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
				instances.set_instance_transform(index, Transform3D(Basis(Vector3.UP, -side * PI / 2), position))
				instances.set_instance_color(index, Color("b2b9c2") if column % 13 < 2 else Color.WHITE)
				if (column + row * 3) % 13 != 0: crowd_positions.append(position)
	if seat_scene: seat_scene.free()
	# Far-end tier stays visible from the requested end-line camera.
	for row in 9:
		box(Vector3(0, row * 0.52, -18.5 - row * 0.9), Vector3(24 + row * 1.5, 0.48, 0.92), concrete)
		for column in 43:
			if not seat_mesh: continue
			var chair := MeshInstance3D.new()
			chair.mesh = seat_mesh
			chair.material_override = seat_material
			chair.position = Vector3((column - 21) * 0.62, row * 0.52 + 0.25, -18.5 - row * 0.9)
			add_child(chair)
			if (column + row) % 11 != 0: crowd_positions.append(chair.position)

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
	shader.code = "shader_type spatial; render_mode cull_disabled; uniform sampler2D diffuse_map : source_color, filter_linear_mipmap_anisotropic; void vertex(){ VERTEX.x += sin(TIME*0.8 + INSTANCE_CUSTOM.x*6.283)*0.018*smoothstep(0.5,1.4,VERTEX.y); } void fragment(){ ALBEDO=texture(diffuse_map,UV).rgb*COLOR.rgb; ROUGHNESS=0.85; }"
	for variant in 3:
		var mesh := Crowd.create(variant)
		if mesh == null: return false
		for surface in mesh.get_surface_count():
			var original: StandardMaterial3D = mesh.surface_get_material(surface)
			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("diffuse_map", original.albedo_texture)
			mesh.surface_set_material(surface, material)
		var node := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.use_custom_data = true
		instances.mesh = mesh
		instances.instance_count = int(ceil(float(crowd_positions.size() - variant) / 3.0))
		var instance := 0
		for i in range(variant, crowd_positions.size(), 3):
			var p: Vector3 = crowd_positions[i]
			var angle := 0.0 if p.z < -18 else (-PI / 2 if p.x > 0 else PI / 2)
			var orientation := Basis(Vector3.UP, angle)
			instances.set_instance_transform(instance, Transform3D(orientation, p + orientation * Vector3(0, 0, 0.09)))
			instances.set_instance_color(instance, Color.WHITE * (0.83 + float(i % 7) * 0.035))
			instances.set_instance_custom_data(instance, Color(float(i % 71) / 71,0,0,1))
			instance += 1
		node.multimesh = instances
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	return true

func build_branding() -> void:
	var board := solid(Color("082136"), 0.45)
	var illuminated := solid(Color("b8def4"))
	illuminated.emission_enabled = true
	illuminated.emission = Color("3984a9")
	illuminated.emission_energy_multiplier = 0.65
	for x in [-9.2, 9.2]:
		box(Vector3(x, 0.38, 0), Vector3(0.12, 0.75, 25), board)
	for z in [-14.4, 14.4]:
		box(Vector3(0, 0.4, z), Vector3(19, 0.8, 0.14), board)
		for x in [-6.2, 0, 6.2]:
			var label := Label3D.new()
			label.text = "SPIKE FOREVER"
			label.font_size = 64
			label.pixel_size = 0.006
			label.position = Vector3(x, 0.52, z + (0.09 if z < 0 else -0.09))
			label.rotation.y = 0 if z < 0 else PI
			label.modulate = Color("d8e8ef")
			add_child(label)
	for x in [-6.5, 6.5]:
		for z in [-8, 0, 8]:
			box(Vector3(x, 12.5, z), Vector3(1.8, 0.05, 0.18), illuminated)

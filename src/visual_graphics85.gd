extends Node3D
## Visual upgrade layered over the intact v0.84 arena. New decorations are
## MultiMeshes: they are deliberately absent from the existing scenery scan.
const Materials=preload("res://src/visual_materials85.gd")
const Assets=preload("res://src/source_assets.gd")
var arena
var world: WorldEnvironment
var key_light: DirectionalLight3D
var court_lights: Array[SpotLight3D]=[]
var bounce_lights: Array[DirectionalLight3D]=[]
var probe: ReflectionProbe
var settings: Dictionary={}
var built:=false
var palette_wait:=0.0
var palette_key:=""

func _ready():
	name="VisualUpgrade85";arena=get_parent()
	if not Materials.enabled:set_process(false);return
	add_to_group("visual_graphics85")
	call_deferred("build")
func build():
	for node in arena.get_children():
		if node is WorldEnvironment:world=node
		elif node is DirectionalLight3D:key_light=node
		elif node is SpotLight3D:court_lights.append(node)
	var environment=world.environment
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	environment.ambient_light_color=Color("c7d2df");environment.ambient_light_energy=.38
	environment.ssao_radius=.45;environment.ssao_intensity=1.25;environment.ssao_power=1.25;environment.ssao_light_affect=.08
	environment.glow_intensity=.18;environment.glow_hdr_threshold=1.3
	environment.fog_density=.0011;environment.fog_light_color=Color("172332")
	key_light.name="CeilingCourtKey85";key_light.rotation_degrees=Vector3(-79,-12,0)
	key_light.light_color=Color("fff8ef");key_light.light_energy=.92
	key_light.shadow_bias=.025;key_light.shadow_normal_bias=.65;key_light.light_angular_distance=0
	for light in court_lights:
		light.light_color=Color("f3f6ff");light.light_energy=2.0;light.spot_angle=58;light.spot_attenuation=1.2
		light.look_at(Vector3(light.position.x*.22,0,light.position.z*.35))
	# Broad bounce approximation for vertical faces under ceiling luminaires.
	# Affect athletes/staff only, not court pigments or the spectator bowl.
	for side in [-1,1]:
		var fill:=DirectionalLight3D.new();fill.name="CeilingBounce85";fill.rotation_degrees=Vector3(-42,0 if side==1 else 180,0)
		fill.light_energy=.32;fill.light_color=Color("f1f3f7");fill.light_cull_mask=2;fill.shadow_enabled=false;add_child(fill);bounce_lights.append(fill)
	configure_floor(arena.court_material,true)
	configure_floor(arena.attack_zone_material,true)
	configure_floor(arena.free_zone_material,false)
	arena.dynamic_net.material.shader=preload("res://src/net_surface85.gdshader")
	arena.ball.material_override.set_shader_parameter("visual_detail85",2.0)
	arena.home_half.material_override=arena.court_material.duplicate()
	arena.home_half.material_override.uv1_scale=Vector3(5,3,5)
	# Respect club pigment and its optional differently coloured half.
	if not arena.home_club_id.is_empty():
		var profile: Dictionary=preload("res://src/arena_profiles.gd").profile(arena.home_club_id)
		if profile.has("second_half"):arena.home_half.material_override.albedo_color=Color(profile.second_half).srgb_to_linear()
	architecture()
	probe=ReflectionProbe.new();probe.name="StaticArenaReflection85";probe.position=Vector3(0,3,0);probe.size=Vector3(24,10,32)
	probe.origin_offset=Vector3(0,1,0);probe.interior=true;probe.box_projection=true;probe.intensity=.62;probe.cull_mask=1;probe.max_distance=36
	probe.update_mode=ReflectionProbe.UPDATE_ONCE;add_child(probe)
	# Only render layers change; simulation, mesh data and skinning remain intact.
	var game=arena.get_parent()
	for athlete in game.players:
		for part in athlete.body_parts.values():part.layers=2
		if athlete.body_parts.has("eyes"):
			var eye:=ShaderMaterial.new();eye.shader=preload("res://src/eye_surface85.gdshader")
			eye.set_shader_parameter("iris",Assets.texture("T_Char_Eye_Brown_Base.png"));eye.set_shader_parameter("sclera",Assets.texture("EyeScleraBaseColor_Example_2.png"))
			athlete.body_parts.eyes.material_override=eye
	for node in arena.find_children("*","MeshInstance3D",true,false):
		if node.skin!=null:node.layers=2;continue
		var mat=node.material_override
		if mat is StandardMaterial3D:
			if mat.albedo_color.is_equal_approx(Color("b3b9b9")):mat.metallic=.82;mat.roughness=.38
			if mat.albedo_color.is_equal_approx(Color("505968")) or mat.albedo_color.is_equal_approx(Color("9ba3aa")):
				mat.roughness_texture=Assets.texture("T_Ground_Grunge_Roughness.png");mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;mat.roughness=.98;mat.metallic_specular=.18
			if "Credem" in str(node.get_parent().name):
				mat.roughness=.64
				if mat.albedo_texture==null:mat.normal_texture=Assets.texture("T_Furn_VolleyNetPad01A_Normal.png");mat.normal_enabled=true;mat.normal_scale=.18
			if node.mesh is CylinderMesh and arena.get_node("NetEquipment").is_ancestor_of(node) and mat.albedo_color.v>.6:mat.metallic=.65;mat.roughness=.38
			if node.name=="ScorersTableTop":mat.roughness=.40;mat.metallic_specular=.3
	built=true
	set_quality(settings)
	refresh_palette()
func refresh_palette():
	var game=arena.get_parent()
	if game.players.size()!=12:return
	var home=game.players[game.home_team*6].kit_identity;var visitor=game.players[(1-game.home_team)*6].kit_identity
	var home_color: String=str(home.get("primary_hex_approx","#254770"));var away_color: String=str(visitor.get("primary_hex_approx","#7b3a38"))
	if home_color+away_color==palette_key:return
	palette_key=home_color+away_color
	preload("res://src/visual_palette85.gd").apply(arena,Color(home_color),Color(away_color))
func _process(dt: float):
	if not built:return
	palette_wait+=dt
	if palette_wait>=1:palette_wait=0;refresh_palette()
func configure_floor(material: StandardMaterial3D,wood: bool):
	material.metallic_specular=.32;material.roughness=.86
	material.roughness_texture=Assets.texture("court_detail_roughness.png" if wood else "vinyl_roughness.png")
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	if wood:
		material.albedo_texture=Assets.texture("court_detail_albedo.png")
		material.normal_texture=Assets.texture("court_detail_normal.png");material.normal_enabled=true;material.normal_scale=.32
	else:material.normal_scale=.22
func material(color: String,roughness: float,metallic: float=0.0) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new();result.albedo_color=Color(color);result.roughness=roughness;result.metallic=metallic
	return result
func instances(name: String,mesh: Mesh,mat: Material,transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new();node.name=name
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=mesh;batch.instance_count=transforms.size()
	for i in transforms.size():batch.set_instance_transform(i,transforms[i])
	node.multimesh=batch;node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	return node
func scaled_box(at: Vector3,size: Vector3) -> Transform3D:return Transform3D(Basis.IDENTITY.scaled(size),at)
func architecture():
	var unit:=BoxMesh.new()
	var roof: Array[Transform3D]=[scaled_box(Vector3(0,16.8,-2),Vector3(49,.12,59))]
	instances("CeilingAcousticPanels85",unit,material("1c2532",.94),roof)
	var trusses: Array[Transform3D]=[]
	for z in [-22.0,-14.0,-6.0,2.0,10.0,18.0]:
		for y in [14.6,15.6]:trusses.append(scaled_box(Vector3(0,y,z),Vector3(45,.12,.12)))
		for x in range(-20,21,4):
			trusses.append(scaled_box(Vector3(x,15.1,z),Vector3(.09,1.0,.09)))
			var brace:=scaled_box(Vector3(x+1.5,15.1,z),Vector3(3.1,.07,.07));brace.basis=Basis(Vector3.FORWARD,.32)*brace.basis;trusses.append(brace)
	instances("CeilingTrusses85",unit,material("46515f",.43,.55),trusses)
	var housings: Array[Transform3D]=[];var lenses: Array[Transform3D]=[]
	for x in [-7.0,7.0]:
		for z in [-12.0,-6.0,0.0,6.0,12.0]:
			housings.append(scaled_box(Vector3(x,13.85,z),Vector3(1.65,.18,.68)))
			lenses.append(scaled_box(Vector3(x,13.74,z),Vector3(1.48,.018,.54)))
	instances("LuminairesHousing85",unit,material("151d29",.38,.6),housings)
	var lens_material:=material("dce9f7",.3);lens_material.emission_enabled=true;lens_material.emission=Color("e2edff");lens_material.emission_energy_multiplier=2.2
	instances("LuminairesDiffusers85",unit,lens_material,lenses)
	var fascias: Array[Transform3D]=[]
	for x in [-11.0,11.0]:fascias.append(scaled_box(Vector3(x,.24,0),Vector3(.11,.48,36)))
	fascias.append(scaled_box(Vector3(0,-.08,-17.9),Vector3(25,.48,.10)))
	instances("TierSeparation85",unit,material("122437",.65),fascias)
	# Thin sideline displays/laptop details remain purely decorative instances.
	var screens: Array[Transform3D]=[]
	for z in [-1.2,0.0,1.2]:screens.append(scaled_box(Vector3(-7.414,1.02,z),Vector3(.004,.255,.405)))
	var display:=material("2e6b8c",.28);display.emission_enabled=true;display.emission=Color("18364b");display.emission_energy_multiplier=.30
	instances("ScorersScreens85",unit,display,screens)
func set_quality(values: Dictionary):
	settings=values.duplicate()
	if not built:return
	var level: int=int(values.get("arena_lighting",2))
	Materials.quality(int(values.get("material_detail",2)))
	probe.visible=int(values.get("reflections",1))>0
	probe.mesh_lod_threshold=1.0 if level==3 else 2.0
	key_light.shadow_blur=1.35 if level>=2 else 1.0
	# PCSS creates a stippled self-shadow on the source overlapping hair cards.
	# The existing PCF path stays stable; its filter radius provides soft edges.
	key_light.light_angular_distance=0
	arena.ball.material_override.set_shader_parameter("visual_detail85",float(Materials.detail))
	for light in court_lights:light.visible=level>0
	for fill in bounce_lights:fill.shadow_enabled=false;fill.visible=level>0
	world.environment.ambient_light_energy=.42 if level==0 else .38

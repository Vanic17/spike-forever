extends Node3D
## Presentation-only revision. The frozen 0.85 build is the reference.
const Assets=preload("res://src/source_assets.gd")
var base
var arena
var upper_lights: Array[OmniLight3D]=[]
var phase:="final"
var prototype
var integrated
func configure(previous):
	name="VisualUpgrade86";base=previous;arena=base.arena
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--graphics86-phase="):phase=arg.trim_prefix("--graphics86-phase=")
	for z in [-12.0,0.0,12.0]:
		var light:=OmniLight3D.new();light.name="UpperArenaBounce86";light.position=Vector3(0,9.5,z)
		light.light_color=Color("fffdf8");light.light_energy=.70;light.omni_range=27;light.omni_attenuation=1.0
		light.shadow_enabled=false;add_child(light);upper_lights.append(light)
	if phase!="lighting" and arena.get_parent().players[0].body_parts.has("head"):
		if "--athlete-prototype87" in OS.get_cmdline_user_args():
			prototype=load("res://src/athlete_next88.gd" if "--athlete-next88" in OS.get_cmdline_user_args() else "res://src/athlete_prototype87.gd").new()
			prototype.attach(arena.get_parent().players[0])
			prototype.shoes(arena.get_parent().players)
		else:
			prototype=preload("res://src/athlete_prototype86.gd").new();prototype.attach(arena.get_parent().players[0])
	if phase not in ["lighting","prototype"]:surfaces()
	if phase=="final":
		preload("res://src/spectator_variants86.gd").apply(arena);architecture()
	if phase=="final" and not "--graphics-previous88" in OS.get_cmdline_user_args() and not "--athlete-prototype87" in OS.get_cmdline_user_args():
		integrated=load("res://src/stadium_fidelity89.gd").new();add_child(integrated);integrated.configure(self)
	quality(base.settings)
func quality(values: Dictionary):
	var level:=int(values.get("arena_lighting",2))
	var env: Environment=base.world.environment
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=float(values.get("exposure",1.0))
	env.ambient_light_color=Color("e6e7e8");env.ambient_light_energy=.53 if level>0 else .57
	env.ssao_radius=.28;env.ssao_intensity=.65;env.ssao_power=1.1
	env.glow_intensity=.08;env.glow_hdr_threshold=1.6
	env.fog_density=.00035;env.fog_light_color=Color("68717a")
	base.key_light.light_color=Color("fffdf9");base.key_light.light_energy=.82
	base.key_light.shadow_opacity=.64;base.key_light.shadow_blur=1.4 if level>=2 else 1.0
	for light in base.court_lights:light.light_color=Color("fffdf9");light.light_energy=2.7
	for fill in base.bounce_lights:fill.light_color=Color("f7f8fa");fill.light_energy=.45
	for light in upper_lights:light.visible=level>0;light.shadow_enabled=false
	if integrated!=null:integrated.quality(values)
	elif prototype!=null:prototype.quality(int(values.get("material_detail",2)))
func surfaces():
	for m in [arena.court_material,arena.attack_zone_material,arena.home_half.material_override]:
		m.albedo_texture=Assets.texture("maple_albedo86.png")
		m.normal_texture=Assets.texture("maple_normal86.png");m.normal_scale=.22
		m.roughness_texture=Assets.texture("maple_roughness86.png");m.roughness=.88;m.metallic_specular=.28
	arena.dynamic_net.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func pipe(a: Vector3,b: Vector3) -> Transform3D:
	var delta:=b-a
	return Transform3D(Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(1,delta.length(),1)),(a+b)*.5)
func architecture():
	var tube:=CylinderMesh.new();tube.top_radius=.026;tube.bottom_radius=.026;tube.height=1;tube.radial_segments=8
	var rails: Array[Transform3D]=[]
	for side in [-1,1]:
		for aisle in 4:
			var z: float=(aisle*15-28.0)*.62
			for row in [0,3,6,9]:
				var at:=Vector3(side*(11.7+row*.9),row*.48+.35,z)
				rails.append(pipe(at,at+Vector3(0,.88,0)))
			rails.append(pipe(Vector3(side*11.7,1.23,z),Vector3(side*19.8,5.55,z)))
	base.instances("StairHandrails86",tube,base.material("aab2b6",.42,.65),rails)
	var steel: Array[Transform3D]=[]
	for z in [-22.0,-14.0,-6.0,2.0,10.0,18.0]:
		for x in range(-20,20,4):
			steel.append(pipe(Vector3(x,14.6,z),Vector3(x+2,15.6,z)))
			steel.append(pipe(Vector3(x+2,15.6,z),Vector3(x+4,14.6,z)))
	base.instances("TriangulatedRoof86",tube,base.material("909a9f",.50,.52),steel)
	var panels: Array[Transform3D]=[];var support: Array[Transform3D]=[]
	for x in [-15.0,-5.0,5.0,15.0]:
		for z in [-18.0,-6.0,6.0,18.0]:
			panels.append(base.scaled_box(Vector3(x,16.5,z),Vector3(8.6,.10,9.8)))
			support.append(base.scaled_box(Vector3(x,16.40,z-4.9),Vector3(8.7,.12,.07)))
	base.instances("RoofInsulatedPanels86",BoxMesh.new(),base.material("9ca3a7",.90),panels)
	base.instances("RoofPanelFrames86",BoxMesh.new(),base.material("5c6972",.54,.35),support)
	var fascia: Array[Transform3D]=[]
	for side in [-1,1]:
		fascia.append(base.scaled_box(Vector3(side*21.8,5.55,0),Vector3(.16,.52,42)))
	fascia.append(base.scaled_box(Vector3(0,5.1,-26.4),Vector3(37,.55,.16)))
	base.instances("UpperConcourseTrim86",BoxMesh.new(),base.material("4c6072",.72),fascia)
	# Thin steps/rails and roof panels are MultiMeshes: scenery proxies unchanged.


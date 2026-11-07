extends Node3D
const Assets=preload("res://src/source_assets.gd")
var revision
var base
var arena
var pilot
var athletes: Array=[]
var details: Array[Node3D]=[]
var crowd_original: Dictionary={}
var crowd_cache: Dictionary={}
var crowd_extra: Dictionary={}
var quality_level:=2
func configure(parent_revision):
	name="StadiumFidelity89";revision=parent_revision;base=revision.base;arena=revision.arena
	if revision.prototype!=null:revision.prototype.restore()
	pilot=load("res://src/pilot_quality89.gd").new();pilot.attach(arena.get_parent().players[0]);revision.prototype=pilot
	for i in range(1,arena.get_parent().players.size()):attach_athlete(arena.get_parent().players[i])
	var benches=arena.get_node_or_null("TeamBenches")
	if benches!=null:
		for entry in benches.actors:
			if not entry.coach:attach_athlete(entry.actor)
	pilot.shoes(arena.get_parent().players)
	architecture();equipment();crowd_surfaces()
	reference_finishes()
	for node in arena.get_children():
		if node is MultiMeshInstance3D and node.has_meta("spectators"):crowd_original[node]=node.multimesh.mesh
	quality(base.settings)
func attach_athlete(actor):
	if not actor.body_parts.has("head"):return
	var adapter=load("res://src/character_quality89.gd").new();adapter.attach(actor);athletes.append(adapter)
func batch(label: String,mesh: Mesh,material: Material,transforms: Array[Transform3D]):
	var node=base.instances(label,mesh,material,transforms);details.append(node);return node
func architecture():
	var metal=base.material("9aa3a8",.42,.70)
	var duct:=CylinderMesh.new();duct.top_radius=.28;duct.bottom_radius=.28;duct.height=1;duct.radial_segments=20
	var ducts: Array[Transform3D]=[]
	for x in [-16.0,16.0]:ducts.append(revision.pipe(Vector3(x,15.85,-24),Vector3(x,15.85,23)))
	batch("VentilationDucts89",duct,metal,ducts)
	var ribs: Array[Transform3D]=[]
	var ring:=TorusMesh.new();ring.inner_radius=.277;ring.outer_radius=.298;ring.rings=20;ring.ring_segments=6
	for x in [-16.0,16.0]:
		for z in range(-23,24,3):ribs.append(Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(x,15.85,z)))
	batch("DuctJoints89",ring,metal,ribs)
	var walk: Array[Transform3D]=[];var columns: Array[Transform3D]=[];var frames: Array[Transform3D]=[];var glass: Array[Transform3D]=[]
	for side in [-1,1]:
		walk.append(base.scaled_box(Vector3(side*22.1,6.0,-1),Vector3(1.35,.18,47)))
		for z in [-22,-14,-6,2,10,18]:
			columns.append(base.scaled_box(Vector3(side*22.7,9.3,z),Vector3(.45,7,.5)))
			frames.append(base.scaled_box(Vector3(side*22.65,7.9,z+2.6),Vector3(.12,2.3,4.2)))
			glass.append(base.scaled_box(Vector3(side*22.56,7.9,z+2.6),Vector3(.025,1.95,3.8)))
	batch("ConcourseWalk89",BoxMesh.new(),base.material("777f84",.92),walk)
	batch("StructuralColumns89",BoxMesh.new(),base.material("b0b2af",.86),columns)
	batch("ConcourseFrames89",BoxMesh.new(),base.material("333d46",.45,.48),frames)
	batch("ConcourseGlazing89",BoxMesh.new(),base.material("536775",.18,.48),glass)
	var battens: Array[Transform3D]=[]
	for z in range(-24,26,2):battens.append(base.scaled_box(Vector3(0,16.34,z),Vector3(42,.08,.035)))
	batch("AcousticRoofBattens89",BoxMesh.new(),base.material("6f787e",.82),battens)
	var bench_rails: Array[Transform3D]=[];var bench_pads: Array[Transform3D]=[]
	for side in [-1,1]:
		for slot in 8:
			var z: float=side*(4.65+slot*.72)
			bench_pads.append(base.scaled_box(Vector3(-7.40,.49,z),Vector3(.59,.065,.59)))
			bench_pads.append(base.scaled_box(Vector3(-7.65,.83,z),Vector3(.08,.51,.59)))
			for x in [-7.64,-7.17]:bench_rails.append(base.scaled_box(Vector3(x,.25,z),Vector3(.035,.46,.035)))
	batch("BenchIndividualCushions89",BoxMesh.new(),base.material("244d65",.77),bench_pads)
	batch("BenchSteelFrames89",BoxMesh.new(),metal,bench_rails)
	var feet: Array[Transform3D]=[]
	for z in [-1.2,0,1.2]:
		feet.append(base.scaled_box(Vector3(-7.53,.845,z),Vector3(.22,.025,.32)))
		feet.append(base.scaled_box(Vector3(-7.50,.91,z),Vector3(.035,.14,.045)))
	batch("MonitorFeet89",BoxMesh.new(),base.material("272e35",.52),feet)
func equipment():
	var rope:=CylinderMesh.new();rope.top_radius=.006;rope.bottom_radius=.006;rope.height=1;rope.radial_segments=8
	var ties: Array[Transform3D]=[]
	for side in [-1,1]:
		for y in [.98,1.65,2.43]:ties.append(revision.pipe(Vector3(side*4.53,y,0),Vector3(side*5.16,y,.01)))
	batch("NetTensionCords89",rope,base.material("d2d0c6",.84),ties)
	var turnbuckle:=CylinderMesh.new();turnbuckle.top_radius=.018;turnbuckle.bottom_radius=.018;turnbuckle.height=1;turnbuckle.radial_segments=12
	var mechanisms: Array[Transform3D]=[]
	for side in [-1,1]:mechanisms.append(revision.pipe(Vector3(side*5.13,1.62,.02),Vector3(side*5.13,1.86,.02)))
	batch("NetTurnbuckles89",turnbuckle,base.material("909ba2",.30,.85),mechanisms)
	for node in arena.find_children("*","MeshInstance3D",true,false):
		var material=node.material_override
		if material is StandardMaterial3D and node.mesh is BoxMesh:
			if node.name=="ScorersTableTop":material.roughness=.48;material.normal_texture=Assets.texture("sport_normal89.png");material.normal_enabled=true;material.normal_scale=.08
			if node.get_parent().name.to_lower().contains("credem"):
				material.normal_texture=Assets.texture("T_Furn_VolleyNetPad01A_Normal.png");material.normal_enabled=material.normal_texture!=null;material.normal_scale=.22;material.roughness=.66
func crowd_surfaces():
	if arena.crowd_materials.is_empty():return
	var shader:=Shader.new();var code: String=arena.crowd_materials[0].shader.code
	code=code.replace("person=INSTANCE_CUSTOM;","person=INSTANCE_CUSTOM;\n\tfloat face89=smoothstep(.98,1.22,VERTEX.y);\n\tVERTEX.x*=1.0+face89*(person.y-.5)*.10;\n\tVERTEX.z+=face89*(person.z-.6)*.008;")
	code=code.replace("ALBEDO=mix(skin,shirt,clothing);","skin*=mix(vec3(.55,.39,.29),vec3(1.05,1.00,.96),smoothstep(.12,.78,person.z));\n\tALBEDO=mix(skin,shirt,clothing);")
	code=code.replace("uniform float clothing=0.0;","uniform float clothing=0.0;\nuniform float eyes89=0.0;")
	var end:=code.rfind("}")
	code=code.substr(0,end)+"\nif(eyes89>.5){vec2 p=(UV-vec2(.5))*1.9+vec2(.5);float iris=1.0-smoothstep(.465,.495,length(p-vec2(.5)));ALBEDO=mix(vec3(.78,.74,.69),texture(diffuse_map,clamp(p,vec2(.01),vec2(.99))).rgb,iris);ROUGHNESS=.18;SPECULAR=.45;}\n}"
	shader.code=code
	for material in arena.crowd_materials:material.shader=shader
func reference_finishes():
	# Material/wardrobe changes only: the court dimensions, club colours,
	# spectator placement and existing response animations are preserved.
	var palette: Array[Color]=[Color("20242b"),Color("253750"),Color("cfcec4"),Color("7c2730"),Color("183e38"),Color("636363"),Color("d9d5ca"),Color("bc8b48"),Color("465163"),Color("263e69"),Color("9aacae"),Color("423c37"),Color("e3dfd3"),Color("9b3334"),Color("314b58"),Color("595f53")]
	var serial:=0
	for node in arena.get_children():
		if not node is MultiMeshInstance3D:continue
		if node.has_meta("spectators"):
			for i in node.multimesh.instance_count:
				var choice:=posmod(serial*7+int(serial/13),palette.size())
				# Instance colours are linear vertex data, unlike StandardMaterial
				# source-colour uniforms. Convert explicitly to avoid washed-out shirts.
				node.multimesh.set_instance_color(i,palette[choice].srgb_to_linear());serial+=1
		elif node.material_override is StandardMaterial3D and node.material_override.albedo_texture==Assets.texture("T_Furn_PublicChairC_BaseColor.png"):
			node.material_override.albedo_color=Color("39434b");node.material_override.roughness=.73;node.material_override.metallic_specular=.20
func floor_material(material: StandardMaterial3D,level: int):
	material.albedo_texture=Assets.texture("sport_floor89.png") if level>0 else null
	material.normal_texture=Assets.texture("sport_normal89.png") if level>0 else null
	material.normal_enabled=level>0;material.normal_scale=.12
	material.uv1_scale=Vector3(5,9 if material==arena.court_material else 3,1)
	material.roughness_texture=Assets.texture("sport_rough89.png") if level>0 else null
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness=.75 if level==0 else .83;material.metallic_specular=.28
func quality(values: Dictionary):
	quality_level=int(values.get("material_detail",2))
	pilot.quality(quality_level)
	for actor in athletes:actor.quality(quality_level)
	for material in [arena.court_material,arena.attack_zone_material,arena.home_half.material_override]:floor_material(material,quality_level)
	for node in details:node.visible=quality_level>=1
	for label in ["DuctJoints89","MonitorFeet89","NetTurnbuckles89","ConcourseGlazing89"]:
		for node in details:
			if node.name==label:node.visible=quality_level>=2
	for label in ["TriangulatedRoof86","StairHandrails86","RoofPanelFrames86"]:
		var node=base.get_node_or_null(label)
		if node!=null:node.visible=quality_level>=1
	for node in crowd_original:
		node.lod_bias=[.15,.40,.80,1.15][quality_level]
		var key: String=str(node.get_instance_id())+":"+str(quality_level)
		if not crowd_cache.has(key):
			var variant: int=node.get_meta("crowd_variant89",0)
			var mesh: ArrayMesh=load("res://assets/art/quality89/crowd/v%02d_l%d.res"%[variant,quality_level]).duplicate()
			for s in mesh.get_surface_count():
				if s<3:mesh.surface_set_material(s,crowd_original[node].surface_get_material(s))
				else:
					var extra_key: String=str(node.get_instance_id())+":"+str(s)
					if not crowd_extra.has(extra_key):
						var m: ShaderMaterial=crowd_original[node].surface_get_material(0).duplicate()
						m.set_shader_parameter("diffuse_map",Assets.texture("lambertian.jpg" if s==3 else "T_Char_Eye_Brown_Base.png"));m.set_shader_parameter("eyes89",1.0 if s==4 else 0.0)
						crowd_extra[extra_key]=m;arena.crowd_materials.append(m)
					mesh.surface_set_material(s,crowd_extra[extra_key])
			crowd_cache[key]=mesh
		node.multimesh.mesh=crowd_cache[key]
		var density: float=minf([.35,.65,1.0][int(values.get("crowd",2))],[.25,.55,1.0,1.0][quality_level])
		node.multimesh.visible_instance_count=roundi(node.multimesh.instance_count*density)
	arena.free_zone_material.roughness=.66 if quality_level>0 else .88
	arena.free_zone_material.roughness_texture=null
	arena.free_zone_material.normal_enabled=quality_level>0



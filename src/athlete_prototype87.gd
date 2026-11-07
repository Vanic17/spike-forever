extends RefCounted
## Opt-in single-athlete visual prototype. No simulation or pose ownership.
const Assets=preload("res://src/source_assets.gd")
var actor
var meshes: Dictionary={}
var original: Dictionary={}
var skin_material: StandardMaterial3D
var strand_material: StandardMaterial3D
var occlusion: StandardMaterial3D
var lashes: StandardMaterial3D
var cloth_source
var cloth_material
var nails: MeshInstance3D
var eyelash_node: MeshInstance3D
func attach(player):
	actor=player
	for part in ["head","body","cloth","hair","beard","eyes","shoes"]:
		if actor.body_parts.has(part):original[part]=actor.body_parts[part].mesh
		meshes[part]=load("res://assets/art/athlete87/"+part+".res")
	meshes.cloth=preload("res://src/club_kits.gd").mesh_with_print_uv(meshes.cloth)
	skin_material=StandardMaterial3D.new()
	skin_material.albedo_texture=Assets.texture("T_Char_Head_Tier1_M_Perrin_Base.png")
	skin_material.normal_texture=Assets.texture("T_Char_Head_Tier1_M_Perrin_Normal.png");skin_material.normal_enabled=true
	skin_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	skin_material.normal_scale=.65;skin_material.cull_mode=BaseMaterial3D.CULL_BACK;skin_material.metallic_specular=.30
	# Alpha of the authored facial atlas stores roughness, not transparency.
	skin_material.roughness_texture=Assets.texture("T_Char_Head_Tier1_M_Perrin_Base.png");skin_material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_ALPHA
	skin_material.roughness=.86
	strand_material=StandardMaterial3D.new();strand_material.vertex_color_use_as_albedo=true
	strand_material.albedo_color=Color(.35,.26,.18)
	strand_material.roughness=.90;strand_material.metallic_specular=.08;strand_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	occlusion=StandardMaterial3D.new();occlusion.albedo_color=Color(0,0,0,0);occlusion.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	lashes=Assets.material("T_Char_Eyelashes.png","",Color("33271e"),.65)
	lashes.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;lashes.alpha_scissor_threshold=.4
	actor.set_meta("visual_prototype87",self)
	nails=MeshInstance3D.new();nails.name="Prototype87Fingernails";actor.visual_root.add_child(nails)
	nails.mesh=load("res://assets/art/athlete87/nails.res");nails.skin=actor.skeleton.create_skin_from_rest_transforms();nails.skeleton=nails.get_path_to(actor.skeleton);nails.extra_cull_margin=3
	meshes.nails=nails.mesh
	eyelash_node=MeshInstance3D.new();eyelash_node.name="Prototype87Eyelashes";actor.visual_root.add_child(eyelash_node)
	eyelash_node.mesh=load("res://assets/art/athlete87/lashes.res");eyelash_node.skin=nails.skin;eyelash_node.skeleton=eyelash_node.get_path_to(actor.skeleton);eyelash_node.extra_cull_margin=3;eyelash_node.material_override=lashes
	meshes.lashes=eyelash_node.mesh
	var keratin:=StandardMaterial3D.new();keratin.albedo_color=Color("bfa699");keratin.roughness=.40;keratin.metallic_specular=.28;keratin.cull_mode=BaseMaterial3D.CULL_DISABLED;nails.material_override=keratin
	var eye_material:=ShaderMaterial.new();eye_material.shader=load("res://src/athlete_eye87.gdshader");eye_material.set_shader_parameter("iris",Assets.texture("T_Char_Eye_Brown_Base.png"));actor.body_parts.eyes.material_override=eye_material
	apply()
func quality(_level: int):
	if is_instance_valid(actor):apply()
func apply():
	for part in ["head","body","cloth","hair","eyes","shoes"]:
		actor.body_parts[part].mesh=meshes[part]
	var node: MeshInstance3D=actor.body_parts.head
	node.material_override=skin_material
	var hair: MeshInstance3D=actor.body_parts.hair;hair.visible=true;hair.material_override=strand_material
	for s in hair.get_surface_override_material_count():hair.set_surface_override_material(s,null)
	var beard=actor.body_parts.get("beard")
	if beard==null:
		beard=MeshInstance3D.new();actor.visual_root.add_child(beard);beard.skin=actor.skeleton.create_skin_from_rest_transforms();beard.skeleton=beard.get_path_to(actor.skeleton);actor.body_parts.beard=beard;beard.extra_cull_margin=3
	beard.mesh=meshes.beard;beard.visible=true;beard.material_override=strand_material
	for s in beard.get_surface_override_material_count():beard.set_surface_override_material(s,null)
	# Keep team kit, player name, number and print UVs; change only the weave.
	if actor.cloth_material!=cloth_material:
		cloth_source=actor.cloth_material
		if cloth_source is ShaderMaterial:
			cloth_material=cloth_source.duplicate()
		else:
			cloth_material=ShaderMaterial.new()
		cloth_material.shader=load("res://src/athlete_fabric87.gdshader")
		if cloth_source is StandardMaterial3D:
			cloth_material.set_shader_parameter("fabric",cloth_source.albedo_texture)
			cloth_material.set_shader_parameter("fabric_normal",cloth_source.normal_texture)
			var blank:=Image.create(1,1,false,Image.FORMAT_RGBA8);blank.fill(Color(0,0,0,0))
			cloth_material.set_shader_parameter("identity",ImageTexture.create_from_image(blank))
	actor.cloth_material=cloth_material;actor.body_parts.cloth.material_override=cloth_material
func restore():
	for part in original:actor.body_parts[part].mesh=original[part]
	actor.remove_meta("visual_prototype87")
static func shoes(players: Array):
	# Presentation only: independent footwear colors, never shared across the squad.
	var palette=[Color("ebebe4"),Color("25313f"),Color("c1d443"),Color("e68545"),Color("afc5d5"),Color("d8c4b9"),Color("839eaa"),Color("e2d5a7")]
	for i in players.size():
		var shoe=players[i].body_parts.get("shoes")
		if shoe==null:continue
		var m: StandardMaterial3D=shoe.material_override.duplicate()
		m.albedo_color=palette[(i*3+i/6)%palette.size()]
		m.albedo_texture=Assets.texture(["SK_Char_Shoe_M_01_Base02.png","SK_Char_Shoe_M_01_Base05.png","SK_Char_Shoe_M_01_Base08.png"][i%3])
		if i==0 and players[i].has_meta("visual_prototype87"):
			m.albedo_texture=Assets.texture("shoe02_87.png");m.albedo_color=Color.WHITE
			m.normal_texture=Assets.texture("T_Char_Shoes_M_02_Normal.png");m.normal_enabled=true
			m.roughness_texture=Assets.texture("T_Char_Shoes_M_02_AORM.png");m.ao_texture=m.roughness_texture
		shoe.material_override=m

extends "res://src/athlete_prototype87.gd"
## A single real-scan athlete. Same skeleton, simulation, and animation owner.
var seam_node: MeshInstance3D
var body_material: StandardMaterial3D
func attach(player):
	super.attach(player)
	for part in ["head","body","cloth","hair","beard","eyes"]:meshes[part]=load("res://assets/art/athlete88/"+part+".res")
	meshes.cloth=preload("res://src/club_kits.gd").mesh_with_print_uv(meshes.cloth)
	skin_material.albedo_texture=Assets.texture("lambertian.jpg")
	skin_material.normal_texture=Assets.texture("scan_normal88.png");skin_material.normal_scale=.4
	skin_material.roughness_texture=Assets.texture("scan_roughness88.png");skin_material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;skin_material.roughness=1.0
	skin_material.subsurf_scatter_enabled=true;skin_material.subsurf_scatter_skin_mode=true;skin_material.subsurf_scatter_strength=.055;skin_material.subsurf_scatter_texture=Assets.texture("scan_sss88.png")
	# The scan's eyelids use real surface geometry, with independent eyeballs.
	eyelash_node.hide();meshes.erase("lashes")
	actor.set_meta("visual_next88",true)
	body_material=actor.body_parts.body.material_override.duplicate()
	body_material.albedo_texture=Assets.texture("body_albedo88.png");body_material.roughness=.58;body_material.metallic_specular=.30
	body_material.subsurf_scatter_enabled=true;body_material.subsurf_scatter_skin_mode=true;body_material.subsurf_scatter_strength=.035
	seam_node=MeshInstance3D.new();seam_node.name="Next88StitchedEdges";actor.visual_root.add_child(seam_node)
	seam_node.mesh=load("res://assets/art/athlete88/seams.res");seam_node.skin=nails.skin;seam_node.skeleton=seam_node.get_path_to(actor.skeleton);seam_node.extra_cull_margin=3;meshes.seams=seam_node.mesh
	apply()
func apply():
	super.apply()
	if actor.has_meta("visual_next88"):
		eyelash_node.hide()
		if cloth_material!=null and cloth_material.shader!=load("res://src/athlete_fabric88.gdshader"):cloth_material.shader=load("res://src/athlete_fabric88.gdshader")
		if seam_node!=null:seam_node.material_override=cloth_material
		if body_material!=null:actor.body_parts.body.material_override=body_material
func quality(level: int):
	super.quality(level)
	if skin_material!=null:skin_material.subsurf_scatter_enabled=level>=2
	if body_material!=null:body_material.subsurf_scatter_enabled=level>=2

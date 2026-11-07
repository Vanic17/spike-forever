extends RefCounted
## One athlete only. Mesh resources have the original bind frame and bone IDs.
const Assets=preload("res://src/source_assets.gd")
var actor
var originals: Dictionary={}
var meshes: Dictionary={}
func attach(player):
	actor=player
	for part in ["head","body","eyes","shoes"]:
		if not actor.body_parts.has(part):continue
		originals[part]=actor.body_parts[part].mesh
		var path: String="res://assets/art/visual86/prototype_"+part+".res"
		if ResourceLoader.exists(path):
			var candidate=load(path)
			if candidate is ArrayMesh:meshes[part]=candidate
	actor.set_meta("visual_prototype86",true)
	var face: StandardMaterial3D=actor.body_parts.head.material_override
	face.normal_scale=.48;face.metallic_specular=.32
	apply_skin(actor)
static func apply_skin(player,appearance=null):
	if not player.body_parts.has("head"):return
	var face: StandardMaterial3D=player.body_parts.head.material_override
	var beard=player.body_parts.get("beard")
	var detailed: bool=beard!=null and beard.visible
	if appearance is Dictionary:player.set_meta("visual_appearance86",appearance.duplicate(true))
	var selected: Dictionary=player.get_meta("visual_appearance86",player.roster_identity.get("appearance",{}))
	var bald: bool=str(selected.get("hair_style",selected.get("hair_length","")))=="pelato"
	var prefix: String="T_Char_Head_Caucasian_M_01" if detailed else "T_Char_Head_Caucasian_M_02"
	var albedo=Assets.texture(prefix+"_Base.png" if not bald or detailed else "T_Char_Head_M_Coach02_Base.png")
	if albedo==null:return
	face.albedo_texture=albedo
	var normal=Assets.texture(prefix+"_Normal.png" if not bald or detailed else "T_Char_Head_M_Coach02_Normal.png")
	if normal!=null:face.normal_texture=normal
	var roughness=Assets.texture(prefix+"_Rough.png")
	if roughness!=null:face.roughness_texture=roughness
	var scatter=Assets.texture(prefix+"_SSS.png")
	if scatter!=null:face.subsurf_scatter_texture=scatter
	face.normal_scale=.48
func quality(level: int):
	if actor==null or not is_instance_valid(actor):return
	apply_skin(actor)
	for part in originals:
		var enabled: bool=meshes.has(part) and (level>=2 if part in ["head","eyes"] else level>=3)
		var target: Mesh=meshes[part] if enabled else originals[part]
		if actor.body_parts[part].mesh!=target:actor.body_parts[part].mesh=target
func restore():
	if actor==null or not is_instance_valid(actor):return
	for part in originals:actor.body_parts[part].mesh=originals[part]
	if actor.has_meta("visual_prototype86"):actor.remove_meta("visual_prototype86")
	if actor.has_meta("visual_appearance86"):actor.remove_meta("visual_appearance86")

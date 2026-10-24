extends RefCounted
## Shared source meshes, rebound to the existing skeleton. No per-frame IO.
const PSK=preload("res://src/psk.gd")
const Assets=preload("res://src/source_assets.gd")
const STYLES={"corti":"SK_Char_Hair_M_Blond_Short","rasati":"SK_Char_Hair_Tier1_M_Grebennikov","sfumati":"SK_Char_Hair_M_05","mossi":"SK_Char_Hair_M_Caucasian_02","ricci":"SK_Char_Hair_M_Afro_02","afro":"SK_Char_Hair_M_Afro_01","frangia":"SK_Char_Hair_M_Asian03","riga":"SK_Char_Hair_M_Asian04","lunghi":"SK_Char_Hair_M_Rezende","treccine":"SK_Char_Hair_M_Rasta"}
const BEARDS={"corta":"SK_Char_Hair_M_Beard_Ngapeth","piena":"SK_Char_Hair_M_Beard_Watten"}
const COLORS={"nero":Color("191411"),"marrone":Color("493024"),"castano chiaro":Color("806041"),"biondo":Color("b59b68"),"rosso":Color("824827"),"grigio":Color("8a827b")}
const SKIN={"rosa":Color.WHITE,"chiara":Color.WHITE,"olivastra":Color("dfcbb4"),"ambrata":Color("ba9475"),"scura":Color("805d46"),"nero":Color("604331"),"ebano":Color("503a30")}
static var meshes: Dictionary={}
static var descriptions: Dictionary={}
static var materials: Dictionary={}
static func model(name: String, bones: Array[String]):
	if not meshes.has(name):
		var p=PSK.new()
		if not p.load_file("res://assets/art/appearance47/"+name+".psk",bones): return null
		meshes[name]=p
	return meshes[name]
static func material(key: String, color: Color) -> StandardMaterial3D:
	var cache_key:=key+":"+color.to_html()
	if materials.has(cache_key): return materials[cache_key]
	if descriptions.is_empty(): descriptions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/appearance47/materials.json"))
	var data: Dictionary=descriptions.get(key,{})
	var m:=Assets.material(data.get("Diffuse",""),"",color,.88)
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold=.32
	materials[cache_key]=m; return m
static func apply(avatar, appearance: Dictionary) -> void:
	var tone: Color=SKIN.get(appearance.get("skin_tone"),Color.WHITE)
	for part in ["head","body"]:
		if avatar.body_parts.has(part): avatar.body_parts[part].material_override.albedo_color=tone
	var style: String=str(appearance.get("hair_style",appearance.get("hair_length","corti")))
	if style=="<null>" or style=="Non specificato": style="corti"
	# The old head diffuse contains painted scalp hair. Use the original
	# bald scalp for a shaved head rather than leaving a brown hair patch.
	if avatar.body_parts.has("head"):
		avatar.body_parts.head.material_override.albedo_texture=Assets.texture("T_Char_Head_M_Coach02_Base.png" if style=="pelato" else "T_Char_Head_Caucasian_M_02_Base.png")
	var hair=avatar.body_parts.get("hair")
	if hair!=null:
		hair.scale=Vector3.ONE
		hair.visible=style!="pelato"
		if hair.visible: assign(hair,avatar,STYLES.get(style,STYLES.corti),COLORS.get(appearance.get("hair_color"),COLORS.marrone))
	var beard=avatar.body_parts.get("beard")
	var beard_style: String=str(appearance.get("beard","nessuna"))
	if beard==null and BEARDS.has(beard_style):
		beard=MeshInstance3D.new(); avatar.visual_root.add_child(beard)
		beard.skin=avatar.skeleton.create_skin_from_rest_transforms(); beard.skeleton=beard.get_path_to(avatar.skeleton)
		beard.extra_cull_margin=3; avatar.body_parts.beard=beard
	if beard!=null:
		beard.visible=BEARDS.has(beard_style)
		if beard.visible: assign(beard,avatar,BEARDS[beard_style],COLORS.get(appearance.get("hair_color"),COLORS.marrone))
static func assign(node: MeshInstance3D, avatar, name: String, color: Color) -> void:
	var source=model(name,avatar.model_bank.body.names)
	if source==null: return
	node.mesh=source.mesh; node.material_override=null
	for i in source.material_names.size(): node.set_surface_override_material(i,material(source.material_names[i],color))

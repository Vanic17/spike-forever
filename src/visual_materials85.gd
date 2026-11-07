extends RefCounted
## Materials only. No mesh, rig, identity, animation or gameplay state writes.
static var enabled:=not "--graphics-original85" in OS.get_cmdline_user_args()
static var detail:=2
static var surfaces: Array[Dictionary]=[]
static var fabrics: Array[WeakRef]=[]
static func texture(name: String) -> Texture2D:return load("res://src/source_assets.gd").texture(name)
static func register(material: StandardMaterial3D,base: String,normal: String) -> void:
	if not enabled:return
	var kind:=""
	if base.begins_with("T_Char_Head_"):kind="head"
	elif base.begins_with("T_Char_Body_"):kind="skin"
	elif normal.contains("Shoe"):kind="shoe"
	elif base.contains("Eye_"):kind="eye"
	elif normal.contains("Cloth_"):kind="cloth"
	elif base.contains("PublicChair"):kind="seat"
	if kind.is_empty():return
	surfaces.append({"material":weakref(material),"kind":kind});configure(material,kind)
static func configure(m: StandardMaterial3D,kind: String) -> void:
	if kind in ["head","skin"]:
		m.metallic_specular=.30;m.normal_scale=.74 if detail>=1 else .45
		if kind=="head":
			m.roughness_texture=texture("T_Char_Head_Caucasian_M_02_Rough.png");m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;m.roughness=.92
		m.subsurf_scatter_enabled=detail>=3;m.subsurf_scatter_skin_mode=true;m.subsurf_scatter_strength=.085 if kind=="head" else .055
		if kind=="head":m.subsurf_scatter_texture=texture("T_Char_Head_Caucasian_M_02_SSS.png")
	elif kind=="shoe":
		m.albedo_texture=texture("SK_Char_Shoe_M_01_Base02.png")
		m.roughness_texture=texture("T_Char_Shoes_M_01_AORM.png");m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN;m.roughness=.95
		m.ao_texture=m.roughness_texture;m.ao_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;m.ao_enabled=detail>=1;m.normal_scale=.8;m.metallic_specular=.28
	elif kind=="eye":m.roughness=.18;m.metallic_specular=.45
	elif kind=="seat":m.roughness=.56;m.metallic_specular=.30;m.normal_scale=.28
	elif kind=="cloth":
		m.roughness_texture=texture("T_Char_Cloth_FRA_Roughness.png");m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;m.roughness=.98;m.normal_scale=.65;m.metallic_specular=.18
static func fabric(m: ShaderMaterial) -> void:
	if not enabled:return
	fabrics.append(weakref(m));m.set_shader_parameter("visual_detail85",float(detail));m.set_shader_parameter("fabric_micro85",texture("fabric_micro_normal.png"))
static func hair(m: StandardMaterial3D) -> void:
	if not enabled:return
	m.metallic_specular=.22;m.roughness=.76
	# Keep source alpha scissors: alpha-to-coverage on these overlapping cards
	# leaves a visible screen-door pattern across forehead and beard at 4x MSAA.
	m.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_OFF
static func quality(level: int) -> void:
	detail=clampi(level,0,3)
	for entry in surfaces:
		var material=entry.material.get_ref()
		if material!=null:configure(material,entry.kind)
	for reference in fabrics:
		var material=reference.get_ref()
		if material!=null:material.set_shader_parameter("visual_detail85",float(detail))

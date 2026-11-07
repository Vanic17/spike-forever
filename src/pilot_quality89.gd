extends "res://src/athlete_next88.gd"
var detail:=2
var full: Dictionary={}
var saved_original: Dictionary={}
func attach(player):
	super.attach(player)
	full=meshes.duplicate();saved_original=original.duplicate()
	nails.layers=2;eyelash_node.layers=2
	if seam_node!=null:seam_node.layers=2
	actor.set_meta("visual_quality89",self)
func apply():
	super.apply()
	if not actor.has_meta("visual_quality89"):return
	# The original appearance helper selects its own head atlas before this
	# callback. Keep its skin tint, but restore the scan's different UV atlas
	# whenever a roster, preset or edited identity is applied.
	skin_material.albedo_texture=Assets.texture("lambertian.jpg")
	var appearance: Dictionary=actor.libero_identity.get("appearance",{}) if actor.libero_active else actor.roster_identity.get("appearance",{})
	appearance=actor.get_meta("visual_appearance89",appearance)
	var source=load("res://src/player_appearance.gd")
	var style: String=str(appearance.get("hair_style",appearance.get("hair_length","corti")))
	var color: Color=source.COLORS.get(appearance.get("hair_color"),source.COLORS.marrone)
	strand_material.vertex_color_use_as_albedo=false;strand_material.albedo_color=color.darkened(.10)
	var hair=actor.body_parts.hair
	if style=="pelato":hair.hide()
	elif style not in ["corti","sfumati"]:
		var name: String=source.STYLES.get(style,source.STYLES.corti)
		source.assign(hair,actor,name,color);hair.mesh=load("res://assets/art/quality89/fit_"+name+".res")
	else:
		strand_material.vertex_color_use_as_albedo=false;strand_material.albedo_color=color.darkened(.10)
	var beard_style: String=str(appearance.get("beard","nessuna"))
	if beard_style not in ["corta","piena"]:actor.body_parts.beard.hide()
	elif beard_style=="piena":
		actor.body_parts.beard.mesh=load("res://assets/art/quality89/beard_full%d.res"%detail)
	actor.body_parts.beard.layers=actor.body_parts.head.layers
	nails.visible=detail>=2
	if seam_node!=null:seam_node.visible=detail>=2
func quality(level: int):
	detail=level
	if full.is_empty():return
	for part in ["head","eyes","hair","beard"]:meshes[part]=full[part] if level>=3 else load("res://assets/art/quality89/"+part+str(level)+".res")
	meshes.body=full.body if level>=2 else saved_original.body
	var cloth: Mesh=saved_original.cloth if level==0 else (load("res://assets/art/athlete87/cloth.res") if level<3 else full.cloth)
	meshes.cloth=preload("res://src/club_kits.gd").mesh_with_print_uv(cloth)
	super.quality(level)
	if cloth_material!=null:cloth_material.set_shader_parameter("visual_detail85",float(level))

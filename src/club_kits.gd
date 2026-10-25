extends RefCounted
## Shared immutable 2K fabric + a small, cached identity print per player.
## Only UV2 is added; vertex positions, weights, bones and native UVs are preserved.
const Assets = preload("res://src/source_assets.gd")
const FABRIC_SHADER = preload("res://src/club_kit.gdshader")
static var catalog: Dictionary = {}
static var fabrics: Dictionary = {}
static var print_meshes: Dictionary = {}
static var prints: Dictionary = {}
static var materials: Dictionary = {}

static func data() -> Dictionary:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/kits.json"))
	return catalog

static func selection(club: String, variant: String, libero: bool = false) -> Dictionary:
	var record: Dictionary = data().clubs.get(club,{})
	if record.is_empty(): return {}
	var selected := variant
	if libero:
		selected = "libero" if record.dedicated_libero else ("away" if variant == "home" else "home")
	var result: Dictionary = record.variants[selected].duplicate()
	result["_club_id"] = club
	result["_variant"] = selected
	return result

static func mesh_with_print_uv(source: ArrayMesh) -> ArrayMesh:
	var key := source.get_instance_id()
	if print_meshes.has(key): return print_meshes[key]
	var mesh := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var native_uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var print_uv := PackedVector2Array()
		for i in vertices.size():
			var p: Vector3=vertices[i]
			var uv := Vector2(-4,-4)
			# The negative-Z torso is the back in the original ActorX bind pose.
			# Assign the whole native back island, including its boundary vertices.
			# An off-body sentinel inside a triangle would clip names at the edges.
			if native_uv[i].y > 0.50 and native_uv[i].x < 0.395:
				uv = Vector2((0.18-p.x)/0.36,(1.55-p.y)/0.40)
			print_uv.append(uv)
		arrays[Mesh.ARRAY_TEX_UV2] = print_uv
		mesh.add_surface_from_arrays(source.surface_get_primitive_type(surface),arrays)
	print_meshes[key] = mesh
	return mesh

static func identity_name(person: Dictionary) -> String:
	# Keep an explicitly supplied shirt name, including compounds and diacritics.
	# Otherwise use the editable full name, never an unrelated baked photograph ID.
	return str(person.get("shirt_name",person.get("name",""))).strip_edges().to_upper()

static func identity_print(owner: Node, person: Dictionary) -> Texture2D:
	var name_text := identity_name(person)
	var number_text := str(int(person.jersey_number)) if person.get("jersey_number") != null else "?"
	var key := name_text + ":" + number_text
	if prints.has(key): return prints[key]
	var viewport := SubViewport.new()
	viewport.name = "JerseyPrint_" + str(key.hash())
	viewport.size = Vector2i(512,512)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	owner.get_tree().root.add_child(viewport)
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.0
	var label := Label.new()
	label.text = name_text
	label.position = Vector2(14,30)
	label.size = Vector2(484,84)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",font)
	var size := 44
	while size > 16 and font.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > 380:
		size -= 1
	label.add_theme_font_size_override("font_size",size)
	viewport.add_child(label)
	var number_label := Label.new()
	number_label.text = number_text
	number_label.position = Vector2(12,110)
	number_label.size = Vector2(488,330)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_label.add_theme_font_override("font",font)
	number_label.add_theme_font_size_override("font_size",276)
	viewport.add_child(number_label)
	var texture := viewport.get_texture()
	prints[key] = texture
	return texture

static func material(owner: Node, person: Dictionary, kit: Dictionary) -> ShaderMaterial:
	var texture_path: String = kit.texture
	var key := texture_path + ":" + identity_name(person) + ":" + str(person.get("jersey_number","?"))
	if materials.has(key): return materials[key]
	if not fabrics.has(texture_path):
		var image := Image.load_from_file(texture_path)
		if image == null: return null
		fabrics[texture_path] = preload("res://src/texture_quality.gd").create(image,texture_path)
	var result := ShaderMaterial.new()
	result.shader = FABRIC_SHADER
	result.set_shader_parameter("fabric",fabrics[texture_path])
	result.set_shader_parameter("fabric_normal",Assets.texture("T_Char_Cloth_MyTeam_Normal.png"))
	result.set_shader_parameter("identity",identity_print(owner,person))
	result.set_shader_parameter("ink",Color(kit.ink))
	materials[key] = result
	return result

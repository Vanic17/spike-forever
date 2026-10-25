extends RefCounted
## Runtime loading keeps the locally licensed archive separate from source code.
static var files: Dictionary = {}
static var textures: Dictionary = {}
static var scenes: Dictionary = {}

static func scan(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		files[file] = path.path_join(file)
	for folder in DirAccess.get_directories_at(path):
		scan(path.path_join(folder))

static func initialize() -> void:
	if not files.is_empty(): return
	for path in ["res://assets/art", "res://assets/arena_source"]:
		scan(path)

static func texture(name: String) -> Texture2D:
	initialize()
	if textures.has(name): return textures[name]
	if not files.has(name): return null
	var image := Image.load_from_file(files[name])
	if image == null or image.is_empty(): return null
	var result := preload("res://src/texture_quality.gd").create(image,files[name])
	textures[name] = result
	return result

static func scene(name: String) -> Node3D:
	initialize()
	if not files.has(name): return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(files[name], state) != OK: return null
	return document.generate_scene(state)

static func material(base: String, normal: String = "", color: Color = Color.WHITE, roughness: float = 0.65) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.albedo_texture = texture(base)
	result.roughness = roughness
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if not normal.is_empty():
		result.normal_texture = texture(normal)
		result.normal_enabled = result.normal_texture != null
		result.normal_scale = 0.55
	return result

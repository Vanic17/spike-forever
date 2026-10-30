extends RefCounted
## Presentation only: club identity is independent of kit, camera and court end.
const FILE := "res://assets/art/arenas70/profiles.json"
static var cached: Dictionary = {}
static func data() -> Dictionary:
	if cached.is_empty(): cached = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	return cached
static func profile(club: String) -> Dictionary:
	return data().clubs.get(club, {}).duplicate(true)
static func artwork(key: String) -> Dictionary:
	return data().artwork.get(key, {})

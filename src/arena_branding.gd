extends RefCounted
## Reuses scene geometry/materials; no collision, physics or animation writes.
static func apply(arena, club: String) -> bool:
	var profile: Dictionary = preload("res://src/arena_profiles.gd").profile(club)
	if profile.is_empty(): return false
	if arena.home_club_id == club: return true
	# Profile hex values describe the broadcast's sRGB pigments. Materials take
	# linear reflectance; otherwise overhead lights wash beige/red into white/pink.
	arena.free_zone_material.albedo_color = Color(profile.free_zone).srgb_to_linear()
	arena.court_material.albedo_color = Color(profile.court).srgb_to_linear()
	arena.attack_zone_material.albedo_color = Color(profile.attack_zone).srgb_to_linear()
	arena.home_half.visible = profile.has("second_half")
	if arena.home_half.visible:
		arena.home_half.material_override.albedo_color = Color(profile.second_half).srgb_to_linear()
	arena.sponsors.set_club(club)
	arena.home_club_id = club
	return true

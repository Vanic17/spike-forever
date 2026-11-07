extends RefCounted
## Reuses scene geometry/materials; no collision, physics or animation writes.
static func pigment(value: String) -> Color:
	var old: bool="--graphics-baseline85" in OS.get_cmdline_user_args() or not preload("res://src/visual_materials85.gd").enabled
	for arg in OS.get_cmdline_user_args():
		if arg in ["--graphics86-phase=lighting","--graphics86-phase=prototype"]:old=true
	# StandardMaterial's source_color uniform already converts the sRGB value.
	return Color(value).srgb_to_linear() if old else Color(value)
static func apply(arena, club: String) -> bool:
	var profile: Dictionary = preload("res://src/arena_profiles.gd").profile(club)
	if profile.is_empty(): return false
	if arena.home_club_id == club: return true
	arena.free_zone_material.albedo_color = pigment(profile.free_zone)
	arena.court_material.albedo_color = pigment(profile.court)
	arena.attack_zone_material.albedo_color = pigment(profile.attack_zone)
	arena.home_half.visible = profile.has("second_half")
	if arena.home_half.visible:
		arena.home_half.material_override.albedo_color = pigment(profile.second_half)
	arena.sponsors.set_club(club)
	arena.home_club_id = club
	return true

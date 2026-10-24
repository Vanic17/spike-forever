extends RefCounted
const PATH="user://roster-overrides.json"
const ROLES=["outside_hitter","middle_blocker","opposite","outside_hitter","middle_blocker","setter"]
var teams: Array=[]
var overrides: Dictionary={}
func _init() -> void:
	teams=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/league.json")).teams
	if FileAccess.file_exists(PATH):
		var data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if data is Dictionary: overrides=data
	for team in teams:
		for p in team.roster:
			if overrides.has(p.id):
				var base_appearance: Dictionary=p.get("appearance",{}).duplicate(true)
				var saved: Dictionary=overrides[p.id]
				p.merge(saved,true)
				# Old full-player saves contain unspecified appearance fields.
				# Preserve actual edits while allowing improved defaults underneath.
				for key in saved.get("appearance",{}):
					if saved.appearance[key]!=null: base_appearance[key]=saved.appearance[key]
				if not saved.get("appearance",{}).has("hair_style") and saved.get("appearance",{}).get("hair_length")!=null:
					base_appearance.hair_style=saved.appearance.hair_length
				p.appearance=base_appearance
func save(p: Dictionary) -> Error:
	overrides[p.id]=p.duplicate(true)
	var f=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if f==null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify(overrides,"\t")); f.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
func lineup(team: Dictionary) -> Array:
	var selected: Array=overrides.get("_lineups",{}).get(team.id,[])
	if selected.size()==7:
		var saved: Array=[]
		for i in 7:
			var matches: Array=team.roster.filter(func(p): return p.id==selected[i] and p.role==(ROLES+["libero"])[i])
			if matches.size()!=1 or selected.count(selected[i])!=1: break
			saved.append(matches[0])
		if saved.size()==7: return saved
	var result: Array=[]
	var used: Array=[]
	var projection: Dictionary=team.get("projected_starting_7",{})
	for role in ROLES+["libero"]:
		var candidates: Array=team.roster.filter(func(p): return p.role==role and not p.id in used)
		if candidates.is_empty(): return []
		var preferred=projection.get({"outside_hitter":"outside_hitters","middle_blocker":"middle_blockers"}.get(role,role),[])
		if preferred is String: preferred=[preferred]
		candidates.sort_custom(func(a,b): return preferred.has(a.name) and not preferred.has(b.name))
		result.append(candidates[0]); used.append(candidates[0].id)
	return result

func save_lineup(team: Dictionary, ids: Array) -> Error:
	if ids.size()!=7: return ERR_INVALID_DATA
	for i in 7:
		if ids.count(ids[i])!=1: return ERR_INVALID_DATA
		var matches: Array=team.roster.filter(func(p): return p.id==ids[i] and p.role==(ROLES+["libero"])[i])
		if matches.size()!=1: return ERR_INVALID_DATA
	var updated: Dictionary=overrides.duplicate(true)
	if not updated.has("_lineups"): updated._lineups={}
	updated._lineups[team.id]=ids.duplicate()
	var f=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if f==null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify(updated,"\t")); f.close()
	var error=DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
	if error==OK: overrides=updated
	return error

extends RefCounted
## Ephemeral host catalogue. Never loads or writes the guest's local overrides.
const League=preload("res://src/league.gd")
var teams: Array=[]
var overrides: Dictionary={}
func capture(db) -> Dictionary:
	teams=db.teams.duplicate(true)
	overrides={"_lineups":db.overrides.get("_lineups",{}).duplicate(true)}
	return payload()
func payload() -> Dictionary:return {"schema":1,"teams":teams.duplicate(true),"lineups":overrides.get("_lineups",{}).duplicate(true)}
static func digest(value: Dictionary) -> String:return JSON.stringify(value,"",true).sha256_text()
func install(value: Dictionary,expected: String) -> bool:
	if value.get("schema")!=1 or not value.get("teams") is Array or value.teams.is_empty() or value.teams.size()>64 or digest(value)!=expected:return false
	if not value.get("lineups",{}) is Dictionary:return false
	var ids: Array=[]
	for t in value.teams:
		if not t is Dictionary or not t.get("roster") is Array or t.roster.size()<7 or t.roster.size()>64 or t.get("id","") in ids:return false
		ids.append(t.id)
		for p in t.roster:
			if not p is Dictionary or not p.get("ratings") is Dictionary or not p.get("role","") in League.ROLES+["libero"]:return false
	teams=value.teams.duplicate(true);overrides={"_lineups":value.get("lineups",{}).duplicate(true)};return true
static func fits_slot(role: String,slot: int) -> bool:return League.fits_slot(role,slot)
func lineup(team: Dictionary) -> Array:
	var selected: Array=overrides.get("_lineups",{}).get(team.id,[])
	var saved: Array=[]
	if selected.size()==7:
		for i in 7:
			var matches: Array=team.roster.filter(func(p):return p.id==selected[i] and fits_slot(p.role,i))
			if matches.size()!=1 or selected.count(selected[i])!=1:break
			saved.append(matches[0])
		if saved.size()==7:return saved
	var result: Array=[];var used: Array=[]
	for role in League.ROLES+["libero"]:
		var candidates: Array=team.roster.filter(func(p):return p.role==role and not p.id in used)
		if candidates.is_empty():return []
		var preferred=team.get("projected_starting_7",{}).get({"outside_hitter":"outside_hitters","middle_blocker":"middle_blockers"}.get(role,role),[])
		if preferred is String:preferred=[preferred]
		candidates.sort_custom(func(a,b):return preferred.has(a.name) and not preferred.has(b.name))
		result.append(candidates[0]);used.append(candidates[0].id)
	return result
func canonical(value: Dictionary) -> Dictionary:
	var matches: Array=teams.filter(func(t):return t.id==value.get("club",""))
	if matches.size()!=1 or not value.get("roster") is Array or value.roster.size()!=7:return {}
	var club: Dictionary=matches[0];var squad: Array=[];var ids: Array=[]
	for incoming in value.roster:
		if not incoming is Dictionary:return {}
		var players: Array=club.roster.filter(func(p):return p.id==incoming.get("id",""))
		if players.size()!=1 or players[0].id in ids:return {}
		squad.append(players[0].duplicate(true));ids.append(players[0].id)
	var result: Dictionary=value.duplicate(true);result.roster=squad
	result.bench=club.roster.filter(func(p):return not p.id in ids).duplicate(true)
	return result

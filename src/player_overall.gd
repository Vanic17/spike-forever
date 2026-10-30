extends RefCounted
## Role-weighted six-skill OVR supplied by the user, 30 October 2026.
const KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
const WEIGHTS={
	"setter":[15,5,10,45,5,20],
	"opposite":[20,5,10,5,40,20],
	"outside_hitter":[15,20,15,5,30,15],
	"middle_blocker":[15,5,5,5,35,35],
	"libero":[0,45,45,10,0,0]
}
static func calculate(ratings: Dictionary,role: String) -> int:
	var weights: Array=WEIGHTS.get(role,WEIGHTS.outside_hitter)
	var total:=0.0
	for i in KEYS.size():
		var value=float(ratings.get(KEYS[i],50))
		if not is_finite(value): value=50
		total+=clampf(value,0,99)*int(weights[i])
	return clampi(roundi(total/100.0),0,99)
static func refresh(player: Dictionary):
	if not player.has("ratings"): player.ratings={}
	player.ratings.generale=calculate(player.ratings,str(player.get("role","outside_hitter")))
static func refresh_teams(teams: Array):
	for team in teams:
		for player in team.get("roster",[]): refresh(player)

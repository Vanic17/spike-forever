extends "res://tools/Benchmark-Rendered42.gd"
func setup() -> void:
	super.setup()
	if "--plain-kits" in OS.get_cmdline_user_args(): return
	var db=load("res://src/league.gd").new()
	var kits=load("res://src/club_kits.gd")
	for side in 2:
		var team: Dictionary=db.teams[side]
		var squad: Array=db.lineup(team)
		var variant: String="home" if side==0 else "away"
		for i in 6:
			game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(team.id,variant),kits.selection(team.id,variant,true))
	game.reset_rally()
	print("KIT BENCHMARK: production club materials, live name/number prints, original skinning")

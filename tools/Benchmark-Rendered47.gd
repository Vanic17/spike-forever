extends "res://tools/Benchmark-Rendered42.gd"
func setup() -> void:
	super.setup()
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for side in 2:
		var club: Dictionary=db.teams.filter(func(t): return t.id==("sir-susa-scai-perugia" if side==0 else "vero-volley-monza"))[0]
		var squad: Array=db.lineup(club)
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(club.id,"home"),kits.selection(club.id,"home",true))

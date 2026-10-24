extends "res://tools/Preview-Approach42.gd"
func setup() -> void:
	super.setup()
	var db=load("res://src/league.gd").new()
	var kits=load("res://src/club_kits.gd")
	for side in 2:
		var team: Dictionary=db.teams[5 if side==0 else 3]
		var squad: Array=db.lineup(team)
		game.team_names[side]=team.name
		for i in 6:
			game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(team.id,"home"),kits.selection(team.id,"home",true))
	game.reset_rally(); begin(0)
	title.text="SPIKE FOREVER v45 / ITAS TRENTINO - ACQUA SANT'ANNA CUNEO"
func _process(elapsed: float) -> bool:
	if game==null: return false
	super._process(elapsed)
	if frame==45:
		RenderingServer.frame_post_draw.connect(func():
			root.get_texture().get_image().save_png("res://docs/kits45-match.png")
			print("KIT45 ACTUAL MATCH CAPTURE PASS")
			quit(),CONNECT_ONE_SHOT)
	return false

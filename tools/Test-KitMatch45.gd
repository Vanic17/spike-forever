extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false)
	var db=load("res://src/league.gd").new()
	var kits=load("res://src/club_kits.gd")
	var matches:=0
	for team in db.teams:
		var squad: Array=db.lineup(team)
		for variant in ["home","away"]:
			for side in 2:
				for i in 6:
					game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(team.id,variant),kits.selection(team.id,variant,true))
			for rotation in 6:
				game.rotations=[rotation,rotation]; game.server=0; game.reset_rally()
				for player in game.players:
					assert(player.cloth_material is ShaderMaterial)
					assert(not player.jersey_number.visible)
					var identity: Dictionary=player.libero_identity if player.libero_active else player.roster_identity
					assert(player.jersey_number.text==str(int(identity.jersey_number)))
					var expected: Dictionary=kits.selection(team.id,variant,player.libero_active)
					var active: Dictionary=player.libero_kit if player.libero_active else player.kit_identity
					assert(active._variant==expected._variant)
					var unchanged=player.cloth_material
					player.set_libero(player.libero_active)
					assert(player.cloth_material==unchanged,"Unchanged libero state must not rebuild materials")
				matches+=1
	assert(matches==144)
	print("KIT MATCH45 PASS: 12 clubs x 2 kits x 6 rotations; both teams, correct identities and libero kit; repeated states cached")
	quit()

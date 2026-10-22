extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	var cases:=0
	for rotation in 6:
		for serving_team in 2:
			game.rotations=[rotation,rotation]
			game.server=serving_team
			game.reset_rally()
			for team in 2:
				for i in range(team*6,team*6+6):
					var label: String=game.players[i].role_label()
					assert(label in ["S","OH1","OH2","OPP","MB1","MB2","L"])
					assert((label=="L")==game.Tactics.libero(i,rotation,team==serving_team))
					if team==serving_team and game.Tactics.front(i,rotation):
						var x: float=game.players[i].position.x*(1 if team==0 else -1)
						assert(x<0 if label.begins_with("OH") else (absf(x)<0.1 if label.begins_with("MB") else x>0))
			for possession in 2:
				game.possession=possession
				game.defensive_lanes.reset()
				var defending:=1-possession
				for phase in ["RECEIVE","SET","ATTACK"]:
					game.phase=phase if possession==0 else "CPU_"+phase
					var row: Array[int]=game.defensive_lanes.line(game,defending)
					assert(row.size()==3 and game.Tactics.ROLES[row[1]%6].begins_with("MB"))
					for index in row: assert(game.Tactics.front(index,rotation) and not game.players[index].libero_active)
					var before:=row.duplicate()
					var left: Vector3=game.players[row[0]].position
					var right: Vector3=game.players[row[2]].position
					game.players[row[0]].position.x=right.x+1
					game.players[row[2]].position.x=left.x-1
					assert(game.defensive_lanes.line(game,defending)==before,"Flank identity cannot switch during one opponent construction")
					game.players[row[0]].position=left
					game.players[row[2]].position=right
					for direction in 4:
						var hitter: int=game.Tactics.attacker(possession,rotation,direction,possession*6+5,game.Tactics.first_ball(game))
						assert(hitter>=0 and not game.players[hitter].libero_active and hitter%6!=5)
						if direction in [0,1]: assert(game.Tactics.front(hitter,rotation))
						if direction==3: assert(not game.Tactics.front(hitter,rotation))
						cases+=1
	print("ROLE MATRIX PASS: ",cases," offense/defense/rotation cases; role labels, serving specialist lanes, stable blocking flanks and legal attackers")
	game.free()
	quit()

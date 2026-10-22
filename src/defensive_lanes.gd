extends RefCounted
const Tactics=preload("res://src/tactics.gd")
var episode := ""
var rows: Dictionary = {}
func reset() -> void:
	episode=""
	rows.clear()
func update(game) -> void:
	if game.phase in ["POINT","LOOSE"]: return
	var key := str(game.rally_serial)+":"+str(game.possession)+":"+str(game.rotations)
	if key==episode: return
	episode=key
	rows.clear()
	var committed=game.get("rally_lanes")
	if committed!=null:
		for team in 2: rows[team]=committed.line(team)
		return
	for team in 2:
		var pins: Array[int]=[]
		var middle := -1
		for i in range(team*6,team*6+6):
			if not Tactics.front(i,game.rotations[team]): continue
			if Tactics.ROLES[i%6].begins_with("MB"): middle=i
			else: pins.append(i)
		# The specification fixes OH to Z4 and OPP/front S to Z2. Their
		# temporary crossing positions cannot reassign specialist responsibilities.
		pins.sort_custom(func(a,b): return Tactics.home(a,team,game.rotations[team],team==game.server,false).x<Tactics.home(b,team,game.rotations[team],team==game.server,false).x)
		# Keep R1's first-ball flanks for the following wall. Commit once per
		# possession, so both wings never cross under an incoming opposing set.
		if posmod(game.rotations[team],6)==0 and team!=game.server and pins.size()==2 and absf(game.players[pins[0]].position.x-game.players[pins[1]].position.x)>1.6:
			pins.sort_custom(func(a,b): return game.players[a].position.x<game.players[b].position.x)
		if pins.size()==2 and middle>=0: rows[team]=[pins[0],middle,pins[1]]
func line(game, team: int) -> Array[int]:
	update(game)
	var result: Array[int]=[]
	if rows.has(team): result.assign(rows[team])
	return result
func wing(game, index: int, team: int) -> float:
	var row:=line(game,team)
	if row.is_empty() or index==row[1]: return 0.0
	var world_side := -1.0 if index==row[0] else 1.0
	return world_side if team==0 else -world_side

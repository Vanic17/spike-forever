extends RefCounted
## A coordinated floor plan, separate from rotational identities and the wall.
const Tactics=preload("res://src/tactics.gd")
var cue:=""
var targets: Dictionary={}
var assignments: Dictionary={}
var defending_team:=-1
var attack_id:=-1

func reset() -> void:
	cue=""; targets.clear(); assignments.clear()
	defending_team=-1; attack_id=-1

func plan(game, team: int, hit: Vector3, blockers: Array) -> Dictionary:
	var key:=str([game.rally_serial,game.attack_serial,team,game.rotations[team],blockers])
	if cue==key: return targets
	reset(); cue=key
	defending_team=team; attack_id=game.attack_serial
	var side:=1.0 if team==0 else -1.0
	var hit_x:=hit.x*side
	var wing:=signf(hit_x) if absf(hit_x)>1.2 else 0.0
	if game.destination in [1,3]: wing=0.0
	var back: Array[int]=[]
	var short_x: Array[float]=[]
	for i in range(team*6,team*6+6):
		if i in blockers: continue
		if not Tactics.front(i,game.rotations[team]): back.append(i)
		else:
			# A free front-row player covers short balls rather than duplicating
			# the libero's deep diagonal lane. Join commands override this plan.
			var front_wing: float=game.defensive_lanes.wing(game,i,team)
			var x:=front_wing*2.6
			var current_x: float=game.players[i].position.x*side
			# In a rotation still crossing its specialist lanes, retreat on the
			# reachable side rather than traverse the whole court after the set.
			if absf(x-current_x)>3.0: x=clampf(current_x,-2.6,2.6)
			var best_short:=INF
			var chosen_x:=x
			for candidate in [-2.6,0.0,2.6]:
				if short_x.any(func(occupied): return absf(candidate-occupied)<1.5): continue
				var cost: float=absf(candidate-x)
				if cost<best_short: best_short=cost; chosen_x=candidate
			x=chosen_x
			short_x.append(x)
			targets[i]=Tactics.world(team,x,3.05)
			assignments[i]="short"
	if back.size()!=3: return targets
	var diagonal_x: float=-wing*3.15 if wing!=0 else -2.9
	var line_x: float=wing*3.15 if wing!=0 else 2.9
	var anchors: Array[Vector3]=[
		Tactics.world(team,diagonal_x,6.2 if wing!=0 else 5.7),
		Tactics.world(team,-wing*0.55,5.0 if blockers.size()>=2 else 5.7),
		Tactics.world(team,line_x,6.8 if wing!=0 else 5.7)]
	var best:=INF
	var order: Array=[]
	for permutation in [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]:
		var cost:=0.0
		for lane in 3:
			var i: int=back[permutation[lane]]
			cost+=game.players[i].position.distance_squared_to(anchors[lane])
			if Tactics.libero(i,game.rotations[team],team==game.server): cost+=0.0 if lane==0 else 22.0
		if cost<best: best=cost; order=permutation
	for lane in 3:
		var i: int=back[order[lane]]
		targets[i]=anchors[lane]; assignments[i]=["diagonal","seam","line"][lane]
	return targets

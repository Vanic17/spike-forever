extends RefCounted
const Model=preload("res://src/rotation_model.gd")
var last_ground: Dictionary={}
var service_snapshot: Dictionary={}

func reset() -> void:
	last_ground.clear()
	service_snapshot.clear()

func feet(game, index: int) -> Array:
	var player=game.players[index]
	var points: Array=[]
	if not player.last_pose.is_empty() and player.clips.has("idle"):
		for prefix in ["Left","Right"]:
			var foot: Vector3=player.current_joint(prefix+"Foot")
			var toe: Vector3=player.current_joint(prefix+"ToeBase")
			if minf(foot.y,toe.y)>0.19: continue
			var forward: Vector3=toe-foot
			forward.y=0
			if forward.length()<0.01: forward=player.global_basis.z
			forward=forward.normalized()
			var normal:=Vector3(forward.z,0,-forward.x)
			var centre: Vector3=(foot+toe)*0.5
			for a in [-1.0,1.0]:
				for b in [-1.0,1.0]: points.append(centre+forward*a*0.14+normal*b*0.055)
	if not points.is_empty(): last_ground[index]=points
	elif last_ground.has(index): return last_ground[index]
	else:
		# Initial procedural fallback has no imported skeleton; its planted shoe
		# regions still remain independent from the athlete's root/slot identity.
		for x in [-0.18,0.18]:
			for z in [-0.14,0.14]: points.append(player.global_transform*Vector3(x,0,z))
		last_ground[index]=points
	return points

func capture(game, serving_team: int) -> Dictionary:
	var receiving_team:=1-serving_team
	var by_zone: Dictionary={}
	var contacts: Dictionary={}
	var roster: Array=[]
	for index in range(receiving_team*6,receiving_team*6+6):
		var identity:=Model.state(index,game.rotations[receiving_team],false)
		by_zone[identity.rotation_slot]=index
		contacts[index]=feet(game,index)
		roster.append(identity)
	var checks:=Model.receiving_checks(by_zone,contacts,receiving_team)
	var legal:=true
	for check in checks: legal=legal and check.legal
	service_snapshot={"team":receiving_team,"rotation":game.rotations[receiving_team],"legal":legal,
		"checks":checks,"feet":contacts,"roster":roster,"zones":by_zone}
	return service_snapshot

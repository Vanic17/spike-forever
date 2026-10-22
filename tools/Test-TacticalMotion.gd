extends SceneTree
## Intent and role geometry checks independent of graphics and ball timing.
const Intent = preload("res://src/movement_intent.gd")
const RallyAI = preload("res://src/rally_ai.gd")
const Tactics = preload("res://src/tactics.gd")

func _initialize() -> void:
	var reactions := check_individual_reads()
	var consistency := check_frame_rates()
	var targets := check_role_targets()
	var report := {
		"support_reaction_seconds":reactions,
		"target_velocity_preserved_across_cues":true,
		"direct_contact_assistance_immediate":true,
		"maximum_60_120hz_steering_difference_m":consistency,
		"finite_role_phase_targets":targets,
		"middle_approach_threshold_continuous":true,
		"receiving_lanes_preserved":true,
		"coverage_rows_separated":true,
	}
	var output := FileAccess.open("res://docs/tactical-motion-quality-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("TACTICAL MOTION PASS: ",targets," role targets / continuous support velocity / staggered reads / 60-120Hz error=",consistency)
	quit()

func check_individual_reads() -> Array[float]:
	var starts: Array[float] = []
	var roles := ["OH1","MB1","OPP","OH2","L","S"]
	for number in 6:
		var movement = Intent.new()
		movement.configure(0,number+1)
		movement.reset(Vector3.ZERO)
		movement.observe("SET:1",roles[number],"cover",0)
		var first := -1.0
		for frame in 48:
			var point: Vector3 = movement.perceive(Vector3(2,0,1),frame/120.0,1.0/120.0)
			if point.length()>0.001 and first<0: first=frame/120.0
		starts.append(first)
		assert(movement.target_velocity.length()>0.1)
		var ongoing_velocity: Vector3 = movement.target_velocity
		var before: Vector3 = movement.filtered_target
		movement.observe("ATTACK:2",roles[number],"cover",0.4)
		assert(movement.target_velocity==ongoing_velocity,"A new touch must retain the preceding support stride")
		var maximum_step := 0.0
		for frame in 240:
			var point: Vector3 = movement.perceive(Vector3(-2,0,2),0.4+frame/120.0,1.0/120.0)
			maximum_step=maxf(maximum_step,before.distance_to(point))
			before=point
		assert(maximum_step<0.18,"A new touch must not teleport the steering target")
		assert(before.distance_to(Vector3(-2,0,2))<0.001)
		movement.observe("RECEIVE:3",roles[number],"contact",3)
		assert(movement.perceive(Vector3(3,0,6),3,1.0/120.0)==Vector3(3,0,6),"Contact deadlines bypass perception smoothing")
	assert(starts.max()-starts.min()>0.14,"The team must read the touch at different times")
	return starts

func track_at_rate(fps: int) -> Array[Vector3]:
	var movement = Intent.new()
	movement.configure(0,4)
	movement.reset(Vector3.ZERO)
	movement.observe("SET:1","OH2","cover",0)
	var samples: Array[Vector3] = []
	for frame in fps*2:
		var clock := float(frame)/fps
		if frame==fps: movement.observe("ATTACK:2","OH2","cover",clock)
		var target := Vector3(2,0,1) if frame<fps else Vector3(-1,0,3)
		var point: Vector3 = movement.perceive(target,clock,1.0/fps)
		if (frame+1)%(fps/2)==0: samples.append(point)
	return samples

func check_frame_rates() -> float:
	var rate_60 := track_at_rate(60)
	var rate_120 := track_at_rate(120)
	var difference := 0.0
	for sample in rate_60.size(): difference=maxf(difference,rate_60[sample].distance_to(rate_120[sample]))
	assert(difference<0.035,"Support response must be stable at 60 and 120Hz")
	return difference

func fixture(rotation: int, possession: int) -> Dictionary:
	var game := {"rotations":[rotation,rotation],"server":0,"possession":possession,"phase":"SET" if possession==0 else "CPU_SET","planned_hitter":0,"flight_left":0.421,"flight_target":Tactics.world(possession,0,1.5)+Vector3(0,2.5,0),"incoming_kind":"spike","receiver":3,"fast_set":false,"out_of_system":1,"phase_time":0.2,"players":[],"setter":possession*6+5,"hitter":possession*6,"attack_serial":1,"destination":0}
	for number in 12: game.players.append({"position":Tactics.home(number,int(number/6),rotation,int(number/6)==game.server,true)})
	game.hitter=Tactics.attacker(possession,rotation,0,game.setter)
	game.planned_hitter=game.hitter
	game.receiver=possession*6+3
	return game

func check_role_targets() -> int:
	var game := fixture(0,0)
	var before: Vector3 = RallyAI.target(game,1,0)
	game.flight_left=0.419
	var after: Vector3 = RallyAI.target(game,1,0)
	assert(before.distance_to(after)<0.02,"Middle approach cannot jump at the old 0.42-second threshold")
	game.phase="SET"
	game.players[game.planned_hitter].position.x=-0.1
	before=RallyAI.target(game,4,0)
	game.players[game.planned_hitter].position.x=0.1
	after=RallyAI.target(game,4,0)
	assert(before.distance_to(after)<0.001,"A pipe runner crossing centre must not reverse the libero's coverage lane")
	game.phase="RECEIVE"
	game.flight_left=0.9
	before=RallyAI.target(game,0,0)
	game.flight_left=0.22
	after=RallyAI.target(game,0,0)
	assert(before==after and after==RallyAI.defensive_base(game,0,0),"Off-ball wings retain the reference defensive lane until the dig")
	game.incoming_kind="serve"
	before=RallyAI.target(game,0,0)
	assert(before==Tactics.serve_position(0,0,0,false),"Supporting serve receivers retain the exact rotation formation")
	var count := 0
	for rotation in 6:
		for possession in 2:
			game=fixture(rotation,possession)
			for stage in ["RECEIVE","SET","ATTACK"]:
				game.phase=stage if possession==0 else "CPU_"+stage
				game.phase_time=0.6
				for number in 12:
					var team := int(number/6)
					var point: Vector3 = RallyAI.target(game,number,team)
					assert(point.is_finite() and absf(point.x)<=5.0 and absf(point.z)<=10.0)
					assert(point.z*(1.0 if team==0 else -1.0)>0)
					var role := Tactics.role(number,rotation,team==game.server)
					var front := Tactics.front(number,rotation)
					if team==possession and stage=="RECEIVE" and not front and role!="S":
						var home := Tactics.home(number,team,rotation,team==game.server,true)
						assert(point.distance_to(home)<0.5,"Supporting receivers retain separate defensive lanes")
					if team==possession and stage=="ATTACK":
						if not front and role!="S": assert(is_equal_approx(absf(point.z),4.26),"Back-row coverage retains the source 4.26m row")
						if front and role!="S": assert(is_equal_approx(absf(point.z),2.0),"Front-row coverage retains the source 2m row")
					count+=1
	return count

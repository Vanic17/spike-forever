extends SceneTree
## Independent checks against original scene transforms and the male JobMover branches.
const Tactics = preload("res://src/tactics.gd")
const RallyAI = preload("res://src/rally_ai.gd")

var checks := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/reference-killer-aces/reference-profile.json"))
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/reference-killer-aces/manager-settings.json"))
	assert(int(settings.modeGender)==0,"The inspected scene must be the male reference")
	var player_code := FileAccess.get_file_as_string("res://docs/reference-killer-aces/decompiled/player.cs")
	assert(player_code.contains("mg.trackSetterFront[tm] == 1 && mg.modeGender == 1"))
	assert(player_code.contains("mg.trackSetterFront[tm] == 1 && mg.modeGender == 0 && num == 2"))
	assert(player_code.contains("setTargKind = -3;") and player_code.contains("setTargKind = -1;"))
	var source_ids := [5,4,3,2,1,0]
	for serving in [true,false]:
		var raw: Array = source.positions.locServe if serving else source.positions.locReceive
		for rotation in 6:
			for team in 2:
				for number in 6:
					var original: Array = raw[rotation*7+posmod(source_ids[number]+rotation,6)].position
					if serving and Tactics.front(number,rotation):
						var role: String=Tactics.ROLES[number]
						original=source.positions.locBase[4 if role.begins_with("MB") else (3 if role.begins_with("OH") else 5)].position
					assert_near(Tactics.serve_position(team*6+number,team,rotation,serving),from_unity(original,team),"Original serve/receive transform")
	for rotation in 6:
		for team in 2:
			var setter := team*6+5
			var middle := Tactics.attacker(team,rotation,1,setter)
			var opposite := Tactics.attacker(team,rotation,2,setter)
			assert(middle>=0 and Tactics.ROLES[middle%6].begins_with("MB") and Tactics.front(middle,rotation))
			assert(opposite>=0 and Tactics.ROLES[opposite%6]=="OPP" and opposite!=middle,"A back set must retain its opposite assignment")
			assert(Tactics.front(setter,rotation)!=Tactics.front(opposite,rotation),"Setter and opposite remain three rotations apart")
			checks+=3
			var game := fixture(rotation,team)
			for number in range(team*6,team*6+6):
				var role := Tactics.role(number,rotation,team==game.server)
				var front := Tactics.front(number,rotation)
				var raw_index := 0
				if role=="L" or (role.begins_with("MB") and not front): raw_index=1
				elif role.begins_with("OH"): raw_index=3 if front else 2
				elif role.begins_with("MB"): raw_index=4
				elif role in ["OPP","S"]: raw_index=5 if front else 0
				assert_near(RallyAI.defensive_base(game,number,team),from_unity(source.positions.locBase[raw_index].position,team),"Original role defensive base")
			check_offence(game,team,rotation)
			check_receive(game,team,rotation)
			check_attack_assignments(game,team,rotation)
		assert_near(Tactics.setter_position(0),from_unity(source.positions.locActions[2].position,0),"Original male setter action transform")
		assert_near(Tactics.setter_position(1),from_unity(source.positions.locActions[3].position,0),"Mirrored original setter action transform")
	var report := {"source_assembly_sha256":source.assembly_sha256,"source_gender":int(settings.modeGender),"source_gender_name":"male","serve_receive_positions_compared":144,"rotations_per_team":6,"position_checks":checks,"back_set_assigned_to_opposite":true,"middle_first_tempo_separate_from_opposite":true,"female_slide_branch_imported":false,"reference_scope":"positioning only"}
	var output := FileAccess.open("res://docs/positioning-audit-v11.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("POSITIONING PASS: ",checks," source placement checks / male reference / six rotations / opposite D distinct from middle / no female slide")
	quit()

func from_unity(value: Array, team: int) -> Vector3:
	var side := 1.0 if team==0 else -1.0
	return Vector3(-float(value[2])*side,0,-float(value[0])*side)

func assert_near(actual: Vector3, expected: Vector3, label: String) -> void:
	assert(actual.distance_to(expected)<0.00006,label+": "+str(actual)+" versus "+str(expected))
	checks+=1

func fixture(rotation: int, team: int) -> Dictionary:
	# These comparisons exercise the specialist transition lanes. A separate
	# reception-lane regression checks the deliberate P1 first-ball pin swap.
	var game := {"rotations":[rotation,rotation],"server":0,"possession":team,"phase":"SET" if team==0 else "CPU_SET","phase_time":0.6,"flight_left":0.9,"flight_target":Tactics.world(team,1.5,0.5)+Vector3(0,2.53,0),"incoming_kind":"spike","fast_set":false,"out_of_system":1,"players":[],"setter":team*6+5,"receiver":team*6+3,"hitter":team*6,"planned_hitter":team*6,"destination":0,"attack_serial":1}
	for number in 12:
		var player_team := int(number/6)
		game.players.append({"position":Tactics.home(number,player_team,rotation,player_team==game.server,true)})
	game.hitter=Tactics.attacker(team,rotation,0,game.setter)
	game.planned_hitter=game.hitter
	return game

func check_offence(game: Dictionary, team: int, rotation: int) -> void:
	# Expected metres come from JobMover's male branches, not the runtime tables.
	var covers: Array[Vector3] = []
	for number in range(team*6,team*6+6):
		var role := Tactics.role(number,rotation,team==game.server)
		var front := Tactics.front(number,rotation)
		if front and (role.begins_with("OH") or role=="OPP"):
			game.fast_set=false
			assert_near(RallyAI.opening(game,number,team),Tactics.world(team,-5.0 if role.begins_with("OH") else 5.0,4.0),"Male wing opening")
			game.fast_set=true
			assert_near(RallyAI.opening(game,number,team),Tactics.world(team,-3.5 if role.begins_with("OH") else 5.0,4.0),"Source quick wing opening keeps its lane")
			game.fast_set=false
		if front and role.begins_with("MB"):
			game.fast_set=false
			game.flight_left=0.9
			assert_near(RallyAI.opening(game,number,team),Tactics.world(team,-0.02,3.52),"Male middle waits near the setter rather than running a slide")
			game.flight_left=0.15
			assert_near(RallyAI.opening(game,number,team),Tactics.world(team,-0.02,1.52),"Male middle commits towards the nearby first tempo")
			game.flight_left=0.9
		game.flight_target=Tactics.world(team,-3.4,1.05)+Vector3(0,3.3,0)
		var cover: Vector3 = RallyAI.coverage(game,number,team)
		if number==game.setter:
			assert_near(cover,Tactics.world(team,1.5,0.5),"The active setter retains the original setter lane after release")
		else:
			assert(is_equal_approx(absf(cover.z),2.0 if front else 4.26),"Source short/deep coverage rows must retain their depths")
			var cover_width := 3.0
			if not front:
				if role=="L" or role.begins_with("MB"): cover_width=-3.0
				elif role.begins_with("OH"): cover_width=0.0
			elif role.begins_with("MB"): cover_width=-0.52
			elif role.begins_with("OH"): cover_width=-3.0
			assert_near(cover,Tactics.world(team,cover_width,2.0 if front else 4.26),"Original role coverage width")
		covers.append(cover)
		checks+=1
		game.phase="ATTACK" if team==0 else "CPU_ATTACK"
		game.phase_time=2.0
		if number!=game.hitter:
			assert_near(RallyAI.target(game,number,team),cover,"Live off-ball target must enter the source coverage row")
		game.phase="SET" if team==0 else "CPU_SET"
		game.phase_time=0.6
		game.flight_target=Tactics.world(team,1.5,0.5)+Vector3(0,2.53,0)
	for first in covers.size():
		for second in range(first+1,covers.size()):
			assert(covers[first].distance_to(covers[second])>=0.78,"Coverage roles must not share a target")
			checks+=1

func check_receive(game: Dictionary, team: int, rotation: int) -> void:
	game.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
	game.incoming_kind="serve"
	for number in range(team*6,team*6+6):
		var expected := Tactics.world(team,1.5,0.5) if number==game.setter else Tactics.serve_position(number,team,rotation,false)
		assert_near(RallyAI.target(game,number,team),expected,"Live serve reception retains the source lanes, with setter penetration")
	game.phase="SET" if team==0 else "CPU_SET"
	game.incoming_kind="spike"

func check_attack_assignments(game: Dictionary, team: int, rotation: int) -> void:
	var set_contact := Tactics.world(team,1.5,0.5)
	for direction in 4:
		var attacker := Tactics.attacker(team,rotation,direction,game.setter)
		assert(attacker>=0)
		var back := not Tactics.front(attacker,rotation)
		var width: float = [-3.4,-0.02,4.48 if back else 3.4,-1.6][direction]
		assert_near(RallyAI.attack_contact(game,direction,attacker,set_contact),Tactics.world(team,width,3.65 if back else 1.05),"Contact lane keeps middle, opposite and pipe separate")
	var middle := Tactics.attacker(team,rotation,1,game.setter)
	assert_near(RallyAI.attack_contact(game,1,middle,Tactics.world(team,-1.5,0.5)),Tactics.world(team,0.02,1.05),"A middle behind a displaced setter remains a nearby first tempo")

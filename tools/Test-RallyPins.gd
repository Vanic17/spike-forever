extends SceneTree
## Pin responsibility must survive serve -> attack -> opponent return.
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
var checks:=0
var failures:=0
var failure_messages: Dictionary={}

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	for rotation in 6:
		for serving_team in 2:
			game.rotations=[rotation,rotation]
			game.server=serving_team
			game.reset_rally()
			var committed: Dictionary={}
			for team in 2:
				game.possession=team
				game.setter=team*6+5
				game.receiver=team*6+3
				game.phase="SET" if team==0 else "CPU_SET"
				game.incoming_kind="serve"
				game.pass_quality=1.0
				game.out_of_system=1
				game.flight_left=0.9
				game.flight_target=Tactics.world(team,0.0,1.5)+Vector3.UP*game.contact_height("set")
				for direction in 4:
					game.plan_attack(direction,false)
					committed[str(team)+":"+str(direction)]=game.planned_hitter
					check_attacker(game,team,rotation,direction)
			# Alternate the ball owner and flight kinds without a reset, exactly
			# the circumstance where the previous first_ball flag changed lanes.
			for incoming in ["spike","block","soft","net","free","spike"]:
				for team in 2:
					game.possession=team
					game.setter=team*6+5
					game.receiver=team*6+3
					game.incoming_kind=incoming
					game.phase="SET" if team==0 else "CPU_SET"
					game.flight_target=Tactics.world(team,0.0,1.5)+Vector3.UP*game.contact_height("set")
					for direction in 4:
						game.plan_attack(direction,false)
						expect(game.planned_hitter==committed[str(team)+":"+str(direction)],"An opponent return must not swap the same rally's left/right hitter responsibilities")
						check_attacker(game,team,rotation,direction)
					# Check the unblended first target as well: returning the old
					# specialist base for a few frames causes a direction reversal
					# even if the eventual set chooses the correct committed hitter.
					game.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					game.phase_time=0.0
					for direction in [0,2]:
						var pin: int=committed[str(team)+":"+str(direction)]
						if not Tactics.front(pin,rotation): continue
						var flank: float=(-1.0 if direction==0 else 1.0)*(1.0 if team==0 else -1.0)
						expect(signf(AI.defensive_base(game,pin,team).x)==flank,"A committed front pin must retain its flank in the defensive base")
						expect(signf(AI.target(game,pin,team).x)==flank,"The first dig preparation target must not reverse toward the old specialist flank")
					game.possession=1-team
					game.phase="CPU_SET" if team==0 else "SET"
					var row: Array[int]=game.defensive_lanes.line(game,team)
					expect(row.size()==3,"Every legal rotation supplies exactly three front-row blockers")
					for blocker in row:
						expect(Tactics.front(blocker,rotation) and not game.players[blocker].libero_active,"Only front-row players can own a blocking flank")
					if rotation==0 and team!=serving_team:
						var left:=row[0] if team==0 else row[2]
						var right:=row[2] if team==0 else row[0]
						expect(left==team*6+2 and right==team*6,"R1 blocking flanks must agree with the committed OPP-left/OH1-right attack lanes")
	# Winning service changes the actual slots; a new rally must refresh the
	# commitment instead of retaining a previous serving or receiving mirror.
	game.rotations=[0,0]
	game.server=0
	game.reset_rally()
	game.award(1,"RALLY PIN SIDEOUT")
	game.reset_rally()
	expect(game.rotations==[0,1] and game.server==1,"Only the side-out winner advances its regulatory rotation")
	for team in 2:
		game.possession=team
		game.setter=team*6+5
		game.phase="SET" if team==0 else "CPU_SET"
		game.incoming_kind="spike"
		game.pass_quality=1.0
		game.out_of_system=1
		game.plan_attack(2,false)
		expect(game.planned_hitter==(0 if team==0 else 8),"A new side-out refreshes receiving R1 pins and serving R2 specialist pins separately")
	var contact_cases:=0
	for native in [false,true]:
		game.Avatar.native_animation_enabled=native
		for team in 2:
			game.rotations=[0,0]
			game.server=1-team
			game.reset_rally()
			game.rng.seed=20261023
			var before: int=game.test_contacts
			for incoming in ["serve","spike"]:
				# The two deliveries are controlled so this fixture tests pin
				# commitment and real contacts, rather than random CPU shot choice.
				game.possession=team
				game.touches[team]=0
				game.set_dir=2
				game.incoming_kind=incoming
				game.incoming_power=0.5
				game.late_receive=false
				game.incoming_out=false
				var target: Vector3=Tactics.world(team,2.0,5.3)+Vector3.UP*game.contact_height("receive")
				game.receiver=game.choose_receiver(team,target,incoming=="serve")
				game.select_receive_pose(game.receiver,target)
				game.ball_pos=Tactics.world(1-team,1.5,8.0)+Vector3.UP*3.2
				game.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE")
				game.launch(target,1.1)
				var set_prepared:=false
				var attack_started:=false
				for frame in 600:
					if game.phase in ["RECEIVE","CPU_RECEIVE"]:
						game.armed=true
						game.input_quality=1.0
					if game.phase in ["SET","CPU_SET"]:
						if not set_prepared:
							game.plan_attack(2,false)
							set_prepared=true
						game.armed=true
						game.input_quality=1.0
					if game.phase in ["ATTACK","CPU_ATTACK"]:
						attack_started=true
						expect(game.hitter==team*6,"R1 second back set must still use the OH1 already on the right")
						expect(game.flight_target.x*(1 if team==0 else -1)>3.0,"A back set must remain on the selected right antenna")
						game.armed=true
						game.input_quality=1.0
						game.charge=0.72
					game.step(1.0/60.0)
					if game.phase in ["POINT","LOOSE"] or (attack_started and game.possession!=team): break
				if not (attack_started and game.possession!=team): print("RALLY PIN CONTACT FAILURE team=",team," incoming=",incoming," phase=",game.phase," hitter=",game.hitter)
				expect(attack_started and game.possession!=team,"Both successive back sets must result in actual receive-set-attack contact")
				contact_cases+=1
				# Give the previous attackers their ordinary defensive movement
				# during the opponent's reception, without starting a new rally.
				for frame in 30:
					game.phase_time+=1.0/60.0
					game.clock_time+=1.0/60.0
					game.move_players(1.0/60.0)
					for player in game.players: player.tick(1.0/60.0,false,false)
			expect(game.test_contacts>=before+6,"Serve reception and later dig must each produce three real touches")
	if failures>0:
		print("RALLY PINS FAILED: ",failures," of ",checks," checks; ",failure_messages.keys())
		game.free()
		quit(1)
		return
	print("RALLY PINS PASS: ",checks," checks / six rotations / both teams / serve and transition / ",contact_cases," actual receive-set-back-attack sequences / shared blocking flanks / side-out refresh / PSA-native")
	game.free()
	quit()

func check_attacker(game, team: int, rotation: int, direction: int) -> void:
	var hitter: int=game.planned_hitter
	expect(hitter>=team*6 and hitter<team*6+6 and hitter!=game.setter,"An attack lane must select an eligible teammate, never the setter")
	expect(not game.players[hitter].libero_active,"A libero cannot own an attack lane")
	if direction in [0,1]: expect(Tactics.front(hitter,rotation),"The high left ball and first tempo must retain front-row eligibility")
	if direction==3: expect(not Tactics.front(hitter,rotation),"The pipe remains a back-row attack")
	var contact:=AI.attack_contact(game,direction,hitter,game.flight_target)
	if not Tactics.front(hitter,rotation): expect(absf(contact.z)>3.0,"Back-row attacks must retain their legal takeoff zone")
	if direction in [0,2] and Tactics.front(hitter,rotation):
		var opening:=AI.opening(game,hitter,team)
		expect(signf(opening.x)==signf(contact.x),"Preparation and the actual set must agree on the same flank")

func expect(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		if not failure_messages.has(message):
			failure_messages[message]=true
			push_error(message)

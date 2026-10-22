extends SceneTree
const Model=preload("res://src/rotation_model.gd")
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
const EXPECTED=[
	["S","OH1","MB1","OPP","OH2","MB2"],
	["OH1","MB1","OPP","OH2","MB2","S"],
	["MB1","OPP","OH2","MB2","S","OH1"],
	["OPP","OH2","MB2","S","OH1","MB1"],
	["OH2","MB2","S","OH1","MB1","OPP"],
	["MB2","S","OH1","MB1","OPP","OH2"]
]
var snapshots:=0
var checks:=0

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.demo=false
	game.self_test=true
	var replay: Array=[]
	for native in [false,true]:
		game.Avatar.native_animation_enabled=native
		for rotation in 6:
			for serving in 2:
				game.rotations=[rotation,rotation]
				game.server=serving
				game.reset_rally()
				for team in 2:
					var ids: Dictionary={}
					var fronts:=0
					var liberos:=0
					for index in range(team*6,team*6+6):
						var state:=Model.state(index,rotation,team==serving)
						assert(Model.ROLES[index%6]==EXPECTED[rotation][state.rotation_slot-1])
						assert(not ids.has(state.player_id))
						ids[state.player_id]=true
						fronts+=int(state.is_front_row)
						liberos+=int(state.is_libero)
						if state.is_libero: assert(not state.is_front_row and not state.is_server and state.replaces_player_id.contains("MB"))
						if state.is_server: assert(state.rotation_slot==1 and not game.players[index].libero_active)
						assert(Model.slot(index,rotation+6)==Model.slot(index,rotation))
						checks+=5
					assert(ids.size()==6 and fronts==3 and liberos<=1)
					assert(Model.front(team*6+5,rotation)!=Model.front(team*6+2,rotation))
					assert(Model.front(team*6,rotation)!=Model.front(team*6+3,rotation))
					assert(Model.front(team*6+1,rotation)!=Model.front(team*6+4,rotation))
				for frame in 61:
					if frame%30==0:
						var snapshot=game.rotation_context.capture(game,serving)
						assert(snapshot.legal,"Illegal receiving feet: R"+str(rotation+1)+" / serving "+str(serving)+" / native "+str(native)+" / "+str(snapshot))
						assert(snapshot.checks.size()==9)
						snapshots+=1
					game.phase_time+=1.0/60.0
					game.clock_time+=1.0/60.0
					game.move_players(1.0/60.0)
					for player in game.players: player.tick(1.0/60.0,false,false)
				var receiving:=1-serving
				var legal=game.rotation_context.capture(game,serving)
				replay.append({"rotation":rotation+1,"serving":serving,"native":native,"roster":legal.roster,"feet":legal.feet})
				for team in 2:
					game.possession=1-team
					game.defensive_lanes.reset()
					var row: Array[int]=game.defensive_lanes.line(game,team)
					assert(row.size()==3 and Model.ROLES[row[1]%6].begins_with("MB"))
					for i in row: assert(Model.front(i,rotation) and not game.players[i].libero_active)
					for first_ball in [false,true]:
						var setter:=team*6+5
						var oh:=Tactics.attacker(team,rotation,0,setter,first_ball)
						var opp:=Tactics.attacker(team,rotation,2,setter,first_ball)
						assert(Model.front(oh,rotation) and (Model.ROLES[oh%6]=="OPP" if first_ball and rotation==0 else Model.ROLES[oh%6].begins_with("OH")))
						assert(Model.ROLES[opp%6]==("OH1" if first_ball and rotation==0 else "OPP"))
						checks+=3
				# Receiving feet are checked; serving fronts are deliberately free.
				var bad_index: int=legal.zones[4]
				game.players[bad_index].position.x=4.8*(1 if receiving==0 else -1)
				assert(not game.rotation_context.capture(game,serving).legal)
				# Holding service never rotates; side-out rotates exactly once.
				for winner in [serving,receiving]:
					game.server=serving
					game.rotations=[rotation,rotation]
					game.phase="RECEIVE"
					game.award(winner,"TEST ROTATION")
					assert(game.rotations[winner]==posmod(rotation+int(winner!=serving),6))
					assert(game.rotations[1-winner]==rotation)
	FileAccess.open("res://docs/rotation-spec-replay.json",FileAccess.WRITE).store_string(JSON.stringify(replay,"  "))
	print("ROTATION SPEC PASS: ",snapshots," grounded-foot snapshots / 24 native-PSA serve-receive cases / ",checks," identity and eligibility checks / side-out rotation / specialist attack lanes / detected illegal feet")
	game.free()
	quit()

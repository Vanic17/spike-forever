extends SceneTree
const PreviousLayout=preload("res://docs/baseline-v63/rotation_layout.gd")
const PreviousAI=preload("res://docs/baseline-v63/rally_ai.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	assert(g.Tactics.Layout.RECEIVE==PreviousLayout.RECEIVE and g.Tactics.Layout.DEFENSE==PreviousLayout.DEFENSE,"Receiving and defensive rotation diagrams must remain unchanged")
	var rows: Array=[]
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.planned_hitter=team*6; g.out_of_system=1; g.phase="SET" if team==0 else "CPU_SET"; g.flight_left=1.0
			g.incoming_kind="serve"; g.flight_target=g.Tactics.world(team,0,1.5)+Vector3.UP*2.6
			assert(g.Tactics.first_ball(g))
			for i in range(team*6,team*6+6):
				var role: String=g.Tactics.role(i,rotation,false)
				if role=="S" or (g.Tactics.front(i,rotation) and role.begins_with("MB")): continue
				var anchor: Vector3=g.Tactics.Layout.first_attack(i,rotation)
				var expected: Vector3=g.Tactics.world(team,anchor.x,anchor.z)
				assert(g.RallyAI.opening(g,i,team).distance_to(expected)<.0001)
				rows.append({"team":team,"rotation":g.Tactics.Layout.label(rotation),"role":role,"anchor":str(expected)})
			g.incoming_kind="spike"
			assert(not g.Tactics.first_ball(g))
			for phase in ["SET","ATTACK"]:
				g.phase=phase if team==0 else "CPU_"+phase
				for i in range(team*6,team*6+6):
					assert(g.RallyAI.opening(g,i,team).distance_to(PreviousAI.opening(g,i,team))<.0001,"Later attack opening must retain the previous layout")
	FileAccess.open("res://docs/first-attack64-layouts.json",FileAccess.WRITE).store_string(JSON.stringify({"anchors":rows,"receiving_defense_unchanged":true,"later_attack_unchanged":true},"  "))
	print("FIRST ATTACK64 PASS all six diagrams / mirrored teams / receive and defense unchanged / later attack unchanged"); g.free(); quit()

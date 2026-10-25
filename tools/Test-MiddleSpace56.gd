extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for rotation in 6:
			for wide in [false,true]:
				g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.receiver=team*6+4
				g.phase="SET" if team==0 else "CPU_SET"; g.out_of_system=1; g.pass_quality=.95; g.armed=true
				g.flight_target=g.Tactics.world(team,0,1.5)+Vector3.UP*2.65; g.flight_left=1.1
				g.plan_attack(1,wide); g.middle_decoy.update(g)
				var middle: int=g.planned_hitter
				var point: Vector3=g.RallyAI.attack_contact(g,1,middle,g.flight_target); point.y=g.players[middle].contact_local("attack").y
				var stance: Vector3=g.players[middle].stance_for_contact("attack",point)
				var targets: Array[Vector3]=[]
				for i in 12:
					g.players[i].position=g.Tactics.world(int(i/6),-4 if i%2==0 else 4,7-float(i%6)*.5)
					g.players[i].target=g.players[i].position; targets.append(g.players[i].position)
				g.players[g.setter].position=g.Tactics.world(team,.5,1.5); targets[g.setter]=g.players[g.setter].position
				g.players[middle].position=g.Tactics.world(team,stance.x*(1 if team==0 else -1),2.35)
				var early: Array[Vector3]=g.court_shape.arrange(g,targets,g.setter,"set",[])
				var depth: float=early[middle].z*(1 if team==0 else -1)
				assert(depth>2.1,"The middle must not wait at the final under-net stance")
				g.flight_left=.1
				var late: Array[Vector3]=g.court_shape.arrange(g,targets,g.setter,"set",[])
				assert(late[middle].z*(1 if team==0 else -1)<depth-.35,"Close the runway progressively before contact")
				rows.append({"team":team,"rotation":rotation,"wide":wide,"staging_depth":depth,"late_depth":late[middle].z*(1 if team==0 else -1)})
	FileAccess.open("res://docs/middle-space56-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("MIDDLE SPACE56 PASS 24 preparations / first tempo and 7 / open before closing")
	g.free(); quit()

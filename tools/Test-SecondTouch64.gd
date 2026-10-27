extends SceneTree
## Real first-pass pipelines, including the receiver crossing the reserved
## setter footprint reproduced in the 0.56 audit (seed 57002).
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	test_planned_footprint(g)
	var rows: Array=[]; var failures:=0
	for hz in [60,120]:
		for team in 2:
			for rotation in 6:
				for seed_value in ([57001,57002] if hz==60 else range(57000,57012)):
					g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
					g.receiver=team*6+(4 if rotation in [0,1,5] else 1); g.set_dir=0; g.rng.seed=seed_value
					g.incoming_kind="serve"; g.incoming_power=.85; g.input_quality=.70; g.armed=true
					for p in g.players: p.blend_left=0; p.apply_pose(0)
					g.players[g.receiver].position=g.Tactics.world(team,1.5,5.5)
					g.players[team*6+5].position=g.Tactics.world(team,.5,2.2)
					g.ball_pos=g.players[g.receiver].contact_world("receive")
					g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					var initial: int=g.test_contacts
					g.receive_ball()
					if g.phase not in ["SET","CPU_SET"]: continue
					g.armed=true; g.input_quality=.9
					var source={"actor":g.setter,"action":g.setter_action,"target":str(g.flight_target),"start":str(g.players[g.setter].position),"seconds":g.flight_left}
					var max_step:=0.0; var waiting:=0.0; var max_waiting:=0.0
					for frame in 500:
						if g.phase not in ["SET","CPU_SET"]: break
						var actor: int=g.setter
						var position: Vector3=g.players[actor].position
						g.step(1.0/hz)
						var moved: float=position.distance_to(g.players[actor].position)
						max_step=maxf(max_step,moved)
						if moved<.001 and g.players[actor].position.distance_to(g.players[actor].target)<.01 and g.players[actor].position.distance_to(g.flight_target)>.8: waiting+=1.0/hz
						else: waiting=0
						max_waiting=maxf(max_waiting,waiting)
						if frame%maxi(1,hz/30)==0:
							for p in g.players: p.apply_pose(1.0/30)
					var good: bool=g.test_contacts==initial+2 and g.phase in ["ATTACK","CPU_ATTACK"]
					var gap: float=g.contact_log.back().gap if good else -1
					var row={"hz":hz,"team":team,"rotation":rotation,"seed":seed_value,"contact":good,"source":source,"actual_actor":g.setter,"phase":g.phase,"gap":gap,"max_step":max_step,"max_waiting":max_waiting}
					if not good or gap>.18 or max_step>7.2/hz+.025:
						failures+=1; row["events"]=g.rally_events.slice(-5); print("SECOND TOUCH64 FAIL ",JSON.stringify(row))
					rows.append(row)
	var baseline_failures: Array=[{"team":0,"rotation":3,"seed":57001}]
	for rotation in [2,3,4,5]: baseline_failures.append({"team":1,"rotation":rotation,"seed":57002})
	FileAccess.open("res://docs/second-touch64-report.json",FileAccess.WRITE).store_string(JSON.stringify({"scenarios":rows.size(),"failed":failures,"baseline_audit_cases":144,"baseline_failed":5,"baseline_failures":baseline_failures,"cases":rows},"  "))
	print("SECOND TOUCH64 ",rows.size()-failures,"/",rows.size()," / all rotations / 60-120Hz / real hands and second-touch count")
	g.free(); quit(1 if failures else 0)

func test_planned_footprint(g) -> void:
	var access=load("res://src/setter_access.gd")
	for team in 2:
		g.server=1-team; g.rotations=[0,0]; g.reset_rally(); g.possession=team; g.setter=team*6+5; g.receiver=team*6+4
		var p=g.players[g.setter]
		p.select_variant("receive","receive_step")
		for other in range(team*6,team*6+6): g.players[other].position=g.Tactics.world(team,6,9)
		var yaw: float=PI if team==0 else 0.0
		var contact: Vector3=g.Tactics.world(team,0,3)+Vector3.UP*p.contact_local("receive").y
		var stance: Vector3=p.stance_for_contact("receive",contact)
		var platform: Vector3=Basis(Vector3.UP,yaw)*p.contact_local("receive")*.4; platform.y=0
		p.position=stance+Vector3(-2,0,0)
		var obstacle=team*6+4
		g.players[obstacle].position=stance+platform.normalized()*(1.12+platform.length()*.5)
		assert(stance.distance_to(g.players[obstacle].position)>1.12,"Fixture root must look free to the old endpoint selector")
		assert((stance+platform).distance_to(g.players[obstacle].position)<1.12,"Future forearm platform must expose the obstruction")
		var adjusted: Vector3=access.clear_target(g,contact,g.setter,"receive")
		assert(adjusted.distance_to(contact)>.1)
		var reserved: Vector3=p.stance_for_contact("receive",adjusted)
		for offset in access.contact_offsets(p,"receive",yaw):
			assert((reserved+offset).distance_to(g.players[obstacle].position)>=1.119,"Both future root and forearm platform require a free footprint")
	print("SECOND TOUCH64 PLANNED FOOTPRINT PASS both sides / future platform protected before launch")

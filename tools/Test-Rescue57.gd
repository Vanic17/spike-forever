extends SceneTree
const Rescue=preload("res://src/contact_rescue.gd")
func _initialize(): call_deferred("run")
func prepare(g,team: int) -> void:
	g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team
	g.setter=team*6+5; g.receiver=team*6; g.touches=[0,0]; g.touches[team]=1
	g.phase="SET" if team==0 else "CPU_SET"; g.armed=true; g.input_quality=.8; g.pass_quality=.38; g.setter_dump=false; g.out_of_system=-1
	for i in range(team*6,team*6+6):
		g.players[i].position=g.Tactics.world(team,3.8,8-float(i%6)*.8)
		g.players[i].velocity=Vector3.ZERO; g.players[i].play("idle",1,true); g.players[i].blend_left=0
	var p=g.players[g.setter]; p.position=g.Tactics.world(team,-1.0,4.7); p.rotation.y=PI if team==0 else 0.0
	p.select_variant("receive","receive_step"); g.setter_action="receive"; g.plan_attack(0,false)
	g.ball_pos=g.Tactics.world(team,-1.0,3.4)+Vector3.UP*1.15
	var target: Vector3=g.ball_pos+Vector3(0,-1.045,(1 if team==0 else -1)*.15)
	g.launch(target,.42)
	var hit: Dictionary=g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,p.contact_local("receive").y)
	g.flight_target=hit.point; g.flight_left=hit.seconds
	g.next_second_touch_read=1000

func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for hz in [60,120]:
			prepare(g,team)
			var plan: Dictionary=Rescue.proposal(g,g.setter)
			print("RESCUE57 PLAN ",team," ",plan)
			assert(not plan.is_empty(),"A short reachable low ball needs a physical save proposal")
			var origin: Vector3=g.ball_pos; var velocity: Vector3=g.ball_vel; var spin: Vector3=g.flight_spin
			assert(Rescue.try_second_touch(g))
			assert(origin==g.ball_pos and velocity==g.ball_vel and spin==g.flight_spin,"Save must intercept the unchanged flight")
			var count: int=g.test_contacts; var actor: int=g.setter; var max_step:=0.0
			for frame in 180:
				if g.phase not in ["SET","CPU_SET"]: break
				var prior: Vector3=g.players[actor].position
				g.step(1.0/hz); max_step=maxf(max_step,prior.distance_to(g.players[actor].position))
				for p in g.players: p.apply_pose(1.0/hz)
			var touched: bool=g.test_contacts==count+1 and g.phase in ["ATTACK","CPU_ATTACK"]
			# Keep measuring through landing/rise. A stopped source must not bank
			# travel and then jump forward when a teammate clears its path.
			for frame in 360:
				if not g.dive_motions.has(actor): break
				var prior: Vector3=g.players[actor].position
				g.advance_dive_body(actor,1.0/hz); g.players[actor].tick(1.0/hz,false,false)
				max_step=maxf(max_step,prior.distance_to(g.players[actor].position))
			rows.append({"team":team,"hz":hz,"contact":touched,"max_root_step":max_step,"variant":plan.variant})
			assert(touched,"The physical one-hand second touch must remain playable")
			assert(max_step<7.3/hz,"No root teleport to make a save")
	# A human still has to command the second touch; a distant ball is not rescued.
	prepare(g,0); g.armed=false
	assert(not Rescue.try_second_touch(g) and not g.dive_motions.has(g.setter))
	g.players[g.setter].position=Vector3(-6,0,10)
	assert(Rescue.proposal(g,g.setter).is_empty())
	# Follow a genuinely committed one-hand second touch through the THIRD
	# physical hit. A regression fixture can stop exercising rescue once its
	# ordinary approach improves, so assert the source save itself here too.
	for team in 2:
		for hz in [60,120]:
			prepare(g,team)
			var hitter: int=g.planned_hitter
			g.players[hitter].position=g.Tactics.world(team,-4.65,3.5)
			assert(Rescue.try_second_touch(g))
			var actor: int=g.setter
			var count: int=g.test_contacts
			var source_touch:=false
			for frame in 650:
				if g.phase in ["POINT","LOOSE"] or g.test_contacts>=count+2: break
				if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
				g.step(1.0/hz)
				for player in g.players: player.apply_pose(1.0/hz)
				if g.test_contacts==count+1 and not g.contact_log.is_empty():
					source_touch=g.contact_log.back().player==actor and g.contact_log.back().action=="dive"
			var complete: bool=source_touch and g.test_contacts==count+2
			rows.append({"team":team,"hz":hz,"case":"source_save_to_attack","source_touch":source_touch,"contacts":g.test_contacts-count,"complete":complete})
			assert(complete,"A commanded one-hand rescue must lead to an actual playable attack")
	FileAccess.open("res://docs/rescue57-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("RESCUE57 PASS source-driven second touch / both sides / 60-120Hz / no input and unreachable preserved")
	g.free(); quit()

extends SceneTree
## Natural serve-to-point diagnostic; never positions players or fabricates contacts.
func _initialize(): call_deferred("run")
func wall_snapshot(g) -> Dictionary:
	var team: int=1-g.last_touch
	var members: Array=[]
	for index in g.blocking_players(team):
		var p=g.players[index]
		p.apply_pose(0)
		var left: Vector3=p.current_hand(true)
		var right: Vector3=p.current_hand(false)
		members.append({"index":index,"root":p.position,"target":g.blocking_target(index,team),"target_gap":p.position.distance_to(g.blocking_target(index,team)),"can_jump":g.can_jump_block(index,team),"clip":p.clip_name,"animation_time":p.animation_time,"left":left,"right":right,"ball_gap":Geometry3D.get_closest_point_to_segment(g.ball_pos,left,right).distance_to(g.ball_pos)})
	return {"time":g.clock_time,"phase":g.phase,"ball":g.ball_pos,"velocity":g.ball_vel,"left":g.flight_left,"attack_id":g.attack_serial,"team":team,"block_age":g.clock_time-g.block_time,"checked":g.block_checked,"quality":g.block_quality,"members":members}
func run():
	var scene=load("res://src/main.tscn")
	var seeds: Array=[59001]
	var target_points:=25
	var manual:=false
	var report_path:="res://docs/block-rallies59-baseline.json"
	for arg in OS.get_cmdline_user_args():
		if arg=="--manual": manual=true
		if arg.begins_with("--seeds="):
			seeds.clear()
			for value in arg.trim_prefix("--seeds=").split(","): seeds.append(int(value))
		if arg.begins_with("--points="): target_points=int(arg.trim_prefix("--points="))
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	var rows: Array=[]
	for seed in seeds:
		var g=scene.instantiate(); root.add_child(g)
		g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=not manual
		g.rng.seed=seed; g.server=0; g.rotations=[0,0]; g.scores=[0,0]; g.sets=[0,0]; g.match_best_of=5; g.match_points=25; g.match_finished=false; g.reset_rally()
		g.rally_events.clear(); g.block_jump_log.clear()
		var start_points: int=g.test_points; var start_contacts: int=g.test_contacts
		var counts: Dictionary={}; var points: Array=[]; var net_samples: Array=[]; var attack_samples: Dictionary={}; var rotations: Dictionary={}; var events: Array=[]
		var event_count:=0; var last_block: Dictionary={}; var touches_after_block:=0
		var prior_contacts: int=g.test_contacts
		for frame in 120000:
			if manual:
				Input.action_release("left"); Input.action_release("right")
				if g.human_wall():
					var wanted: Vector3=g.manual_wall.attack_position(g)
					var delta: float=wanted.x-g.block_helper_x
					if absf(delta)>.1: Input.action_press("right" if delta>0 else "left",minf(1,absf(delta)*2))
				g.demo_input()
			if g.phase in ["ATTACK","CPU_ATTACK"] and g.flight_left<.40:
				var key:=str(g.attack_serial)+":"+str(int(g.flight_left*10))
				if not attack_samples.has(key): attack_samples[key]=wall_snapshot(g)
			var old_phase: String=g.phase
			if g.phase in ["RECEIVE","CPU_RECEIVE"] and g.incoming_kind in ["spike","soft","dump"] and absf(g.ball_pos.z)<1.35:
				net_samples.append(wall_snapshot(g))
			g.step(1.0/60)
			if frame%4==0:
				for p in g.players: p.apply_pose(1.0/15)
			for i in range(event_count,g.rally_events.size()):
				var event: Dictionary=g.rally_events[i]
				events.append(event.duplicate(true))
				counts[event.kind]=int(counts.get(event.kind,0))+1
				if event.kind in ["block_tool","block_touch","stuff_block"]:
					last_block=event.duplicate(true); touches_after_block=0
				elif event.kind in ["dig","reception","spike","soft","setter_dump"] and not last_block.is_empty(): touches_after_block+=1
				if event.kind=="formation": last_block={}; touches_after_block=0; rotations[str(g.rotations)]=true
			event_count=g.rally_events.size()
			if old_phase!="POINT" and g.phase=="POINT":
				var direct_block: bool=not last_block.is_empty() and touches_after_block==0 and g.server==last_block.get("blocking_team",-1) and g.point_reason=="PALLA A TERRA"
				points.append({"winner":g.server,"reason":g.point_reason,"ball":g.ball_pos,"last_touch":g.last_touch,"last_block":last_block,"touches_after_block":touches_after_block,"direct_block_point":direct_block,"rally":g.rally_serial})
			if g.test_points-start_points>=target_points: break
		var block_points: Array=[0,0]
		for point in points:
			if point.direct_block_point: block_points[point.winner]+=1
		var row={"seed":seed,"points":g.test_points-start_points,"contacts":g.test_contacts-start_contacts,"counts":counts,"block_points":block_points,"block_jumps":g.block_jump_log.duplicate(true),"net_samples":net_samples,"approach_samples":attack_samples.values(),"points_detail":points,"rotations_seen":rotations.keys(),"events":events}
		rows.append(row)
		print("BLOCK NATURAL59 seed=",seed," points=",row.points," block_points=",block_points," counts=",counts," jumps=",g.block_jump_log.size()," net_samples=",net_samples.size())
		g.free()
	Input.action_release("left"); Input.action_release("right")
	var report={"fixture":"Natural serve-to-point simulation, no forced positions/contacts; left attacker charges ~65%. Manual mode uses production human_wall, simulated real analog action strength toward attack lane, X jump via demo_input, autonomous pins. Demo mode uses automatic wall selection.","manual":manual,"hz":60,"seeds":seeds,"rows":rows}
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  ").replace(": inf",": null"))
	print("BLOCK NATURAL59 COMPLETE ",report_path)
	quit()

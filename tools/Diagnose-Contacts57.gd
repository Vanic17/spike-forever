extends SceneTree
## Diagnostic only: real serve/rally paths, bounded manual simulation.
func _initialize(): call_deferred("run")
func snapshot(g) -> Dictionary:
	var rows: Array=[]
	for p in g.players:
		rows.append({"position":p.position,"velocity":p.velocity,"yaw":p.rotation.y,"clip":p.clip_name,"time":p.animation_time,"variants":p.variant_names.duplicate()})
	return {"time":g.clock_time,"phase":g.phase,"left":g.flight_left,"ball":g.ball_pos,"velocity":g.ball_vel,"spin":g.flight_spin,"target":g.flight_target,"receiver":g.receiver,"setter":g.setter,"hitter":g.hitter,"quality":g.pass_quality,"action":g.setter_action,"out_of_system":g.out_of_system,"armed":g.armed,"rotation":g.rotations.duplicate(),"players":rows}
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=true
	var seed:=57001
	var report_path:="res://docs/contact57-baseline.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): seed=int(arg.trim_prefix("--seed="))
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	g.rng.seed=seed; g.reset_rally()
	var entries: Array=[]; var misses: Array=[]; var previous_phase: String=g.phase; var history: Array=[]
	var event_count: int=g.rally_events.size(); var points_before: int=g.test_points
	for frame in 36000:
		if g.phase in ["SET","CPU_SET"]:
			history.append(snapshot(g))
			if history.size()>18: history.pop_front()
			if previous_phase!=g.phase: entries.append(snapshot(g))
		previous_phase=g.phase
		g.step(1.0/60)
		if frame%4==0:
			for p in g.players: p.apply_pose(1.0/15)
		for i in range(event_count,g.rally_events.size()):
			var event: Dictionary=g.rally_events[i]
			if event.kind=="missed_contact" and event.phase in ["SET","CPU_SET"]:
				var row={"seed":seed,"event":event,"entry":entries[-1] if not entries.is_empty() else {},"last_frames":history.duplicate(true),"recent_events":g.rally_events.slice(maxi(0,i-8),i+1)}
				misses.append(row); print("DIAG57 MISS ",event)
		event_count=g.rally_events.size()
		if g.test_points-points_before>=10: break
	var report={"seed":seed,"points":g.test_points-points_before,"contacts":g.test_contacts,"seconds":g.clock_time,"set_entries":entries.size(),"misses":misses,"events":g.rally_events}
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  ").replace(": inf",": null"))
	print("DIAG57 seed=",seed," points=",report.points," contacts=",report.contacts," set_entries=",entries.size()," set_misses=",misses.size())
	g.free(); quit()

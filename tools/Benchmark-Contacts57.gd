extends SceneTree
## Headless CPU cost only; never a rendered FPS/GPU measurement.
func _initialize(): call_deferred("run")
func statistics(values: Array) -> Dictionary:
	if values.is_empty(): return {"samples":0}
	var sorted:=values.duplicate(); sorted.sort()
	var total:=0.0
	for value in sorted: total+=value
	return {"samples":sorted.size(),"mean_ms":total/sorted.size(),"p95_ms":sorted[mini(sorted.size()-1,ceili(sorted.size()*.95)-1)],"max_ms":sorted[-1]}
func run():
	var report_path:="res://docs/performance57-report.json"; var label:="current57"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
		if arg.begins_with("--label="): label=arg.trim_prefix("--label=")
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	if g.match_audio: g.match_audio.enabled=false
	var steps: Array=[]; var poses: Array=[]; var combined: Array=[]; var rows: Array=[]
	# One full pass through both sides/all six rotations warms source variants,
	# AnimationTree resources and source pose caches. Its wall times are excluded.
	for repetition in 3:
		for team in 2:
			for rotation in 6:
				g.clock_time=0; g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4; g.set_dir=0; g.rng.seed=57002
				g.incoming_kind="spike"; g.incoming_power=.85; g.input_quality=.45; g.armed=true
				for p in g.players: p.blend_left=0; p.apply_pose(0)
				g.players[g.receiver].position=g.Tactics.world(team,1.5,5.5); g.players[team*6+5].position=g.Tactics.world(team,.5,2.2)
				g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
				var initial: int=g.test_contacts; g.receive_ball()
				if g.phase not in ["SET","CPU_SET"]: continue
				g.armed=true; g.input_quality=.9
				var local_steps: Array=[]; var local_combined: Array=[]
				for frame in 480:
					if g.phase not in ["SET","CPU_SET"]: break
					var begin:=Time.get_ticks_usec(); g.step(1.0/120); var step_end:=Time.get_ticks_usec()
					if frame%4==0:
						for p in g.players: p.apply_pose(1.0/30)
					var end:=Time.get_ticks_usec()
					if repetition>0:
						var step_ms:=float(step_end-begin)/1000
						var pose_ms:=float(end-step_end)/1000
						var combined_ms:=float(end-begin)/1000
						steps.append(step_ms); poses.append(pose_ms); combined.append(combined_ms)
						local_steps.append(step_ms); local_combined.append(combined_ms)
				if repetition>0: rows.append({"repetition":repetition,"team":team,"rotation":rotation,"contacts":g.test_contacts-initial,"end_phase":g.phase,"step":statistics(local_steps),"step_plus_sampled_poses":statistics(local_combined)})
	var hashes: Dictionary={}
	for source in ["main","court_shape","setter_access","contact_navigation","avatar","contact_rescue","receive_access","middle_decoy","attack_run"]:
		var path: String="res://src/"+source+".gd"
		if FileAccess.file_exists(path): hashes[source]=FileAccess.get_sha256(path)
	var report={"label":label,"godot":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"physics_hz":120,"rendered":false,"warmup_excluded":"12 full SET constructions, both teams/all rotations; scene, assets and all source variants loaded before measurement","scenario":"Physical first-pass -> second-touch SET. Same seed57002, spike power .85, initial input .45; all rotations both teams; includes passer-yield crossing team1rotation4. Source poses sampled at30Hz, cost reported separately; no GPU draw/display/frame-pacing measurement.","source_hashes":hashes,"step":statistics(steps),"sampled_pose_component":statistics(poses),"step_plus_sampled_poses":statistics(combined),"cases":rows}
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PERFORMANCE57 ",label," ",JSON.stringify(report.step)," combined=",JSON.stringify(report.step_plus_sampled_poses))
	g.free(); quit()

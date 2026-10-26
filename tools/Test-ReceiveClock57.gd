extends SceneTree
const Access=preload("res://src/receive_access.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]; var baseline_misses:=0; var fixed_contacts:=0; var largest_height_gap:=0.0
	var variants: Array=["receive","receive_low","receive_step","receive_left_step","receive_right_step"]
	for name in preload("res://src/animation_expansion.gd").GROUPS.receive: variants.append(name)
	for team in 2:
		for hz in [60,120]:
			for variant in variants:
				var baseline: Dictionary=run_case(g,team,hz,variant,false)
				var fixed: Dictionary=run_case(g,team,hz,variant,true)
				if not baseline.contact: baseline_misses+=1
				if fixed.contact: fixed_contacts+=1
				largest_height_gap=maxf(largest_height_gap,fixed.height_gap)
				rows.append({"baseline":baseline,"fixed":fixed})
				assert(fixed.contact,"Reachable receive must meet its selected performance: "+str(variant))
				assert(fixed.max_root_step<.18,"Receive cannot teleport its root")
	FileAccess.open("res://docs/receive-clock57-report.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"baseline_misses":baseline_misses,"fixed_contacts":fixed_contacts,"largest_height_gap":largest_height_gap},"  "))
	print("RECEIVE CLOCK57 PASS ",fixed_contacts," contacts / selected hand heights / immutable ball flight / cached clock / both sides 60-120Hz; matched baseline misses=",baseline_misses," max height gap=",largest_height_gap)
	g.free(); quit()

func run_case(g, team: int, hz: int, variant: String, synchronized: bool) -> Dictionary:
	g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4; g.rng.seed=57001
	for i in 12:
		g.players[i].position=g.Tactics.world(int(i/6),-4.8+float(i%6)*1.9,9.5); g.players[i].play("idle",1,true); g.players[i].blend_left=0
	var p=g.players[g.receiver]; p.select_variant("receive",variant); p.rotation.y=PI if team==0 else 0.0
	g.set_phase("RECEIVE" if team==0 else "CPU_RECEIVE"); g.incoming_kind="soft"; g.incoming_power=.25; g.incoming_out=false; g.cpu_defense.reset(); g.winner_team=-1
	g.ball_pos=g.Tactics.world(team,0,1)+Vector3.UP*3.0
	g.launch(g.Tactics.world(team,0,7)+Vector3.UP*.105,.65)
	var original: Dictionary=g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,g.contact_height("receive"),g.flight_gravity)
	g.flight_target=original.point; g.flight_left=original.seconds; g.receive_deadline=g.clock_time+original.seconds
	# The matched runs begin in precisely the same pose, position and velocity.
	p.position=p.stance_for_contact("receive",original.point)+g.Tactics.world(team,0,.65); p.target=p.position; p.velocity=Vector3.ZERO
	var velocity: Vector3=g.ball_vel; var spin: Vector3=g.flight_spin
	var height_gap: float=absf(p.contact_local("receive").y-original.point.y)
	if synchronized:
		Access.sync_performance(g,true)
		assert(g.ball_vel==velocity and g.flight_spin==spin,"Receive sync cannot rewrite physical shot")
		assert(absf(g.flight_target.y-p.contact_local("receive").y)<.003,"Deadline must correspond to selected hands")
	else:
		# Disable only the clock repair, preserving animation and palm validation.
		p.set_meta("receive_clock_key",g.phase+":"+str(g.shot_serial)+":"+str(g.possession)+":"+str(p.variant_names.get("receive","receive")))
	var target: Vector3=g.flight_target; var seconds: float=g.flight_left
	assert(not Access.sync_performance(g),"Cached receive clock must not be solved every frame")
	assert(g.flight_left==seconds and g.flight_target==target)
	var before: int=g.test_contacts; var max_step:=0.0
	for frame in 150:
		if g.phase not in ["RECEIVE","CPU_RECEIVE"] or g.test_contacts>before: break
		g.armed=true; g.input_quality=.8
		var previous: Vector3=p.position; g.step(1.0/hz); max_step=maxf(max_step,p.position.distance_to(previous))
		for player in g.players: player.apply_pose(1.0/hz)
	return {"team":team,"hz":hz,"variant":variant,"height_gap":height_gap,"time_adjustment":seconds-original.seconds,"contact":g.test_contacts>before,"max_root_step":max_step,"phase":g.phase}

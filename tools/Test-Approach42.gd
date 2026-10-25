extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var avatar=g.players[0]
	var previous:=0.0
	for n in range(1,1201):
		var seconds: float=n/1000.0
		var mapped: float=avatar.attack_source_remaining(seconds)
		assert(mapped>previous and absf(avatar.attack_clock_seconds(mapped)-seconds)<0.0002,"Attack source clock must be monotone and invertible without a phase jump")
		if seconds<=0.2: assert(is_equal_approx(mapped,seconds*1.15),"Final contact playback remains unchanged")
		previous=mapped
	var report: Array=[]
	var cases:=0; var early_runs:=0; var early_gestures:=0; var failures:=0
	for team in 2:
		for rotation in 6:
			for direction in 4:
				for quick in [false,true]:
					g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
					for player in g.players:
						player.blend_left=0; player.apply_pose(0)
					g.rng.seed=40001
					g.receiver=team*6+4; g.set_dir=direction
					# A deep, clean reception gives every attack a legal construction;
					# crowded passes at the setter's feet are covered separately.
					g.players[g.receiver].position=g.Tactics.world(team,0,5.5)
					g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
					g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
					g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=0.3
					var before: int=g.test_contacts
					g.receive_ball()
					if team==1: g.plan_attack(direction,quick)
					else: g.press_action("alternate" if quick else "action")
					var runner: int=g.planned_hitter
					var opening: Vector3=g.players[runner].position
					var run_distance:=0.0; var gesture_started:=false
					var release_gap:=-1.0; var run_metres:=0.0; var max_run_speed:=0.0; var setter_time:=-1.0; var last_root: Vector3=g.players[runner].position; var decoy_count: int=g.middle_decoy.events.size()
					for frame in 700:
						if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
						if g.phase in ["SET","CPU_SET"]: run_distance=maxf(run_distance,g.players[runner].position.distance_to(opening))
						if g.phase=="ATTACK": g.armed=true; g.charge=0.75; g.input_quality=1
						g.step(1.0/120)
						# Collision footprints must follow the displayed pose, as they
						# do in the rendered game; a stale previous-rally jump is invalid.
						if frame%8==0:
							for player in g.players: player.apply_pose(1.0/15)
						# Preparation now has a grounded upper-body layer instead
						# of launching the contact jump before the set exists.
						if not gesture_started and g.phase in ["SET","CPU_SET"] and g.players[runner].middle_load>.5:
							gesture_started=true; early_gestures+=1
						if g.phase in ["ATTACK","CPU_ATTACK"]:
							if release_gap<0: release_gap=g.players[runner].position.distance_to(g.players[runner].stance_for_contact("attack",g.flight_target)); setter_time=g.clock_time
							run_metres+=g.players[runner].position.distance_to(last_root); max_run_speed=maxf(max_run_speed,g.players[runner].velocity.length())
						last_root=g.players[runner].position
						if g.phase in ["ATTACK","CPU_ATTACK"] and not gesture_started and g.players[g.hitter].clip_name=="attack":
							gesture_started=true
							if g.flight_left>0.70: early_gestures+=1
					if run_distance>0.3: early_runs+=1
					if g.test_contacts!=before+3:
						failures+=1; print("APPROACH42 FAIL roots=",g.players.map(func(p): return {"p":str(p.position),"target":str(p.target),"v":str(p.velocity),"clip":p.clip_name})," decoy=",g.middle_decoy.index," team=",team," rot=",rotation," dir=",direction," quick=",quick," phase=",g.phase," contacts=",g.test_contacts-before," hitter=",g.hitter," point=",g.flight_target)
					report.append({"team":team,"rotation":rotation,"direction":direction,"quick":quick,"hitter":runner,"front":g.Tactics.front(runner,rotation),"release_gap":release_gap,"run_metres":run_metres,"max_run_speed":max_run_speed,"middle_fake":g.middle_decoy.events[-1].apex_at-setter_time if g.middle_decoy.events.size()>decoy_count and setter_time>0 else null})
					cases+=1
	if failures>0:
		push_error("Reception, set and attack must retain all three real contacts; failures="+str(failures))
		g.free(); quit(1); return
	var pin_cases:=0; var pin_travel:=0.0; var pin_gap:=0.0
	for row in report:
		if row.front and row.direction in [0,2] and not row.quick:
			pin_cases+=1; pin_travel+=row.run_metres; pin_gap+=row.release_gap
	assert(pin_cases==18 and pin_travel/pin_cases>1.0 and pin_gap/pin_cases>0.5,"Pins retain a running jump after starting the runway before set release")
	assert(early_runs>cases/2 and early_gestures>0,"Approaches start during the first pass and show grounded preparation before set release")
	print("APPROACH42 PASS cases=",cases," early_runs=",early_runs," longer_gestures=",early_gestures," high pin run mean=",pin_travel/pin_cases," release gap mean=",pin_gap/pin_cases," all real receive/set/attack contacts")
	FileAccess.open("res://docs/approach42-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	g.free(); quit()

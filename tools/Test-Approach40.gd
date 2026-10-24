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
	var cases:=0; var early_runs:=0; var early_gestures:=0; var failures:=0
	for team in 2:
		for rotation in 6:
			for direction in 4:
				for quick in [false,true]:
					g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
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
					for frame in 700:
						if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]: break
						if g.phase in ["SET","CPU_SET"]: run_distance=maxf(run_distance,g.players[runner].position.distance_to(opening))
						if g.phase=="ATTACK": g.armed=true; g.charge=0.75; g.input_quality=1
						g.step(1.0/120)
						if g.phase in ["ATTACK","CPU_ATTACK"] and not gesture_started and g.players[g.hitter].clip_name=="attack":
							gesture_started=true
							if g.flight_left>0.70: early_gestures+=1
					if run_distance>0.3: early_runs+=1
					if g.test_contacts!=before+3:
						failures+=1; print("APPROACH40 FAIL team=",team," rot=",rotation," dir=",direction," quick=",quick," phase=",g.phase," contacts=",g.test_contacts-before," hitter=",g.hitter," point=",g.flight_target)
					cases+=1
	assert(failures==0,"Reception, set and attack must retain all three real contacts")
	print("APPROACH40 totals cases=",cases," early_runs=",early_runs," longer_gestures=",early_gestures)
	assert(early_runs>cases/2 and early_gestures>0,"Approaches start during the first pass and show a longer pre-contact gesture")
	print("APPROACH40 PASS cases=",cases," early_runs=",early_runs," longer_gestures=",early_gestures," all real receive/set/attack contacts")
	g.free(); quit()

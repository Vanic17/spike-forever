extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.started=true
	game.demo=false
	var cases:=0
	var minimum_jump:=INF
	for team in 2:
		for rotation in 6:
			for direction in [0,2,3]:
				game.rotations=[rotation,rotation]
				game.server=1-team
				game.reset_rally()
				game.possession=team
				game.setter=team*6+5
				game.set_phase("SET" if team==0 else "CPU_SET")
				game.pass_quality=0.9
				game.out_of_system=1
				game.armed=true
				game.flight_target=game.Tactics.setter_position(team)
				game.flight_target.y=game.contact_height("set")
				game.flight_left=1.10
				game.players[game.setter].position=game.players[game.setter].stance_for_contact("set",game.flight_target)
				game.plan_attack(direction,false)
				var middle: int=game.Tactics.attacker(team,rotation,1,game.setter)
				var before: int=game.middle_decoy.events.size()
				var setter_contact: float=game.clock_time+game.flight_left
				var touches: Array=game.touches.duplicate()
				var peak:=0.0
				var runup_seen:=false
				for frame in 180:
					var dt:=1.0/60.0
					game.clock_time+=dt
					game.phase_time+=dt
					game.flight_left=maxf(0,game.flight_left-dt)
					if frame==66:
						game.set_phase("ATTACK" if team==0 else "CPU_ATTACK")
						game.hitter=game.planned_hitter
						game.flight_target=game.RallyAI.attack_contact(game,game.planned_direction,game.hitter,game.flight_target)
						game.flight_target.y=game.contact_height("attack")
						game.flight_left=1
					game.move_players(dt)
					for p in game.players: p.tick(dt,false,false)
					var p=game.players[middle]
					p.apply_pose(dt)
					if p.clip_name=="attack" and game.middle_decoy.events.size()>before:
						if not runup_seen and p.animation_time>=p.clips.attack.contact_time:
							var source_travel: float=(p.clips.attack.root_motion(p.clips.attack.contact_time)-p.clips.attack.root_motion(game.middle_decoy.source_begin)).length()
							assert(p.position.distance_to(game.middle_decoy.motion_origin)>minf(0.5,source_travel*0.70),"Both the full approach and contextual last steps must move the real body by their source displacement")
							runup_seen=true
						var left: int=p.clips.idle.names.find("LeftToeBase")
						var right: int=p.clips.idle.names.find("RightToeBase")
						peak=maxf(peak,minf(p.last_pose[left].origin.y,p.last_pose[right].origin.y))
				assert(game.middle_decoy.events.size()==before+1,"Every good non-middle set needs exactly one middle decoy")
				if absf(game.middle_decoy.events[-1].apex_at-setter_contact)>=0.35:
					print("DECOY ARRIVAL DIAGNOSTIC team=",team," R=",rotation+1," direction=",direction," apex=",game.middle_decoy.events[-1].apex_at-setter_contact," origin=",game.middle_decoy.motion_origin)
				assert(absf(game.middle_decoy.events[-1].apex_at-setter_contact)<0.35,"The decoy must threaten a first tempo near the set, not jump late with the wing")
				assert(peak>0.20,"The middle must actually leave the floor for the quick decoy")
				assert(runup_seen)
				assert(game.touches==touches,"A decoy cannot touch or redirect the ball")
				assert(game.middle_decoy.index==-1,"After landing the middle must resume coverage")
				minimum_jump=minf(minimum_jump,peak)
				cases+=1
	# No fake jump for a poor reception or the actual first-tempo recipient.
	game.reset_rally()
	game.possession=0
	game.setter=5
	game.set_phase("SET")
	game.pass_quality=0.5
	game.out_of_system=1
	game.plan_attack(0,false)
	game.middle_decoy.update(game)
	assert(game.middle_decoy.index==-1)
	game.pass_quality=0.9
	game.setter=3
	game.out_of_system=0
	game.plan_attack(0,false)
	game.middle_decoy.update(game)
	assert(game.middle_decoy.index>=0,"A good pass also retains the threat when a non-middle teammate must set")
	game.pass_quality=0.9
	game.plan_attack(1,true)
	game.middle_decoy.update(game)
	assert(game.middle_decoy.index==-1)
	print("MIDDLE DECOY PASS: ",cases," good-pass plays / all six rotations and both teams / exactly one real empty jump / no ball touch / landing then coverage / minimum toe rise=",minimum_jump)
	game.queue_free()
	quit()

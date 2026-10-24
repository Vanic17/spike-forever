extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	var rows: Array=[]; var fake_total:=0; var fake_started:=0; var real_total:=0; var real_prepared:=0
	for team in 2:
		for rotation in 6:
			for direction in 4:
				for quality in [.55,.95]:
					if "--trace-fake" in OS.get_cmdline_user_args() and (team!=0 or rotation!=1 or direction!=0 or quality<.9): continue
					if "--trace" in OS.get_cmdline_user_args() and (team!=0 or rotation!=0 or direction!=1 or quality<.9): continue
					game.rotations=[rotation,rotation]; game.server=1-team; game.reset_rally(); game.possession=team; game.setter=team*6+5
					for athlete in game.players:
						athlete.play("relaxed",1,true); athlete.velocity=Vector3.ZERO; athlete.acceleration=Vector3.ZERO; athlete.motion_lock=0
						athlete.tick(0,false,false)
						athlete.apply_pose(0)
					# A playable pass includes the observed incoming-flight phase.
					# Starting directly in SET with service-overlap positions tests an
					# impossible teleporting reception, not early anticipation.
					game.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; game.phase_time=0
					game.receiver=team*6+3
					for candidate in range(team*6,team*6+6):
						if game.Tactics.libero(candidate,rotation,false): game.receiver=candidate
					game.flight_target=game.Tactics.world(team,-1,5.5)+Vector3.UP*1.2; game.flight_left=.55; game.incoming_kind="serve"
					for incoming in 66:
						game.clock_time+=1.0/120; game.phase_time+=1.0/120; game.flight_left-=1.0/120
						game.move_players(1.0/120)
						for p in game.players: p.tick(1.0/120,false,false)
						if incoming%8==0:
							for p in game.players: p.apply_pose(1.0/15)
					game.phase="SET" if team==0 else "CPU_SET"; game.phase_time=0; game.armed=false; game.setter_dump=false
					game.pass_quality=quality; game.out_of_system=1
					game.flight_target=game.Tactics.world(team,1.65,1.5)+Vector3.UP*game.contact_height("set")
					game.flight_left=1.15
					game.players[game.setter].position=game.players[game.setter].stance_for_contact("set",game.flight_target)
					game.plan_attack(direction,false)
					var middle: int=game.Tactics.attacker(team,rotation,1,game.setter)
					var actual: bool=middle==game.planned_hitter
					var before: int=game.middle_decoy.events.size(); var seen:=false; var first_time:=-1.0
					for frame in 132:
						game.clock_time+=1.0/120; game.phase_time+=1.0/120; game.flight_left-=1.0/120
						game.move_players(1.0/120)
						for p in game.players: p.tick(1.0/120,false,false)
						if frame%8==0:
							for p in game.players: p.apply_pose(1.0/15)
						if "--trace" in OS.get_cmdline_user_args() and frame in [0,60,120]:
							var p=game.players[middle]
							print("TEMPO TRACE ",frame," middle=",middle," planned=",game.planned_hitter," decoy=",game.middle_decoy.index," real=",game.middle_decoy.real_attack," clip=",p.clip_name," variant=",p.variant_names.attack," sourcecontact=",p.clips.attack.contact_time," lead=",p.preparation_lead("attack",1.65)," flight=",game.flight_left," pos=",p.position," target=",p.target)
						if not seen and (game.players[middle].middle_load>.5 or (game.players[middle].clip_name=="attack" and game.players[middle].animation_time>0.02)):
							seen=true; first_time=game.flight_left
					var started: bool=game.middle_decoy.events.size()>before
					if "--trace-fake" in OS.get_cmdline_user_args():
						print("FAKE TRACE middle=",middle," p=",game.players[middle].position," goal=",game.middle_decoy.target," waypoint=",game.players[middle].target," jumped=",game.middle_decoy.jumped," begin=",game.middle_decoy.source_begin)
						for i in range(team*6,team*6+6): print("BODY ",i," ",game.players[i].position," target=",game.players[i].target)
					if actual: real_total+=1; real_prepared+=int(seen)
					else: fake_total+=1; fake_started+=int(seen)
					rows.append({"team":team,"rotation":rotation+1,"direction":direction,"quality":quality,"actual_middle":actual,"fake":started,"prepared":seen,"seconds_before_set":first_time,"gap":game.players[middle].position.distance_to(game.middle_decoy.target)})
	# A genuinely detached second touch must not launch a stale first tempo.
	game.middle_decoy.reset(); game.phase="SET"; game.flight_target.z=3.25; game.pass_quality=.95
	game.move_players(1.0/120); assert(game.middle_decoy.index<0)
	var output: String="res://docs/preparation46-report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"fake_started":fake_started,"fake_total":fake_total,"real_prepared":real_prepared,"real_total":real_total,"three_metre_exception":true},"\t"))
	print("PREPARATION46 RESULTS fakes=",fake_started,"/",fake_total," real=",real_prepared,"/",real_total)
	if not "--baseline" in OS.get_cmdline_user_args():
		assert(fake_started==fake_total,"Every ordinary near-net pass must prepare an automatic middle threat")
		assert(real_prepared==real_total,"Every actual middle must prepare before the setter contact")
		print("PREPARATION46 PASS")
	quit()

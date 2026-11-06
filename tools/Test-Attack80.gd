extends SceneTree
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok:errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate();root.add_child(g)
	g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.replay.enabled=false;g.match_audio.enabled=false
	var cases: Array=[]
	for native in [false,true]:
		g.Avatar.native_animation_enabled=native
		for left in [false,true]:
			for scenario in [[0,0],[4,2],[2,3]]:
				g.rotations=[scenario[0],scenario[0]];g.server=1;g.rng.seed=40001;g.reset_rally();g.shot_serial=1;g.possession=0;g.set_dir=scenario[1]
				for index in 6:g.players[index].left_handed=left
				for index in 6:
					if g.Tactics.libero(index,scenario[0],false):g.receiver=index
				g.players[g.receiver].position=g.Tactics.world(0,0,5.5);g.players[5].position=g.Tactics.world(0,1.65,2)
				g.ball_pos=g.players[g.receiver].contact_world("receive");g.phase="RECEIVE";g.armed=true;g.input_quality=1;g.incoming_kind="spike";g.incoming_power=.3;g.winner_team=-1
				var before: int=g.test_contacts;g.receive_ball();g.press_action("action")
				var runner: int=g.planned_hitter;var running:=false;var largest_step:=0.0
				var performance: String=g.players[runner].variant_names.get("attack","")
				check(performance.begins_with("attack_middle_style"),"new performance selected for "+str([native,left,scenario,performance]))
				for frame in 700:
					if g.test_contacts>=before+3 or g.phase in ["POINT","LOOSE"]:break
					if g.phase=="ATTACK":g.armed=true;g.charge=.8;g.input_quality=1
					if g.players[runner].travel_animation_name=="run" and g.players[runner].velocity.length()>1.25:running=true
					var previous: Vector3=g.players[runner].position;g.step(1.0/120)
					largest_step=maxf(largest_step,previous.distance_to(g.players[runner].position))
				check(g.test_contacts==before+3,"real spike contacts "+str([native,left,scenario]))
				check(running,"visible running feet "+str([native,left,scenario]))
				check(largest_step<.13,"no root teleport in approach")
				if scenario[1] in [2,3]:check(g.attack_run.air_start.z>3 and g.players[runner].position.z<3,"legal back row takeoff and forward flight")
				cases.append({"native":native,"left_handed":left,"scenario":scenario,"variant":performance,"contacts":g.test_contacts-before,"running":running,"largest_step":largest_step})
	FileAccess.open("res://docs/attack80-gameplay.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"cases":cases,"failures":errors},"  "))
	print("ATTACK80 ","PASS" if errors.is_empty() else "FAIL",errors);g.free();quit(0 if errors.is_empty() else 1)

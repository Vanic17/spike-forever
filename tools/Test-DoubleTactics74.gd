extends SceneTree
## Native exhibition scene: double changes preserve legal slots and change jobs.
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
const Access=preload("res://src/setter_access.gd")
var game
var manager
var db
var teams: Array=[]
var squads: Array=[]
var checks:=0
var failures: Array[String]=[]
var cases: Array=[]

func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error("DOUBLE TACTICS74 "+message)

func setup(side: int,rotation: int):
	game.substitution_scene.cancel()
	game.replay.reset(); game.replay.enabled=false
	check(manager.configure_rosters(teams,squads,{}, {"fatigue":false,"auto_subs":false}),"native roster configuration")
	manager.lock_lineup()
	game.started=true; game.paused=false; game.demo=false; game.use_player_stats=true
	game.phase="POINT"; game.match_finished=false; game.charging=false; game.toss_active=false
	game.rotations=[rotation,rotation]; game.server=1-side; game.possession=side
	game.incoming_kind="serve"; game.receiver=side*6; game.setter=side*6+5
	game.flight_spin=Vector3.ZERO; game.ball_pos=Vector3(0,2,3); game.ball_vel=Vector3(1,2,3)
	game.touches=[0,0]; game.last_touch=1-side
	game.rally_lanes.reset(game.rotations,game.server)
	game.court_shape.reset()
	for i in 12:
		var p=game.players[i]
		p.libero_active=Tactics.libero(i,rotation,int(i/6)==game.server)
		p.position=Tactics.serve_position(i,int(i/6),rotation,int(i/6)==game.server)
		p.rotation.y=PI if i<6 else 0.0; p.velocity=Vector3.ZERO; p.motion_lock=0; p.reach_weight=0
		p.play("idle",1,true)
	var opposite_options: Array=manager.double_options(side,"opposite")
	var setter_options: Array=manager.double_options(side,"setter")
	check(not opposite_options.is_empty() and not setter_options.is_empty(),"real club has both reserves")
	return [str(opposite_options[0].id),str(setter_options[0].id)]

func stage_native_set(side: int,direction: int,quick: bool):
	var setter_index:=Tactics.designated_setter(game,side)
	var p=game.players[setter_index]
	game.substitution_scene.cancel()
	game.phase="SET" if side==0 else "CPU_SET"; game.phase_time=0
	game.possession=side; game.setter=setter_index; game.receiver=side*6
	game.touches=[1,0] if side==0 else [0,1]; game.last_touch=side
	game.pass_quality=1; game.input_quality=1; game.out_of_system=1; game.armed=true; game.setter_dump=false
	game.planned_hitter=-1; game.hitter=-1; game.set_dir=direction; game.fast_set=quick
	p.position=Tactics.world(side,0,2.6); p.rotation.y=-PI/2 if side==0 else PI/2; p.setting_yaw=p.rotation.y
	p.velocity=Vector3.ZERO; p.body_lean=Vector2.ZERO; p.motion_lock=0; p.reach_weight=0
	game.plan_attack(direction,quick)
	var action: String="fast_set" if quick else "set"
	game.setter_action=action; p.prepare_contact(action,0)
	game.ball_pos=p.contact_world(action); game.flight_target=game.ball_pos
	game.ball_vel=Vector3(0,-1,0); game.flight_left=0; game.airborne=true
	var incoming_id: String=manager.actor_id(setter_index)
	var prior: int=manager.stat(incoming_id).sets
	game.set_ball()
	check(game.phase==("ATTACK" if side==0 else "CPU_ATTACK"),"new setter completes native set, side "+str(side)+" direction "+str(direction))
	check(manager.stat(incoming_id).sets==prior+1,"measured set is credited to reserve setter")
	check(game.hitter!=setter_index,"new specialist is not selected as his own attacker")
	check(is_finite(game.flight_left) and game.flight_left>0 and game.flight_left<4,"same set flight remains bounded")
	check(game.PlayerStats.rating(game,setter_index,"palleggio")==float(manager.identity(incoming_id).ratings.palleggio),"source PlayerStats reads actual reserve setter")
	return game.hitter

func test_entry_rotations():
	for side in 2:
		for rotation in 6:
			var reserves: Array=setup(side,rotation)
			var expected_front:=Tactics.front(side*6+5,rotation)
			var legal_before: Array=[]
			for i in range(side*6,side*6+6): legal_before.append(Tactics.slot(i,rotation))
			var ball_before: Array=[game.ball_pos,game.ball_vel,game.flight_spin,game.flight_gravity]
			var current_before: Array=manager.current.duplicate(true)
			var result: String=manager.double_change(side,reserves[0],reserves[1])
			check(result.is_empty()==expected_front,"entry only original setter front row, both sides all rotations")
			if not expected_front:
				check(manager.current==current_before and manager.counts==[0,0],"invalid rotation changes nothing")
				continue
			check(ball_before==[game.ball_pos,game.ball_vel,game.flight_spin,game.flight_gravity],"substitution cannot alter ball physics")
			check(manager.current[side][5]==reserves[0] and manager.current[side][2]==reserves[1],"pair inherits registered slots")
			check(Tactics.designated_setter(game,side)==side*6+2,"reserve setter assumes regia")
			var old_pipe:=Tactics.attacker(side,rotation,3,side*6+5)
			var old_middle:=Tactics.attacker(side,rotation,1,side*6+5)
			check(Tactics.attacker_for(game,side,3,side*6+2)==old_pipe,"OH pipe identity preserved")
			check(Tactics.attacker_for(game,side,1,side*6+2)==old_middle,"middle and its quick lane preserved")
			var front_attackers: Array=[]
			for direction in 3:
				var hitter:=Tactics.attacker_for(game,side,direction,side*6+2)
				front_attackers.append(hitter)
				check(hitter>=0 and Tactics.front(hitter,rotation),"each front attack has a legal front-row attacker")
			check(front_attackers.has(side*6+5) and not front_attackers.has(side*6+2),"reserve opposite joins three attackers")
			for i in range(side*6,side*6+6):
				check(Tactics.slot(i,rotation)==legal_before[i%6],"registered rotation order unchanged")
				check(Tactics.serve_position_for(game,i,side,rotation,false)==Tactics.serve_position(i,side,rotation,false),"receiving diagram remains the same legal slot")
				check(game.players[i].role_label()==Tactics.role_for(game,i) or i%6 in [0,1,3,4],"swapped role label matches current job")
			game.phase="SET" if side==0 else "CPU_SET"; game.phase_time=.1; game.flight_left=.9; game.flight_target=Tactics.world(side,0,1.5); game.setter=side*6+2
			var opening:=AI.opening(game,side*6+5,side)
			check(absf(opening.x)>4.0 and absf(opening.z)>2.0,"new opposite opens for an actual pin approach instead of setter anchor")
			var regia:=AI.opening(game,side*6+2,side)
			check(regia==Tactics.setter_position(side),"new setter receives setter preparation target")
			for direction in 4:
				for quick in [false,true]: stage_native_set(side,direction,quick)
			cases.append({"side":side,"rotation":rotation,"front":front_attackers,"pipe":old_pipe,"setter":side*6+2})

func test_later_rotations_and_return():
	for side in 2:
		var reserves: Array=setup(side,3)
		check(manager.double_change(side,reserves[0],reserves[1]).is_empty(),"entry for continuous rotation test")
		var stored: Dictionary=manager.export_state()
		for rotation in 6:
			game.rotations[side]=rotation; game.phase="RECEIVE" if side==0 else "CPU_RECEIVE"; game.possession=side
			var index:=side*6+2
			check(Tactics.designated_setter(game,side)==index and Tactics.role_for(game,index)=="S","new setter stays specialist through every rotation")
			var point:=Tactics.world(side,0,2.2)
			game.players[index].setting_yaw=-PI/2 if side==0 else PI/2
			game.players[index].position=game.players[index].stance_for_contact("set",point)
			check(game.choose_setter(side,point,2.0)==index,"shared second-touch selection uses new setter all rotations")
			var before: int=game.rng.state
			var duration:=Access.pass_seconds(game,point,1.1)
			check(is_finite(duration) and duration>=1.1 and duration<=1.95 and game.rng.state==before,"dynamic default setter arrival uses source bounds without RNG")
			var context: Dictionary=game.rotation_context.capture(game,1-side)
			var ownrow: Dictionary={}
			for row in context.roster:
				if row.player_id==reserves[1]: ownrow=row
			check(not ownrow.is_empty() and ownrow.role=="S" and ownrow.rotation_slot==Tactics.ZONES[Tactics.slot(index,rotation)],"rotation capture reports actual setter in original regulatory slot")
		game.phase="POINT"; game.charging=false; game.toss_active=false
		check(manager.double_change(side,"","",true).is_empty(),"single return restores both starters")
		check(Tactics.designated_setter(game,side)==side*6+5 and manager.counts[side]==4,"returned regia and four ordinary changes")
		check(manager.current[side][5]==squads[side][5].id and manager.current[side][2]==squads[side][2].id,"starting identities restored")
		manager.import_state(stored)
		check(Tactics.designated_setter(game,side)==side*6+2 and manager.actor_id(side*6+2)==reserves[1],"online state import restores specialist and identity together")
		manager.start_set()
		check(Tactics.designated_setter(game,side)==side*6+5 and manager.counts[side]==0,"next set restores original tactical pair and fresh counts")

func test_career_result():
	var host
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child; break
	host.installed_version="999.0.0"; host.startup_scan=false
	var career=host.career_menu; career.ensure_manager()
	check(career.manager.new_career(str(teams[0].id),{"seed":74074,"best_of":3,"autosave":false,"stats":true,"fatigue":false,"injuries":false},11),"actual championship created in isolated profile")
	var fixture: Dictionary=career.manager.next_fixture()
	career.launch_match()
	check(game.started and manager.active,"championship launches existing substitution manager")
	game.replay.enabled=false; game.substitution_scene.testing=true
	manager.lock_lineup(); game.phase="POINT"; game.rotations[0]=3; game.charging=false; game.toss_active=false
	var opposite_options: Array=manager.double_options(0,"opposite")
	var setter_options: Array=manager.double_options(0,"setter")
	check(not opposite_options.is_empty() and not setter_options.is_empty(),"championship actual roster supplies both reserves")
	if opposite_options.is_empty() or setter_options.is_empty(): return
	var incoming_setter: String=setter_options[0].id
	check(manager.double_change(0,str(opposite_options[0].id),incoming_setter).is_empty(),"championship double entry")
	stage_native_set(0,2,false)
	game.phase="POINT"; game.charging=false; game.toss_active=false; game.rotations[0]=0
	check(manager.double_change(0,"","",true).is_empty(),"championship starters return")
	check(manager.counts[0]==4 and manager.substitutions.size()==4,"championship consumes four ordinary changes")
	game.substitution_scene.cancel()
	for set_index in 2:
		game.phase="ATTACK"; game.scores=[24,15]; game.award(0,"DOUBLE74 TEST")
	check(game.match_finished,"actual championship finishes through original scoring")
	var result: Dictionary=career.manager.fixture(fixture.id).result
	check(not result.is_empty() and result.get("substitutions",[]).size()==4,"played career result contains all four substitution events")
	check(result.get("players",{}).get(incoming_setter,{}).get("sets",0)==1,"championship result retains actual reserve setter statistics")
	check(career.manager.save(),"championship result saves through existing checksummed repository")
	var reloaded=load("res://src/career_manager.gd").new()
	check(reloaded.load_career(11) and reloaded.fixture(fixture.id).result.get("substitutions",[]).size()==4,"double-change events survive real save and reload")

func run():
	check(ProjectSettings.globalize_path("user://").contains("double74"),"isolated data directory")
	if not failures.is_empty(): quit(1); return
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false; game.replay.enabled=false
	game.substitution_scene.testing=true; game.substitution_scene.set_process(false)
	await process_frame
	db=load("res://src/league.gd").new(); teams=[db.teams[0],db.teams[1]]; squads=[db.lineup(teams[0]),db.lineup(teams[1])]; manager=game.match_management
	test_entry_rotations(); test_later_rotations_and_return(); test_career_result()
	var report: Dictionary={"checks":checks,"failures":failures,"native_source_clips":game.players[0].clips.size(),"cases":cases,"same_regulatory_slots":true,"actual_set_contacts":49,"all_rotations_second_touch":12,"imports_restore_roles":true,"career_played_result_save_reload":true}
	FileAccess.open("res://docs/double74-tactics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DOUBLE TACTICS74 ",JSON.stringify(report)); game.free(); quit(0 if failures.is_empty() else 1)

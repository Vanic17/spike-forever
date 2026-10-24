extends SceneTree
## Paired deterministic games: original and authored visuals receive identical
## commands. Compare real physics/tactical state at every simulation substep.
const Motion=preload("res://src/motion_prototypes.gd")
var original
var authored
var comparisons:=0
var maximum_ball_error:=0.0
var maximum_root_error:=0.0
var prototype_attack_contacts:=0
var prototype_dive_contacts:=0
var case_reports: Array=[]

func _initialize() -> void: call_deferred("run")

func create_game():
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	return game

func equal_state(context: String) -> void:
	for key in ["phase","possession","receiver","setter","hitter","planned_hitter","rotations","scores","sets","touches","armed","charging","set_dir","fast_set","incoming_kind","incoming_power","last_power","clock_time","flight_left","receive_deadline","flight_gravity","winner_team","test_contacts"]:
		var a=original.get(key)
		var b=authored.get(key)
		if typeof(a)==TYPE_FLOAT:
			assert(absf(a-b)<0.000001,context+": scalar gameplay diverged: "+key+" "+str([a,b]))
		else:
			assert(a==b,context+": discrete gameplay diverged: "+key+" "+str([a,b]))
	for key in ["ball_pos","ball_vel","flight_target","flight_spin"]:
		var distance: float=original.get(key).distance_to(authored.get(key))
		maximum_ball_error=maxf(maximum_ball_error,distance)
		assert(distance<0.000001,context+": ball trajectory/deadline target diverged: "+key+" "+str(distance))
	assert(original.rng.state==authored.rng.state,context+": visuals consumed gameplay random values")
	for i in 12:
		for key in ["position","target","velocity","acceleration"]:
			var distance: float=original.players[i].get(key).distance_to(authored.players[i].get(key))
			maximum_root_error=maxf(maximum_root_error,distance)
			assert(distance<0.000001,context+": actor motion diverged: "+str(i)+":"+key+" "+str(distance))
		assert(absf(original.players[i].motion_lock-authored.players[i].motion_lock)<0.000001,context+": physical recovery lock changed")
	comparisons+=1

func prepare_construction(g, enabled: bool, team: int, rotation: int, direction: int, quick: bool, serial: int) -> void:
	Motion.enabled=enabled
	g.clock_time=0
	g.rally_serial=0
	g.shot_serial=serial
	g.rotations=[rotation,rotation]
	g.server=1-team
	g.rng.seed=40001
	g.reset_rally()
	g.possession=team
	g.receiver=team*6+4
	g.set_dir=direction
	g.players[g.receiver].position=g.Tactics.world(team,0,5.5)
	g.players[team*6+5].position=g.Tactics.world(team,1.65,2)
	g.ball_pos=g.players[g.receiver].contact_world("receive")
	g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
	g.armed=true
	g.input_quality=1
	g.incoming_kind="spike"
	g.incoming_power=0.3
	g.receive_ball()
	if team==1: g.plan_attack(direction,quick)
	else: g.press_action("alternate" if quick else "action")

func construction(team: int, rotation: int, direction: int, quick: bool, serial: int) -> void:
	var before: int=original.test_contacts
	prepare_construction(original,false,team,rotation,direction,quick,serial)
	prepare_construction(authored,true,team,rotation,direction,quick,serial)
	var context:="construction "+str([team,rotation,direction,quick])
	equal_state(context+" start")
	var steps:=0
	for frame in 700:
		if original.test_contacts>=before+3 or original.phase in ["POINT","LOOSE"]: break
		var previous_contacts: int=authored.contact_log.size()
		Motion.enabled=false
		if original.phase=="ATTACK": original.armed=true; original.charge=0.75; original.input_quality=1
		original.step(1.0/120)
		Motion.enabled=true
		if authored.phase=="ATTACK": authored.armed=true; authored.charge=0.75; authored.input_quality=1
		authored.step(1.0/120)
		for index in range(previous_contacts,authored.contact_log.size()):
			if authored.contact_log[index].variant=="attack_adaptive41":
				prototype_attack_contacts+=1
				var player=authored.players[authored.contact_log[index].player]
				assert(player.pose_tree.initialized and player.pose_tree.library.has_animation("attack_adaptive41"))
		equal_state(context+" step "+str(frame))
		steps+=1
	assert(original.test_contacts==before+3 and authored.test_contacts==before+3,context+": all three real contacts must complete")
	case_reports.append({"team":team,"rotation":rotation,"direction":direction,"quick":quick,"steps":steps,"hitter":authored.hitter,"phase":authored.phase,"clock_time":authored.clock_time,"flight_left":authored.flight_left,"target":str(authored.flight_target),"rng_state":str(authored.rng.state)})

func prepare_dive(g, enabled: bool, team: int) -> int:
	Motion.enabled=enabled
	g.clock_time=0
	g.rally_serial=0
	g.shot_serial=5
	g.rotations=[0,0]
	g.server=1-team
	g.rng.seed=40001
	g.reset_rally()
	g.receiver=team*6+4
	g.possession=team
	g.incoming_kind="spike"
	g.input_quality=1
	var defender=g.players[g.receiver]
	var sign_z:=1.0 if team==0 else -1.0
	defender.position=Vector3(0,0,sign_z*5.5)
	defender.rotation.y=PI if team==0 else 0.0
	var point:=Vector3(0,g.contact_height("dive"),sign_z*4.6)
	g.ball_pos=point+Vector3(0,1.6,-sign_z*3)
	g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,point,0.30,Vector3.ZERO)
	g.flight_spin=Vector3.ZERO
	assert(g.queue_recovery(true),"Forward recovery must be physically queueable")
	return g.receiver

func queued_dive(team: int) -> void:
	var index:=prepare_dive(original,false,team)
	assert(prepare_dive(authored,true,team)==index)
	assert(original.players[index].variant_names.dive==Motion.Dive.SOURCE)
	assert(authored.players[index].variant_names.dive=="dive_authored41")
	equal_state("queued dive start")
	var seconds: float=original.flight_left
	for frame in int(ceil(seconds*120)):
		var dt:=minf(1.0/120,seconds-float(frame)/120)
		Motion.enabled=false
		original.advance_dive_body(index,dt)
		Motion.enabled=true
		authored.advance_dive_body(index,dt)
		equal_state("queued dive travel "+str(frame))
	original.ball_pos=original.flight_target
	authored.ball_pos=authored.flight_target
	Motion.enabled=false
	assert(original.validate_contact(index,"dive"))
	Motion.enabled=true
	assert(authored.validate_contact(index,"dive"))
	assert(authored.contact_log.back().variant=="dive_authored41")
	prototype_dive_contacts+=1
	equal_state("queued dive contact")
	for frame in 400:
		if not original.dive_motions.has(index): break
		assert(authored.dive_motions.has(index),"New floor recovery ended before original")
		Motion.enabled=false
		original.advance_dive_body(index,1.0/120)
		Motion.enabled=true
		authored.advance_dive_body(index,1.0/120)
		equal_state("queued dive floor/rise "+str(frame))
	assert(not original.dive_motions.has(index) and not authored.dive_motions.has(index))
	assert(authored.players[index].motion_lock==0)

func run() -> void:
	Motion.enabled=false
	original=create_game()
	Motion.enabled=true
	authored=create_game()
	for team in 2:
		for rotation in 6:
			for direction in 4:
				# receive_ball.launch increments the serial before planning. Start
				# at zero so the naturally selected pipe variant is attack_line.
				for quick in [false,true]: construction(team,rotation,direction,quick,0)
	for team in 2: queued_dive(team)
	assert(case_reports.size()==96)
	print("MOTION GAMEPLAY41 counters new_attack_contacts=",prototype_attack_contacts," new_dive_contacts=",prototype_dive_contacts," paired_checks=",comparisons)
	assert(prototype_attack_contacts>0 and prototype_dive_contacts==2,"Both new performances must meet the ball in the actual gameplay pipeline")
	var report: Dictionary={"construction_cases":case_reports.size(),"paired_substep_checks":comparisons,"queued_dive_cases":2,"prototype_attack_contacts":prototype_attack_contacts,"prototype_dive_contacts":prototype_dive_contacts,"maximum_ball_error":maximum_ball_error,"maximum_root_error":maximum_root_error,"tolerance":0.000001,"checks":["ball position/velocity/spin/target/deadline","all actor roots/targets/velocity/acceleration","eligible hitter/rotations/touches/scores/sets","action arming/charge state/CPU and player phases","gameplay RNG state","identical dive travel/floor/rise physical lock"],"cases":case_reports}
	var output:=FileAccess.open("res://docs/animation41-gameplay-parity.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	print("MOTION GAMEPLAY41 PASS cases=",case_reports.size()," paired_substep_checks=",comparisons," new_attack_contacts=",prototype_attack_contacts," new_dive_contacts=",prototype_dive_contacts," max_ball_error=",maximum_ball_error," max_root_error=",maximum_root_error)
	original.free()
	authored.free()
	Motion.enabled=true
	quit()

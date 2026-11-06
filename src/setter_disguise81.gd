extends RefCounted
## Explicit human set modifier. Failed requests leave the ordinary set intact.
static func held(game) -> bool:
	if game.network_match():return float(game.online_session.inputs[game.input_team].get("right",0))>.55
	if game.legend_match.enabled():return game.legend_match.buttons.get("dive_trigger",false) or game.legend_match.keys.get(KEY_B,false)
	return Input.get_action_strength("block_right")>.55
static func request(game,quick: bool) -> bool:
	if game.phase not in ["SET","CPU_SET"] or not game.airborne:return false
	if game.armed or game.setter_disguise or not game.human_team(game.possession) or game.touches[game.possession]!=1:return false
	if game.out_of_system!=1:return false
	var p=game.players[game.setter]
	if game.Tactics.libero(game.setter,game.rotations[game.possession],game.possession==game.server):return false
	if not game.Tactics.front(game.setter,game.rotations[game.possession]) and absf(p.position.z)<3.05:return false
	var clip=p.source_clips.get("set_disguise81")
	if clip==null:return false
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,clip.contact_offset.y,game.flight_gravity)
	# Leave time for a real plant/takeoff. A late command must never insert an
	# already-airborne pose into an otherwise grounded push animation.
	var minimum: float=maxf(.28,(clip.contact_time-clip.takeoff_time)/1.15+.045)
	if hit.is_empty() or hit.seconds<minimum:return false
	var offset: Vector3=clip.contact_offset
	if p.left_handed:offset.x=-offset.x
	var stance: Vector3=hit.point-Basis(Vector3.UP,PI if game.possession==0 else 0.0)*offset;stance.y=0
	if stance.distance_to(p.position)>hit.seconds*game.Reference.run_speed()+.55:return false
	if stance.z*(1 if game.possession==0 else -1)<.25:return false
	p.select_variant("dump","set_disguise81")
	if p.variant_names.get("dump","")!="set_disguise81":return false
	game.setter_disguise=true;game.setter_dump=false;game.setter_spike=false;game.setter_action="dump"
	game.plan_attack(game.set_dir,quick)
	game.flight_target=hit.point;game.flight_left=hit.seconds;p.target=stance
	game.attack_buffer_start=-1.0;game.attack_buffer_power=-1.0
	game.armed=true;game.input_quality=game.pass_quality
	p.prepare_contact("dump",hit.seconds)
	if game.legend_controls(game.setter):
		game.legend_match.source_motion={"action":"dump","last_root":p.action_root_motion("dump",p.animation_time),"origin":p.position,"rally":game.rally_serial,"second_spike":true}
	game.notice(preload("res://src/legend_locale.gd").text("FINTA DI SECONDA · ALZATA"),1.1)
	game.log_rally_event("human_disguised_set",{"setter":game.setter,"seconds":hit.seconds,"direction":game.planned_direction,"quick":game.planned_fast})
	return true

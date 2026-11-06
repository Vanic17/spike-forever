extends RefCounted
## Circle retains its original second-touch action. A following Cross converts
## that live, reachable opportunity before contact; no CPU decision calls this.
const WINDOW:=.28
static func offer(game):
	if game.human_team(game.possession) and game.touches[game.possession]==1 and (game.setter_dump or game.setter_spike):
		game.set_meta("second_disguise81",{"actor":game.setter,"rally":game.rally_serial,"until":game.clock_time+WINDOW})
static func convert(game) -> bool:
	if game.phase not in ["SET","CPU_SET"] or not game.airborne:return false
	if game.setter_disguise or not game.human_team(game.possession) or game.touches[game.possession]!=1:return false
	if not game.setter_dump and not game.setter_spike:return false
	var offered: Dictionary=game.get_meta("second_disguise81",{})
	if offered.get("actor",-1)!=game.setter or offered.get("rally",-1)!=game.rally_serial or game.clock_time>offered.get("until",-1.0):return false
	var p=game.players[game.setter]
	if game.Tactics.libero(game.setter,game.rotations[game.possession],game.possession==game.server):return false
	if not game.Tactics.front(game.setter,game.rotations[game.possession]) and absf(p.position.z)<3.05:return false
	var clip=p.source_clips.get("set_disguise81")
	if clip==null:return false
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,clip.contact_offset.y,game.flight_gravity)
	# Leave time for a real plant/takeoff. A late Cross must never insert an
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
	game.plan_attack(game.set_dir,false)
	game.flight_target=hit.point;game.flight_left=hit.seconds;p.target=stance
	game.attack_buffer_start=-1.0;game.attack_buffer_power=-1.0
	game.armed=true;game.input_quality=game.pass_quality
	p.prepare_contact("dump",hit.seconds)
	if game.legend_controls(game.setter):
		game.legend_match.source_motion={"action":"dump","last_root":p.action_root_motion("dump",p.animation_time),"origin":p.position,"rally":game.rally_serial,"second_spike":true}
	game.notice(preload("res://src/legend_locale.gd").text("FINTA DI SECONDA · ALZATA"),1.1)
	game.log_rally_event("human_disguised_set",{"setter":game.setter,"seconds":hit.seconds,"direction":game.planned_direction})
	return true

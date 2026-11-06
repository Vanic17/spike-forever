extends RefCounted
## Explicit human-only second-touch spike; CPU decision code never calls it.
static func request(game) -> bool:
	if not game.human_team(game.possession) or game.touches[game.possession]!=1:return false
	var p=game.players[game.setter]
	if game.Tactics.libero(game.setter,game.rotations[game.possession],game.possession==game.server):return false
	if not game.Tactics.front(game.setter,game.rotations[game.possession]) and absf(p.position.z)<3.05:return false
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,p.contact_local("attack").y,game.flight_gravity)
	if hit.is_empty() or hit.seconds<.08:return false
	var stance: Vector3=p.stance_for_contact("attack",hit.point)
	if stance.distance_to(p.position)>hit.seconds*game.Reference.run_speed()+.55:return false
	game.setter_spike=true;game.setter_dump=false;game.setter_action="attack"
	game.flight_target=hit.point;game.flight_left=hit.seconds;p.target=stance
	game.armed=true;game.input_quality=maxf(.4,game.pass_quality)
	if game.legend_controls(game.setter):
		p.prepare_contact("attack",hit.seconds)
		game.legend_match.source_motion={"action":"attack","last_root":p.action_root_motion("attack",p.animation_time),"origin":p.position,"rally":game.rally_serial,"second_spike":true}
	game.notice("SCHIACCIATA DI SECONDA",.9)
	game.log_rally_event("human_second_spike_prepared",{"setter":game.setter,"seconds":hit.seconds})
	return true
static func strike(game):
	game.hitter=game.setter;game.hitter_action="attack";game.charge=.85
	game.setter_spike=false
	game.attack_ball()

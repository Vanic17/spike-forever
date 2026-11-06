extends RefCounted
## Match the manual setter's actual hands to the same existing ball flight.
static func sync(game,force: bool=false):
	if game.phase!="SET" or not game.airborne or not game.legend_controls(game.setter) or game.setter_dump or game.setter_spike or game.setter_disguise:return
	var p=game.players[game.setter];var action: String=game.second_touch_contact_action()
	if action not in ["set","fast_set","receive"]:return
	var key:=str([game.shot_serial,game.setter,action,p.variant_names.get(action,action)])
	if not force and p.get_meta("legend_set_clock79","")==key:return
	p.set_meta("legend_set_clock79",key);p.setting_yaw=-PI/2
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,p.contact_local(action).y,game.flight_gravity)
	if hit.is_empty() or hit.seconds<=.001:return
	game.flight_target=hit.point;game.flight_left=hit.seconds;p.target=p.stance_for_contact(action,hit.point)
	game.log_rally_event("legend_set_sync",{"actor":game.setter,"action":action,"variant":p.variant_names.get(action,action),"seconds":hit.seconds})

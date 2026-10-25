extends RefCounted
static func start(game, passer: int) -> void:
	var side:=1.0 if game.possession==0 else -1.0
	var target:=Vector3(clampf(game.ball_pos.x+game.rng.randf_range(-1.3,1.3),-5.5,5.5),0.105,side*clampf(absf(game.ball_pos.z)+game.rng.randf_range(-0.8,0.8),0.8,9.8))
	game.launch(target,game.rng.randf_range(0.65,0.95))
	var contact: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,game.contact_height("recovery"),game.flight_gravity)
	if contact.is_empty(): game.phase="LOOSE"; return
	game.set_phase("RECEIVE" if game.possession==0 else "CPU_RECEIVE")
	game.incoming_kind="shank"; game.incoming_power=0.15; game.incoming_out=false
	game.receiver=game.nearest(game.possession,contact.point,passer)
	var planned: Dictionary=preload("res://src/low_recovery.gd").plan(game,game.receiver)
	if planned.is_empty():
		game.phase="LOOSE"; game.flight_left=100; game.marker.visible=false
		game.log_rally_event("low_save_unreachable",{"actor":game.receiver})
		return
	contact=planned
	game.flight_target=contact.point; game.flight_left=contact.seconds; game.receive_deadline=game.clock_time+contact.seconds
	game.late_receive=true; game.recovery_action="dive"; game.selected=game.receiver if game.possession==0 else game.selected
	game.players[game.receiver].target=game.players[game.receiver].stance_for_contact("dive",contact.point)
	game.notice("PALLA SPORCA · RECUPERO",0.8)

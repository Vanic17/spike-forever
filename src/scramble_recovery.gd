extends RefCounted
static func start(game, passer: int) -> void:
	var side:=1.0 if game.possession==0 else -1.0
	var target:=Vector3(clampf(game.ball_pos.x+game.rng.randf_range(-1.3,1.3),-5.5,5.5),0.105,side*clampf(absf(game.ball_pos.z)+game.rng.randf_range(-0.8,0.8),0.8,9.8))
	game.launch(target,game.rng.randf_range(0.65,0.95))
	var contact: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,game.contact_height("recovery"),game.flight_gravity)
	if contact.is_empty(): game.phase="LOOSE"; return
	game.set_phase("RECEIVE" if game.possession==0 else "CPU_RECEIVE")
	game.incoming_kind="shank"; game.incoming_power=0.15; game.incoming_out=false
	var nearest: int=game.nearest(game.possession,contact.point,passer)
	var planned: Dictionary={}
	# A close teammate may still be landing or lying across the route. Read
	# every legal rescuer before committing a pose, not merely the nearest root.
	for index in range(game.possession*6,game.possession*6+6):
		if index==passer: continue
		var candidate: Dictionary=preload("res://src/contact_rescue.gd").proposal(game,index,1.2)
		if candidate.is_empty(): continue
		if planned.is_empty() or candidate.cost<planned.cost: planned=candidate
	if planned.is_empty():
		game.phase="LOOSE"; game.flight_left=100; game.marker.visible=false
		game.log_rally_event("low_save_unreachable",{"actor":nearest})
		return
	game.receiver=planned.index
	preload("res://src/contact_rescue.gd").commit(game,planned,false)
	if game.receiver!=nearest: game.log_rally_event("low_save_handoff",{"nearest":nearest,"rescuer":game.receiver})
	contact=planned
	game.flight_target=contact.point; game.flight_left=contact.seconds; game.receive_deadline=game.clock_time+contact.seconds
	game.late_receive=true; game.recovery_action="dive"; game.selected=game.receiver if game.possession==0 else game.selected
	game.players[game.receiver].target=game.players[game.receiver].stance_for_contact("dive",contact.point)
	game.notice("PALLA SPORCA · RECUPERO",0.8)

extends RefCounted
static func choose(game) -> bool:
	if game.planned_direction!=1 or game.planned_fast or game.setter_dump or game.setter_spike or game.setter_disguise:return false
	if game.first_set_cooldown102[game.possession]>0:return false
	if game.pass_quality<=.95 or game.out_of_system<0 or game.Tactics.role_for(game,game.setter)!="S":return false
	var p=game.players[game.setter]
	var clip=p.source_clips.get("set_first96")
	if clip==null or not game.airborne:return false
	var key: String=str([game.rally_serial,game.shot_serial,game.setter])
	if game.get_meta("first_set_roll102",{}).get("key","")==key:return p.variant_names.get("set","")=="set_first96"
	var roll: float=game.rng.randf();game.set_meta("first_set_roll102",{"key":key,"roll":roll})
	if roll>=.25:return false
	# Judge the real one-hand interception, not the old two-hand marker. A
	# higher contact on the same descending pass happens slightly farther out.
	var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,clip.contact_offset.y*p.height_scale90,game.flight_gravity)
	if hit.is_empty() or hit.seconds<.18 or absf(hit.point.z)>1.35:return false
	var local: Vector3=clip.contact_offset
	if p.left_handed:local.x=-local.x
	var offset: Vector3=Basis(Vector3.UP,p.setting_yaw)*(local*p.height_scale90)
	var stance: Vector3=hit.point-offset;stance.y=0
	if p.position.distance_to(stance)>game.Reference.run_speed()*1.10*hit.seconds+.35:return false
	p.select_variant("set","set_first96")
	if p.variant_names.get("set","")!="set_first96":return false
	game.flight_target=hit.point;game.flight_left=hit.seconds
	p.target=stance;game.contact_navigation.reset()
	game.log_rally_event("first_set_one_hand",{"setter":game.setter,"depth":absf(hit.point.z),"remaining":hit.seconds})
	return true

static func contact(game,action: String) -> void:
	if action!="set" or game.planned_direction!=1 or game.planned_fast or game.Tactics.role_for(game,game.setter)!="S":return
	var team: int=game.possession
	var key: String=str([game.rally_serial,game.shot_serial,game.setter])
	if game.first_set_contact102[team]==key:return
	game.first_set_contact102[team]=key
	if game.players[game.setter].variant_names.get("set","")=="set_first96":game.first_set_cooldown102[team]=3
	elif game.first_set_cooldown102[team]>0:game.first_set_cooldown102[team]-=1

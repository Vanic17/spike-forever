extends RefCounted
const Flight=preload("res://src/ball_flight.gd")
static func candidates(game,index: int) -> Array:
	if game.winner_team>=0 or game.ball_vel.y>=-1 or game.ball_pos.y>1.3:return []
	var p=game.players[index]
	var ordinary:=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,p.contact_local("receive").y,game.flight_gravity)
	if not ordinary.is_empty() and ordinary.seconds>.015:
		var stance: Vector3=p.stance_for_contact("receive",ordinary.point)
		if p.position.distance_to(stance)<=ordinary.seconds*game.Reference.run_speed()+.50:return []
	var choices: Array=[]
	for variant in ["dive_pancake80","dive_roll80","dive_roll_right80"]:
		if not p.source_clips.has(variant):continue
		var clip=p.source_clips[variant]
		var hit:=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,clip.contact_offset.y,game.flight_gravity)
		if hit.is_empty() or hit.seconds<.11 or hit.seconds>.40:continue
		var local: Vector3=p.global_basis.inverse()*(hit.point-p.position)
		var distance:=Vector2(local.x,local.z).length()
		if distance<1.15 or distance>2.8:continue
		if variant=="dive_pancake80":
			if game.ball_pos.y>.85 or local.z<.75 or absf(local.x)>.65 or hit.seconds<.16:continue
		elif absf(local.x)<.85 or local.z<-.35 or (variant=="dive_roll80")!=(local.x>0):continue
		choices.append(variant)
	return choices
static func plan(game,index: int) -> Dictionary:
	var p=game.players[index]
	if game.dive_motions.has(index) or game.player_recovery_seconds(index)>.10:return {}
	var obstacles: Array[Vector3]=[]
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other!=index:obstacles.append_array(game.compute_footprint_points(other))
	for variant in candidates(game,index):
		var clip=p.source_clips[variant]
		var hit:=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,clip.contact_offset.y,game.flight_gravity)
		var toward: Vector3=hit.point-p.position
		var yaw: float=atan2(toward.x,toward.z)-atan2(clip.contact_offset.x,clip.contact_offset.z)
		if absf(wrapf(yaw-p.rotation.y,-PI,PI))>minf(deg_to_rad(110),hit.seconds*7.0):continue
		var stance: Vector3=hit.point-Basis(Vector3.UP,yaw)*clip.contact_offset;stance.y=0
		if stance.z*(1 if index<6 else -1)<.3 or absf(stance.x)>7 or absf(stance.z)>11.5:continue
		if p.position.distance_to(stance)>hit.seconds*4.8+.15:continue
		var begin: float=clip.contact_time-hit.seconds*1.15
		var route: Dictionary=load("res://src/contact_rescue.gd").forecast(p,clip,stance,yaw,begin,hit.seconds,obstacles)
		if not route.free or route.peak>7.2:continue
		return {"index":index,"variant":variant,"point":hit.point,"seconds":hit.seconds,"stance":stance,"yaw":yaw,"begin":begin,"cost":0.0}
	return {}
static func pancake_active(game) -> bool:
	var index: int=game.receiver if game.phase in ["RECEIVE","CPU_RECEIVE"] else (game.setter if game.phase in ["SET","CPU_SET"] else -1)
	return index>=0 and game.dive_motions.has(index) and game.players[index].variant_names.get("dive","")=="dive_pancake80"

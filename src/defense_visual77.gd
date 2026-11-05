extends RefCounted
## Visual reaction only after a failed contact. Never changes the ball,
## contact deadline, touch count, score or a successful defensive attempt.
static func extreme_attempt(game, index: int) -> bool:
	if index<0 or index>=game.players.size():return false
	if game.phase not in ["RECEIVE","CPU_RECEIVE"] or game.incoming_kind not in ["spike","soft","block"]:return false
	if game.human_team(game.possession) and not game.armed:return false
	var p=game.players[index]
	if game.dive_motions.has(index) or (p.clip_name in ["dive","recovery"] and p.contact_recovery_remaining()>0):return false
	var local: Vector3=p.global_basis.inverse()*(game.ball_pos-p.position)
	var gap:=Vector2(local.x,local.z).length()
	if gap<1.25 or gap>2.8 or game.ball_pos.y<.14 or game.ball_pos.y>1.15 or absf(local.x)<.7 or local.z<-.5 or game.ball_vel.y>-.2:return false
	if posmod(game.shot_serial,2)!=0:return false
	p.motion_lock=0;p.contact_scheduled=false;p.looping=true
	p.select_variant("dive","defense_miss77" if local.x>0 else "defense_miss_right77")
	p.play("dive",1,false)
	# The ball has already passed the playable window. Begin at the visible
	# last lunge, blending from the actual displayed pose, without a teleport.
	p.animation_time=maxf(0,p.clips.dive.contact_time-.22)
	p.reach_weight=0;p.velocity=Vector3.ZERO;p.target=p.position
	p.motion_lock=p.contact_recovery_remaining()
	game.log_rally_event("extreme_defence_visual",{"actor":index,"gap":gap,"variant":p.variant_names.dive})
	return true

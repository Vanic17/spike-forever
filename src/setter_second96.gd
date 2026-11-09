extends RefCounted
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_spec94.gd")
static func kind(game) -> int:
	if game.aim.y>.3 and absf(game.aim.y)>=absf(game.aim.x):return 3
	var facing: Vector3=Basis(Vector3.UP,game.players[game.setter].setting_yaw)*Vector3.BACK
	return 7 if game.aim.x*facing.x>0 else 2
static func request(game) -> bool:
	if not game.human_team(game.possession) or game.touches[game.possession]!=1 or game.armed:return false
	if game.Tactics.role_for(game,game.setter)!="S":return false
	if not game.Tactics.front(game.setter,game.rotations[game.possession]):return false
	var p=game.players[game.setter]
	p.setting_yaw=-PI/2 if game.possession==0 else PI/2
	var choice:=kind(game)
	var name: String={2:"dump_back96",3:"dump_down96",7:"dump_forward96"}[choice]
	var clip=p.source_clips.get(name)
	if clip==null:return false
	if game.flight_left<=0 or not game.airborne:return false
	var hit: Dictionary={"point":game.flight_target,"seconds":game.flight_left}
	# The fingers meet the ball inside the anatomical reach envelope, rather
	# than demanding the authored maximum extension plus the set's forward reach.
	var height: float=(clip.contact_offset.y-.12)*p.height_scale90
	var higher: Dictionary=Flight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,height,game.flight_gravity)
	# A prepared jump meets the SAME flight higher. Late inputs retain the
	# existing contact, never rewind the ball or fire a zero-time interception.
	if not higher.is_empty() and higher.seconds>=.16 and higher.seconds<=game.flight_left+.12 and higher.point.z*(1 if game.possession==0 else -1)>.25:hit=higher
	p.second_contact97=p.contact_local("set")
	p.second_contact97.y=hit.point.y
	if hit.seconds>.28:
		p.second_contact97.x=clip.contact_offset.x*p.height_scale90
		p.second_contact97.z=clip.contact_offset.z*p.height_scale90
	var offset: Vector3=p.second_contact97
	var stance: Vector3=hit.point-Basis(Vector3.UP,p.setting_yaw)*offset;stance.y=0
	p.select_variant("dump",name)
	game.setter_second96=choice;game.setter_dump=true;game.setter_spike=false;game.setter_disguise=false;game.setter_action="dump"
	game.flight_target=hit.point;game.flight_left=hit.seconds;p.target=stance;game.armed=true;game.input_quality=game.pass_quality
	p.prepare_contact("dump",hit.seconds)
	if game.legend_controls(game.setter):game.legend_match.source_motion={"action":"dump","last_root":p.action_root_motion("dump",p.animation_time),"origin":p.position,"rally":game.rally_serial,"second_spike":true}
	game.log_rally_event("setter_second_requested",{"kind":choice,"setter":game.setter})
	return true
static func trajectory(game) -> Dictionary:
	var choice: int=game.setter_second96;var side: float=-1 if game.possession==0 else 1
	var facing: Vector3=Basis(Vector3.UP,game.players[game.setter].setting_yaw)*Vector3.BACK
	var target:=Vector3(clampf(game.ball_pos.x+facing.x*(2.2 if choice==7 else -2.1),-4.0,4.0),Net.BALL_RADIUS,side*3.8)
	# Lateral second touches finish in the front court, not deep zone 1/5.
	if choice in [2,7]:target=Vector3(signf(facing.x*(1 if choice==7 else -1))*3.75,Net.BALL_RADIUS,side*2.15)
	if choice==3:target=Vector3(clampf(game.ball_pos.x*.80,-3.4,3.4),Net.BALL_RADIUS,side*3.6)
	var spin:=Vector3(side*(8.0 if choice==3 else 1.4),0,0)
	if absf(game.ball_pos.z)>1.65 or game.ball_pos.y<Net.TOP-.15:
		# Still execute the selected gesture. Do not manufacture a towering
		# legal lob from an unsuitable position: let the actual net absorb it.
		target=Vector3(clampf(game.ball_pos.x+facing.x*.30,-4.2,4.2),1.72,side*.12)
		return {"target":target,"seconds":.42+absf(game.ball_pos.z)*.035,"spin":spin,"pressure":.18}
	# Solve clearance with the real spin/drag integrator, not a gravity-only
	# parabola. The classic starts downward when the high contact permits it.
	var seconds: float=.50 if choice==3 else (.68 if choice==2 else .72)
	seconds=preload("res://src/winning_shot.gd").flight_seconds(game,target,seconds,Net.TOP+Net.BALL_RADIUS+.035)
	for attempt in 16:
		if crosses_cleanly(game,target,seconds,spin):break
		seconds+=.012
	if choice==3 and Flight.velocity_to(game.ball_pos,target,seconds,spin,game.flight_gravity).y>=0:
		# A low ball cannot be pushed down over the tape. Execute the gesture
		# into the actual mesh rather than substituting an upward lob or a fault.
		return {"target":Vector3(game.ball_pos.x,1.60,side*.12),"seconds":.30+minf(.15,absf(game.ball_pos.z)*.05),"spin":spin,"pressure":.18}
	return {"target":target,"seconds":seconds,"spin":spin,"pressure":.62 if choice==3 else .38}

static func crosses_cleanly(game,target: Vector3,seconds: float,spin: Vector3) -> bool:
	var point: Vector3=game.ball_pos
	var velocity:=Flight.velocity_to(point,target,seconds,spin,game.flight_gravity)
	for tick in ceili(seconds*120)+2:
		var next:=Flight.advance(point,velocity,spin,1.0/120,game.flight_gravity)
		if point.z*next[0].z<=0:
			var fraction: float=absf(point.z)/maxf(.00001,absf(point.z-next[0].z))
			return point.lerp(next[0],fraction).y>Net.TOP+Net.BALL_RADIUS+.025
		point=next[0];velocity=next[1]
	return false

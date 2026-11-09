extends RefCounted
const Net=preload("res://src/net_spec94.gd")
static func kind(game) -> int:
	if game.aim.y>.3 and absf(game.aim.y)>=absf(game.aim.x):return 3
	var facing: Vector3=Basis(Vector3.UP,game.players[game.setter].setting_yaw)*Vector3.BACK
	return 7 if game.aim.x*facing.x>0 else 2
static func request(game) -> bool:
	if not game.human_team(game.possession) or game.touches[game.possession]!=1 or game.armed:return false
	if game.Tactics.role_for(game,game.setter)!="S":return false
	var p=game.players[game.setter];var choice:=kind(game)
	var name: String={2:"dump_back96",3:"dump_down96",7:"dump_forward96"}[choice]
	var clip=p.source_clips.get(name)
	if clip==null:return false
	if game.flight_left<=0 or not game.airborne:return false
	# All three gestures intercept the already planned second ball. Selecting
	# a high palm must not advance its deadline or move its reserved footprint
	# into a teammate. Native animation plus bounded arm IK adapts the release.
	var hit: Dictionary={"point":game.flight_target,"seconds":game.flight_left}
	p.second_contact97=p.contact_local("set")
	p.second_contact97.y=hit.point.y
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
	var target:=Vector3(clampf(game.ball_pos.x+facing.x*(2.2 if choice==7 else -2.1),-4.0,4.0),Net.BALL_RADIUS,side*3.3)
	if choice==3:target=Vector3(clampf(game.ball_pos.x*.65,-3.4,3.4),Net.BALL_RADIUS,side*1.75)
	var spin:=Vector3((1 if game.possession==0 else -1)*(5.5 if choice==3 else 2.2),0,0)
	if absf(game.ball_pos.z)>1.65 or game.ball_pos.y<Net.TOP+.08:
		# Still execute the selected gesture. Do not manufacture a towering
		# legal lob from an unsuitable position: let the actual net absorb it.
		target=Vector3(clampf(game.ball_pos.x+facing.x*.30,-4.2,4.2),1.72,side*.12)
		return {"target":target,"seconds":.42+absf(game.ball_pos.z)*.035,"spin":spin,"pressure":.18}
	var seconds: float=preload("res://src/winning_shot.gd").flight_seconds(game,target,.48 if choice==3 else .76,Net.TOP+Net.BALL_RADIUS+.04)
	return {"target":target,"seconds":seconds,"spin":spin,"pressure":.62 if choice==3 else .38}

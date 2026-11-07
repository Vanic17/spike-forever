extends RefCounted
## One physics-tick presentation buffer. Never interpolate gameplay positions,
## contact deadlines or velocities. Replay and the online guest own their draws.
var previous: Dictionary={}
var current: Dictionary={}
var displayed_time:=0.0
var enabled:=not "--render-original84" in OS.get_cmdline_user_args()

func owns(game) -> bool:
	return enabled and game.started and not game.gallery and not game.paused and not (game.replay!=null and game.replay.active) and not (game.substitution_scene!=null and game.substitution_scene.active) and not (game.network_match() and not game.online_session.authority())

func reset(game,restore_ball: bool=false) -> void:
	if restore_ball and not current.is_empty():
		game.ball.position=game.ball_pos
		game.ball.quaternion=current.rotation
	for p in game.players:
		if p.visual_root:p.visual_root.transform=Transform3D.IDENTITY
		p.render_previous84={};p.render_current84={}
	previous={};current={}

func before_tick(game) -> void:
	# The displayed sphere has an interpolated rotation. Spin integration must
	# always resume from the authoritative last tick, never from that drawing.
	if not current.is_empty() and owns(game):
		game.ball.position=game.ball_pos;game.ball.quaternion=current.rotation
	# visual_root is deliberately presentation-only: physics reads the parent
	# actor and exact local contact pose. Do not dirty every mesh twice per tick.

func after_tick(game) -> void:
	if not owns(game):return
	var row: Dictionary={"time":game.clock_time,"rally":game.rally_serial,"ball":game.ball_pos,"rotation":game.ball.quaternion,"actors":[],"poses":[]}
	for p in game.players:
		row.actors.append(p.transform);row.poses.append(p.presentation_state84())
	previous=current;current=row
	if previous.is_empty() or previous.rally!=current.rally or current.time<previous.time or current.time-previous.time>.05:
		previous=current

func draw(game,fraction: float=-1.0) -> void:
	if not owns(game):
		if current.is_empty():return
		var other_owner: bool=(game.replay!=null and game.replay.active) or (game.substitution_scene!=null and game.substitution_scene.active) or (game.network_match() and not game.online_session.authority())
		reset(game,not other_owner);return
	if current.is_empty():return
	var alpha: float=clampf(Engine.get_physics_interpolation_fraction() if fraction<0 else fraction,0,1)
	displayed_time=lerpf(previous.time,current.time,alpha)
	game.ball.position=previous.ball.lerp(current.ball,alpha)
	game.ball.quaternion=previous.rotation.slerp(current.rotation,alpha)
	game.shadow.position=Vector3(game.ball.position.x,.034,game.ball.position.z)
	game.shadow.scale=Vector3.ONE*(1+maxf(0,game.ball.position.y)*.06)
	for i in game.players.size():
		var p=game.players[i]
		var first: Transform3D=previous.actors[i];var last: Transform3D=current.actors[i]
		var shown: Transform3D=last if first.origin.distance_squared_to(last.origin)>1 else first.interpolate_with(last,alpha)
		p.visual_root.transform=p.transform.affine_inverse()*shown
		p.visual_root.position/=p.height_scale90
		p.render_previous84=previous.poses[i];p.render_current84=current.poses[i];p.render_alpha84=alpha

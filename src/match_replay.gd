extends Node
## Presentation-only playback of rendered poses. No gameplay/RNG state is rewound.
const FPS:=30.0
const MAX_FRAMES:=540
const Brand=preload("res://src/league_branding.gd")
var game
var testing:=false
var enabled:=true
var set_started:=-1.0
var segment_start:=-1.0
var frames: Array=[]
var active:=false
var state:=""
var elapsed:=0.0
var pending: Dictionary={}
var candidate: Dictionary={}
var last_attack: Dictionary={}
var saved: Dictionary={}
var clip: Array=[]
var cursor:=0
var play_time:=0.0
var next_sample:=-1.0
var serial:=0
var last_token:=-1
var overlay: Control
var capture_usec:=0
var captures:=0

func _ready() -> void:
	var layer:=CanvasLayer.new(); layer.layer=40; add_child(layer)
	overlay=Control.new(); overlay.set_script(preload("res://src/replay_transition.gd")); overlay.replay=self
	layer.add_child(overlay); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.hide()

func allowed() -> bool:
	return enabled and game.started and (not game.self_test or testing) and not game.gallery and not (game.tutorial!=null and game.tutorial.active)

func reset() -> void:
	if active: finish()
	frames.clear(); clip.clear(); pending.clear(); candidate.clear(); last_attack.clear(); next_sample=-1; last_token=-1
	set_started=-1; segment_start=-1

func capture(force: bool=false) -> void:
	if not allowed() or active or game.paused: return
	if game.phase=="POINT" and game.phase_time>.16: return
	if not force and game.clock_time<next_sample: return
	var began:=Time.get_ticks_usec()
	next_sample=game.clock_time+1.0/FPS
	var row: Dictionary={"time":game.clock_time,"ball":game.ball_pos,"rotation":game.ball.quaternion,"players":[],"serving":game.phase=="SERVE" and game.toss_active}
	for p in game.players:
		# Array.duplicate is native; no extra AnimationTree/PSA/IK evaluations.
		row.players.append({"transform":p.transform,"pose":p.last_pose.duplicate()})
	if game.dynamic_net:
		row.net=[game.dynamic_net.elapsed,game.dynamic_net.amplitude,game.dynamic_net.material.get_shader_parameter("impact")]
	if not frames.is_empty() and is_equal_approx(float(frames[-1].time),game.clock_time): frames[-1]=row
	else: frames.append(row)
	if frames.size()>MAX_FRAMES: frames.pop_front()
	captures+=1; capture_usec+=Time.get_ticks_usec()-began

func mark_shot(kind: String,team: int,perfect: bool=false) -> void:
	if not allowed(): return
	var start: float=game.clock_time-.65
	if kind=="attack" and set_started>=0 and game.touches[team]>=3: start=set_started-.22
	elif kind=="monster" and not last_attack.is_empty(): start=last_attack.start
	elif kind=="serve":
		for row in frames:
			if row.get("serving",false) and float(row.time)>=game.clock_time-2.5:
				start=float(row.time)-.12; break
	candidate={"kind":kind,"team":team,"perfect":perfect,"start":start}; capture(true)
	if kind=="attack": last_attack=candidate.duplicate()
	elif kind not in ["monster"]: last_attack.clear()

func clear_shot() -> void: candidate.clear(); last_attack.clear()

func mark_set() -> void: set_started=game.clock_time

func on_point(team: int) -> void:
	if not allowed() or frames.size()<3 or candidate.is_empty(): return
	if candidate.team!=team:
		if candidate.kind=="monster" and not last_attack.is_empty() and last_attack.team==team and last_attack.perfect: candidate=last_attack
		else: return
	var kind: String=candidate.kind
	if kind=="attack" and not candidate.perfect: return
	if kind not in ["attack","serve","monster"]: return
	serial+=1; queue(kind,serial,float(candidate.get("start",game.clock_time-3.0)))
	if game.network_match() and game.online_session.authority(): game.online_session.replay_notice.rpc_id(game.online_session.guest,kind,serial,segment_start)

func queue(kind: String,token: int,start: float=-1.0) -> void:
	if token==last_token or active: return
	last_token=token; segment_start=start; pending={"kind":kind,"left":.65}

func _process(dt: float) -> void: advance(dt)

func advance(dt: float) -> void:
	if active:
		if not game.started: finish(); return
		if game.paused: return
		elapsed+=dt
		if state=="IN" and elapsed>=.9:
			state="PLAY"; elapsed=0; play_time=float(clip[0].time); show_frame(play_time); overlay.hide()
		elif state=="PLAY":
			play_time+=dt*.8
			show_frame(play_time)
			if play_time>=float(clip[-1].time): begin_exit()
		elif state=="OUT" and elapsed>=.9:
			if not game.network_match() or game.online_session.authority(): finish()
		if active and state in ["IN","OUT"]: overlay.queue_redraw()
		return
	capture()
	if pending.is_empty() or game.paused: return
	pending.left-=dt
	if pending.left<=0:
		pending.clear(); begin()

func begin() -> bool:
	if active or frames.size()<3: return false
	clip=frames.duplicate(); cursor=0
	# Replays show the decisive approach and finish; bounded memory also
	# handles a long rally without creating a second match simulation.
	var start_time: float=maxf(float(clip[0].time),maxf(segment_start,float(clip[-1].time)-5.5))
	while clip.size()>3 and float(clip[1].time)<start_time: clip.pop_front()
	saved={"players":[],"ball":game.ball.transform,"shadow":game.shadow.transform,"marker":game.marker.visible,"camera":game.camera.transform,"fov":game.camera.fov,"projection":game.camera.projection,"focus":game.camera_focus}
	for p in game.players:
		saved.players.append({"transform":p.transform,"pose":p.last_pose,"pending":p.pending_pose_dt,"render":p.render_at_draw,"indicator":p.indicator.visible if p.indicator else false})
		p.pending_pose_dt=0; p.render_at_draw=false
		if p.indicator: p.indicator.hide()
	if game.dynamic_net:
		saved.net=[game.dynamic_net.elapsed,game.dynamic_net.amplitude,game.dynamic_net.material.get_shader_parameter("impact"),game.dynamic_net.is_processing()]
		game.dynamic_net.set_process(false)
	active=true; state="IN"; elapsed=0; game.marker.hide(); overlay.show(); overlay.queue_redraw()
	return true

func show_frame(time: float) -> void:
	while cursor+1<clip.size() and float(clip[cursor+1].time)<time: cursor+=1
	var a: Dictionary=clip[cursor]; var b: Dictionary=clip[mini(cursor+1,clip.size()-1)]
	var blend:=clampf((time-float(a.time))/maxf(.00001,float(b.time)-float(a.time)),0,1)
	for i in game.players.size():
		var p=game.players[i]; var first: Dictionary=a.players[i]; var second: Dictionary=b.players[i]
		p.transform=first.transform.interpolate_with(second.transform,blend)
		apply_pose(p,first.pose,second.pose,blend)
	game.ball.position=a.ball.lerp(b.ball,blend); game.ball.quaternion=a.rotation.slerp(b.rotation,blend)
	game.shadow.position=Vector3(game.ball.position.x,.034,game.ball.position.z); game.shadow.scale=Vector3.ONE*(1+maxf(0,game.ball.position.y)*.06)
	if game.dynamic_net and a.has("net"):
		game.dynamic_net.material.set_shader_parameter("elapsed",lerpf(a.net[0],b.net[0],blend)); game.dynamic_net.material.set_shader_parameter("amplitude",a.net[1]); game.dynamic_net.material.set_shader_parameter("impact",a.net[2])
	game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE; game.camera.fov=40
	game.camera.position=preload("res://src/view_controls.gd").origin(2)
	game.camera.look_at(Vector3(0,.9+maxf(0,game.ball.position.y-3.2)*.04,clampf(game.ball.position.z*.06,-.45,.45)))

func apply_pose(player,a: Array,b: Array,weight: float) -> void:
	if not player.skeleton or a.is_empty() or b.size()!=a.size(): return
	var body=player.model_bank.body
	for i in body.names.size():
		var idx: int=player.animation_bones[i]
		if idx<0: continue
		var first: Transform3D=a[idx]; var second: Transform3D=b[idx]
		if i>0:
			var parent: int=player.animation_bones[body.parents[i]]
			if parent>=0: first=a[parent].affine_inverse()*first; second=b[parent].affine_inverse()*second
		var local:=first.interpolate_with(second,weight)
		player.skeleton.set_bone_pose_position(i,local.origin); player.skeleton.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion())

func begin_exit() -> void:
	if not active or state=="OUT": return
	state="OUT"; elapsed=0; overlay.show(); overlay.queue_redraw()

func request_skip() -> void:
	if game.network_match(): game.online_session.request_replay_skip()
	else: begin_exit()

func finish() -> void:
	if not active: return
	if game.network_match() and game.online_session.authority() and game.online_session.guest!=0: game.online_session.replay_finished.rpc_id(game.online_session.guest)
	for i in game.players.size():
		var p=game.players[i]; var previous: Dictionary=saved.players[i]
		p.transform=previous.transform; apply_pose(p,previous.pose,previous.pose,0)
		p.pending_pose_dt=previous.pending; p.render_at_draw=previous.render
		if p.indicator: p.indicator.visible=previous.indicator
	game.ball.transform=saved.ball; game.shadow.transform=saved.shadow; game.marker.visible=saved.marker
	game.camera.transform=saved.camera; game.camera.fov=saved.fov; game.camera.projection=saved.projection; game.camera_focus=saved.focus
	if game.dynamic_net and saved.has("net"):
		game.dynamic_net.elapsed=saved.net[0]; game.dynamic_net.amplitude=saved.net[1]; game.dynamic_net.material.set_shader_parameter("elapsed",saved.net[0]); game.dynamic_net.material.set_shader_parameter("amplitude",saved.net[1]); game.dynamic_net.material.set_shader_parameter("impact",saved.net[2]); game.dynamic_net.set_process(saved.net[3])
	active=false; state=""; overlay.hide(); saved.clear(); clip.clear(); frames.clear(); candidate.clear(); last_attack.clear(); pending.clear(); next_sample=-1
	if game.network_match() and not game.online_session.authority(): game.online_session.buffered.clear()

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event.is_action_pressed("start") or (event is InputEventKey and event.physical_keycode==KEY_ESCAPE): return false
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_SPACE): request_skip()
	# GlobalAudio owns L3/M, including preferences and press debouncing.
	return true

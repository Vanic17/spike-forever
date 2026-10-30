extends Node
## Dead-ball presentation. The manager commits the legal substitution once;
## this sequence never changes slots, contacts, scores or match RNG.
const Avatar=preload("res://src/avatar.gd")
const Sideline=preload("res://src/sideline_pose.gd")
const Motion=preload("res://src/sideline_animation.gd")
const Routes=preload("res://src/substitution_routes.gd")
const Brand=preload("res://src/league_branding.gd")
const TRANSITION_SECONDS:=1.08
var game
var active:=false
var testing:=false
var pending: Array=[]
var state:=""
var elapsed:=0.0
var overlay: Control
var actors: Array=[]
var saved: Dictionary={}
var current: Dictionary={}
var poses: Dictionary={}
var benches
var update_left:=0.0
var routing
var timeline: Dictionary={}
var last_planning_usec:=0

func _ready() -> void:
	var layer:=CanvasLayer.new(); layer.layer=41; add_child(layer)
	overlay=Control.new(); overlay.set_script(preload("res://src/replay_transition.gd")); overlay.replay=self
	layer.add_child(overlay); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.hide()

func enqueue(side: int,slot: int,outgoing: Dictionary,incoming: Dictionary,seat_slot: int=-1) -> void:
	if game.self_test and not testing: return
	var benches_now=game.arena_visuals.get_node("TeamBenches")
	var seat:=Vector3(-6.8,0,(1 if side==0 else -1)*10.8)
	for entry in benches_now.actors:
		if entry.team!=side or entry.coach: continue
		if (seat_slot>=0 and entry.slot==seat_slot) or (seat_slot<0 and str(entry.actor.roster_identity.get("id",""))==str(incoming.get("id",""))):
			seat=entry.actor.global_position; seat_slot=entry.slot; break
	pending.append({"side":side,"slot":slot,"out":outgoing.duplicate(true),"in":incoming.duplicate(true),"bench_slot":seat_slot,"seat":seat,"has_seat":seat_slot>=0})

func make_actor(identity: Dictionary,template):
	var actor=Avatar.new(); game.add_child(actor); actor.team=template.team; actor.number=template.number
	actor.clips=game.clips; actor.source_clips=game.clips; actor.model_bank=game.models
	actor.visual_root=Node3D.new(); actor.add_child(actor.visual_root); actor.setup_meshes()
	actor.set_roster_identity(identity,{},template.kit_identity,{})
	actor.set_process(false); actor.set_physics_process(false); actor.jersey_number.hide()
	return actor

func begin() -> bool:
	if active or pending.is_empty() or not game.started or not game.models.has("body"): return false
	if game.replay.active or not game.replay.pending.is_empty(): return false
	current=pending.pop_front(); var index: int=int(current.side)*6+int(current.slot); var player=game.players[index]
	benches=game.arena_visuals.get_node("TeamBenches")
	saved={"camera":game.camera.transform,"fov":game.camera.fov,"focus":game.camera_focus,"player":player,"visibility":player.visible,"marker":game.marker.visible,"bench":[]}
	var origin: Vector3=current.seat
	for entry in benches.actors:
		if entry.team==current.side and not entry.coach and entry.slot==current.bench_slot:
			saved.bench.append(entry.actor); entry.actor.hide(); break
	current["seat"]=origin; current["field"]=player.position
	current["gate_out"]=Vector3(-5.1,0,(1 if current.side==0 else -1)*2.2)
	current["gate_in"]=Vector3(-5.9,0,(1 if current.side==0 else -1)*2.2)
	var planned_at:=Time.get_ticks_usec()
	routing=Routes.new(); routing.configure(game,index,int(current.bench_slot),int(current.side))
	var paths: Dictionary={"out":routing.route(player.position,current.gate_out,current.gate_in),"in":routing.route(origin,current.gate_in,current.gate_out),"back":routing.route(current.gate_out,origin,current.gate_in),"field":routing.route(current.gate_in,player.position,current.gate_out)}
	if paths.values().any(func(path): return path.is_empty()):
		for actor in saved.bench: actor.show()
		game.log_rally_event("substitution_path_unavailable",{"side":current.side,"slot":current.slot})
		saved.clear(); current.clear(); return false
	for key in paths: current["path_"+key]=paths[key]
	timeline={}
	for key in paths: timeline[key]=maxf(1.15,Routes.length(paths[key])/1.75)
	timeline.in_delay=Routes.safe_delay(paths["out"],timeline["out"],paths["in"],timeline["in"])
	timeline.meet=.8+maxf(timeline["out"],timeline.in_delay+timeline["in"])
	timeline.leave=timeline.meet+1.2
	timeline.field_delay=Routes.safe_delay(paths.back,timeline.back,paths.field,timeline.field)
	timeline.end=timeline.leave+maxf(timeline.back+.65,timeline.field_delay+timeline.field)
	last_planning_usec=Time.get_ticks_usec()-planned_at
	current["field_yaw"]=player.rotation.y
	actors=[make_actor(current["out"],player),make_actor(current["in"],player)]
	actors[0].position=player.position; actors[1].position=origin
	poses={"seat":Motion.sample(game.models.body,"bench_stand_l",0),"stand":Motion.sample(game.models.body,"stand",0)}
	poses["five"]=Sideline.pose(game.models.body,false,"highfive",0,poses.stand)
	show_scene(0)
	player.hide(); game.marker.hide(); game.paused=true
	if game.match_management.menu.opened: game.match_management.menu.close()
	game.pause_menu.surface.hide()
	active=true; state="IN"; elapsed=0; overlay.show(); overlay.queue_redraw()
	if game.network_match() and game.online_session.authority() and game.online_session.guest!=0:
		game.online_session.substitution_presentation.rpc_id(game.online_session.guest,int(current.side),int(current.slot),str(current["out"].id),str(current["in"].id),int(current.bench_slot))
	return true

func _process(dt: float) -> void: advance(dt)

func advance(dt: float) -> void:
	if not game.started:
		cancel(); return
	if not active:
		if game.match_finished: pending.clear(); return
		if not pending.is_empty() and game.started and game.phase in ["SERVE","POINT"]: begin()
		return
	if not game.started: finish(); pending.clear(); return
	elapsed+=dt
	game.pause_menu.surface.hide()
	if state=="IN" and elapsed>=TRANSITION_SECONDS:
		state="PLAY"; elapsed=0; overlay.hide()
	elif state=="PLAY":
		update_left-=dt
		if update_left<=0: update_left=1.0/30; show_scene(elapsed)
		if elapsed>=float(timeline.end): state="OUT"; elapsed=0; overlay.show()
	elif state=="OUT" and elapsed>=TRANSITION_SECONDS:
		if not game.network_match() or game.online_session.authority(): finish()
		return
	if state in ["IN","OUT"]: overlay.queue_redraw()

func walk_pose(actor,time: float,action: String="walk") -> void:
	var source: Array=actor.psa_normalized_pose(action,time,true)
	var body=game.models.body
	for i in body.names.size():
		var bone: int=actor.animation_bones[i]; var local: Transform3D=source[bone]
		if i>0: local=source[actor.animation_bones[body.parents[i]]].affine_inverse()*local
		actor.skeleton.set_bone_pose(i,local)

func travel(actor,path: Array,time: float,duration: float,from_yaw: float,to_yaw: float) -> void:
	var total:=Routes.length(path); var distance:=total*smoothstep(0,1,clampf(time/duration,0,1))
	actor.position=Routes.at_distance(path,distance)
	var direction:=Routes.at_distance(path,minf(total,distance+.18))-Routes.at_distance(path,maxf(0,distance-.18))
	var yaw:=atan2(direction.x,direction.z) if direction.length()>.001 else to_yaw
	yaw=lerp_angle(from_yaw,yaw,smoothstep(0,.32,time))
	actor.rotation.y=lerp_angle(yaw,to_yaw,smoothstep(duration-.3,duration,time))
	var cycle:=Motion.bank().get_animation("walk").length
	var pose:=Motion.sample(game.models.body,"walk",distance/1.25*cycle)
	var weight:=smoothstep(0,.18,distance)*(1-smoothstep(total-.18,total,distance))
	Sideline.apply(actor,poses.stand,pose,weight)

func show_scene(time: float) -> void:
	var a=actors[0]; var b=actors[1]
	if time<.8:
		a.position=current.field; b.position=current.seat; b.rotation.y=PI/2
		a.rotation.y=current.field_yaw
		var standing: Array=Motion.sample(game.models.body,"bench_stand_l",time) if current.has_seat else poses.stand
		Sideline.apply(a,poses.stand,poses.stand,0); Sideline.apply(b,standing,standing,0)
	elif time<float(timeline.meet):
		travel(a,current.path_out,time-.8,timeline["out"],current.field_yaw,-PI/2)
		travel(b,current.path_in,time-.8-timeline.in_delay,timeline["in"],PI/2,PI/2)
	elif time<float(timeline.leave):
		a.position=current.gate_out; b.position=current.gate_in
		a.rotation.y=-PI/2; b.rotation.y=PI/2
		var relative: float=time-timeline.meet
		var five:=smoothstep(.2,.55,relative)*(1.0-smoothstep(.85,1.2,relative))
		Sideline.apply(a,poses.stand,poses.five,five); Sideline.apply(b,poses.stand,poses.five,five)
	else:
		travel(a,current.path_back,time-timeline.leave,timeline.back,-PI/2,PI/2)
		travel(b,current.path_field,time-timeline.leave-timeline.field_delay,timeline.field,PI/2,current.field_yaw)
		if current.has_seat and time>timeline.leave+timeline.back:
			var seating:=Motion.sample(game.models.body,"bench_stand_l",.8*(1-smoothstep(0,.65,time-timeline.leave-timeline.back)))
			Sideline.apply(a,seating,seating,0)
	var focus: Vector3=a.position.lerp(b.position,.5)+Vector3(0,1.05,0)
	var pullback:=1.0+maxf(0,a.position.distance_to(b.position)-2.0)*.045
	game.camera.position=focus+Vector3(5.2,3.1,5.8)*pullback; game.camera.fov=48
	game.camera.look_at(focus)

func finish() -> void:
	if not active: return
	if game.network_match() and game.online_session.authority() and game.online_session.guest!=0: game.online_session.substitution_finished.rpc_id(game.online_session.guest)
	for actor in actors: actor.queue_free()
	actors.clear(); saved.player.visible=saved.visibility
	for actor in saved.bench: if is_instance_valid(actor): actor.show()
	benches.identity_key=""; benches.sync_identity()
	game.camera.transform=saved.camera; game.camera.fov=saved.fov; game.camera_focus=saved.focus; game.marker.visible=saved.marker
	active=false; state=""; overlay.hide(); game.paused=false; current.clear(); saved.clear()

func cancel() -> void:
	pending.clear()
	if active: finish()

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		if not game.network_match(): state="OUT"; elapsed=0; overlay.show()
	return true

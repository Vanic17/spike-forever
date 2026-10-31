extends RefCounted
## A last reachable second touch uses one source clock, never an invisible hit.
const Access=preload("res://src/setter_access.gd")
const VARIANTS=["dive_short","dive_v26_01","dive_v26_02","dive_v26_04","dive_v26_06"]

static func proposal(game, index: int, maximum: float = .8) -> Dictionary:
	var adapter=game.get("legend_match")
	if is_instance_valid(adapter) and adapter.owns(index) and not adapter.allow_requested_recovery: return {}
	if game.dive_motions.has(index): return {}
	if game.player_recovery_seconds(index)>.10: return {}
	var player=game.players[index]
	var best: Dictionary={}
	var best_cost:=INF
	var samples: Array[Vector3]=[]
	for other in range(int(index/6)*6,int(index/6)*6+6):
		if other!=index: samples.append_array(game.compute_footprint_points(other))
	for variant in VARIANTS:
		if not player.source_clips.has(variant): continue
		var clip=player.source_clips[variant]
		var offset: Vector3=clip.contact_offset
		var hit: Dictionary=game.BallFlight.intercept(game.ball_pos,game.ball_vel,game.flight_spin,offset.y,game.flight_gravity)
		if hit.is_empty() or hit.seconds<.10 or hit.seconds>maximum: continue
		if hit.point.z*(1 if index<6 else -1)<.15: continue
		var toward: Vector3=hit.point-player.position
		var yaw: float=atan2(toward.x,toward.z)-atan2(offset.x,offset.z)
		var turn: float=absf(wrapf(yaw-player.rotation.y,-PI,PI))
		if turn>minf(deg_to_rad(110),hit.seconds*7.0): continue
		var stance: Vector3=hit.point-Basis(Vector3.UP,yaw)*offset; stance.y=0
		if stance.z*(1 if index<6 else -1)<.30 or absf(stance.x)>7 or absf(stance.z)>11.5: continue
		var gap: float=player.position.distance_to(stance)
		if gap>hit.seconds*4.8+.15: continue
		var begin: float=clip.contact_time-hit.seconds*1.15
		var path:=forecast(player,clip,stance,yaw,begin,hit.seconds,samples)
		if not path.free or path.peak>7.2: continue
		var peak: float=path.peak
		var cost: float=gap+turn*.25+maxf(0,peak-4.8)*.15
		if cost>=best_cost: continue
		best_cost=cost
		best={"index":index,"variant":variant,"point":hit.point,"seconds":hit.seconds,"stance":stance,"yaw":yaw,"begin":begin,"cost":cost}
	return best

static func forecast(player, clip, stance: Vector3, yaw: float, begin: float, seconds: float, obstacles: Array[Vector3]) -> Dictionary:
	# Match BOTH stages of advance_dive_body: a continuous run to the plant,
	# then rebase the source at commitment. A single smooth curve predicts the
	# wrong route/speed when the source clock still has a negative lead-in.
	var position: Vector3=player.position
	var velocity: Vector3=player.velocity
	var origin:=position
	var start:=begin
	var elapsed:=0.0
	var total:=0.0
	var duration:=seconds
	var committed:=begin>=0
	var basis:=Basis(Vector3.UP,yaw)
	var peak:=0.0
	while total<seconds-.000001:
		var dt:=minf(1.0/120.0,seconds-total)
		total+=dt; elapsed+=dt
		var source_time: float=minf(clip.duration,start+elapsed*1.15)
		var previous:=position
		if not committed and source_time<0:
			var plant: Vector3=stance-basis*(clip.root_motion(clip.contact_time)-clip.root_motion(0))
			var delta:=plant-position; delta.y=0
			velocity=velocity.move_toward(delta.normalized()*minf(4.8,delta.length()*5.0),22*dt)
			position+=velocity*dt
		else:
			if not committed:
				start=source_time-dt*1.15; origin=position; elapsed=dt
				duration=(clip.contact_time-start)/1.15; committed=true
			var root_start: Vector3=clip.root_motion(start)
			var correction: Vector3=stance-origin-basis*(clip.root_motion(clip.contact_time)-root_start)
			position=origin+basis*(clip.root_motion(source_time)-root_start)+correction*smoothstep(0,1,clampf(elapsed/maxf(.001,duration),0,1))
		peak=maxf(peak,position.distance_to(previous)/dt)
		for obstacle in obstacles:
			var near:=Geometry3D.get_closest_point_to_segment(obstacle,previous,position)
			var was:=previous.distance_to(obstacle)
			if near.distance_to(obstacle)<.985 and (was>=.985 or position.distance_to(obstacle)<was-.001): return {"free":false,"peak":peak}
	return {"free":true,"peak":peak}

static func commit(game, plan: Dictionary, second_touch: bool = false) -> void:
	var index: int=plan.index
	var player=game.players[index]
	player.select_variant("dive",plan.variant)
	player.dive_yaw=plan.yaw
	game.dive_motions[index]={"origin":player.position,"stance":plan.stance,"start_time":plan.begin,"source_time":plan.begin,"duration":plan.seconds,"elapsed":0.0,"yaw":plan.yaw,"initial_yaw":player.rotation.y,"action":"dive","committed":plan.begin>=0,"second_touch":second_touch}
	if plan.begin>=0: player.prepare_contact("dive",plan.seconds)
	game.flight_target=plan.point; game.flight_left=plan.seconds
	game.contact_navigation.reset()
	game.log_rally_event("second_touch_one_hand" if second_touch else "low_save_plan",{"actor":index,"variant":plan.variant,"seconds":plan.seconds})

static func try_second_touch(game) -> bool:
	if game.setter_dump or game.phase not in ["SET","CPU_SET"] or not game.airborne: return false
	if game.human_team(game.possession) and not game.armed: return false
	if game.dive_motions.has(game.setter): return false
	if game.flight_left>.55 or game.ball_vel.y>0: return false
	var action: String="receive" if game.out_of_system<0 else ("fast_set" if game.fast_set else "set")
	if Access.current_contact_reachable(game,action): return false
	# Prefer the assigned setter. The libero only takes over an unreachable
	# second touch; the original first toucher cannot touch consecutively.
	var candidates: Array[int]=[game.setter]
	for index in range(game.possession*6,game.possession*6+6):
		if index!=game.setter and index!=game.receiver and game.Tactics.role(index,game.rotations[game.possession],game.possession==game.server)=="L": candidates.append(index)
	for index in candidates:
		if index==game.receiver: continue
		var plan:=proposal(game,index)
		if plan.is_empty() or plan.seconds<=game.flight_left+.035: continue
		game.setter=index; game.setter_action="dive"; game.out_of_system=-1
		if game.possession==0: game.selected=index
		game.fast_set=false; game.planned_fast=false
		commit(game,plan,true)
		return true
	return false

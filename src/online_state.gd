extends RefCounted
## Snapshots contain clocks/poses, never Skeleton3D resources or per-bone RPCs.
const FIELDS=["destination","charge_attack108","charge_serve108","serve_aim106","serve_locked106","first_set_cooldown102","rally_serial","match_condition","timing_results","use_player_stats","stats_set_grade","stats_release_flight","stats_release_clock","phase","phase_time","clock_time","server","possession","scores","sets","rotations","team_names","touches","receiver","setter","hitter","selected","planned_hitter","planned_direction","middle_wide","destination","set_dir","setter_action","setter_second96","setter_dump","setter_spike","setter_disguise","fast_set","pass_quality","set_quality","input_quality","charge","charge_start","charging","charge_button","armed","serve_type","toss_active","serve_adjusting","airborne","ball_pos","ball_vel","flight_target","flight_left","flight_spin","receive_deadline","receive_feedback","receive_feedback_left","hitter_action","attack_tip","block_count","block_commanded","block_time","block_quality","block_hand","feedback","feedback_left","point_reason","paused","match_finished","match_best_of","match_points","test_contacts","attack_serial","shot_serial","test_rallies"]
const VISUAL=["clip_name","animation_time","animation_speed","looping","velocity","acceleration","ready_stance","relaxed_stance","block_ready_stance","middle_ready","middle_load","middle_load_age","pin_reference_load","travel_animation_name","travel_animation_time","travel_animation_speed","reach_action","reach_target","reach_weight","hand_adjust","look_target","visual_context","effort","setting_yaw","dive_yaw","wrist_tip_variant","post_point","power_transfer_from","power_transfer_start","body_lean","idle_time","second_contact97","pin_run104"]
const NAMED=["clip_name","travel_animation_name","reach_action","wrist_tip_variant"]
const VECTOR_FIELDS=["serve_aim106","ball_pos","ball_vel","flight_target","flight_spin","velocity","acceleration","reach_target","look_target","power_transfer_from","second_contact97"]
const FLOAT_FIELDS=["pin_reference_load","stats_release_flight","stats_release_clock","phase_time","clock_time","pass_quality","set_quality","input_quality","charge","charge_start","flight_left","receive_deadline","receive_feedback_left","block_time","block_quality","block_hand","feedback_left","animation_time","animation_speed","middle_load","middle_load_age","travel_animation_time","travel_animation_speed","reach_weight","hand_adjust","effort","setting_yaw","dive_yaw","power_transfer_start","idle_time"]
static var names: Array=[]
static var name_ids: Dictionary={}

static func vector_pack(value: Vector3) -> PackedInt32Array:
	return PackedInt32Array([roundi(value.x*1000),roundi(value.y*1000),roundi(value.z*1000)])

static func vector_unpack(value: PackedInt32Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])*.001

static func pack_field(key: String,value):
	if key in VECTOR_FIELDS: return vector_pack(value)
	if key=="body_lean": return PackedInt32Array([roundi(value.x*1000),roundi(value.y*1000)])
	if key in FLOAT_FIELDS: return roundi(value*1000)
	return value

static func unpack_field(key: String,value):
	if key in VECTOR_FIELDS: return vector_unpack(value)
	if key=="body_lean": return Vector2(value[0],value[1])*.001
	if key in FLOAT_FIELDS: return float(value)*.001
	return value

static func setup(game) -> void:
	if not names.is_empty(): return
	names=game.players[0].source_clips.keys()
	for key in game.players[0].clips.keys():
		if not key in names: names.append(key)
	names.append(""); names.sort()
	for i in names.size(): name_ids[names[i]]=i

static func name_at(index: int) -> String:
	return str(names[index]) if index>=0 and index<names.size() else ""

static func encode(value: Dictionary) -> PackedByteArray:
	var compact: Array=[value.seq,[],value.marker,value.marker_visible,value.rotation,[]]
	for key in FIELDS: compact[1].append(pack_field(key,value[key]))
	for p in value.players:
		var item: Array=[vector_pack(p.position),roundi(p.yaw*1000),p.libero,[],[]]
		for action in p.variants: item[3].append([name_ids.get(action,-1),name_ids.get(p.variants[action],-1)])
		for key in VISUAL: item[4].append(name_ids.get(p[key],-1) if key in NAMED else pack_field(key,p[key]))
		compact[5].append(item)
	var raw:=var_to_bytes(compact)
	var result:=PackedByteArray(); result.resize(4); result.encode_u32(0,raw.size())
	result.append_array(raw.compress(FileAccess.COMPRESSION_ZSTD)); return result

static func decode(value: PackedByteArray) -> Dictionary:
	if value.size()<5 or value.size()>32768: return {}
	var length:=value.decode_u32(0)
	if length<1 or length>65536: return {}
	var unpacked:=value.slice(4).decompress(length,FileAccess.COMPRESSION_ZSTD)
	if unpacked.is_empty(): return {}
	var compact=bytes_to_var(unpacked)
	if not compact is Array or compact.size()!=6 or compact[1].size()!=FIELDS.size() or compact[5].size()!=12: return {}
	var result: Dictionary={"seq":compact[0],"marker":compact[2],"marker_visible":compact[3],"rotation":compact[4],"players":[]}
	for i in FIELDS.size(): result[FIELDS[i]]=unpack_field(FIELDS[i],compact[1][i])
	for p in compact[5]:
		if not p is Array or p.size()!=5 or p[4].size()!=VISUAL.size(): return {}
		var item: Dictionary={"position":vector_unpack(p[0]),"yaw":float(p[1])*.001,"libero":p[2],"variants":{}}
		for pair in p[3]: item.variants[name_at(pair[0])]=name_at(pair[1])
		for i in VISUAL.size(): item[VISUAL[i]]=name_at(p[4][i]) if VISUAL[i] in NAMED else unpack_field(VISUAL[i],p[4][i])
		result.players.append(item)
	return result

static func capture(game) -> Dictionary:
	setup(game)
	var result: Dictionary={"seq":Engine.get_physics_frames(),"players":[],"marker":game.marker.position,"marker_visible":game.marker.visible,"rotation":game.ball.quaternion}
	for key in FIELDS: result[key]=game.get(key)
	result.charge_attack108=game.charge_seconds("attack")
	result.charge_serve108=game.charge_seconds("serve")
	for p in game.players:
		var item: Dictionary={"position":p.position,"yaw":p.rotation.y,"variants":p.variant_names.duplicate(),"libero":p.libero_active}
		for key in VISUAL: item[key]=p.get(key)
		result.players.append(item)
	return result

static func valid(value: Dictionary) -> bool:
	return value.has("clock_time") and value.get("players",[]) is Array and value.players.size()==12 and value.get("ball_pos") is Vector3 and value.ball_pos.is_finite() and value.has("seq")

static func presentation_time84(session,dt: float,now: float=-1.0) -> float:
	var latest: Dictionary=session.buffered[-1]
	var target: float=float(latest.clock_time)+maxf(0,(Time.get_ticks_msec()/1000.0 if now<0 else now)-float(latest.arrived))-.025
	if session.render_clock84<0 or absf(target-session.render_clock84)>2:
		session.render_clock84=target
	else:
		# Arrival jitter used to restart the visual clock on every packet,
		# occasionally drawing the ball backwards. Steer its rate gently instead.
		var advance: float=maxf(0,dt)
		session.render_clock84=minf(float(latest.clock_time),session.render_clock84+advance+clampf(target-session.render_clock84-advance,-advance*.12,advance*.12))
	return session.render_clock84

static func render(session,dt: float) -> void:
	if session.buffered.is_empty(): return
	var latest: Dictionary=session.buffered[-1]
	var time: float=presentation_time84(session,dt)
	var a: Dictionary=session.buffered[0]; var b: Dictionary=latest
	for item in session.buffered:
		if float(item.clock_time)<=time: a=item
		if float(item.clock_time)>=time: b=item; break
	var blend:=clampf((time-float(a.clock_time))/maxf(.001,float(b.clock_time)-float(a.clock_time)),0,1)
	if latest.paused: a=latest; b=latest; blend=1
	# Discrete events belong to the presentation time, never to a future
	# bracket. Previously a SET ball could be drawn with ATTACK controls/pose.
	var sample: Dictionary=b if blend>=.99999 else a
	if a.rally_serial!=b.rally_serial:
		if blend<.99999:b=a;blend=0
		else:a=b;blend=1
	var g=session.game
	for key in FIELDS: g.set(key,sample[key])
	g.clock_time=lerpf(float(a.clock_time),float(b.clock_time),blend)
	g.phase_time=float(sample.phase_time)+maxf(0,g.clock_time-float(sample.clock_time))
	g.ball_pos=a.ball_pos.lerp(b.ball_pos,blend); g.ball.position=g.ball_pos
	g.ball.quaternion=a.rotation.slerp(b.rotation,blend)
	g.shadow.position=Vector3(g.ball_pos.x,.034,g.ball_pos.z); g.shadow.scale=Vector3.ONE*(1+maxf(0,g.ball_pos.y)*.06)
	g.marker.visible=sample.marker_visible; g.marker.position=sample.marker
	for i in 12:
		var p=g.players[i]; var before: Dictionary=a.players[i]; var upcoming: Dictionary=b.players[i];var shown: Dictionary=sample.players[i]
		for action in shown.variants:
			if p.variant_names.get(action)!=shown.variants[action]: p.select_variant(action,shown.variants[action])
		if p.clip_name!=shown.clip_name: p.play(shown.clip_name,shown.animation_speed,shown.looping)
		for key in VISUAL: p.set(key,shown[key])
		if before.clip_name==upcoming.clip_name and before.variants.get(before.clip_name)==upcoming.variants.get(upcoming.clip_name) and absf(float(upcoming.animation_time)-float(before.animation_time))<.3:
			p.animation_time=lerpf(before.animation_time,upcoming.animation_time,blend)
		if before.travel_animation_name==upcoming.travel_animation_name:p.travel_animation_time=lerpf(before.travel_animation_time,upcoming.travel_animation_time,blend)
		for key in ["middle_load","middle_load_age","pin_reference_load","idle_time"]:p.set(key,lerpf(float(before[key]),float(upcoming[key]),blend))
		p.body_lean=before.body_lean.lerp(upcoming.body_lean,blend)
		p.position=before.position.lerp(upcoming.position,blend); p.rotation.y=lerp_angle(before.yaw,upcoming.yaw,blend)
		if p.libero_active!=shown.libero: p.set_libero(shown.libero)
		# Advance local transition blends, then draw the authoritative cursors.
		# A second local movement/load tick must not lead the network ball.
		var authored: Dictionary={}
		for key in VISUAL:authored[key]=p.get(key)
		p.contact_scheduled=true;p.render_at_draw=false;p.tick(dt,i==g.display_selected(),false)
		for key in VISUAL:p.set(key,authored[key])
		p.apply_pose(dt)
	if g.test_contacts>session.last_contact:
		if g.match_audio:g.match_audio.contact(("tip" if g.attack_tip else "attack") if g.phase in ["RECEIVE","CPU_RECEIVE"] else "receive",g.ball_pos,.7)
		session.last_contact=g.test_contacts
	if g.scores!=session.last_scores:
		if g.match_audio: g.match_audio.point_event(g.scores[g.home_team]>session.last_scores[g.home_team])
		session.last_scores=g.scores.duplicate()

extends RefCounted
## Manual-player input assistance only. Flights, contacts and native poses
## continue through main.gd; this helper never moves the ball or the athlete.
const LATE_WINDOW:=.20
var adapter
var gesture:="receive"
var overhead_index:=-1
var old_receive:=""
var feedback: Dictionary={}
var pending_dive_until:=-1.0
var pending_dive_key:=""

static func quality(remaining: float,difficulty: float=1.0) -> float:
	var scale:=clampf(difficulty,.85,1.25)
	if remaining<-.035: return clampf(1.0-(-remaining-.035)/(LATE_WINDOW-.035)*.78,.12,1)
	return clampf(1.0-maxf(0,remaining-.14*scale)/(.95*scale),0,1)

static func label(remaining: float,difficulty: float=1.0) -> String:
	var scale:=clampf(difficulty,.85,1.25)
	if remaining>.55*scale: return "MOLTO IN ANTICIPO"
	if remaining>.28*scale: return "IN ANTICIPO"
	if remaining>.14*scale: return "LEGGERMENTE IN ANTICIPO"
	if remaining>=-.035: return "PERFETTA"
	if remaining>=-.10: return "LEGGERMENTE IN RITARDO"
	return "IN RITARDO"

func reset() -> void:
	restore_gesture(true); gesture="receive"; feedback.clear(); pending_dive_until=-1; pending_dive_key=""

func restore_gesture(force: bool=false) -> void:
	if overhead_index>=0 and adapter!=null and adapter.game!=null:
		var p=adapter.game.players[overhead_index]
		if p.variant_names.get("receive","")=="set":
			if force and p.source_clips.has(old_receive):
				# At a mode/rally boundary the native recovery guard must not
				# leave a career-only alias in the next exhibition match.
				p.clips["receive"]=p.source_clips[old_receive]; p.variant_names["receive"]=old_receive
			else:
				p.select_variant("receive",old_receive)
				if p.variant_names.get("receive","")=="set": return
	overhead_index=-1; old_receive=""

func put(kind: String,action: String,status: String,message: String,value: float=0.0,seconds: float=1.65) -> void:
	var g=adapter.game
	feedback={"visible":true,"kind":kind,"action":action,"status":status,"feedback":message,"quality":value,"until":g.clock_time+seconds,"seconds":0.0,"armed":g.armed}

func unavailable(action: String,message: String) -> void:
	put("command",action,"unavailable",message)

func receive(overhead: bool=false) -> bool:
	var g=adapter.game; var index: int=adapter.controlled_index; var p=g.players[index]
	if g.armed: return false
	if not p.looping and p.clips.has(p.clip_name) and p.animation_time>=p.clips[p.clip_name].contact_time and p.contact_recovery_remaining()>.12:
		unavailable("receive","ATTENDI IL RECUPERO DEL GIOCATORE"); return false
	var fallback:=false
	gesture="receive"
	if overhead:
		var hit: Dictionary=g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,p.source_clips.set.contact_offset.y,g.flight_gravity)
		if not hit.is_empty() and hit.seconds>.001:
			restore_gesture(); overhead_index=index; old_receive=str(p.variant_names.get("receive","receive"))
			p.select_variant("receive","set"); gesture="set"
			# Only the intercept of the existing flight changes to the real
			# overhead palms. Position, velocity, spin and gravity are untouched.
			g.flight_target=hit.point; g.flight_left=hit.seconds; g.receive_deadline=g.clock_time+hit.seconds
			p.target=p.stance_for_contact("receive",hit.point)
		else: fallback=true
	else:
		restore_gesture(); g.select_receive_pose(index,g.flight_target)
		preload("res://src/receive_access.gd").sync_performance(g,true)
	var remaining: float=g.receive_deadline-g.clock_time
	if remaining< -LATE_WINDOW:
		unavailable("receive","TROPPO TARDI · PREPARA PRIMA IL TOCCO"); return false
	if remaining<0:
		var recovery: Dictionary=g.BallFlight.intercept(g.ball_pos,g.ball_vel,g.flight_spin,g.contact_height("recovery"),g.flight_gravity)
		if recovery.is_empty() or recovery.seconds>.22 or recovery.seconds<=.001:
			unavailable("receive","PALLA TROPPO BASSA · SERVE IL TUFFO"); return false
		g.late_receive=true; g.recovery_action="recovery"; gesture="receive"
		g.flight_target=recovery.point; g.flight_left=recovery.seconds
	g.receive_offset=remaining; g.input_quality=quality(remaining,g.difficulty_scale()); g.armed=true
	var detail:=label(remaining,g.difficulty_scale())
	g.receive_feedback=detail+" · %d%%"%roundi(g.input_quality*100); g.receive_feedback_left=2.4
	g.TimingResult.put(g,0,"PALLEGGIO" if gesture=="set" else ("RICEZIONE" if g.incoming_kind=="serve" else "DIFESA"),g.input_quality,detail)
	put("receive","overhead" if gesture=="set" else "receive","early" if remaining>.28 else ("late" if remaining<-.035 else "good"),"PALLA BASSA · BAGHER" if fallback else detail,g.input_quality)
	return true

func dive_attempt() -> bool:
	var g=adapter.game
	var old_receiver: int=g.receiver; var old_setter: int=g.setter; var old_deadline: float=g.receive_deadline
	adapter.claim_contact(true)
	if not adapter.owns(adapter.action_actor(0)): return false
	adapter.allow_requested_recovery=true
	var accepted:=false
	if g.phase=="RECEIVE": accepted=g.queue_recovery(true)
	if not accepted:
		var plan: Dictionary=preload("res://src/contact_rescue.gd").proposal(g,adapter.controlled_index,.8)
		if not plan.is_empty():
			var second: bool=g.phase=="SET"
			if second: g.setter_action="dive"; g.out_of_system=-1
			preload("res://src/contact_rescue.gd").commit(g,plan,second)
			if not second: g.late_receive=true; g.recovery_action="dive"
			accepted=true
	adapter.allow_requested_recovery=false
	if accepted:
		g.armed=true; g.input_quality=maxf(g.input_quality,.65); gesture="receive"; pending_dive_until=-1
		put("dive","dive","armed","TUFFO PREPARATO",g.input_quality)
	else:
		g.receiver=old_receiver; g.setter=old_setter; g.receive_deadline=old_deadline
	return accepted

func dive() -> bool:
	var g=adapter.game
	if g.paused or not adapter.manual_available or g.possession!=0 or g.phase not in ["RECEIVE","SET"] or adapter.last_contact_index==adapter.controlled_index:
		unavailable("dive","TUFFO NON DISPONIBILE SU QUESTA PALLA"); return false
	if g.dive_motions.has(adapter.controlled_index): return true
	if dive_attempt(): return true
	# An early explicit request is retained briefly, without moving the
	# player or claiming a teammate's contact until a real recovery exists.
	if g.flight_left>.45 and g.flight_left<1.0:
		pending_dive_until=g.clock_time+.65; pending_dive_key=str([g.rally_serial,g.shot_serial,g.phase])
		put("dive","dive","ready","TUFFO IN PREPARAZIONE",0,.65); return true
	unavailable("dive","TUFFO FUORI PORTATA · AVVICINATI ALLA PALLA"); return false

func tick() -> void:
	var g=adapter.game
	if pending_dive_until>=0:
		if pending_dive_key!=str([g.rally_serial,g.shot_serial,g.phase]) or g.possession!=0:
			pending_dive_until=-1; pending_dive_key=""
			if feedback.get("kind","")=="dive" and feedback.get("status","")=="ready": feedback.clear()
		elif g.clock_time>pending_dive_until:
			pending_dive_until=-1
			unavailable("dive","TUFFO FUORI PORTATA · AVVICINATI ALLA PALLA")
		elif g.flight_left<=.8: dive_attempt()

func cue() -> Dictionary:
	var g=adapter.game
	if not adapter.enabled(): return {"visible":false}
	if not feedback.is_empty() and g.clock_time<float(feedback.until):
		var result:=feedback.duplicate(); result.feedback_left=float(feedback.until)-g.clock_time
		return result
	if not adapter.manual_available or g.phase not in ["RECEIVE","SET"] or g.possession!=0 or adapter.last_contact_index==adapter.controlled_index: return {"visible":false}
	var mine: bool=adapter.owns(adapter.action_actor(0))
	if not mine: return {"visible":false}
	var action: String="overhead" if gesture=="set" else "receive"
	if g.phase=="SET":
		action={"set":"set","fast_set":"quick","dive":"dive","receive":"receive","dump":"dump"}.get(g.second_touch_contact_action(),"set")
	var seconds: float=maxf(0,g.flight_left)
	var p=g.players[adapter.controlled_index]
	var stance: Vector3=p.stance_for_contact("receive" if g.phase=="RECEIVE" else g.second_touch_contact_action(),g.flight_target)
	var distance: float=Vector2(stance.x-p.position.x,stance.z-p.position.z).length()
	var status: String="armed" if g.armed else ("move" if distance>.55 else ("good" if seconds<=.14*clampf(g.difficulty_scale(),.85,1.25) else "ready"))
	return {"visible":true,"kind":"receive" if g.phase=="RECEIVE" else "set","action":action,"seconds":seconds,"status":status,"quality":g.input_quality if g.armed else quality(seconds,g.difficulty_scale()),"armed":g.armed,"feedback":"","feedback_left":0.0}

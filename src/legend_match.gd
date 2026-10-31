extends Node
## Input/identity adapter only. main.gd owns exhibition physics, tactics,
## native animation scheduling, scoring, sound and replay in every mode.
signal match_finished(result: Dictionary)
const Kits=preload("res://src/club_kits.gd")
const Tactics=preload("res://src/tactics.gd")
const INPUT_DEADZONE:=.18
var game
var active:=false
var test_ai_driver:=false
var controlled_index:=0
var manual_available:=true
var role:="OH"
var config: Dictionary={}
var move_input:=Vector2.ZERO
var aim_input:=Vector2.ZERO
var sprint_input:=0.0
var keys: Dictionary={}
var buttons: Dictionary={}
var recommended_position:=Vector3.ZERO
var guide
var energy:=100.0
var performance: Dictionary={}
var saved_game: Dictionary={}
var source_motion: Dictionary={}
var allow_requested_recovery:=false
var last_contact_index:=-1
var last_own_set:=false
var assists:=0
var misses:=0
var attack_errors:=0
var active_minutes:=0.0
var requested_set:=false
var finished_sent:=false
var initial_placement:=false
var return_positions: Dictionary={}
var buffered_stroke:=""

func _input(event: InputEvent) -> void:
	# Replay/dialog input can consume releases before _unhandled_input. Keep
	# physical held-state current without issuing a stroke during those views.
	if not enabled(): return
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_X: move_input.x=event.axis_value
		elif event.axis==JOY_AXIS_LEFT_Y: move_input.y=event.axis_value
		elif event.axis==JOY_AXIS_RIGHT_X: aim_input.x=event.axis_value
		elif event.axis==JOY_AXIS_RIGHT_Y: aim_input.y=event.axis_value
		elif event.axis==JOY_AXIS_TRIGGER_LEFT: sprint_input=maxf(0,event.axis_value)
		elif event.axis==JOY_AXIS_TRIGGER_RIGHT and event.axis_value<=.55: buttons.dive_trigger=false
	if event is InputEventKey and not event.pressed:
		var code: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		keys[code]=false
		var kind: String={KEY_SPACE:"action",KEY_Q:"alternate",KEY_E:"dump"}.get(code,"")
		if not kind.is_empty(): buttons[kind]=false
		if game.paused: game.charging=false
	if event is InputEventJoypadButton and not event.pressed:
		var kind: String={JOY_BUTTON_A:"action",JOY_BUTTON_X:"alternate",JOY_BUTTON_B:"dump"}.get(event.button_index,"")
		if not kind.is_empty(): buttons[kind]=false
		if game.paused: game.charging=false

static func normalize_role(value: String) -> String:
	match value.to_upper():
		"S","SETTER","PALLEGGIATORE": return "S"
		"MB","MB1","MB2","MIDDLE_BLOCKER","CENTRALE": return "MB"
		"OPP","OPPOSITE","OPPOSTO": return "OPP"
		"L","LIBERO": return "L"
	return "OH"

func start(options: Dictionary) -> bool:
	if game==null or game.players.size()!=12: return false
	stop(); config=options.duplicate(true)
	for key in ["use_player_stats","match_best_of","match_points","difficulty","demo"]: saved_game[key]=game.get(key)
	role=normalize_role(str(config.get("role",config.get("player",{}).get("role","OH"))))
	controlled_index={"OH":0,"MB":1,"OPP":2,"S":5,"L":4}.get(role,0)
	var squads: Array=[config.get("club_lineup",[]),config.get("opponent_lineup",[])]
	if squads[0].size()!=7 or squads[1].size()!=7: return false
	var clubs: Array=[config.get("club",{}),config.get("opponent",{})]
	for team in 2:
		var variant: String="home" if str(clubs[team].id)==str(config.get("home_club_id","")) else "away"
		for slot in 6: game.players[team*6+slot].set_roster_identity(squads[team][slot],squads[team][6],Kits.selection(str(clubs[team].id),variant),Kits.selection(str(clubs[team].id),variant,true))
		game.team_names[team]=str(clubs[team].get("name",""))
	var settings: Dictionary=config.get("options",{}).duplicate(true)
	settings.injuries=false; settings.auto_subs=false; settings.seed=int(config.get("seed",settings.get("seed",194260)))
	settings.date=str(settings.get("date",config.get("fixture",{}).get("scheduled_date","2026-10-18")))
	if not game.match_management.configure_rosters(clubs,squads,{},settings): return false
	if not game.match_management.match_completed.is_connected(on_completed): game.match_management.match_completed.connect(on_completed)
	game.use_player_stats=true; game.match_best_of=int(config.get("best_of",5)); game.match_points=int(config.get("points",25)); game.difficulty=clampi(int(settings.get("difficulty",1)),0,2)
	game.started=true; game.paused=false; game.demo=false; game.gallery=false; game.match_finished=false
	game.scores=[0,0]; game.sets=[0,0]; game.rotations=[0,0]; game.server=int(config.get("first_server",0))
	game.clock_time=0; game.attack_serial=0; game.shot_serial=0; game.rally_serial=0
	game.test_points=0; game.test_contacts=0; game.test_rallies=0; game.contact_log.clear(); game.rally_events.clear(); game.play_log.clear()
	game.rng.seed=int(config.get("seed",settings.seed))
	game.set_home_club(str(config.get("home_club_id",clubs[0].id)),0); game.home_team=0 if str(clubs[0].id)==str(config.get("home_club_id",clubs[0].id)) else 1
	energy=100; active_minutes=0; assists=0; misses=0; attack_errors=0; last_own_set=false; finished_sent=false
	performance={}; source_motion.clear(); active=true; initial_placement=true
	game.reset_rally(); initial_placement=false; sync_identity()
	if guide==null: guide=preload("res://src/legend_position_guide.gd").new(); guide.game=game; game.add_child(guide)
	recommended_position=game.players[controlled_index].position
	return true

func stop() -> void:
	if game!=null and active:
		for key in saved_game: game.set(key,saved_game[key])
		game.match_management.suspend()
	saved_game.clear(); active=false; source_motion.clear(); move_input=Vector2.ZERO; aim_input=Vector2.ZERO; sprint_input=0
	keys.clear(); buttons.clear(); allow_requested_recovery=false
	return_positions.clear()
	buffered_stroke=""
	if is_instance_valid(guide): guide.hide()

func enabled() -> bool: return active and not test_ai_driver
func owns(index: int) -> bool: return enabled() and manual_available and index==controlled_index

func sync_identity() -> void:
	var id: String=str(config.get("player_id",config.get("player",{}).get("id","")))
	manual_available=false
	for index in 6:
		var p=game.players[index]
		var person: Dictionary=p.libero_identity if p.libero_active else p.roster_identity
		if str(person.get("id",""))==id:
			if controlled_index!=index: source_motion.clear()
			controlled_index=index; manual_available=true; break

func action_actor(team: int=0) -> int:
	match game.phase:
		"SERVE": return game.server_index(team)
		"RECEIVE","CPU_RECEIVE": return game.receiver if game.possession==team else -1
		"SET","CPU_SET": return game.setter if game.possession==team else -1
		"ATTACK","CPU_ATTACK": return game.hitter if game.possession==team else -1
	return -1
func cpu_team(team: int) -> bool: return team!=0 or not owns(action_actor(team))

func handle_input(event: InputEvent) -> bool:
	if not enabled(): return false
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X: move_input.x=event.axis_value
			JOY_AXIS_LEFT_Y: move_input.y=event.axis_value
			JOY_AXIS_RIGHT_X: aim_input.x=event.axis_value
			JOY_AXIS_RIGHT_Y: aim_input.y=event.axis_value
			JOY_AXIS_TRIGGER_LEFT: sprint_input=maxf(0,event.axis_value)
			JOY_AXIS_TRIGGER_RIGHT:
				if event.axis_value>.55 and not buttons.get("dive_trigger",false): dive()
				buttons.dive_trigger=event.axis_value>.55
		return true
	if event is InputEventJoypadButton:
		var command: String={JOY_BUTTON_A:"action",JOY_BUTTON_X:"alternate",JOY_BUTTON_B:"dump",JOY_BUTTON_RIGHT_SHOULDER:"jump",JOY_BUTTON_LEFT_SHOULDER:"request"}.get(event.button_index,"")
		if not command.is_empty():
			if event.pressed: press(command)
			else: release(command)
		return not command.is_empty()
	if event is InputEventKey:
		var code: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		if event.echo: return true
		keys[code]=event.pressed
		var command: String={KEY_SPACE:"action",KEY_Q:"alternate",KEY_E:"dump",KEY_R:"jump",KEY_C:"dive",KEY_F:"request"}.get(code,"")
		if not command.is_empty():
			if event.pressed: press(command)
			else: release(command)
		return true
	return false

func press(kind: String) -> void:
	if not enabled() or game.paused or game.match_finished or not manual_available: return
	if kind=="jump": jump(); return
	if kind=="dive": dive(); return
	if kind=="request": requested_set=true; call_for_set(); return
	if kind not in ["action","alternate","dump"] or buttons.get(kind,false): return
	buttons[kind]=true
	if game.phase=="SET" and game.setter!=controlled_index and game.planned_hitter==controlled_index and kind in ["action","alternate"]:
		buffered_stroke=kind; game.attack_buffer_start=game.clock_time; game.attack_buffer_power=-1.0
		return
	claim_contact()
	if action_actor(0)!=controlled_index or game.phase=="POINT": return
	apply_controls(0); game.input_team=0; game.press_action(kind)

func release(kind: String) -> void:
	buttons[kind]=false
	if not enabled() or game.paused:
		if game!=null and game.charging: game.charging=false
		return
	if game.phase=="SET" and buffered_stroke==kind:
		game.attack_buffer_power=maxf(0,(game.clock_time-game.attack_buffer_start)/game.Timing.ATTACK_CHARGE_SECONDS)
		return
	if owns(action_actor(0)) and kind==game.charge_button: game.input_team=0; game.release_action()

func current_aim() -> Vector2:
	var value:=aim_input
	var keyboard:=Vector2(float(keys.get(KEY_RIGHT,false))-float(keys.get(KEY_LEFT,false)),float(keys.get(KEY_DOWN,false))-float(keys.get(KEY_UP,false)))
	if keyboard.length_squared()>0: value=keyboard
	return value.limit_length() if value.length()>INPUT_DEADZONE else Vector2.ZERO

func movement_vector() -> Vector3:
	var value:=move_input
	var keyboard:=Vector2(float(keys.get(KEY_D,false))-float(keys.get(KEY_A,false)),float(keys.get(KEY_S,false))-float(keys.get(KEY_W,false)))
	if keyboard.length_squared()>0: value=keyboard
	if value.length()<=INPUT_DEADZONE: return Vector3.ZERO
	value=value.limit_length()
	var right: Vector3=game.camera.global_basis.x; right.y=0
	var back: Vector3=game.camera.global_basis.z; back.y=0
	return (right.normalized()*value.x+back.normalized()*value.y).limit_length()

func apply_controls(dt: float) -> void:
	if not enabled() or game.paused: return
	if owns(action_actor(0)):
		game.apply_direction(preload("res://src/view_controls.gd").court_direction(current_aim(),game.camera_mode),dt)
		game.serve_move=Vector2.ZERO

func before_step(dt: float) -> void:
	if not enabled(): return
	sync_identity()
	if manual_available and game.phase not in ["SERVE","POINT"]: active_minutes+=dt/60
	energy=100.0-game.match_management.fatigue_for(controlled_index) if manual_available else minf(100,energy+dt*2)
	if requested_set: call_for_set()
	if not buffered_stroke.is_empty() and game.phase=="ATTACK" and game.hitter==controlled_index:
		if buffered_stroke=="alternate":
			game.charging=false; game.armed=false; game.press_action("alternate")
			if not buttons.get("alternate",false): game.release_action()
		buffered_stroke=""
	if not source_motion.is_empty():
		var p=game.players[controlled_index]
		if p.clip_name!=source_motion.action or p.looping or not p.clips.has(p.clip_name) or p.animation_time>=p.clips[p.clip_name].recovery_end+.1: source_motion.clear()

func set_recommendation(point: Vector3) -> void:
	if point.is_finite(): recommended_position=Vector3(point.x,0,point.z)

func move_controlled(dt: float, target: Vector3, blockers: Array) -> void:
	var p=game.players[controlled_index]
	set_recommendation(target); p.target=target
	if game.serve_motion_active and game.serve_motion_player==controlled_index: game.advance_serve_body(dt); return
	if game.dive_motions.has(controlled_index): game.advance_dive_body(controlled_index,dt); return
	var direction:=movement_vector()
	var sprint: float=maxf(sprint_input,1.0 if keys.get(KEY_SHIFT,false) else 0.0)
	var desired: Vector3=direction*game.Reference.run_speed()*lerpf(1.0,1.10,clampf(sprint,0,1))
	if game.serve_adjusting and game.server_index(game.server)==controlled_index: desired=(game.serve_adjust_target-p.position).limit_length(.5)*5.0
	var acceleration: Vector3=((desired-p.velocity)/.12).limit_length(22.0)
	p.acceleration=p.acceleration.move_toward(acceleration,150*dt)
	p.velocity=(p.velocity+p.acceleration*dt).limit_length(game.Reference.run_speed()*1.10)
	if direction.length()<.01 and p.velocity.length()<.08: p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO
	var displacement: Vector3=p.velocity*dt
	if not source_motion.is_empty() and p.clips.has(source_motion.action):
		var root: Vector3=p.action_root_motion(source_motion.action,p.animation_time)
		var delta: Vector3=Basis(Vector3.UP,p.rotation.y)*(root-source_motion.last_root); delta.y=0; source_motion.last_root=root
		if p.animation_time>=p.clips[source_motion.action].takeoff_time: displacement+=delta.limit_length(game.Reference.run_speed()*1.3*dt)
	var endpoint: Vector3=p.position+displacement
	endpoint.x=clampf(endpoint.x,-7,7); endpoint.z=clampf(endpoint.z,.25,13.5); endpoint.y=0
	var safe: Vector3=game.collision_safe_step(controlled_index,endpoint-p.position)
	if safe.length()<displacement.length()*.2 and direction.length()>.1:
		for tangent in [Vector3(displacement.x,0,0),Vector3(0,0,displacement.z)]:
			var candidate: Vector3=game.collision_safe_step(controlled_index,tangent)
			if candidate.length()>safe.length(): safe=candidate
	p.position+=safe; p.position.y=0
	if safe.length()+.001<displacement.length(): p.velocity=safe/maxf(.001,dt)
	game.travel[controlled_index]+=safe.length()
	var facing:=PI
	if p.velocity.length()>2.0 and source_motion.is_empty(): facing=atan2(p.velocity.x,p.velocity.z)
	if game.phase in ["SET","CPU_SET"] and game.setter==controlled_index and game.armed: facing=p.setting_yaw
	if p.clip_name in ["dive","recovery"] and not p.looping: facing=p.dive_yaw
	p.rotation.y=rotate_toward(p.rotation.y,facing,7*dt); p.look_target=game.ball_pos
	p.ready_stance=game.phase in ["RECEIVE","CPU_RECEIVE"] or game.possession!=0
	p.block_ready_stance=controlled_index in blockers and absf(p.position.z)<1.5
	p.relaxed_stance=not p.ready_stance; p.post_point=game.phase=="POINT"
	p.intent.task="approach" if game.phase in ["SET","ATTACK"] and game.planned_hitter==controlled_index else "cover"
	p.locomotion(p.velocity.length(),dt)
	if owns(action_actor(0)) and game.armed and game.phase in ["RECEIVE","SET"]:
		var action: String=(game.recovery_action if game.late_receive else "receive") if game.phase=="RECEIVE" else game.second_touch_contact_action()
		if game.flight_left<p.preparation_lead(action,.38):
			p.prepare_contact(action,maxf(0,game.flight_left-dt)); p.reach_action=action; p.reach_target=game.flight_target; p.reach_weight=1.0-smoothstep(.04,.22,game.flight_left)

func jump() -> bool:
	if not enabled() or not manual_available or game.paused or game.match_finished or game.phase in ["POINT","SERVE"] or not source_motion.is_empty(): return false
	var p=game.players[controlled_index]
	if p.contact_recovery_remaining()>.12 and not p.looping: return false
	var blocking: bool=(game.possession!=0 or (game.incoming_kind in ["spike","soft","dump"] and game.last_touch==1)) and absf(p.position.z)<1.65
	var action: String="block" if blocking else "attack"
	if blocking:
		if not Tactics.front(controlled_index,game.rotations[0]) or role=="L": return false
		game.block_jumps.erase(controlled_index)
		if not game.request_block_jump(controlled_index,.22): return false
		game.block_time=game.clock_time; game.block_quality=1.0; game.block_commanded=true
	else:
		p.play(action,1.15,false)
		if p.clips.has(action): p.animation_time=maxf(0,p.clips[action].takeoff_time-.12)
	source_motion={"action":action,"last_root":p.action_root_motion(action,p.animation_time),"origin":p.position,"rally":game.rally_serial}
	return true

func claim_contact() -> void:
	if game.possession!=0 or game.phase not in ["RECEIVE","SET"] or last_contact_index==controlled_index or owns(action_actor(0)): return
	var p=game.players[controlled_index]
	var action: String="receive" if game.phase=="RECEIVE" else game.second_touch_contact_action()
	var stance: Vector3=p.stance_for_contact(action,game.flight_target)
	if Vector2(p.position.x-stance.x,p.position.z-stance.z).length()>maxf(.7,game.flight_left*game.Reference.run_speed()): return
	if game.phase=="RECEIVE": game.receiver=controlled_index; game.select_receive_pose(controlled_index,game.flight_target)
	else: game.setter=controlled_index
	game.receive_deadline=game.clock_time+game.flight_left

func dive() -> bool:
	if not enabled() or game.paused or not manual_available or game.possession!=0 or game.phase not in ["RECEIVE","SET"]: return false
	claim_contact()
	if not owns(action_actor(0)): return false
	allow_requested_recovery=true
	var accepted:=false
	if game.phase=="RECEIVE": accepted=game.queue_recovery(true)
	else:
		var plan: Dictionary=preload("res://src/contact_rescue.gd").proposal(game,controlled_index)
		if not plan.is_empty():
			game.setter_action="dive"; game.out_of_system=-1; preload("res://src/contact_rescue.gd").commit(game,plan,true); accepted=true
	allow_requested_recovery=false
	if accepted: game.armed=true; game.input_quality=maxf(game.input_quality,.6)
	return accepted

func call_for_set() -> void:
	if not requested_set or not manual_available or game.phase!="SET" or game.setter==controlled_index or role in ["S","L"]: return
	for direction in 4:
		if Tactics.attacker_for(game,0,direction,game.setter)==controlled_index:
			game.plan_attack(direction,game.fast_set); requested_set=false; return

func contact_allowed(index: int, action: String) -> bool:
	if not owns(index): return true
	if action not in ["float","power"] and not game.armed: return false
	if action=="attack":
		var p=game.players[index]
		if source_motion.is_empty() or source_motion.action!="attack" or p.clip_name!="attack": return false
		if absf(p.animation_time-p.clips.attack.contact_time)>.18: return false
		if not Tactics.front(index,game.rotations[0]) and absf(source_motion.origin.z)<3: return false
		if role=="L": return false
	return true

func on_reset() -> void:
	sync_identity(); source_motion.clear(); last_contact_index=-1; last_own_set=false; requested_set=false; buttons.clear(); buffered_stroke=""

func cpu_serve_ready() -> bool:
	if return_positions.is_empty(): return true
	for i in 12:
		if owns(i): continue
		if game.players[i].position.distance_to(return_positions.get(i,game.players[i].position))>.30 and game.phase_time<6.0: return false
	return not manual_available or game.players[controlled_index].position.distance_to(recommended_position)<1.8 or game.phase_time>8.0

func on_touch(index: int) -> void:
	last_contact_index=index
	if game.phase in ["SET","CPU_SET"]: last_own_set=owns(index)

func on_missed(index: int) -> void:
	if owns(index): misses+=1

func on_point(team: int, reason: String) -> void:
	var management=game.match_management
	if team==0 and last_own_set and not management.last_attack.is_empty() and int(management.last_attack.side)==0: assists+=1
	if team==1 and not management.last_attack.is_empty() and str(management.last_attack.id)==str(config.get("player_id",config.player.id)) and reason in ["FUORI","FUORI ANTENNA"]: attack_errors+=1
	last_own_set=false

func on_completed(raw: Dictionary) -> void:
	if not active or finished_sent: return
	finished_sent=true
	var id: String=str(config.get("player_id",config.player.id))
	performance=measured_performance(raw.get("players",{}).get(id,{}))
	var away: bool=str(config.club.id)!=str(config.home_club_id)
	var ordered: Array=[]
	for score in raw.get("set_scores",[]): ordered.append([score[1],score[0]] if away else score.duplicate())
	match_finished.emit({"fixture_id":config.get("fixture_id",""),"score_order":"home_away","sets":[game.sets[1],game.sets[0]] if away else game.sets.duplicate(),"set_scores":ordered,"won":game.sets[0]>game.sets[1],"performance":performance,"duration":game.clock_time,"mode":"legend_shared_exhibition"})

func measured_performance(row: Dictionary) -> Dictionary:
	return {"serves":int(row.get("serve_attempts",0)),"aces":int(row.get("aces",0)),"attacks":int(row.get("attack_attempts",0)),"kills":int(row.get("attack_kills",0)),"digs":int(row.get("digs",0)),"receptions":int(row.get("receptions",0)),"sets":int(row.get("sets",0)),"assists":mini(assists,int(row.get("sets",0))),"blocks":int(row.get("blocks",0)),"errors":int(row.get("serve_errors",0))+misses+attack_errors,"touches":int(row.get("serve_attempts",0))+int(row.get("attack_attempts",0))+int(row.get("receptions",0))+int(row.get("digs",0))+int(row.get("sets",0))+int(row.get("block_contacts",0)),"minutes":active_minutes,"points":int(row.get("points",0))}

func hud_state() -> Dictionary:
	var id: String=str(config.get("player_id",config.get("player",{}).get("id","")))
	var row: Dictionary=game.match_management.measured.get(id,{}) if game!=null else {}
	return {"active":active,"manual_available":manual_available,"player_name":str(config.get("player",{}).get("name","")),"name":str(config.get("player",{}).get("name","")),"role":role,"energy":energy,"performance":measured_performance(row),"power":game.current_charge() if game!=null else 0,"charging":game.charging if game!=null else false,"suggestion":"","context":game.phase if game!=null else "","feedback":"","feedback_left":0}

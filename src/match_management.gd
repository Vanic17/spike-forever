extends Node
## Indoor substitutions and measured match events. Tactical slots never move.
signal match_completed(result: Dictionary)
const RULE_SOURCE="https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-1.pdf"
static var translation_installed:=false
var game
var active:=false
var fatigue_enabled:=true
var injuries_enabled:=false
var injury_intensity:=1.0
var auto_subs:=false
var career_form:=false
var date:="2026-10-18"
var rosters: Array=[[],[]]
var identities: Dictionary={}
var current: Array=[[],[]]
var starters: Array=[[],[]]
var libero_ids: Array=["",""]
var counts: Array=[0,0]
var pairs: Array=[{},{}]
var left_once: Array=[[],[]]
var returned: Array=[[],[]]
var used_subs: Array=[[],[]]
var excluded: Array=[]
var conditions: Dictionary={}
var measured: Dictionary={}
var set_scores: Array=[]
var substitutions: Array=[]
var last_result: Dictionary={}
var last_point: Dictionary={}
var completed:=false
var between_sets:=true
var running_seconds:=0.0
var served_by:=-1
var last_attack: Dictionary={}
var last_block: Dictionary={}
var injury_count:=0
var injury_events: Array=[]
var random:=RandomNumberGenerator.new()
var jump_flags: Array=[false,false,false,false,false,false,false,false,false,false,false,false]
var menu
var tuning: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/match_management_v1.json"))

func _ready() -> void:
	if not translation_installed:
		var english=Translation.new(); english.locale="en"
		for line in FileAccess.get_file_as_string("res://assets/ui/en66_match.tsv").split("\n",false):
			var entry: PackedStringArray=line.strip_edges(false,true).split("\t",true,1)
			if entry.size()==2: english.add_message(entry[0].replace("\\n","\n"),entry[1].replace("\\n","\n"))
		TranslationServer.add_translation(english); translation_installed=true
	for binding in [["ui_up",JOY_BUTTON_DPAD_UP],["ui_down",JOY_BUTTON_DPAD_DOWN],["ui_left",JOY_BUTTON_DPAD_LEFT],["ui_right",JOY_BUTTON_DPAD_RIGHT]]:
		if not InputMap.has_action(binding[0]): InputMap.add_action(binding[0])
		var event=InputEventJoypadButton.new(); event.device=-1; event.button_index=binding[1]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)
	menu=preload("res://src/substitution_menu.gd").new(); menu.manager=self; menu.game=game; add_child(menu)

func configure_rosters(teams: Array,lineups: Array,initial_conditions: Dictionary={},options: Dictionary={}) -> bool:
	if teams.size()!=2 or lineups.size()!=2: return false
	rosters=[[],[]]; identities.clear(); current=[[],[]]; libero_ids=["",""]; conditions=initial_conditions.duplicate(true)
	fatigue_enabled=bool(options.get("fatigue",true)); injuries_enabled=bool(options.get("injuries",false)); auto_subs=bool(options.get("auto_subs",false)); date=str(options.get("date","2026-10-18"))
	career_form=bool(options.get("career_form",false))
	injury_intensity=clampf(float(options.get("injury_intensity",1.0)),0,2)
	for side in 2:
		if lineups[side].size()!=7: return false
		rosters[side]=teams[side].get("roster",lineups[side]).duplicate(true)
		for p in lineups[side]:
			if not rosters[side].any(func(item): return item.id==p.id): rosters[side].append(p.duplicate(true))
		for slot in 6: current[side].append(str(lineups[side][slot].id))
		libero_ids[side]=str(lineups[side][6].id)
		for p in rosters[side]:
			identities[str(p.id)]=p
			if not conditions.has(p.id): conditions[p.id]={"fatigue":0.0,"form":0.0,"injury_until":""}
			conditions[p.id]["fatigue"]=clampf(float(conditions[p.id].get("fatigue",0)),0,100)
			conditions[p.id]["form"]=clampf(float(conditions[p.id].get("form",0)),-5,5)
			conditions[p.id]["injury_until"]=str(conditions[p.id].get("injury_until",""))
	active=true; completed=false; running_seconds=0; served_by=-1; injury_count=0; excluded.clear(); measured.clear(); set_scores.clear(); substitutions.clear(); last_result.clear(); last_attack.clear(); last_block.clear(); last_point.clear()
	between_sets=true
	injury_events.clear()
	jump_flags=[false,false,false,false,false,false,false,false,false,false,false,false]
	random.seed=int(options.get("seed",194260))+int(hash(str(current)+date))
	if not repair_starting_squad(): active=false; return false
	start_set(); update_condition_vector(); return true

func repair_starting_squad() -> bool:
	for side in 2:
		for slot in 6:
			var id: String=current[side][slot]
			if not unavailable(id): continue
			var choices: Array=bench(side).filter(func(p): return str(p.role)!="libero" and not unavailable(str(p.id)))
			choices.sort_custom(func(a,b): return (100 if str(a.role)==str(identity(id).role) else 0)-fatigue(str(a.id))>(100 if str(b.role)==str(identity(id).role) else 0)-fatigue(str(b.id)))
			if choices.is_empty(): return false
			current[side][slot]=str(choices[0].id)
		if unavailable(str(libero_ids[side])) and not replace_libero(side): return false
		for slot in 6:
			var player=game.players[side*6+slot]
			if str(player.roster_identity.get("id",""))!=str(current[side][slot]) or str(player.libero_identity.get("id",""))!=str(libero_ids[side]): player.set_roster_identity(identity(str(current[side][slot])),identity(str(libero_ids[side])),player.kit_identity,player.libero_kit)
	return true

func replace_libero(side: int) -> bool:
	var old: String=libero_ids[side]
	var choices: Array=rosters[side].filter(func(p): return str(p.id)!=old and not str(p.id) in current[side] and not unavailable(str(p.id)))
	choices.sort_custom(func(a,b): return (100 if a.role=="libero" else 0)+float(a.ratings.get("difesa",0))>(100 if b.role=="libero" else 0)+float(b.ratings.get("difesa",0)))
	if choices.is_empty(): return false
	excluded.append(old); libero_ids[side]=str(choices[0].id)
	for slot in 6:
		var player=game.players[side*6+slot]
		player.set_roster_identity(identity(str(current[side][slot])),identity(str(libero_ids[side])),player.kit_identity,player.libero_kit)
	substitutions.append({"set":game.sets[0]+game.sets[1]+1,"side":side,"out":old,"in":libero_ids[side],"libero_redesignation":true,"ordinary":false})
	return true

func identity(id: String) -> Dictionary:
	return identities.get(id,{})

func actor_id(index: int) -> String:
	if index<0 or index>=game.players.size(): return ""
	var player=game.players[index]
	return str((player.libero_identity if player.libero_active else player.roster_identity).get("id",""))

func fatigue(id: String) -> float:
	if active and game.network_match() and not game.online_session.authority():
		for i in 12:
			if actor_id(i)==id: return float(game.match_condition[i])
	return float(conditions.get(id,{}).get("fatigue",0))
func unavailable(id: String) -> bool:
	return id in excluded or (injuries_enabled and str(conditions.get(id,{}).get("injury_until",""))>date)

func fatigue_for(index: int) -> float:
	if not active or not fatigue_enabled: return 0
	if game.network_match() and not game.online_session.authority(): return float(game.match_condition[index])
	return fatigue(actor_id(index))

func quality(index: int,value: float) -> float:
	if not active: return value
	if career_form: value=clampf(value+clampf(float(conditions.get(actor_id(index),{}).get("form",0)),-5,5)*.002,0,1)
	if not fatigue_enabled: return value
	return clampf(value-smoothstep(float(tuning.quality_fatigue_start),100,fatigue_for(index))*float(tuning.quality_penalty_cap)*(1.0-value*.65),0,1)

func precision(index: int,value: float) -> float:
	if not active or not fatigue_enabled: return value
	return clampf(value-smoothstep(float(tuning.precision_fatigue_start),100,fatigue_for(index))*float(tuning.precision_penalty_cap),0,1)

func risk(index: int) -> float:
	if not active or not fatigue_enabled: return 0
	return smoothstep(float(tuning.risk_fatigue_start),100,fatigue_for(index))*float(tuning.extra_error_cap)

func update_condition_vector() -> void:
	for i in 12: game.match_condition[i]=fatigue(actor_id(i)) if active and fatigue_enabled else 0.0

func tick(dt: float) -> void:
	if not active or completed or game.paused or not game.started: return
	if game.network_match() and not game.online_session.authority(): return
	if game.phase in ["POINT","SERVE"]: return
	running_seconds+=dt
	for i in 12:
		var id:=actor_id(i)
		if id.is_empty(): continue
		var row:=stat(id); var set_number: int=game.sets[0]+game.sets[1]
		if not set_number in row.set_numbers: row.set_numbers.append(set_number); row.sets_played=row.set_numbers.size()
		var speed: float=game.players[i].velocity.length()
		var role: String=str(identity(id).get("role","outside_hitter"))
		var workload: float=float(tuning.role_workload.get(role,1.0))
		if fatigue_enabled: conditions[id].fatigue=minf(100,fatigue(id)+dt*(float(tuning.active_second)+minf(7,speed)*float(tuning.movement_second_per_ms))*workload)
		var player=game.players[i]; var jumping:=false
		if player.clip_name in ["attack","block"] and not player.looping and player.clips.has(player.clip_name):
			var performance=player.clips[player.clip_name]
			jumping=player.animation_time>=performance.takeoff_time and player.animation_time<performance.contact_time+.32
		if fatigue_enabled and jumping and not jump_flags[i]: conditions[id].fatigue=minf(100,fatigue(id)+float(tuning.jump_cost))
		jump_flags[i]=jumping
	update_condition_vector()

func stat(id: String) -> Dictionary:
	if not measured.has(id): measured[id]={"appearances":1,"sets_played":0,"attack_attempts":0,"attack_kills":0,"aces":0,"serve_attempts":0,"serve_errors":0,"blocks":0,"block_contacts":0,"receptions":0,"reception_positive":0,"reception_perfect":0,"digs":0,"sets":0,"points":0,"set_numbers":[]}
	return measured[id]

func touch(index: int,kind: String,value: float=1.0) -> void:
	if not active or completed: return
	var id:=actor_id(index)
	if id.is_empty(): return
	var row:=stat(id); var set_index: int=game.sets[0]+game.sets[1]
	if not set_index in row.set_numbers: row.set_numbers.append(set_index); row.sets_played=row.set_numbers.size()
	match kind:
		"serve": row.serve_attempts+=1; served_by=index; last_attack.clear(); last_block.clear()
		"attack": row.attack_attempts+=1; last_attack={"id":id,"side":int(index/6)}; last_block.clear()
		"reception":
			row.receptions+=1
			if value>=.60: row.reception_positive+=1
			if value>=.90: row.reception_perfect+=1
			last_attack.clear(); last_block.clear()
		"dig": row.digs+=1
		"set": row.sets+=1; last_attack.clear(); last_block.clear(); served_by=-1
		"block": row.block_contacts+=1; last_block={"id":id,"side":int(index/6)}
	if fatigue_enabled: conditions[id].fatigue=minf(100,fatigue(id)+float(tuning.attack_contact if kind in ["attack","block"] else tuning.other_contact))

func point(side: int,reason: String) -> void:
	if not active or completed: return
	if not last_block.is_empty() and int(last_block.side)==side:
		var row:=stat(last_block.id); row.blocks+=1; row.points+=1
	elif not last_attack.is_empty() and int(last_attack.side)==side:
		var row:=stat(last_attack.id); row.attack_kills+=1; row.points+=1
	elif served_by>=0 and int(served_by/6)==side:
		var row:=stat(actor_id(served_by)); row.aces+=1; row.points+=1
	if served_by>=0 and int(served_by/6)!=side and last_attack.is_empty() and last_block.is_empty(): stat(actor_id(served_by)).serve_errors+=1
	last_point={"side":side,"reason":reason}; last_attack.clear(); last_block.clear(); served_by=-1
	if injuries_enabled and injury_count<int(tuning.injuries_per_match_cap):
		for index in 12:
			var id:=actor_id(index)
			if id.is_empty() or unavailable(id): continue
			if random.randf()<float(tuning.injury_per_player_point)*injury_intensity*(1+(fatigue(id) if fatigue_enabled else 0)*float(tuning.injury_fatigue_multiplier)):
				var severity:=random.randf(); var limits: Array=tuning.minor_days if severity<float(tuning.minor_share) else (tuning.moderate_days if severity<float(tuning.moderate_cumulative_share) else tuning.severe_days)
				var days:=random.randi_range(int(limits[0]),int(limits[1]))
				var stamp: int=int(Time.get_unix_time_from_datetime_string(date+"T12:00:00"))+days*86400
				conditions[id].injury_until=Time.get_date_string_from_unix_time(stamp); conditions[id].injury_simulated=true; injury_count+=1
				injury_events.append({"player":id,"date":date,"days":days,"until":conditions[id].injury_until,"simulated":true})
				break
	auto_changes()

func start_set() -> void:
	if not active: return
	starters=current.duplicate(true); counts=[0,0]; pairs=[{},{}]; left_once=[[],[]]; returned=[[],[]]; used_subs=[[],[]]
	between_sets=true

func lock_lineup() -> void:
	if not active or not between_sets: return
	starters=current.duplicate(true); between_sets=false
	if game.network_match() and game.online_session.authority(): game.online_session.broadcast_management()

func finish_set(score: Array) -> void:
	if not active or completed: return
	set_scores.append(score.duplicate())
	if fatigue_enabled:
		var set_number: int=game.sets[0]+game.sets[1]
		for id in measured:
			if set_number in measured[id].set_numbers: conditions[id].fatigue=minf(100,fatigue(id)+float(tuning.set_participation))
	start_set()
	if game.network_match() and game.online_session.authority(): game.online_session.broadcast_management()

func dead_ball() -> bool:
	return active and game.started and not game.match_finished and game.phase in ["SERVE","POINT"] and not game.toss_active and not game.charging and not (game.replay!=null and game.replay.active)

func bench(side: int) -> Array:
	return rosters[side].filter(func(p): return not str(p.id) in current[side] and str(p.id)!=str(libero_ids[side]))

func eligibility(side: int,slot: int,incoming: String,exceptional: bool=false) -> String:
	if not active or side<0 or side>1 or slot<0 or slot>5: return "Formazione non disponibile."
	if not dead_ball(): return "Le sostituzioni si effettuano a palla ferma, prima della battuta."
	if game.players[side*6+slot].libero_active and not between_sets: return "Attendi il rientro del centrale al posto del libero."
	var person:=identity(incoming)
	if person.is_empty() or not rosters[side].any(func(p): return str(p.id)==incoming): return "Giocatore non iscritto alla partita."
	if str(person.role)=="libero": return "Il libero utilizza gli ingressi dedicati, non le sostituzioni ordinarie."
	if incoming in current[side] or incoming==str(libero_ids[side]): return "Giocatore già in campo."
	if unavailable(incoming): return "Giocatore indisponibile."
	var outgoing: String=current[side][slot]
	if exceptional:
		if not unavailable(outgoing): return "La sostituzione eccezionale richiede un giocatore impossibilitato a continuare."
		for possible in bench(side):
			if eligibility(side,slot,str(possible.id),false).is_empty(): return "È disponibile una sostituzione ordinaria."
		for index in 6:
			if game.players[side*6+index].libero_active and incoming==str(current[side][index]): return "Il sostituito regolare del libero non può entrare eccezionalmente."
		return ""
	if between_sets: return ""
	if counts[side]>=6: return "Raggiunto il limite di sei sostituzioni ordinarie in questo set."
	var starter: String=starters[side][slot]
	if outgoing!=starter:
		if incoming!=starter or incoming in returned[side]: return "Può rientrare solo il titolare abbinato a questa riserva."
		return ""
	if starter in left_once[side]: return "Il titolare ha già lasciato e ripreso il campo in questo set."
	if incoming in starters[side] or incoming in used_subs[side]: return "La riserva è già stata utilizzata in questo set."
	return ""

func substitute(side: int,slot: int,incoming: String,exceptional: bool=false) -> String:
	var error:=eligibility(side,slot,incoming,exceptional)
	if not error.is_empty(): return error
	var outgoing: String=current[side][slot]
	if exceptional: excluded.append(outgoing)
	elif between_sets: pass
	else:
		counts[side]+=1
		if outgoing==str(starters[side][slot]): left_once[side].append(outgoing); used_subs[side].append(incoming); pairs[side][outgoing]=incoming
		else: returned[side].append(incoming)
	current[side][slot]=incoming
	if between_sets: starters[side]=current[side].duplicate()
	var player=game.players[side*6+slot]
	player.set_roster_identity(identity(incoming),identity(libero_ids[side]),player.kit_identity,player.libero_kit)
	player.motion_lock=0; player.reach_weight=0; player.contact_scheduled=false
	substitutions.append({"set":game.sets[0]+game.sets[1]+1,"side":side,"slot":slot,"out":outgoing,"in":incoming,"exceptional":exceptional,"pre_set":between_sets})
	update_condition_vector()
	if game.network_match() and game.online_session.authority(): game.online_session.broadcast_management()
	return ""

func auto_changes() -> void:
	if not active or not game.started: return
	# Called on a dead rally; award() has not changed phase yet.
	var phase_before: String=game.phase; game.phase="POINT"
	for side in 2:
		if game.network_match() and game.human_team(side): continue
		if unavailable(str(libero_ids[side])): replace_libero(side)
		for slot in 6:
			var id: String=current[side][slot]
			var forced:=unavailable(id)
			if not forced and (not game.cpu_team(side) and not auto_subs): continue
			if not forced and (not fatigue_enabled or fatigue(id)<float(tuning.auto_substitution_fatigue)): continue
			var choices:=bench(side)
			choices.sort_custom(func(a,b): return fatigue(str(a.id))<fatigue(str(b.id)))
			for person in choices:
				if not forced and (str(person.role)!=str(identity(id).role) or fatigue(str(person.id))+float(tuning.auto_substitution_advantage)>fatigue(id)): continue
				if substitute(side,slot,str(person.id)).is_empty(): break
				if forced and substitute(side,slot,str(person.id),true).is_empty(): break
	game.phase=phase_before

func export_state() -> Dictionary:
	return {"active":active,"current":current.duplicate(true),"starters":starters.duplicate(true),"counts":counts.duplicate(),"pairs":pairs.duplicate(true),"left_once":left_once.duplicate(true),"returned":returned.duplicate(true),"used_subs":used_subs.duplicate(true),"excluded":excluded.duplicate(),"conditions":conditions.duplicate(true),"libero":libero_ids.duplicate(),"fatigue":fatigue_enabled,"injuries":injuries_enabled,"between_sets":between_sets}

func import_state(value: Dictionary) -> void:
	if value.is_empty() or value.get("current",[]).size()!=2: return
	active=bool(value.active); current=value.current.duplicate(true); starters=value.starters.duplicate(true); counts=value.counts.duplicate(); pairs=value.pairs.duplicate(true); left_once=value.left_once.duplicate(true); returned=value.returned.duplicate(true); used_subs=value.used_subs.duplicate(true); excluded=value.excluded.duplicate(); conditions=value.conditions.duplicate(true); libero_ids=value.libero.duplicate(); fatigue_enabled=bool(value.fatigue); injuries_enabled=bool(value.injuries)
	between_sets=bool(value.get("between_sets",false))
	for side in 2:
		for slot in 6:
			var player=game.players[side*6+slot]
			if str(player.roster_identity.get("id",""))!=str(current[side][slot]): player.set_roster_identity(identity(str(current[side][slot])),identity(str(libero_ids[side])),player.kit_identity,player.libero_kit)

func finish_match() -> void:
	if not active or completed: return
	completed=true
	var players: Dictionary={}; var team_stats: Array=[{},{}]
	for id in measured:
		players[id]=measured[id].duplicate(true); players[id].erase("set_numbers"); players[id].fatigue_end=fatigue(id); players[id].form=float(conditions.get(id,{}).get("form",0)); players[id].injury_until=str(conditions.get(id,{}).get("injury_until",""))
	for side in 2:
		team_stats[side]={"aces":0,"blocks":0,"serve_errors":0,"attack_kills":0}
		for p in rosters[side]:
			if not players.has(p.id): continue
			for key in team_stats[side]: team_stats[side][key]+=int(players[p.id].get(key,0))
	var best_id:=""; var best_score:=-INF
	for id in players:
		var row: Dictionary=players[id]
		var value: float=float(row.points)+float(row.digs)*.1+float(row.sets)*.04
		if value>best_score: best_score=value; best_id=str(id)
	last_result={"source":"played","statistics_source":"measured","sets":game.sets.duplicate(),"set_scores":set_scores.duplicate(true),"players":players,"team_stats":team_stats,"duration_minutes":maxf(1,running_seconds/60.0),"mvp":best_id,"substitutions":substitutions.duplicate(true),"conditions":conditions.duplicate(true),"injuries":injury_events.duplicate(true),"complete":true}
	match_completed.emit(last_result)

func open() -> void:
	if not active: return
	menu.open()

func suspend() -> void:
	active=false
	if menu.opened: menu.close()

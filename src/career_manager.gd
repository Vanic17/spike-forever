extends RefCounted
## Persistent championship orchestration, independent of the live 6v6 simulation.
signal changed
signal match_finished(result: Dictionary)
signal day_advanced(date: String)
signal player_injured(player_id: String)
signal competition_completed(competition: String,winner: String)
const Saves=preload("res://src/career_save.gd")
const Simulation=preload("res://src/career_simulation.gd")
const League=preload("res://src/league.gd")
const ROLES=["outside_hitter","middle_blocker","opposite","outside_hitter","middle_blocker","setter","libero"]
const STAT_KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
const LABELS={"regular":"SuperLega","cup":"Coppa Italia","supercup":"Supercoppa","playoff":"Playoff Scudetto","fifth":"Playoff 5° posto","playout":"Play Out"}
var state: Dictionary={}
var error:=""
var rng:=RandomNumberGenerator.new()
var repository=Saves.new()
var rules
var last_result: Dictionary={}
func _init():
	if ResourceLoader.exists("res://src/career_rules.gd"): rules=load("res://src/career_rules.gd").new()
func active() -> bool: return not state.is_empty()
func team(id: String) -> Dictionary:
	for t in state.get("teams",[]):
		if t.id==id: return t
	return {}
func player(id: String) -> Dictionary:
	for t in state.get("teams",[]):
		for p in t.roster:
			if p.id==id: return p
	return {}
func player_condition(id: String) -> Dictionary:
	return state.get("conditions",{}).get(id,{"fatigue":0.0,"form":0.0,"injury_until":"","injury_kind":"","history":[]})
func club_name(id: String) -> String: return str(team(id).get("name",id))
static func add_days(date: String,days: int) -> String:
	return Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_datetime_string(date+"T12:00:00"))+days*86400).left(10)
static func day_gap(from: String,to: String) -> int:
	return maxi(0,roundi((Time.get_unix_time_from_datetime_string(to+"T12:00:00")-Time.get_unix_time_from_datetime_string(from+"T12:00:00"))/86400.0))
func best_of() -> int:
	return 3 if int(state.get("options",{}).get("best_of",5))==3 else 5

func _normalized_options(input: Dictionary) -> Dictionary:
	return {"best_of":3 if int(input.get("best_of",5))==3 else 5,"use_player_stats":bool(input.get("stats",input.get("use_player_stats",false))),"stats":bool(input.get("stats",input.get("use_player_stats",false))),"fatigue":bool(input.get("fatigue",true)),"injuries":bool(input.get("injuries",true)),"injury_intensity":clampf(float(input.get("injury_intensity",1.0)),0,2),"difficulty":clampi(int(input.get("difficulty",1)),0,2),"set_points":25,"news_frequency":clampi(int(input.get("news_frequency",1)),0,2),"simulation_detail":input.get("simulation_detail","quick"),"autosave":bool(input.get("autosave",true)),"auto_substitutions":bool(input.get("auto_subs",input.get("auto_substitutions",false))),"auto_subs":bool(input.get("auto_subs",input.get("auto_substitutions",false))),"coach_name":str(input.get("coach_name","")).left(48)}
func new_career(club_id: String,options: Dictionary={},slot: int=1) -> bool:
	error=""
	if rules==null: error="Calendario ufficiale non disponibile: avvio carriera bloccato."; return false
	var imported: Dictionary=rules.official_schedule()
	if not imported.get("valid",false): error=imported.get("error","Calendario ufficiale non verificato."); return false
	var db=League.new(); var clubs: Array=db.teams.duplicate(true)
	if not clubs.any(func(t): return t.id==club_id): error="Squadra non valida."; return false
	var seed_value: int=int(options.get("seed",int(Time.get_unix_time_from_system())^club_id.hash()))
	rng.seed=seed_value
	state={"schema":1,"slot":clampi(slot,1,12),"career_id":str(seed_value)+"-"+club_id,"club_id":club_id,"season":2026,"season_label":"2026/27","date":"2026-10-01","options":_normalized_options(options),"fixtures":imported.fixtures.duplicate(true),"results":{},"conditions":{},"news":[],"archives":[],"teams":clubs,"lineups":{},"competitions":{},"trophies":{},"player_stats":{},"stats_by_comp":{},"seed":seed_value,"rng_state":str(rng.state),"complete":false,"played_ids":[],"news_ids":{},"injury_history":[],"records":{},"last_result":{}}
	for t in clubs:
		var starting: Array=db.lineup(t)
		state.lineups[t.id]={"ids":starting.map(func(p): return p.id),"rotation":0}
		state.trophies[t.id]=[]
		for p in t.roster: state.conditions[p.id]={"fatigue":0.0,"form":0.0,"injury_until":"","injury_kind":"","history":[],"last_injury":""}
	for fixture in state.fixtures: _normalize_fixture(fixture)
	state.competitions={"regular":{"status":"scheduled","champion":""},"cup":{"status":"waiting","champion":""},"supercup":{"status":"waiting","champion":""},"playoff":{"status":"waiting","champion":"","stage":0,"series":[]},"fifth":{"status":"waiting","champion":"","stage":0,"series":[]},"playout":{"status":"waiting","champion":"","participants":[],"bonus":{},"last":""}}
	_initialize_supercup()
	if state.competitions.supercup.status=="blocked": state.clear(); return false
	var earliest: Array=pending_fixtures()
	if not earliest.is_empty(): state.date=mini_date(state.date,earliest[0].scheduled_date)
	_news("welcome","Benvenuto in SuperLega",club_name(club_id)+" apre la stagione 2026/27. Nessun incontro è già stato disputato.",club_id,"regular","welcome-2026")
	_prepare_preview(); return save()
static func mini_date(a: String,b: String) -> String: return a if a<b else b
func _normalize_fixture(fixture: Dictionary) -> void:
	fixture["competition"]=fixture.get("competition","regular")
	fixture["scheduled_date"]=fixture.get("scheduled_date",fixture.get("date","2026-10-18"))
	fixture["date"]=fixture.scheduled_date
	fixture["original_date"]=fixture.get("original_date",fixture.scheduled_date)
	fixture["kickoff_time"]=fixture.get("kickoff_time","18:00")
	fixture["result"]={}; fixture["status"]="scheduled"
func list_saves() -> Array: return repository.list_saves()
func save() -> bool:
	if state.is_empty(): error="Nessuna carriera aperta."; return false
	state.rng_state=str(rng.state)
	var ok: bool=repository.write(int(state.slot),state)
	error=repository.error; changed.emit(); return ok
func load_career(slot: int) -> bool:
	var value: Dictionary=repository.read(slot)
	if value.is_empty(): error=repository.error; return false
	state=value; state.slot=slot; rng.seed=int(state.seed); rng.state=int(str(state.rng_state)); error=""
	preload("res://src/player_overall.gd").refresh_teams(state.get("teams",[]))
	state["schema"]=1
	for key in ["news_ids","stats_by_comp","records"]:
		if not state.has(key): state[key]={}
	last_result=state.get("last_result",{})
	changed.emit(); return true
func pending_fixtures(team_id: String="",competition: String="") -> Array:
	var rows: Array=[]
	for f in state.get("fixtures",[]):
		if not f.get("result",{}).is_empty(): continue
		if not team_id.is_empty() and f.home!=team_id and f.away!=team_id: continue
		if not competition.is_empty() and f.competition!=competition: continue
		rows.append(f)
	rows.sort_custom(func(a,b): return a.scheduled_date<b.scheduled_date if a.scheduled_date!=b.scheduled_date else (a.kickoff_time<b.kickoff_time if a.kickoff_time!=b.kickoff_time else a.id<b.id))
	return rows
func next_fixture(team_id: String="") -> Dictionary:
	var rows:=pending_fixtures(state.get("club_id","") if team_id.is_empty() else team_id)
	return rows[0] if not rows.is_empty() else {}
func fixture(id: String) -> Dictionary:
	for f in state.get("fixtures",[]):
		if f.id==id: return f
	return {}
func eligible(p: Dictionary) -> bool:
	return not state.options.injuries or str(player_condition(p.id).injury_until).is_empty() or str(player_condition(p.id).injury_until)<=str(state.date)
func lineup(team_id: String) -> Array:
	var t:=team(team_id)
	if t.is_empty(): return []
	var plan: Dictionary=state.lineups.get(team_id,{"ids":[],"rotation":0})
	var available: Array=t.roster.filter(func(p): return eligible(p))
	var selected: Array=[]; var used: Array=[]
	for slot in 7:
		var wanted: String=str(plan.ids[slot]) if slot<plan.ids.size() else ""
		var candidates: Array=available.filter(func(p): return not p.id in used and League.fits_slot(p.role,slot))
		if candidates.is_empty():
			# Positions are not regulated player roles: a healthy emergency
			# setter/defensive replacement is legal, unlike fielding an injury.
			candidates=available.filter(func(p): return not p.id in used and (p.role!="libero" or slot==6))
		if candidates.is_empty(): error="Rosa insufficiente: non ci sono sette giocatori disponibili."; return []
		if (team_id!=state.club_id or state.options.auto_substitutions) and not wanted.is_empty():
			var least:=100.0
			for candidate in candidates: least=minf(least,float(player_condition(candidate.id).fatigue))
			if float(player_condition(wanted).fatigue)>36 and least+18<float(player_condition(wanted).fatigue): wanted=""
		candidates.sort_custom(func(a,b):
			if a.id==wanted or b.id==wanted: return a.id==wanted
			return float(player_condition(a.id).fatigue)<float(player_condition(b.id).fatigue))
		var selected_player: Dictionary=candidates[0].duplicate(true)
		selected_player["assigned_role"]=ROLES[slot]
		if not League.fits_slot(selected_player.role,slot): selected_player["original_role"]=selected_player.role; selected_player.role=ROLES[slot]
		selected.append(selected_player); used.append(selected_player.id)
	return selected
func set_lineup(team_id: String,ids: Array,rotation: int=0) -> bool:
	if ids.size()!=7: error="La formazione richiede sette giocatori distinti."; return false
	var t:=team(team_id)
	if t.is_empty(): return false
	for i in 7:
		var candidates: Array=t.roster.filter(func(p): return p.id==ids[i] and League.fits_slot(p.role,i) and eligible(p))
		if ids.count(ids[i])!=1 or candidates.size()!=1: error="Ruoli, disponibilità o giocatori duplicati non validi."; return false
	state.lineups[team_id]={"ids":ids.duplicate(),"rotation":posmod(rotation,6)}
	if state.options.autosave: return save()
	changed.emit(); return true
func rotation(team_id: String) -> int: return int(state.lineups.get(team_id,{}).get("rotation",0))
func standings(competition: String="regular") -> Array:
	var participants: Array=[]
	if competition=="playout": participants=state.get("competitions",{}).get("playout",{}).get("participants",[])
	if competition=="fifth": participants=state.get("competitions",{}).get("fifth",{}).get("participants",[])
	if participants.is_empty(): participants=state.get("teams",[]).map(func(t): return t.id)
	var table: Dictionary={}
	for id in participants:
		table[id]={"team_id":id,"id":id,"name":club_name(id),"played":0,"wins":0,"losses":0,"points":int(state.get("competitions",{}).get(competition,{}).get("bonus",{}).get(id,0)),"sets_for":0,"sets_against":0,"points_for":0,"points_against":0,"aces":0,"blocks":0,"errors":0,"set_ratio":0.0,"point_ratio":0.0,"form":[],"position":0}
	for f in state.get("fixtures",[]):
		if f.competition!=competition or f.get("result",{}).is_empty(): continue
		if competition=="fifth" and state.competitions.fifth.get("mode","")=="group" and f.get("stage","")!="group": continue
		var result: Dictionary=f.result
		for side in 2:
			var id: String=f.home if side==0 else f.away
			if not table.has(id): continue
			var row: Dictionary=table[id]; var own: int=int(result.sets[side]); var other: int=int(result.sets[1-side]); var won:=own>other
			row.played+=1; row.wins+=int(won); row.losses+=int(not won); row.sets_for+=own; row.sets_against+=other
			row.points+=rules.points_for_score(own,other)
			for score in result.set_scores: row.points_for+=int(score[side]); row.points_against+=int(score[1-side])
			if result.get("team_stats",[]).size()==2:
				for key in ["aces","blocks","errors"]:
					if result.team_stats[side].has(key) and row[key]!=null: row[key]+=int(result.team_stats[side][key])
					elif not result.team_stats[side].has(key): row[key]=null
			elif result.get("stats_source","")=="measured":
				for key in ["aces","blocks","errors"]: row[key]=null
			row.form.append("W" if won else "L")
			if row.form.size()>5: row.form.pop_front()
	var rows: Array=table.values()
	for row in rows:
		row.set_ratio=float(row.sets_for)/maxi(1,row.sets_against) if row.sets_against>0 else float(row.sets_for)*1000
		row.point_ratio=float(row.points_for)/maxi(1,row.points_against)
	var direct: Dictionary={}
	for f in state.get("fixtures",[]):
		if f.competition!=competition or f.result.is_empty(): continue
		for side in 2:
			var key: String=(str(f.home)+"|"+str(f.away)) if side==0 else (str(f.away)+"|"+str(f.home))
			direct[key]=int(direct.get(key,0))+rules.points_for_score(int(f.result.sets[side]),int(f.result.sets[1-side]))
	if rules!=null: rows=rules.sort_standings(rows,direct)
	for i in rows.size(): rows[i].position=i+1
	return rows
func leaders(key: String="points",filters: Dictionary={}) -> Array:
	var scope: Dictionary=state
	if not str(filters.get("season","")).is_empty() and str(filters.season) not in [str(state.season),str(state.season_label)]:
		for archive in state.archives:
			if str(filters.season) in [str(archive.season),str(archive.season_label)]: scope=archive; break
	var source: Dictionary=scope.get("player_stats",{})
	if not str(filters.get("competition","")).is_empty(): source=scope.get("stats_by_comp",{}).get(filters.competition,{})
	if not str(filters.get("match_id","")).is_empty(): source=scope.get("results",{}).get(filters.match_id,{}).get("players",{})
	var rows: Array=[]
	for id in source:
		var identity:=player(id)
		if identity.is_empty(): continue
		var club_id:=""
		for t in state.teams:
			if t.roster.any(func(p): return p.id==id): club_id=t.id; break
		if not str(filters.get("team_id","")).is_empty() and filters.team_id!=club_id: continue
		if not str(filters.get("role","")).is_empty() and filters.role!=identity.role: continue
		var values: Dictionary=source[id]; var value: float=float(values.get(key,0))
		if key not in ["attack_efficiency","reception_positive_pct","reception_perfect_pct"] and not values.has(key): continue
		if key=="attack_efficiency":
			if int(values.get("attack_attempts",0))<10: continue
			value=100.0*float(values.get("attack_kills",0))/maxi(1,int(values.attack_attempts))
		elif key in ["reception_positive_pct","reception_perfect_pct"]:
			if int(values.get("receptions",0))<10: continue
			value=100.0*float(values.get("reception_positive" if key=="reception_positive_pct" else "reception_perfect",0))/maxi(1,int(values.receptions))
		var provenance: String="mixed" if int(values.get("measured_matches",0))>0 and int(values.get("estimated_matches",0))>0 else ("measured" if int(values.get("measured_matches",0))>0 else "estimated")
		rows.append({"id":id,"player_id":id,"name":identity.name,"role":identity.role,"team_id":club_id,"value":value,"stats":values,"stats_source":provenance})
	rows.sort_custom(func(a,b): return a.value>b.value if a.value!=b.value else a.id<b.id)
	return rows
func simulate_next() -> Dictionary:
	if not active() or state.complete: error="La stagione è conclusa."; return {}
	var next:=next_fixture()
	if next.is_empty():
		var pending:=pending_fixtures()
		if pending.is_empty(): _progress(); return {}
		next=pending[0]
	var target_id: String=next.id
	var guard:=0
	while guard<600:
		guard+=1
		var pending:=pending_fixtures()
		if pending.is_empty(): _progress(); break
		var f: Dictionary=pending[0]
		_advance_date(f.scheduled_date)
		var result: Dictionary=Simulation.play(self,f)
		if result.is_empty(): error="Formazione non disponibile per "+club_name(f.home)+" / "+club_name(f.away); return {}
		if not _record(f,result): return {}
		if f.id==target_id: return result
	error="Nessun incontro da simulare."; return {}
func simulate_day() -> Array:
	var pending:=pending_fixtures()
	if pending.is_empty(): _progress(); return []
	return advance_to(pending[0].scheduled_date)
func advance_to(date: String) -> Array:
	var rows: Array=[]; var guard:=0
	while guard<1000:
		guard+=1
		var pending:=pending_fixtures()
		if pending.is_empty() or pending[0].scheduled_date>date: break
		var f: Dictionary=pending[0]; _advance_date(f.scheduled_date)
		var result: Dictionary=Simulation.play(self,f)
		if result.is_empty() or not _record(f,result): break
		rows.append(result)
	if date>=state.date: _advance_date(date)
	if state.options.autosave: save()
	return rows
func prepare_match(fixture_id: String) -> bool:
	var f:=fixture(fixture_id)
	if f.is_empty() or not f.result.is_empty(): error="Incontro non disponibile."; return false
	# Resolve prior matches only; the user's fixture is never simulated twice.
	var guard:=0
	while guard<600:
		guard+=1
		var pending:=pending_fixtures()
		if pending.is_empty() or pending[0].id==fixture_id: break
		var previous: Dictionary=pending[0]
		if previous.scheduled_date>f.scheduled_date: break
		_advance_date(previous.scheduled_date)
		var result: Dictionary=Simulation.play(self,previous)
		if result.is_empty() or not _record(previous,result): return false
	_advance_date(f.scheduled_date)
	return true
func record_played_result(fixture_id: String,result: Dictionary) -> bool:
	var f:=fixture(fixture_id)
	if f.is_empty() or not f.result.is_empty(): error="Incontro già registrato o non valido."; return false
	if not prepare_match(fixture_id): return false
	var measured:=result.duplicate(true)
	measured.merge({"fixture_id":f.id,"home":f.home,"away":f.away,"stats_source":"measured","source":"played"},true)
	_advance_date(f.scheduled_date)
	return _record(f,measured)
func _validate_result(result: Dictionary) -> bool:
	if not result.get("sets") is Array or result.sets.size()!=2 or not result.get("set_scores") is Array: return false
	var needed:=int(best_of()/2)+1
	if maxi(result.sets[0],result.sets[1])!=needed or mini(result.sets[0],result.sets[1])<0 or mini(result.sets[0],result.sets[1])>=needed: return false
	if result.set_scores.size()!=int(result.sets[0])+int(result.sets[1]): return false
	var wins: Array=[0,0]
	for i in result.set_scores.size():
		var score: Array=result.set_scores[i]
		if score.size()!=2 or mini(score[0],score[1])<0: return false
		var target:=15 if i==best_of()-1 else 25
		if maxi(score[0],score[1])<target or absi(int(score[0])-int(score[1]))<2: return false
		if maxi(score[0],score[1])>target and absi(int(score[0])-int(score[1]))!=2: return false
		wins[0 if score[0]>score[1] else 1]+=1
		if maxi(wins[0],wins[1])==needed and i<result.set_scores.size()-1: return false
	return wins==result.sets
func _record(f: Dictionary,result: Dictionary) -> bool:
	if not f.result.is_empty() or state.results.has(f.id): error="Incontro già registrato."; return false
	if not _validate_result(result): error="Risultato non valido: set o punteggi incoerenti."; return false
	result["winner"]=f.home if result.sets[0]>result.sets[1] else f.away
	result["date"]=f.scheduled_date; result["competition"]=f.competition
	result["mvp"]=result.get("mvp",""); result["players"]=result.get("players",{})
	if str(result.mvp).is_empty() and result.get("stats_source","")=="measured":
		var best:=0.0
		for id in result.players:
			if _player_club(id)!=result.winner: continue
			var values: Dictionary=result.players[id]
			var score: float=float(values.get("points",int(values.get("attack_kills",0))+int(values.get("aces",0))+int(values.get("blocks",0))))+float(values.get("digs",0))*.16+float(values.get("sets",0))*.06
			if score>best: best=score; result.mvp=id
		if not str(result.mvp).is_empty(): result.players[result.mvp]["mvp"]=1
	result["duration_minutes"]=float(result.get("duration_minutes",0))
	f.result=result; f.status="played"; state.results[f.id]=result; state.played_ids.append(f.id)
	_aggregate(result); _condition_after(f,result)
	state.last_result=result; last_result=result
	_news("result",club_name(result.winner)+" vince "+str(maxi(result.sets[0],result.sets[1]))+"–"+str(mini(result.sets[0],result.sets[1])),club_name(f.home)+" – "+club_name(f.away)+" · "+_score_text(result)+". "+("Statistiche stimate dal simulatore." if result.stats_source=="estimated" else "Statistiche dei contatti realmente registrati in campo."),result.winner,f.competition,"result-"+f.id)
	_editorial_after(f,result)
	_progress(); _prepare_preview(); state.rng_state=str(rng.state)
	if state.options.autosave: save()
	match_finished.emit(result); changed.emit(); return true
func _aggregate(result: Dictionary) -> void:
	if not state.stats_by_comp.has(result.competition): state.stats_by_comp[result.competition]={}
	for id in result.players:
		if player(id).is_empty(): continue
		var values: Dictionary=result.players[id]
		for aggregate in [state.player_stats,state.stats_by_comp[result.competition]]:
			if not aggregate.has(id): aggregate[id]={"measured_matches":0,"estimated_matches":0}
			var row: Dictionary=aggregate[id]
			row["estimated_matches" if result.stats_source=="estimated" else "measured_matches"]+=1
			for key in Simulation.KEYS:
				if values.has(key): row[key]=int(row.get(key,0))+maxi(0,int(values[key]))
		for key in ["points","aces","blocks","digs"]:
			var record_key: String="match_"+key
			if int(values.get(key,0))>int(state.records.get(record_key,{}).get("value",0)):
				state.records[record_key]={"player_id":id,"value":int(values[key]),"season":state.season_label,"fixture_id":result.fixture_id}
				if key=="points" and int(values[key])>=20:
					_news("record",str(player(id).name)+": nuovo record della carriera",str(values[key])+" punti in una partita del salvataggio. "+("Dato stimato dal simulatore." if result.stats_source=="estimated" else "Dato misurato durante la partita giocata."),_player_club(id),result.competition,"record-"+record_key+"-"+result.fixture_id,[id])
func _advance_date(date: String) -> void:
	if date<=state.date: return
	var days:=day_gap(state.date,date)
	state.date=date
	for id in state.conditions:
		var c: Dictionary=state.conditions[id]
		if state.options.fatigue: c.fatigue=maxf(0,float(c.fatigue)-days*12.0)
		if not str(c.injury_until).is_empty() and str(c.injury_until)<=date:
			c.injury_until=""; c.injury_kind=""
			_news("return",str(player(id).get("name",id))+" torna disponibile","Rientro dalla simulazione dell'indisponibilità. Nessun riferimento a un infortunio reale.",_player_club(id),"regular","return-"+id+"-"+date,[id])
	day_advanced.emit(date)
func _condition_after(f: Dictionary,result: Dictionary) -> void:
	var match_sets: int=result.set_scores.size()
	for id in result.players:
		if not state.conditions.has(id): continue
		var c: Dictionary=state.conditions[id]; var values: Dictionary=result.players[id]
		if state.options.fatigue:
			if values.has("fatigue_end"): c.fatigue=clampf(float(values.fatigue_end),0,100)
			else:
				var role: String=player(id).role
				var workload:=6.0 if role=="libero" else (8.3 if role in ["middle_blocker","opposite"] else 7.2)
				c.fatigue=clampf(float(c.fatigue)+workload*int(values.get("sets_played",match_sets)),0,100)
		var club:=_player_club(id); var won: bool=result.winner==club
		c.form=clampf(float(c.form)*.78+(.65 if won else -.5)+rng.randf_range(-.12,.12),-5,5)
		c.history.append({"date":f.scheduled_date,"fixture_id":f.id,"fatigue":c.fatigue,"form":c.form})
		if values.has("injury_until") and state.options.injuries and not str(values.injury_until).is_empty(): _injure(id,str(values.injury_until),str(values.get("injury_kind","Lieve")),f)
	# Low, bounded simulated injury risk; never force an entire role out.
	if result.stats_source=="estimated" and state.options.injuries:
		for club in [f.home,f.away]:
			var candidates: Array=lineup(club)
			for p in candidates:
				var c: Dictionary=player_condition(p.id)
				if not str(c.get("last_injury","")).is_empty() and day_gap(c.last_injury,state.date)<30: continue
				var risk: float=.0012*match_sets*(1+pow(float(c.fatigue)/100,3)*2)*float(state.options.injury_intensity)
				if rng.randf()>=risk: continue
				if team(club).roster.filter(func(other): return other.id!=p.id and other.role==p.role and eligible(other)).size()<(1 if p.role in ["middle_blocker","outside_hitter"] else 1): continue
				var roll:=rng.randf(); var days:=rng.randi_range(1,3) if roll<.77 else (rng.randi_range(4,14) if roll<.97 else rng.randi_range(15,45))
				_injure(p.id,add_days(state.date,days),"Lieve" if days<=3 else ("Media" if days<=14 else "Lunga"),f); break
func _injure(id: String,until: String,kind: String,f: Dictionary) -> void:
	var c: Dictionary=state.conditions[id]; c.injury_until=until; c.injury_kind=kind; c.last_injury=state.date
	var event={"player_id":id,"date":state.date,"until":until,"kind":kind,"fixture_id":f.id,"simulated":true}
	state.injury_history.append(event)
	_news("injury",str(player(id).name)+": indisponibilità simulata","Evento virtuale della carriera: assenza "+kind.to_lower()+" fino al "+until+". Non è una notizia sull'atleta reale.",_player_club(id),f.competition,"injury-"+id+"-"+state.date,[id])
	player_injured.emit(id)
func _player_club(id: String) -> String:
	for t in state.teams:
		if t.roster.any(func(p): return p.id==id): return t.id
	return ""
func _score_text(result: Dictionary) -> String:
	var scores: PackedStringArray=[]
	for score in result.set_scores: scores.append(str(score[0])+"–"+str(score[1]))
	return str(result.sets[0])+"–"+str(result.sets[1])+" ("+", ".join(scores)+")"
func _news(category: String,title: String,body: String,club: String,competition: String,id: String,players: Array=[]) -> void:
	if state.get("news_ids",{}).has(id): return
	if category in ["result","preview"] and int(state.options.news_frequency)==0 and club!=state.club_id: return
	state.news_ids[id]=true
	state.news.push_front({"id":id,"category":category,"title":title,"subtitle":LABELS.get(competition,competition),"body":body,"date":state.date,"club_id":club,"clubs":[club],"players":players,"competition":competition,"image":"arena" if category not in ["injury","return"] else "players","simulated":true,"tags":[category,competition]})
func _prepare_preview() -> void:
	var next:=next_fixture()
	if next.is_empty(): return
	_news("preview","Prossima sfida: "+club_name(next.home)+" – "+club_name(next.away),LABELS.get(next.competition,next.competition)+" · "+next.scheduled_date+". La preparazione della squadra continua.",state.club_id,next.competition,"preview-"+next.id)
func _editorial_after(f: Dictionary,result: Dictionary) -> void:
	var winner_side:=0 if result.winner==f.home else 1
	if int(state.options.news_frequency)==2:
		var short_match: bool=result.sets[1-winner_side]<=1
		_news("analysis",("Continuità decisiva per " if short_match else "Equilibrio e dettagli: vince ")+club_name(result.winner),"Analisi virtuale basata sui set disputati: "+_score_text(result)+". "+("Il rendimento nei primi scambi ha tenuto la partita sotto controllo." if short_match else "I finali di set hanno cambiato gli equilibri dell'incontro.")+" Commento simulato, non una dichiarazione reale.",result.winner,f.competition,"analysis-"+f.id)
	if result.set_scores.size()==5 and result.set_scores[0][winner_side]<result.set_scores[0][1-winner_side] and result.set_scores[1][winner_side]<result.set_scores[1][1-winner_side]:
		_news("comeback",club_name(result.winner)+": rimonta da 0–2!","La squadra ribalta il risultato vincendo gli ultimi tre set. Commento virtuale: la continuità dopo il secondo set ha cambiato l'incontro.",result.winner,f.competition,"comeback-"+f.id)
	if f.competition=="regular":
		var table:=standings()
		for row in table:
			if row.team_id not in [f.home,f.away]: continue
			if row.form.size()>=3 and row.form.slice(-3)==["L","L","L"]:
				_news("form",club_name(row.team_id)+": serve una reazione","Tre sconfitte consecutive nel campionato del salvataggio. Lo staff virtuale valuta condizione e alternative in formazione.",row.team_id,"regular","crisis-"+row.team_id+"-"+state.date.left(7))
		if int(f.round) in [5,11,16,22] and _done("regular",int(f.round)):
			_news("standings",club_name(table[0].team_id)+" guida la classifica",str(table[0].points)+" punti e "+str(table[0].wins)+" vittorie dopo gli incontri disputati. Nessun risultato futuro è incluso.",table[0].team_id,"regular","ranking-"+str(state.season)+"-"+str(int(f.round)))
func update_options(options: Dictionary) -> void:
	var merged: Dictionary=state.options.duplicate(true); merged.merge(options,true)
	if options.has("use_player_stats") and not options.has("stats"): merged.stats=options.use_player_stats
	if options.has("auto_substitutions") and not options.has("auto_subs"): merged.auto_subs=options.auto_substitutions
	state.options=_normalized_options(merged)
	if state.options.autosave: save()
	changed.emit()
func import_roster_edits() -> bool:
	# Explicit import only: automatic game patches never replace career data.
	var db=League.new(); var replacements: Array=[]
	for existing in state.teams:
		var matches: Array=db.teams.filter(func(t): return t.id==existing.id)
		if matches.size()!=1: error="Database locale incompatibile con i club della carriera."; return false
		replacements.append(matches[0].duplicate(true))
	state.teams=replacements
	for t in replacements:
		for p in t.roster:
			if not state.conditions.has(p.id): state.conditions[p.id]={"fatigue":0.0,"form":0.0,"injury_until":"","injury_kind":"","history":[],"last_injury":""}
	if state.options.autosave: return save()
	changed.emit(); return true
func _configuration() -> Dictionary:
	return rules.config(int(state.season)) if rules!=null and rules.has_method("config") else {}
func _dates(section: String,key: String) -> Array:
	var config:=_configuration()
	return config.get(section,{}).get(key,[])
func _date(section: String,key: String,index: int=0,earliest: String="") -> String:
	var dates: Array=_dates(section,key)
	var chosen: String=str(dates[mini(index,dates.size()-1)]) if not dates.is_empty() else add_days(state.date,3+index*4)
	return add_days(earliest,3) if not earliest.is_empty() and chosen<=earliest else chosen
func _add_fixture(id: String,competition: String,round: int,home: String,away: String,date: String,meta: Dictionary={}) -> Dictionary:
	if not fixture(id).is_empty(): return fixture(id)
	var row={"id":id,"competition":competition,"round":round,"home":home,"away":away,"original_date":date,"scheduled_date":date,"date":date,"kickoff_time":"18:00","source_url":"https://www.legavolley.it/formula-superlega-2026-27/" if int(state.season)==2026 else "","verified_at":"2026-10-29" if int(state.season)==2026 else "","official":int(state.season)==2026,"result":{},"status":"scheduled","date_kind":"competition_window" if int(state.season)==2026 else "generated"}
	row.merge(meta,true); state.fixtures.append(row); return row
func _initialize_supercup() -> void:
	var config:=_configuration(); var cup: Dictionary=config.get("supercup",{})
	var pairs: Array=cup.get("pairs",[])
	if int(state.season)>2026 and not state.archives.is_empty():
		var previous: Dictionary=state.archives[-1]; var seeds: Array=[]
		for id in [previous.champions.get("playoff",""),previous.champions.get("cup",""),previous.competitions.playoff.get("finalist",""),previous.competitions.cup.get("finalist","")]:
			if not id.is_empty() and not id in seeds: seeds.append(id)
		if seeds.size()<4:
			for row in previous.standings:
				if not row.team_id in seeds: seeds.append(row.team_id)
				if seeds.size()==4: break
		pairs=[[seeds[0],seeds[3]],[seeds[1],seeds[2]]]
	if pairs.size()!=2:
		error="Partecipanti Supercoppa non verificati."; state.competitions.supercup.status="blocked"; return
	state.competitions.supercup.status="semifinals"
	for i in 2:
		_add_fixture(str(state.season)+"-supercup-sf-"+str(i),"supercup",1,pairs[i][0],pairs[i][1],_date("supercup","dates",0),{"stage":"semi","neutral":true})
func _done(competition: String,maximum_round: int=999,stage: String="") -> bool:
	var count:=0
	for f in state.fixtures:
		if f.competition!=competition or int(f.round)>maximum_round or (not stage.is_empty() and str(f.get("stage",""))!=stage): continue
		count+=1
		if f.result.is_empty(): return false
	return count>0
func _stage_results(competition: String,stage: String) -> Array:
	var rows: Array=state.fixtures.filter(func(f): return f.competition==competition and f.get("stage","")==stage and not f.result.is_empty())
	rows.sort_custom(func(a,b): return a.id<b.id); return rows
func _finish_competition(competition: String,winner: String) -> void:
	var c: Dictionary=state.competitions[competition]
	if c.status=="complete": return
	c.status="complete"; c.champion=winner
	if competition!="playout": state.trophies[winner].append({"season":state.season_label,"competition":competition})
	_news("trophy",club_name(winner)+" conquista "+LABELS[competition],"La competizione della carriera è conclusa. "+("Nessuna retrocessione: tutte le dodici squadre restano in SuperLega." if competition=="playout" else "Riconoscimento virtuale della stagione "+state.season_label+"."),winner,competition,"trophy-"+str(state.season)+"-"+competition)
	competition_completed.emit(competition,winner)
func _progress_cups() -> void:
	var supercup: Dictionary=state.competitions.supercup
	if supercup.status=="semifinals" and _done("supercup",999,"semi"):
		var sf:=_stage_results("supercup","semi"); supercup.status="final"
		_add_fixture(str(state.season)+"-supercup-final","supercup",2,sf[0].result.winner,sf[1].result.winner,_date("supercup","dates",1),{"stage":"final","neutral":true})
	elif supercup.status=="final" and _done("supercup",999,"final"):
		_finish_competition("supercup",_stage_results("supercup","final")[0].result.winner)
	var cup: Dictionary=state.competitions.cup
	if cup.status=="waiting" and _done("regular",11):
		var rows:=_half_standings(); cup.status="quarters"; cup.qualified=rows.slice(0,8).map(func(r): return r.team_id)
		for i in 4:
			var pair: Array=[[0,7],[3,4],[1,6],[2,5]][i]
			_add_fixture(str(state.season)+"-cup-qf-"+str(i),"cup",1,rows[pair[0]].team_id,rows[pair[1]].team_id,_date("cup","quarter_dates"),{"stage":"quarter","neutral":false})
	elif cup.status=="quarters" and _done("cup",999,"quarter"):
		var qf:=_stage_results("cup","quarter"); cup.status="semifinals"
		for i in 2: _add_fixture(str(state.season)+"-cup-sf-"+str(i),"cup",2,qf[i*2].result.winner,qf[i*2+1].result.winner,_date("cup","semi_dates",0,state.date),{"stage":"semi","neutral":true})
	elif cup.status=="semifinals" and _done("cup",999,"semi"):
		var sf:=_stage_results("cup","semi"); cup.status="final"
		_add_fixture(str(state.season)+"-cup-final","cup",3,sf[0].result.winner,sf[1].result.winner,_date("cup","final_dates",0,state.date),{"stage":"final","neutral":true})
	elif cup.status=="final" and _done("cup",999,"final"):
		var final_fixture: Dictionary=_stage_results("cup","final")[0]
		cup.finalist=final_fixture.away if final_fixture.result.winner==final_fixture.home else final_fixture.home
		_finish_competition("cup",final_fixture.result.winner)
func _half_standings() -> Array:
	# Cup qualification is frozen at the end of the first-leg fixtures,
	# irrespective of later fixtures already played ahead of their round.
	var excluded: Array=[]
	for f in state.fixtures:
		if f.competition=="regular" and int(f.round)>11 and not f.result.is_empty(): excluded.append([f,f.result]); f.result={}
	var rows:=standings()
	for pair in excluded: pair[0].result=pair[1]
	return rows
func _rank(id: String) -> int:
	var ranking: Array=state.competitions.get("playoff",{}).get("ranking",[])
	if ranking.is_empty(): ranking=standings().map(func(r): return r.team_id)
	var found:=ranking.find(id); return found if found>=0 else 99
func _start_series(competition: String,stage: int,pairs: Array,best_of: int,section: String,date_key: String) -> void:
	var c: Dictionary=state.competitions[competition]; c.status="playing"; c.stage=stage
	if not c.has("series"): c.series=[]
	for i in pairs.size():
		var a: String=pairs[i][0]; var b: String=pairs[i][1]
		if _rank(a)>_rank(b): var swap:=a; a=b; b=swap
		var series={"id":str(state.season)+"-"+competition+"-s"+str(stage)+"-"+str(i),"team_a":a,"team_b":b,"best_of":best_of,"wins":[0,0],"games":[],"winner":"","stage":stage,"section":section,"date_key":date_key}
		c.series.append(series); _next_series_game(competition,series)
func _next_series_game(competition: String,series: Dictionary) -> void:
	var game: int=series.games.size(); var home_a:=game%2==0
	var date:=_date(series.section,series.date_key,game)
	if game>0:
		var last:=fixture(str(series.games[-1]))
		if date<=last.scheduled_date: date=add_days(last.scheduled_date,3)
	var id: String=series.id+"-g"+str(game+1)
	_add_fixture(id,competition,game+1,series.team_a if home_a else series.team_b,series.team_b if home_a else series.team_a,date,{"stage":"series-"+str(series.stage),"series_id":series.id,"series_stage":series.stage})
	series.games.append(id)
func _update_series() -> void:
	for competition in ["playoff","fifth"]:
		var c: Dictionary=state.competitions[competition]
		for series in c.get("series",[]):
			if not str(series.winner).is_empty(): continue
			var wins: Array=[0,0]; var all_done:=true
			for id in series.games:
				var f:=fixture(id)
				if f.result.is_empty(): all_done=false; break
				wins[0 if f.result.winner==series.team_a else 1]+=1
			series.wins=wins
			if maxi(wins[0],wins[1])>=int(series.best_of/2)+1: series.winner=series.team_a if wins[0]>wins[1] else series.team_b
			elif all_done: _next_series_game(competition,series)
func _series_stage(competition: String,stage: int) -> Array:
	return state.competitions[competition].get("series",[]).filter(func(s): return int(s.stage)==stage)
func _series_done(competition: String,stage: int) -> bool:
	var rows:=_series_stage(competition,stage)
	return not rows.is_empty() and rows.all(func(s): return not str(s.winner).is_empty())
func _playoff_stages() -> void:
	var c: Dictionary=state.competitions.playoff
	if c.status=="waiting" and _done("regular"):
		var table:=standings(); var rank: Array=table.map(func(r): return r.team_id)
		c.ranking=rank; state.competitions.regular.champion=rank[0]; state.competitions.regular.status="complete"
		_start_series("playoff",1,[[rank[0],rank[7]],[rank[3],rank[4]],[rank[1],rank[6]],[rank[2],rank[5]]],5,"playoff","quarter_dates")
		_start_playout(table)
	if int(c.stage)==1 and _series_done("playoff",1):
		var qf:=_series_stage("playoff",1); var winners: Array=qf.map(func(s): return s.winner)
		c.quarter_losers=qf.map(func(s): return s.team_b if s.winner==s.team_a else s.team_a)
		_start_series("playoff",2,[[winners[0],winners[1]],[winners[2],winners[3]]],5,"playoff","semi_dates")
		_start_fifth(c.ranking[0] in winners)
	if int(c.stage)==2 and _series_done("playoff",2):
		var sf:=_series_stage("playoff",2)
		c.semi_losers=sf.map(func(s): return s.team_b if s.winner==s.team_a else s.team_a)
		_start_series("playoff",3,[[sf[0].winner,sf[1].winner]],5,"playoff","final_dates")
	if int(c.stage)==3 and _series_done("playoff",3):
		var final_series: Dictionary=_series_stage("playoff",3)[0]; c.finalist=final_series.team_b if final_series.winner==final_series.team_a else final_series.team_a
		c.stage=4; _finish_competition("playoff",final_series.winner)
func _start_playout(table: Array) -> void:
	var c: Dictionary=state.competitions.playout
	var four: bool=int(table[8].points)-int(table[11].points)<=7
	var entries: Array=table.slice(8 if four else 9,12)
	c.participants=entries.map(func(r): return r.team_id); c.bonus={}; c.status="playing"
	var bonuses: Array=[5,4,3,0] if four else [4,3,0]
	for i in entries.size(): c.bonus[entries[i].team_id]=bonuses[i]
	_group_fixtures("playout",c.participants,"playout","dates")
func _group_fixtures(competition: String,participants: Array,section: String,key: String) -> void:
	var order: Array=participants.duplicate()
	if order.size()%2==1: order.append("")
	var first_rounds:=order.size()-1
	for leg in 2:
		var wheel:=order.duplicate()
		for turn in first_rounds:
			var round_index:=leg*first_rounds+turn
			for i in int(wheel.size()/2):
				var a: String=wheel[i]; var b: String=wheel[wheel.size()-1-i]
				if a.is_empty() or b.is_empty(): continue
				if (turn+i+leg)%2==1: var swap:=a; a=b; b=swap
				_add_fixture(str(state.season)+"-"+competition+"-group-r"+str(round_index+1)+"-"+str(i),competition,round_index+1,a,b,_date(section,key,round_index),{"stage":"group"})
			var last=wheel.pop_back(); wheel.insert(1,last)
func _start_fifth(leader_survives: bool) -> void:
	var c: Dictionary=state.competitions.fifth; var teams: Array=state.competitions.playoff.quarter_losers.duplicate()
	teams.sort_custom(func(a,b): return _rank(a)<_rank(b))
	c.mode="bracket" if leader_survives else "group"
	if leader_survives:
		c.participants=teams
		_start_series("fifth",1,[[teams[0],teams[3]],[teams[1],teams[2]]],3,"fifth","semi_dates")
	else:
		teams.erase(state.competitions.playoff.ranking[0]); c.participants=teams; c.status="playing"; c.stage=1
		_group_fixtures("fifth",teams,"fifth","group_dates")
func _fifth_stages() -> void:
	var c: Dictionary=state.competitions.fifth
	if c.status in ["waiting","complete"]: return
	if c.mode=="bracket":
		if int(c.stage)==1 and _series_done("fifth",1):
			var sf:=_series_stage("fifth",1)
			_start_series("fifth",2,[[sf[0].winner,sf[1].winner]],3,"fifth","final_dates")
		elif int(c.stage)==2 and _series_done("fifth",2): _finish_competition("fifth",_series_stage("fifth",2)[0].winner)
	else:
		if int(c.stage)==1 and _done("fifth",999,"group") and state.competitions.playoff.has("semi_losers"):
			var others: Array=state.competitions.playoff.semi_losers.duplicate(); others.sort_custom(func(a,b): return _rank(a)>_rank(b))
			_start_series("fifth",2,[[standings("fifth")[0].team_id,others[0]]],3,"fifth","challenge_dates")
		elif int(c.stage)==2 and _series_done("fifth",2): _finish_competition("fifth",_series_stage("fifth",2)[0].winner)
func _progress() -> void:
	if state.is_empty() or state.complete: return
	_progress_cups(); _update_series(); _playoff_stages(); _fifth_stages()
	var playout: Dictionary=state.competitions.playout
	if playout.status=="playing" and _done("playout"):
		var rows:=standings("playout"); playout.last=rows[-1].team_id
		_finish_competition("playout",rows[0].team_id)
		_news("playout",club_name(playout.last)+": ultima Play Out","Etichetta sportiva della carriera. Nessuna retrocessione: le stesse dodici squadre saranno iscritte l'anno prossimo.",playout.last,"playout","last-playout-"+str(state.season))
	var complete: bool=state.competitions.values().all(func(c): return c.status=="complete")
	if complete: _archive_season()
func _archive_season() -> void:
	if state.complete: return
	var champions: Dictionary={}
	for key in state.competitions: champions[key]=state.competitions[key].champion
	var archive={"season":state.season,"season_label":state.season_label,"standings":standings().duplicate(true),"champions":champions,"competitions":state.competitions.duplicate(true),"fixtures":state.fixtures.duplicate(true),"results":state.results.duplicate(true),"player_stats":state.player_stats.duplicate(true),"stats_by_comp":state.stats_by_comp.duplicate(true),"news":state.news.duplicate(true),"injury_history":state.injury_history.duplicate(true),"conditions":state.conditions.duplicate(true),"last_playout":state.competitions.playout.last,"promotions":[],"relegations":[],"awards":{}}
	for key in ["points","aces","blocks","digs"]:
		var ranked:=leaders(key)
		if not ranked.is_empty(): archive.awards[key]={"player_id":ranked[0].id,"value":ranked[0].value}
	var sf_losers: Array=state.competitions.playoff.semi_losers.duplicate(); sf_losers.sort_custom(func(a,b): return _rank(a)<_rank(b))
	var regular_survives: bool=state.competitions.fifth.mode=="bracket"
	archive["european_recognition"]={"champions_league":[champions.playoff,state.competitions.playoff.get("finalist",""),sf_losers[0] if regular_survives else champions.regular],"cev_cup":sf_losers[1] if regular_survives else sf_losers[0],"challenge_cup":champions.fifth,"note":"Riconoscimenti virtuali: nessuna gara europea viene generata."}
	for id in state.player_stats:
		for key in ["points","aces","blocks","digs"]:
			var value: int=int(state.player_stats[id].get(key,0))
			if value>int(state.records.get(key,{}).get("value",-1)): state.records[key]={"player_id":id,"value":value,"season":state.season_label}
	_news("awards","Stagione conclusa: "+club_name(champions.playoff)+" campione","Albo d'oro, risultati e record sono conservati. Puoi iniziare la stagione successiva con gli stessi dodici club.",champions.playoff,"playoff","season-end-"+str(state.season))
	archive.news=state.news.duplicate(true)
	state.archives.append(archive); state.complete=true
func next_season() -> bool:
	if not state.get("complete",false): error="Completa tutte le competizioni prima di iniziare una nuova stagione."; return false
	var year: int=int(state.season)+1
	var generated=rules.later_schedule(year,int(state.seed)+year*7919,state.teams.map(func(t): return t.id))
	var fixtures: Array=generated.get("fixtures",[]) if generated is Dictionary else generated
	if fixtures.size()!=132: error="Calendario generato non valido."; return false
	_advance_date(str(year)+"-10-01")
	state.season=year; state.season_label=str(year)+"/"+str(year+1).right(2); state.fixtures=fixtures; state.results={}; state.played_ids=[]; state.news=[]; state.news_ids={}; state.player_stats={}; state.stats_by_comp={}; state.injury_history=[]; state.complete=false; state.last_result={}; last_result={}
	for f in state.fixtures: _normalize_fixture(f)
	state.competitions={"regular":{"status":"scheduled","champion":""},"cup":{"status":"waiting","champion":""},"supercup":{"status":"waiting","champion":""},"playoff":{"status":"waiting","champion":"","stage":0,"series":[]},"fifth":{"status":"waiting","champion":"","stage":0,"series":[]},"playout":{"status":"waiting","champion":"","participants":[],"bonus":{},"last":""}}
	_initialize_supercup()
	_news("welcome","Inizia la stagione "+state.season_label,"Calendario generato in modo deterministico. Tutte le dodici squadre sono confermate; nessuna promozione o retrocessione effettiva.",state.club_id,"regular","welcome-"+str(year))
	_prepare_preview(); return save()

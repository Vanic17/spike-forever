extends RefCounted
## A player career owns its championship snapshot and never edits League or Master League saves.
signal changed
signal match_finished(result: Dictionary)
const Manager=preload("res://src/career_manager.gd")
const Saves=preload("res://src/legend_save.gd")
const League=preload("res://src/league.gd")
const Overall=preload("res://src/player_overall.gd")
const Simulation=preload("res://src/career_simulation.gd")
const INITIAL_CAP:=65
const INITIAL_MIN:=30
const INITIAL_BUDGET:=300
const ATTRIBUTE_CAP:=99
const XP_PER_POINT:=60
const STAT_KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
const ROLES=["outside_hitter","opposite","middle_blocker","setter","libero"]
const PERFORMANCE_KEYS=["serves","aces","errors","attacks","kills","digs","receptions","sets","assists","blocks","touches"]
const APPEARANCE_OPTIONS={"hair_style":["corti","rasati","sfumati","mossi","ricci","afro","frangia","riga","lunghi","treccine","pelato"],"hair_color":["nero","marrone","castano chiaro","biondo","rosso","grigio"],"skin_tone":["rosa","chiara","olivastra","ambrata","scura","nero","ebano"],"beard":["nessuna","corta","piena"]}
var state: Dictionary={}
var error:=""
var engine=Manager.new()
var repository=Saves.new()
var last_result: Dictionary={}

func _init():
	engine.repository=repository

func active() -> bool: return not state.is_empty()
func team(id: String) -> Dictionary: return engine.team(id)
func club_name(id: String) -> String: return engine.club_name(id)
func standings(competition: String="regular") -> Array: return engine.standings(competition) if active() else []
func fixture(id: String) -> Dictionary: return engine.fixture(id)
func overall() -> int: return Overall.calculate(state.get("profile",{}).get("ratings",{}),str(state.get("profile",{}).get("role","outside_hitter")))

func default_profile() -> Dictionary:
	var ratings: Dictionary={}
	for key in STAT_KEYS: ratings[key]=50
	return {"name":"Il tuo nome","number":1,"jersey_number":1,"role":"outside_hitter","dominant_hand":"right","serve_preference":"jump","appearance":{"hair_style":"corti","hair_length":"corti","hair_color":"marrone","skin_tone":"olivastra","beard":"nessuna"},"ratings":ratings}

func validate_profile(profile: Dictionary) -> String:
	if str(profile.get("name","")).strip_edges().is_empty() or str(profile.get("name","")).length()>48: return "Inserisci un nome da 1 a 48 caratteri."
	if str(profile.get("role","")) not in ROLES: return "Scegli un ruolo valido."
	if str(profile.get("dominant_hand","right")) not in ["right","left"]: return "Scegli mano destra o sinistra."
	if str(profile.get("serve_preference","jump")) not in ["jump","float"]: return "Scegli servizio in salto o float."
	var number=profile.get("number",profile.get("jersey_number",1))
	if not _whole_number(number) or int(number)<1 or int(number)>99: return "Il numero di maglia deve essere compreso tra 1 e 99."
	if not profile.get("ratings") is Dictionary: return "Imposta i sei attributi iniziali."
	var total:=0
	for key in STAT_KEYS:
		var value=profile.ratings.get(key,-1)
		if not _whole_number(value) or int(value)<INITIAL_MIN or int(value)>INITIAL_CAP: return "Ogni attributo iniziale deve essere tra %d e %d."%[INITIAL_MIN,INITIAL_CAP]
		total+=int(value)
	if total>INITIAL_BUDGET: return "Budget iniziale superato: massimo %d punti sui sei attributi."%INITIAL_BUDGET
	if Overall.calculate(profile.ratings,str(profile.role))>INITIAL_CAP: return "Valutazione iniziale troppo alta."
	if profile.has("appearance") and not profile.appearance is Dictionary: return "Aspetto non valido."
	for key in APPEARANCE_OPTIONS:
		if profile.get("appearance",{}).has(key) and str(profile.appearance[key]) not in APPEARANCE_OPTIONS[key]: return "Aspetto non valido: "+str(key)
	return ""

func _whole_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))

func _club_strength(club: Dictionary,db) -> float:
	var lineup: Array=db.lineup(club); var total:=0.0
	for player in lineup: total+=Overall.calculate(player.ratings,str(player.role))
	return total/maxi(1,lineup.size())

func starter_clubs() -> Array:
	var db=League.new(); var rows: Array=db.teams.duplicate(true)
	for club in rows:
		club["strength"]=_club_strength(club,db); club["overall"]=roundi(club.strength)
	rows.sort_custom(func(a,b): return a.strength<b.strength if a.strength!=b.strength else a.id<b.id)
	return rows.slice(0,3)

func new_career(profile: Dictionary,club_id: String,options: Dictionary={},slot: int=1) -> bool:
	error=validate_profile(profile)
	if not error.is_empty(): return false
	if not starter_clubs().any(func(club): return str(club.id)==club_id): error="Puoi iniziare soltanto in uno dei tre club più deboli."; return false
	if slot<1 or slot>12: error="Slot Diventa un mito non valido."; return false
	var next_engine=Manager.new(); next_engine.repository=repository
	var settings:=options.duplicate(true); settings["stats"]=true; settings["use_player_stats"]=true
	# Injuries are a team-career mechanic; the created player always remains playable.
	settings["injuries"]=false; settings["auto_substitutions"]=false; settings["auto_subs"]=false
	repository.suspended=true
	var started: bool=next_engine.new_career(club_id,settings,slot)
	repository.suspended=false
	if not started: error=next_engine.error; return false
	engine=next_engine; state=engine.state
	var created:=default_profile(); created.merge(profile.duplicate(true),true)
	created.id="legend72-"+str(state.career_id)+"-"+str(Time.get_ticks_usec())
	created.name=str(created.name).strip_edges(); created.number=int(profile.get("number",profile.get("jersey_number",1))); created.jersey_number=created.number
	created["source"]="created_legend72"; created["ratings_metadata"]={"type":"player_career","initial_cap":INITIAL_CAP,"initial_budget":INITIAL_BUDGET}
	for key in STAT_KEYS: created.ratings[key]=int(created.ratings[key])
	Overall.refresh(created)
	state.merge({"mode":"legend72","profile":created,"skill_points":0,"xp":0,"xp_bank":0,"level":1,"reputation":0.0,"match_history":[],"offers":[],"transfer_history":[],"rewarded_ids":{},"pending_fixture_id":"","contract":{"club_id":club_id,"signed_season":state.season,"expires_season":int(state.season)+1,"salary":500+Overall.calculate(created.ratings,str(created.role))*40,"status":"active"}},true)
	_place_profile(club_id)
	last_result={}
	return save()

func _place_profile(club_id: String) -> void:
	var id: String=state.profile.id
	# There is exactly one roster identity throughout every transfer and reload.
	for club in state.teams:
		club.roster=club.roster.filter(func(player): return str(player.id)!=id)
	team(club_id).roster.append(state.profile)
	state.conditions[id]=state.conditions.get(id,{"fatigue":0.0,"form":0.0,"injury_until":"","injury_kind":"","history":[],"last_injury":""})
	var plan: Dictionary=state.lineups[club_id]
	var slots: Array={"outside_hitter":[0,3],"opposite":[2],"middle_blocker":[1,4],"setter":[5],"libero":[6]}.get(state.profile.role,[0])
	plan.ids[int(slots[0])]=id
	# Rebuild any old club plan referring to the transferred identity.
	var db=League.new()
	for club in state.teams:
		if club.id==club_id: continue
		if id in state.lineups[club.id].ids: state.lineups[club.id]={"ids":db.lineup(club).map(func(player): return player.id),"rotation":0}

func list_saves() -> Array: return repository.list_saves()

func save() -> bool:
	if not active(): error="Nessuna carriera Diventa un mito aperta."; return false
	state.rng_state=str(engine.rng.state)
	var ok: bool=repository.write(int(state.slot),state)
	error=repository.error; changed.emit(); return ok

func load_career(slot: int) -> bool:
	if slot<1 or slot>12: error="Slot Diventa un mito non valido."; return false
	var loaded: Dictionary=repository.read(slot)
	if loaded.is_empty(): error=repository.error; return false
	if not _valid_loaded_state(loaded): error="Dati Diventa un mito incompatibili o non validi."; return false
	engine=Manager.new(); engine.repository=repository; engine.state=loaded; state=loaded
	state.slot=slot; engine.rng.seed=int(state.seed); engine.rng.state=int(str(state.rng_state))
	Overall.refresh_teams(state.teams); Overall.refresh(state.profile)
	_place_profile(str(state.club_id)); state.pending_fixture_id=""
	last_result=state.get("legend_last_result",{}); engine.last_result=state.get("last_result",{})
	error=""; changed.emit(); return true

func _valid_loaded_state(value: Dictionary) -> bool:
	for key in ["profile","teams","club_id","lineups","conditions","seed","rng_state","season","options","contract","skill_points","reputation","match_history","offers","rewarded_ids"]:
		if not value.has(key): return false
	var p: Dictionary=value.profile
	if str(p.get("id","")).is_empty() or str(p.get("role","")) not in ROLES or not p.get("ratings") is Dictionary: return false
	for key in STAT_KEYS:
		if not _whole_number(p.ratings.get(key,-1)) or int(p.ratings[key])<INITIAL_MIN or int(p.ratings[key])>ATTRIBUTE_CAP: return false
	return value.teams.any(func(club): return club.id==value.club_id)

func next_fixture() -> Dictionary:
	if not active() or state.complete: return {}
	# Resolve one CPU fixture at a time: a cup draw can create an earlier player
	# match while the league is advancing. Never let prepare_match simulate it.
	var next: Dictionary={}; var advanced:=false; var guard:=0
	repository.suspended=true
	while not state.complete and guard<600:
		guard+=1
		var pending: Array=engine.pending_fixtures()
		if pending.is_empty(): engine._progress(); break
		var first: Dictionary=pending[0]
		if state.club_id in [first.home,first.away]: next=first; break
		engine._advance_date(str(first.scheduled_date))
		var simulated: Dictionary=Simulation.play(engine,first)
		if simulated.is_empty() or not engine._record(first,simulated): error=engine.error; break
		advanced=true
	repository.suspended=false
	if advanced and bool(state.options.autosave): save()
	return next

func launch_config() -> Dictionary:
	error=""
	var next:=next_fixture()
	if next.is_empty(): error="La stagione è conclusa. Inizia la prossima stagione."; return {}
	repository.suspended=true
	var ready: bool=engine.prepare_match(str(next.id))
	repository.suspended=false
	if not ready: error=engine.error; return {}
	var club: Dictionary=team(str(state.club_id)); var opponent_id: String=next.away if next.home==state.club_id else next.home
	var home_lineup: Array=engine.lineup(str(next.home)); var away_lineup: Array=engine.lineup(str(next.away))
	var own_lineup: Array=home_lineup if next.home==state.club_id else away_lineup
	if not own_lineup.any(func(player): return player.id==state.profile.id): error="Il tuo giocatore non è nella formazione."; return {}
	state.pending_fixture_id=next.id
	if bool(state.options.autosave) and not save(): return {}
	return {"mode":"legend72","fixture_id":next.id,"fixture":next.duplicate(true),"player":state.profile.duplicate(true),"player_id":state.profile.id,"role":state.profile.role,"club":club.duplicate(true),"club_id":club.id,"opponent":team(opponent_id).duplicate(true),"home_club_id":next.home,"club_lineup":own_lineup,"opponent_lineup":away_lineup if next.home==state.club_id else home_lineup,"teams":[home_lineup,away_lineup],"home_team":team(str(next.home)).duplicate(true),"away_team":team(str(next.away)).duplicate(true),"best_of":engine.best_of(),"points":25,"options":state.options.duplicate(true)}

func cancel_match() -> void:
	if active(): state.pending_fixture_id=""; changed.emit()

func _performance(input: Dictionary,total_points: int,club_points: int) -> Dictionary:
	var measured: Dictionary={}; var limit:=maxi(20,total_points*3)
	for key in PERFORMANCE_KEYS:
		var value=input.get(key,0)
		if not _whole_number(value) or int(value)<0 or int(value)>limit: return {}
		measured[key]=int(value)
	var minutes=input.get("minutes",0.0)
	if not (minutes is int or minutes is float) or not is_finite(float(minutes)) or float(minutes)<0 or float(minutes)>360: return {}
	measured.minutes=float(minutes)
	if measured.kills>measured.attacks or measured.aces>measured.serves or measured.assists>measured.sets: return {}
	if measured.kills+measured.aces+measured.blocks>club_points: return {}
	return measured

func complete_match(result: Dictionary) -> bool:
	error=""
	if not active(): error="Nessuna carriera aperta."; return false
	var id: String=str(result.get("fixture_id",state.get("pending_fixture_id","")))
	var next: Dictionary=engine.next_fixture()
	if id.is_empty() or state.rewarded_ids.has(id) or next.is_empty() or str(next.id)!=id: error="Incontro già premiato o non disponibile."; return false
	if not engine._validate_result(result): error="Risultato non valido: set e punteggi devono corrispondere alla partita."; return false
	if not result.get("performance",{}) is Dictionary: error="Prestazione non valida."; return false
	var side:=0 if next.home==state.club_id else 1
	var won: bool=int(result.sets[side])>int(result.sets[1-side])
	if result.has("won") and bool(result.won)!=won: error="Esito personale e punteggio della partita non corrispondono."; return false
	var total_points:=0; var club_points:=0
	for score in result.set_scores: total_points+=int(score[0])+int(score[1]); club_points+=int(score[side])
	var performance:=_performance(result.get("performance",{}),total_points,club_points)
	if performance.is_empty(): error="Statistiche personali incoerenti con le azioni e i punti giocati."; return false
	var measured: Dictionary={"sets":result.sets.duplicate(true),"set_scores":result.set_scores.duplicate(true),"duration_minutes":performance.minutes,"players":{}}
	measured.players[state.profile.id]={"appearances":1,"sets_played":result.set_scores.size(),"points":performance.kills+performance.aces+performance.blocks,"attack_attempts":performance.attacks,"attack_kills":performance.kills,"serve_attempts":performance.serves,"aces":performance.aces,"blocks":performance.blocks,"digs":performance.digs,"receptions":performance.receptions,"sets":performance.sets}
	repository.suspended=true
	var recorded: bool=engine.record_played_result(id,measured)
	repository.suspended=false
	if not recorded: error=engine.error; return false
	var activity: int=performance.serves+performance.attacks+performance.digs+performance.receptions+performance.sets+performance.blocks
	var positive: float=performance.aces*1.2+performance.kills*.85+performance.digs*.6+performance.assists*.35+performance.blocks+performance.receptions*.18+(performance.sets-performance.assists)*.05
	var negative: float=performance.errors*1.3+(performance.attacks-performance.kills)*.1
	var rating: float=clampf(5.0+(positive-negative)/maxf(5.0,sqrt(float(activity))*1.5)+(.3 if won else 0.0),1,10) if activity>0 else 5.0
	var earned_xp:=clampi(roundi(maxf(0,(rating-4.0)*14.0+activity*.45)),0,120) if activity>0 else 0
	var old_bank: int=int(state.xp_bank); var earned_points:=int((old_bank+earned_xp)/XP_PER_POINT)
	state.xp=int(state.xp)+earned_xp; state.xp_bank=(old_bank+earned_xp)%XP_PER_POINT; state.skill_points=int(state.skill_points)+earned_points; state.level=1+int(int(state.xp)/240)
	var rep_gain:=clampf((rating-5.5)*.65+(.35 if won else 0.0),-1.5,3.0) if activity>0 else 0.0
	state.reputation=clampf(float(state.reputation)+rep_gain,0,100)
	var row: Dictionary={"fixture_id":id,"season":state.season,"season_label":state.season_label,"date":next.scheduled_date,"competition":next.competition,"club_id":state.club_id,"opponent_id":next.away if side==0 else next.home,"won":won,"rating":snappedf(rating,.1),"xp":earned_xp,"skill_points":earned_points,"reputation_gain":snappedf(rep_gain,.01),"performance":performance,"sets":result.sets.duplicate(true),"set_scores":result.set_scores.duplicate(true),"stats_source":"measured"}
	state.match_history.push_front(row); state.rewarded_ids[id]=true; state.pending_fixture_id=""; state["legend_last_result"]=row; last_result=row
	_generate_offers()
	var ok:=save() if bool(state.options.autosave) else true
	if ok: error=""; match_finished.emit(row); changed.emit()
	return ok

func attribute_cost(key: String) -> int:
	if not active() or key not in STAT_KEYS: return 0
	var value: int=int(state.profile.ratings[key])
	return 1 if value<70 else (2 if value<85 else 3)

func upgrade_attribute(key: String) -> bool:
	error=""
	if not active() or key not in STAT_KEYS: error="Attributo non valido."; return false
	if not str(state.pending_fixture_id).is_empty(): error="Completa la partita prima di allenarti."; return false
	var cost:=attribute_cost(key)
	if int(state.profile.ratings[key])>=ATTRIBUTE_CAP: error="Attributo già al massimo."; return false
	if int(state.skill_points)<cost: error="Punti abilità insufficienti."; return false
	state.skill_points=int(state.skill_points)-cost; state.profile.ratings[key]=int(state.profile.ratings[key])+1; Overall.refresh(state.profile)
	return save() if bool(state.options.autosave) else _notify()

func _notify() -> bool: changed.emit(); return true

func update_appearance(values: Dictionary) -> bool:
	error=""
	if not active(): error="Nessuna carriera aperta."; return false
	if not str(state.pending_fixture_id).is_empty(): error="Completa la partita prima di modificare l'aspetto."; return false
	for key in values:
		if key not in APPEARANCE_OPTIONS or str(values[key]) not in APPEARANCE_OPTIONS[key]: error="Opzione aspetto non valida."; return false
	state.profile.appearance.merge(values.duplicate(true),true)
	return save() if bool(state.options.autosave) else _notify()

func _generate_offers() -> void:
	# Reputation is earned only by the recorded player's actual performance.
	if state.match_history.size()<3 or float(state.reputation)<6: return
	var db=League.new(); var current_strength:=0.0
	for club in db.teams:
		if club.id==state.club_id: current_strength=_club_strength(club,db); break
	var candidates: Array=[]
	for club in db.teams:
		var strength:=_club_strength(club,db)
		if club.id==state.club_id or strength<=current_strength or strength>current_strength+2+float(state.reputation)*.65: continue
		if state.offers.any(func(offer): return offer.club_id==club.id and offer.status=="open"): continue
		candidates.append({"club":club,"strength":strength})
	candidates.sort_custom(func(a,b): return a.strength<b.strength if a.strength!=b.strength else a.club.id<b.club.id)
	var open_count: int=state.offers.filter(func(offer): return offer.status=="open").size()
	for candidate in candidates.slice(0,maxi(0,3-open_count)):
		var club: Dictionary=candidate.club
		state.offers.push_front({"id":"offer-"+str(state.season)+"-"+str(state.match_history.size())+"-"+str(club.id),"club_id":club.id,"club_name":club.name,"strength":candidate.strength,"salary":500+roundi(candidate.strength)*40+roundi(float(state.reputation)*25),"years":2,"expires_season":state.season,"created_after":state.match_history.size(),"status":"open","description":"Contratto da titolare nel ruolo scelto"})

func accept_offer(id: String) -> bool:
	error=""
	if not active(): error="Nessuna carriera aperta."; return false
	if not str(state.pending_fixture_id).is_empty(): error="Completa o lascia la partita prima di trasferirti."; return false
	var found: Array=state.offers.filter(func(offer): return str(offer.id)==id and offer.status=="open")
	if found.size()!=1: error="Offerta non disponibile."; return false
	var offer: Dictionary=found[0]
	if int(offer.expires_season)<int(state.season) or team(str(offer.club_id)).is_empty() or offer.club_id==state.club_id: error="Offerta scaduta o non valida."; return false
	# Avoid replaying dates already passed by the current club's calendar.
	var previous: String=state.club_id
	state.club_id=offer.club_id; state.contract={"club_id":offer.club_id,"signed_season":state.season,"expires_season":int(state.season)+int(offer.years)-1,"salary":offer.salary,"status":"active"}
	_place_profile(str(offer.club_id))
	state.transfer_history.push_front({"date":state.date,"season":state.season,"player_id":state.profile.id,"from":previous,"to":offer.club_id,"offer_id":id,"salary":offer.salary})
	for item in state.offers: item.status="accepted" if item.id==id else ("withdrawn" if item.status=="open" else item.status)
	return save() if bool(state.options.autosave) else _notify()

func next_season() -> bool:
	error=""
	if not active() or not state.complete: error="Completa tutte le competizioni prima della prossima stagione."; return false
	repository.suspended=true
	var advanced: bool=engine.next_season()
	repository.suspended=false
	if not advanced: error=engine.error; return false
	for offer in state.offers:
		if offer.status=="open": offer.status="expired"
	if int(state.contract.expires_season)<int(state.season):
		state.contract={"club_id":state.club_id,"signed_season":state.season,"expires_season":state.season,"salary":500+overall()*40+roundi(float(state.reputation)*20),"status":"renewed"}
	state.pending_fixture_id=""; last_result={}; state.legend_last_result={}
	_place_profile(str(state.club_id)); _generate_offers()
	return save()

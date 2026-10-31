extends RefCounted
## Two ordinary substitutions, validated as a single transaction. No rotation
## slot, trajectory, pose, or match random generator is changed here.
const Tactics=preload("res://src/tactics.gd")

static func state(manager,side: int) -> Dictionary:
	return manager.double_changes[side] if side in [0,1] else {}

static func active(manager,side: int) -> bool:
	return bool(state(manager,side).get("active",false))

static func options(manager,side: int,role: String) -> Array:
	if side not in [0,1] or role not in ["setter","opposite"]: return []
	var slot:=2 if role=="setter" else 5
	return manager.bench(side).filter(func(person): return str(person.get("role",""))==role and manager.eligibility(side,slot,str(person.id),false,false,true).is_empty())

static func pending(manager,side: int) -> bool:
	return manager.queued_changes.any(func(change): return int(change.side)==side and bool(change.get("double",false)))

static func reserved(manager,side: int) -> int:
	var count:=0
	for change in manager.queued_changes:
		if int(change.side)==side: count+=2 if bool(change.get("double",false)) else (0 if bool(change.get("exceptional",false)) else 1)
	return count

static func validate(manager,side: int,opposite: String,setter: String,returning: bool,require_dead_ball: bool=true,ignore_queue: bool=false) -> String:
	if side not in [0,1] or not manager.active or manager.completed: return "Formazione non disponibile."
	if require_dead_ball and not manager.dead_ball(): return "Le sostituzioni si effettuano a palla ferma, prima della battuta."
	if manager.between_sets: return "Il doppio cambio si effettua durante il set, dopo la prima battuta."
	var info:=state(manager,side)
	if returning:
		if not active(manager,side): return "Nessun doppio cambio da far rientrare."
		if str(manager.current[side][5])!=str(info.reserve_opposite) or str(manager.current[side][2])!=str(info.reserve_setter): return "La coppia del doppio cambio non è più in campo."
		opposite=str(info.starter_opposite); setter=str(info.starter_setter)
	else:
		if active(manager,side): return "Il doppio cambio è già attivo."
		if not Tactics.front(side*6+5,int(manager.game.rotations[side])) or Tactics.front(side*6+2,int(manager.game.rotations[side])): return "Il palleggiatore deve essere in prima linea e l'opposto in seconda linea."
		if str(manager.current[side][5])!=str(manager.starters[side][5]) or str(manager.current[side][2])!=str(manager.starters[side][2]): return "Il doppio cambio richiede entrambi i titolari in campo."
		if str(manager.identity(opposite).get("role",""))!="opposite" or str(manager.identity(setter).get("role",""))!="setter": return "Scegli un opposto e un palleggiatore di riserva."
		if opposite==setter: return "Le due riserve devono essere diverse."
	if not ignore_queue:
		for change in manager.queued_changes:
			if int(change.side)!=side: continue
			if bool(change.get("double",false)) or int(change.get("slot",-1)) in [2,5] or str(change.get("in","")) in [opposite,setter]: return "Esiste già un cambio programmato per questa coppia."
	var cost:=2 if returning else 4
	var reserved_count:=0 if ignore_queue else reserved(manager,side)
	if int(manager.counts[side])+reserved_count+cost>6: return "Servono due cambi per il rientro." if returning else "Servono quattro cambi disponibili: due all'ingresso e due al rientro."
	var first_slot:=5; var first_id:=setter if returning else opposite
	var second_slot:=2; var second_id:=opposite if returning else setter
	var reason: String=manager.eligibility(side,first_slot,first_id,false,require_dead_ball,true)
	if not reason.is_empty(): return reason
	return manager.eligibility(side,second_slot,second_id,false,require_dead_ball,true)

static func request(manager,side: int,opposite: String,setter: String,returning: bool) -> String:
	var error:=validate(manager,side,opposite,setter,returning,false)
	if not error.is_empty(): return error
	if manager.dead_ball(): return commit(manager,side,opposite,setter,returning)
	manager.queued_changes.append({"double":true,"side":side,"opposite":opposite,"setter":setter,"returning":returning,"out":[str(manager.current[side][5]),str(manager.current[side][2])]})
	manager.broadcast_management()
	return ""

static func commit(manager,side: int,opposite: String,setter: String,returning: bool) -> String:
	var error:=validate(manager,side,opposite,setter,returning,true)
	if not error.is_empty(): return error
	var info:=state(manager,side)
	var outgoing_s: String=manager.current[side][5]
	var outgoing_o: String=manager.current[side][2]
	var incoming_s:=str(info.starter_setter) if returning else opposite
	var incoming_o:=str(info.starter_opposite) if returning else setter
	# Everything that may reject the transaction has completed. Neither of
	# these commits publishes intermediate state or executes callbacks.
	manager.commit_change(side,5,incoming_s,false,"double_return" if returning else "double_entry")
	manager.commit_change(side,2,incoming_o,false,"double_return" if returning else "double_entry")
	if returning:
		manager.double_changes[side]={"active":false,"completed":true,"starter_setter":incoming_s,"starter_opposite":incoming_o}
	else:
		manager.double_changes[side]={"active":true,"setter_slot":2,"opposite_slot":5,"starter_setter":outgoing_s,"starter_opposite":outgoing_o,"reserve_setter":setter,"reserve_opposite":opposite}
	manager.sync_role_labels()
	manager.update_condition_vector()
	manager.broadcast_management()
	manager.present_change(side,5,outgoing_s,incoming_s)
	manager.present_change(side,2,outgoing_o,incoming_o)
	return ""

static func new_set(manager) -> void:
	# A new set has a new line-up. Restore the original tactical pair for
	# free rather than leaving a setter in the opposite's fixed slot.
	var restored:=false
	for side in 2:
		var info:=state(manager,side)
		if not active(manager,side): continue
		restored=true
		for replacement in [[5,str(info.starter_setter)],[2,str(info.starter_opposite)]]:
			var slot: int=replacement[0]; var id: String=replacement[1]
			manager.current[side][slot]=id
			var player=manager.game.players[side*6+slot]
			player.set_roster_identity(manager.identity(id),manager.identity(str(manager.libero_ids[side])),player.kit_identity,player.libero_kit)
	manager.double_changes=[{},{}]
	manager.queued_changes.clear()
	# If an original player was injured, use the manager's existing legal
	# pre-set repair; do not put an unavailable identity back on court.
	if restored: manager.repair_starting_squad()

static func coach(manager,side: int) -> bool:
	var game=manager.game
	if not manager.active or manager.between_sets or manager.completed or not manager.dead_ball() or pending(manager,side): return false
	if game.network_match() and game.human_team(side): return false
	if not game.cpu_team(side) and not manager.auto_subs: return false
	if game.legend_match!=null and game.legend_match.enabled() and side==0: return false
	if active(manager,side):
		# The original setter is now the front-row reserve opposite's slot.
		if not Tactics.front(side*6+5,int(game.rotations[side])):
			return commit(manager,side,"","",true).is_empty()
		return false
	if not Tactics.front(side*6+5,int(game.rotations[side])): return false
	var own: int=game.scores[side]; var other: int=game.scores[1-side]
	var finish: int=15 if game.match_best_of>1 and game.sets[0]+game.sets[1]==game.match_best_of-1 else game.match_points
	var late:=maxi(own,other)>=maxi(8,roundi(finish*.62))
	if not late or absi(own-other)>5: return false
	var setter_id: String=manager.current[side][5]
	var old_setter: Dictionary=manager.identity(setter_id)
	var setters:=options(manager,side,"setter"); var opposites:=options(manager,side,"opposite")
	setters.sort_custom(func(a,b): return float(a.ratings.get("palleggio",50))-manager.fatigue(str(a.id))*.12>float(b.ratings.get("palleggio",50))-manager.fatigue(str(b.id))*.12)
	opposites.sort_custom(func(a,b): return float(a.ratings.get("schiacciata",50))-manager.fatigue(str(a.id))*.15>float(b.ratings.get("schiacciata",50))-manager.fatigue(str(b.id))*.15)
	for reserve_s in setters:
		if float(reserve_s.ratings.get("palleggio",50))<float(old_setter.ratings.get("palleggio",50))-18: continue
		for reserve_o in opposites:
			var advantage: float=float(reserve_o.ratings.get("schiacciata",50))-float(old_setter.ratings.get("schiacciata",50))+(manager.fatigue(setter_id)-manager.fatigue(str(reserve_o.id)))*.12
			if advantage<7: continue
			if commit(manager,side,str(reserve_o.id),str(reserve_s.id),false).is_empty(): return true
	return false

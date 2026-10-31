extends SceneTree
const Manager=preload("res://src/match_management.gd")
const DoubleChange=preload("res://src/double_substitution.gd")
const Tactics=preload("res://src/tactics.gd")
var checks:=0
var failures: Array=[]

class Athlete extends RefCounted:
	var roster_identity: Dictionary={}
	var libero_identity: Dictionary={}
	var kit_identity: Dictionary={}
	var libero_kit: Dictionary={}
	var libero_active:=false
	var motion_lock:=0.0
	var reach_weight:=0.0
	var contact_scheduled:=false
	var velocity:=Vector3.ZERO
	var clip_name:="idle"
	var looping:=true
	var clips: Dictionary={}
	func set_roster_identity(person: Dictionary,libero: Dictionary,_kit: Dictionary,_libero_kit: Dictionary): roster_identity=person; libero_identity=libero

class Presentation extends RefCounted:
	var pending: Array=[]
	func cancel(): pending.clear()
	func enqueue(side: int,slot: int,outgoing: Dictionary,incoming: Dictionary): pending.append([side,slot,outgoing.id,incoming.id])

class TestGame extends RefCounted:
	var players: Array=[]
	var substitution_scene=Presentation.new()
	var started:=true
	var paused:=false
	var phase:="SERVE"
	var match_finished:=false
	var toss_active:=false
	var charging:=false
	var replay=null
	var online_session=null
	var legend_match=null
	var match_condition: Array=[]
	var rotations: Array=[3,3]
	var sets: Array=[0,0]
	var scores: Array=[0,0]
	var match_best_of:=5
	var match_points:=25
	var computer: Array=[false,true]
	var notices: Array=[]
	func _init():
		for i in 12: players.append(Athlete.new()); match_condition.append(0.0)
	func network_match(): return false
	func cpu_team(side): return computer[side]
	func human_team(side): return not computer[side]
	func notice(message): notices.append(message)

func _initialize(): call_deferred("run")
func check(condition: bool,label: String):
	checks+=1
	if not condition: failures.append(label); push_error(label)

func person(side: int,id: String,role: String,spike: int=70,set_value: int=70) -> Dictionary:
	return {"id":str(side)+id,"name":id,"role":role,"jersey_number":1,"ratings":{"generale":70,"schiacciata":spike,"palleggio":set_value,"difesa":60}}

func setup() -> Dictionary:
	var game=TestGame.new(); var manager=Manager.new(); manager.game=game
	var teams: Array=[]; var lineups: Array=[]
	for side in 2:
		var lineup: Array=[]
		for role in ["outside_hitter","middle_blocker","opposite","outside_hitter","middle_blocker","setter","libero"]:
			var slot:=lineup.size(); lineup.append(person(side,"starter"+str(slot),role,40 if role=="setter" else 80,90 if role=="setter" else 40))
		var roster:=lineup.duplicate(true)
		roster.append(person(side,"reserve_o","opposite",87,30)); roster.append(person(side,"reserve_s","setter",40,83)); roster.append(person(side,"reserve_oh","outside_hitter",74,35))
		roster.append(person(side,"reserve_mb","middle_blocker",76,40))
		roster.append(person(side,"reserve_extra","outside_hitter",72,40))
		teams.append({"roster":roster}); lineups.append(lineup)
	check(manager.configure_rosters(teams,lineups),"configure actual v66 manager")
	manager.lock_lineup()
	return {"game":game,"manager":manager,"teams":teams,"lineups":lineups}

func snapshot(manager) -> String:
	return JSON.stringify({"state":manager.export_state(),"events":manager.substitutions,"scene":manager.game.substitution_scene.pending,"rng":manager.random.state})

func run():
	var rotations: Array=[]
	for side in 2:
		for rotation in 6:
			var env:=setup(); var manager=env.manager; var game=env.game
			game.rotations[side]=rotation
			var before:=snapshot(manager)
			var error: String=manager.double_change(side,str(side)+"reserve_o",str(side)+"reserve_s")
			var should_enter:=Tactics.front(side*6+5,rotation)
			check(error.is_empty()==should_enter,"entry exact front row side %d rotation %d"%[side,rotation])
			if not should_enter: check(snapshot(manager)==before,"failed entry atomic all state + scenes + RNG")
			else:
				check(manager.counts[side]==2 and manager.substitutions.size()==2,"entry consumes two ordinary substitutions")
				check(manager.setter_slot(side)==2 and manager.opposite_slot(side)==5,"new setter and opposite role mapping")
				check(game.players[side*6+2].get_meta("tactical_role","")=="S" and game.players[side*6+5].get_meta("tactical_role","")=="OPP","actual avatars display active setter/opposite tactical labels")
				check(manager.current[side][5]==str(side)+"reserve_o" and manager.current[side][2]==str(side)+"reserve_s","reserves enter fixed original rotation slots")
				check(manager.game.substitution_scene.pending.size()==2,"one paired transaction has two existing presentations")
				game.rotations[side]=0
				check(manager.double_change(side,"","",true).is_empty(),"both original starters can return at P1")
				check(manager.counts[side]==4 and manager.current[side]==manager.starters[side],"return consumes two and restores original sextet")
				check(manager.setter_slot(side)==5 and manager.opposite_slot(side)==2,"original tactical roles restored")
				check(not game.players[side*6+2].has_meta("tactical_role") and not game.players[side*6+5].has_meta("tactical_role"),"original labels restored without persistent metadata")
				game.rotations[side]=3
				before=snapshot(manager)
				check(not manager.double_change(side,str(side)+"reserve_o",str(side)+"reserve_s").is_empty() and snapshot(manager)==before,"same starter cannot leave twice in set")
			rotations.append({"side":side,"rotation":rotation,"entry":should_enter})
			manager.free()
	# Every budget failure and the second half's invalidity must be fully atomic.
	for count in range(3,7):
		var env:=setup(); var manager=env.manager; manager.counts[0]=count
		var before:=snapshot(manager)
		check(not manager.double_change(0,"0reserve_o","0reserve_s").is_empty() and before==snapshot(manager),"requires entire entry+return budget %d"%count)
		manager.free()
	for invalid in ["missing","0reserve_oh","1reserve_s"]:
		var env:=setup(); var manager=env.manager; var before:=snapshot(manager)
		check(not manager.double_change(0,"0reserve_o",invalid).is_empty() and before==snapshot(manager),"invalid second change never commits first: "+invalid)
		manager.free()
	for unavailable in ["0reserve_s","0reserve_o"]:
		var env:=setup(); var manager=env.manager; manager.excluded.append(unavailable); var before:=snapshot(manager)
		check(not manager.double_change(0,"0reserve_o","0reserve_s").is_empty() and before==snapshot(manager),"unavailable reserve atomic: "+unavailable)
		manager.free()
	var env:=setup(); var manager=env.manager; var game=env.game
	manager.used_subs[0].append("0reserve_s"); var before:=snapshot(manager)
	check(not manager.double_change(0,"0reserve_o","0reserve_s").is_empty() and snapshot(manager)==before,"used reserve second half rejects whole pair")
	manager.used_subs[0].clear(); manager.counts[0]=2
	check(manager.double_change(0,"0reserve_o","0reserve_s").is_empty() and manager.counts[0]==4,"entry with two earlier changes still possible")
	before=snapshot(manager)
	check(not manager.substitute(0,0,"0reserve_oh").is_empty() and snapshot(manager)==before,"two return changes cannot be consumed by unrelated substitution")
	check(not manager.substitute(0,2,"0starter2").is_empty(),"cannot break active pair with an ordinary single change")
	check(manager.double_change(0,"","",true).is_empty() and manager.counts[0]==6,"return at sixth change allowed")
	manager.free()
	# If the second starter is unavailable, the first starter must not return
	# alone. Validate again immediately before applying the transaction.
	env=setup(); manager=env.manager; game=env.game
	manager.double_change(0,"0reserve_o","0reserve_s"); manager.excluded.append("0starter2")
	before=snapshot(manager)
	check(not manager.double_change(0,"","",true).is_empty() and snapshot(manager)==before,"unavailable second starter rejects the entire paired return")
	manager.free()
	env=setup(); manager=env.manager; game=env.game
	manager.double_change(0,"0reserve_o","0reserve_s")
	manager.excluded.append("0reserve_s")
	before=snapshot(manager)
	check(not manager.substitute(0,2,"0reserve_oh",true).is_empty() and snapshot(manager)==before,"exceptional pair change rejects atomically while ordinary original return is available")
	# If every ordinary candidate is unavailable, the existing exceptional
	# system may replace an injured reserve without consuming normal changes.
	manager.excluded.append("0starter2")
	check(manager.substitute(0,2,"0reserve_oh",true).is_empty() and manager.counts[0]==2,"injured active pair reserve has existing exceptional replacement at no ordinary cost")
	check(manager.double_changes[0].reserve_setter=="0reserve_oh" and manager.setter_slot(0)==2,"exceptional replacement updates actual reserve identity and preserves setter tactical slot")
	manager.excluded.erase("0starter2")
	check(manager.double_change(0,"","",true).is_empty() and manager.counts[0]==4 and manager.current[0]==manager.starters[0],"eligible original pair still returns after exceptional reserve replacement")
	manager.free()
	# Queue remains a single item; both halves revalidated at the dead ball.
	env=setup(); manager=env.manager; game=env.game; game.phase="SET"
	check(manager.request_double_change(0,"0reserve_o","0reserve_s").is_empty(),"pair can be scheduled during live rally")
	check(manager.queued_changes.size()==1 and manager.counts[0]==0 and manager.current[0]==manager.starters[0],"queued pair never partially applies")
	check(not manager.request_change(0,2,"0reserve_oh").is_empty(),"ordinary queue conflict rejects")
	game.phase="POINT"; manager.apply_queued_changes()
	check(manager.queued_changes.is_empty() and manager.counts[0]==2 and bool(manager.double_changes[0].active),"queued pair applied together at dead ball")
	game.phase="SET"; check(manager.request_double_change(0,"","",true).is_empty(),"pair return queue supported")
	game.phase="POINT"; manager.apply_queued_changes()
	check(manager.counts[0]==4 and manager.current[0]==manager.starters[0],"queued return restores both together")
	manager.free()
	env=setup(); manager=env.manager; game=env.game; game.phase="SET"
	manager.request_double_change(0,"0reserve_o","0reserve_s"); manager.excluded.append("0reserve_s")
	game.phase="POINT"; before=JSON.stringify([manager.current,manager.counts,manager.substitutions,game.substitution_scene.pending]); manager.apply_queued_changes()
	check(before==JSON.stringify([manager.current,manager.counts,manager.substitutions,game.substitution_scene.pending]) and manager.queued_changes.is_empty(),"stale injured second reserve rejects entire queued pair")
	manager.free()
	env=setup(); manager=env.manager; game=env.game; game.phase="SET"
	manager.request_double_change(0,"0reserve_o","0reserve_s")
	check(manager.request_change(0,0,"0reserve_oh").is_empty(),"unrelated ordinary substitution can share a pair queue")
	check(manager.request_change(0,1,"0reserve_mb").is_empty(),"two unrelated ordinary changes still preserve pair return budget")
	check(not manager.request_change(0,3,"0reserve_extra").is_empty(),"third queued change cannot oversubscribe paired return budget")
	game.phase="POINT"; manager.apply_queued_changes()
	check(manager.counts[0]==4 and manager.current[0][0]=="0reserve_oh" and manager.current[0][1]=="0reserve_mb" and bool(manager.double_changes[0].active),"mixed queue applies complete pair and both legal ordinary changes")
	check(manager.double_change(0,"","",true).is_empty() and manager.counts[0]==6,"mixed queue retains both sixth-substitution return rights")
	manager.free()
	# Export/import used by online and new-set repair preserve actual identities.
	env=setup(); manager=env.manager; game=env.game; manager.double_change(0,"0reserve_o","0reserve_s")
	var exported: Dictionary=manager.export_state(); var second:=setup(); second.manager.import_state(exported)
	check(second.manager.setter_slot(0)==2 and second.manager.current==manager.current and second.manager.counts==manager.counts,"management snapshot imports pair and actual setter mapping")
	check(second.game.players[2].get_meta("tactical_role","")=="S" and second.game.players[5].get_meta("tactical_role","")=="OPP","online management import applies matching tactical display labels")
	manager.finish_set([25,20]); check(manager.double_changes==[{},{}] and manager.counts==[0,0] and manager.current[0][5]=="0starter5" and manager.current[0][2]=="0starter2","new set restores original tactical slots without counting substitutions")
	check(not game.players[2].has_meta("tactical_role") and not game.players[5].has_meta("tactical_role"),"new set clears pair role metadata")
	second.manager.free(); manager.free()
	env=setup(); manager=env.manager; game=env.game; manager.double_change(0,"0reserve_o","0reserve_s")
	manager.excluded.append("0starter5"); manager.finish_set([25,20])
	check(manager.current[0][5]!="0starter5" and str(manager.identity(manager.current[0][5]).role)=="setter" and manager.setter_slot(0)==5,"new-set repair replaces injured original with an available actual setter in setter slot")
	manager.free()
	# CPU takes the pair only when useful and returns automatically on back row.
	env=setup(); manager=env.manager; game=env.game
	check(not DoubleChange.coach(manager,1),"CPU does not double sub early for no reason")
	game.scores=[19,19]; check(DoubleChange.coach(manager,1),"CPU late close score selects suitable actual reserves")
	check(manager.setter_slot(1)==2 and manager.counts[1]==2,"CPU pair starts new reserve setter")
	game.rotations[1]=0; check(DoubleChange.coach(manager,1) and manager.counts[1]==4 and manager.setter_slot(1)==5,"CPU restores both originals when original setter enters back row")
	check(not DoubleChange.coach(manager,0),"human coach is not overridden")
	manager.free()
	var report: Dictionary={"checks":checks,"failures":failures,"rotations":rotations,"atomic_entry_and_return":true,"paired_queue":true,"cpu_entry_and_return":true,"source":"v66 match_management eligibility/count/pair system"}
	FileAccess.open("res://docs/double74-core-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DOUBLE74 CORE ","PASS " if failures.is_empty() else "FAIL ",JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

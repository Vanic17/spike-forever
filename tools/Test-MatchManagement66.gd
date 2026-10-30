extends SceneTree
var signals_seen:=0
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.demo=false
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	var teams: Array=[db.teams[0],db.teams[1]]; var lineups: Array=[db.lineup(teams[0]),db.lineup(teams[1])]
	for side in 2:
		for slot in 6: g.players[side*6+slot].set_roster_identity(lineups[side][slot],lineups[side][6],kits.selection(teams[side].id,"home"),kits.selection(teams[side].id,"home",true))
	g.started=true; g.phase="SERVE"; g.toss_active=false; g.charging=false; g.rotations=[0,0]; g.scores=[0,0]; g.sets=[0,0]
	var m=g.match_management
	assert(m.configure_rosters(teams,lineups,{},{}))
	m.lock_lineup()
	var original: String=m.current[0][0]; var starter_numbers: Array=m.current[0].duplicate()
	var reserves: Array=m.bench(0).filter(func(p): return p.role!="libero")
	assert(reserves.size()>=3)
	for slot in 3:
		g.players[slot].set_libero(false)
		var player_id: String=reserves[slot].id
		assert(m.substitute(0,slot,player_id).is_empty())
		assert(str(g.players[slot].roster_identity.id)==player_id and m.counts[0]==slot*2+1)
		assert(not m.substitute(0,slot,str(reserves[(slot+1)%reserves.size()].id)).is_empty(),"A reserve must be replaced only by its paired starter")
		assert(m.substitute(0,slot,str(starter_numbers[slot])).is_empty())
		assert(not m.substitute(0,slot,player_id).is_empty(),"The starter cannot leave twice in one set")
	assert(m.counts[0]==6)
	assert(not m.substitute(0,3,str(reserves[0].id)).is_empty(),"Six ordinary substitutions is a hard cap")
	m.conditions[original].injury_until="2026-10-22"; m.injuries_enabled=true
	assert(m.substitute(0,0,str(reserves[0].id),true).is_empty(),"Injury permits exceptional replacement after ordinary options are exhausted")
	assert(m.counts[0]==6 and original in m.excluded)
	m.start_set(); assert(m.counts==[0,0]); m.lock_lineup()
	assert(not m.substitute(0,0,original).is_empty(),"An exceptionally replaced injured player cannot re-enter the match")
	g.players[4].set_libero(true)
	assert(not m.substitute(0,4,str(reserves[1].id)).is_empty(),"The libero's regular replacement cannot be substituted while off court")
	var before: Array=g.rotations.duplicate(); var layout: Array=m.current[0].duplicate()
	g.phase="ATTACK"; assert(not m.substitute(0,1,str(reserves[1].id)).is_empty()); assert(m.current[0]==layout and g.rotations==before)
	g.phase="SERVE"; m.injuries_enabled=false; m.fatigue_enabled=false
	for id in m.conditions: m.conditions[id].fatigue=100
	var state: int=g.rng.state
	assert(m.quality(0,.95)==.95 and m.precision(0,.7)==.7 and m.risk(0)==0)
	var active_id: String=m.actor_id(0)
	m.conditions[active_id].form=5; assert(m.quality(0,.50)==.50)
	m.career_form=true; assert(is_equal_approx(m.quality(0,.50),.51))
	m.conditions[active_id].form=-5; assert(is_equal_approx(m.quality(0,.50),.49))
	m.career_form=false; assert(m.quality(0,.50)==.50)
	m.tick(30); m.touch(0,"attack"); assert(g.rng.state==state and m.fatigue(m.actor_id(0))==100)
	m.fatigue_enabled=true
	assert(m.quality(0,.95)>.92 and m.quality(0,.95)<.95 and m.precision(0,.7)>.66 and m.risk(0)<=.035001)
	var exported: Dictionary=m.export_state(); m.counts=[3,4]; m.import_state(exported); assert(m.counts==exported.counts)
	# Finish an actual game through the existing authoritative scoring path.
	m.configure_rosters(teams,lineups,{}, {"fatigue":false,"injuries":false})
	m.match_completed.connect(func(_result): signals_seen+=1)
	g.phase="SERVE"; g.scores=[14,0]; g.sets=[0,0]; g.match_best_of=1; g.match_points=15
	m.touch(0,"attack"); g.award(0,"PALLA A TERRA")
	assert(signals_seen==1 and m.last_result.set_scores==[[15,0]] and m.last_result.sets==[1,0])
	assert(m.last_result.players[str(lineups[0][0].id)].attack_kills==1)
	assert(m.last_result.players[str(lineups[0][0].id)].receptions==0,"No invented receptions")
	g.award(0,"DUPLICATE"); assert(signals_seen==1)
	FileAccess.open("res://docs/match66-management.json",FileAccess.WRITE).store_string(JSON.stringify({"six_substitutions":true,"paired_reentry":true,"new_set_reset":true,"libero_separate":true,"exceptional_injury":true,"identity_propagation":true,"live_ball_rejected":true,"fatigue_off_neutral":true,"moderate_caps":true,"measured_result_once":true,"rule_source":m.RULE_SOURCE},"  "))
	print("MATCH MANAGEMENT66 PASS six substitutions / pair re-entry / libero / exceptional injury / live ball gate / fatigue OFF exact neutral / measured result")
	g.free(); quit()

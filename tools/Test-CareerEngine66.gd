extends SceneTree
const Manager=preload("res://src/career_manager.gd")
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	if not ok: failures+=1; push_error("CAREER ENGINE66 FAIL "+message)
func run():
	var m=Manager.new(); var db=load("res://src/league.gd").new()
	check(m.new_career(db.teams[0].id,{"seed":66016,"autosave":false},12),m.error)
	check(m.state.fixtures.size()==134,"132 untouched official fixtures plus two supercup semifinals")
	check(m.state.results.is_empty(),"No real results imported")
	check(m.save(),"Initial atomic save")
	var clone=Manager.new(); check(clone.load_career(12),clone.error)
	var first_copy: Dictionary=clone.simulate_next(); var first_original: Dictionary=m.simulate_next()
	check(JSON.stringify(first_copy)==JSON.stringify(first_original),"Saved RNG state reproduces exactly the same next match")
	var rows: Array=[]
	for season in 10:
		var guard:=0
		while not m.state.complete and guard<400:
			guard+=1
			var result: Dictionary=m.simulate_next()
			check(not result.is_empty(),"Stalled year="+str(m.state.season)+" error="+m.error+" competitions="+str(m.state.competitions))
		check(m.state.complete,"Season completed")
		check(m.state.results.size()==m.state.fixtures.size(),"Every generated match played exactly once")
		check(m.state.results.size()==m.state.played_ids.size(),"No duplicate result aggregation")
		check(m.standings().all(func(r): return r.played==22),"22 regular-season games for every club")
		check(m.state.competitions.values().all(func(c): return not str(c.champion).is_empty()),"All competition champions known")
		check(not str(m.state.competitions.playout.last).is_empty(),"Last Play Out team known")
		check(m.state.archives.size()==season+1,"One immutable archive per season")
		check(m.state.archives[-1].relegations.is_empty(),"No effective relegation")
		for id in m.state.player_stats:
			var s: Dictionary=m.state.player_stats[id]
			check(int(s.get("attack_kills",0))<=int(s.get("attack_attempts",0)),"Attack statistics coherent")
			check(int(s.get("reception_perfect",0))<=int(s.get("reception_positive",0)) and int(s.get("reception_positive",0))<=int(s.get("receptions",0)),"Reception fractions coherent")
		rows.append({"season":m.state.season_label,"matches":m.state.results.size(),"champions":m.state.archives[-1].champions,"playout_teams":m.state.competitions.playout.participants.size(),"fifth_mode":m.state.competitions.fifth.mode})
		print("CAREER ENGINE66 season=",m.state.season," matches=",m.state.results.size()," fifth=",m.state.competitions.fifth.mode)
		if season<9: check(m.next_season(),m.error)
	check(m.save(),m.error)
	var loaded=Manager.new(); check(loaded.load_career(12),loaded.error)
	check(JSON.stringify(JSON.parse_string(JSON.stringify(loaded.state)))==JSON.stringify(JSON.parse_string(JSON.stringify(m.state))),"Save/reload preserves complete ten-season career")
	# Deliberate corruption must recover the previously committed backup.
	check(m.save(),m.error)
	FileAccess.open(m.repository.path(12),FileAccess.WRITE).store_string("corrupted test fixture")
	check(loaded.load_career(12) and loaded.repository.recovered_backup,"Checksummed backup recovery")
	# A replayed MatchResult never adds duplicate totals.
	var first: Dictionary=loaded.state.fixtures[0]
	check(not loaded.record_played_result(first.id,first.result),"Double-count prevention")
	FileAccess.open("res://docs/career66-engine.json",FileAccess.WRITE).store_string(JSON.stringify({"seasons":rows,"save_reload":true,"backup_recovery":true,"duplicate_guard":true,"initial_results_empty":true},"  "))
	print("CAREER ENGINE66 ","PASS" if failures==0 else "FAIL"," ten complete seasons / competitions / deterministic archives / atomic save / backup / no duplicate stats")
	quit(1 if failures else 0)

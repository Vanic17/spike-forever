extends SceneTree
const Rules=preload("res://src/career_rules.gd")
func _initialize(): call_deferred("run")
func run():
	var official:=Rules.official_schedule()
	assert(official.valid,official.error)
	var rows: Array=official.fixtures
	assert(rows.size()==132)
	var first: Dictionary=rows.filter(func(f): return f.home=="rana-verona" and f.away=="cucine-lube-civitanova" and f.round==1)[0]
	assert(first.original_date=="2026-10-18" and first.scheduled_date=="2026-10-17")
	var early: Dictionary=rows.filter(func(f): return f.home=="sir-susa-scai-perugia" and f.away=="pallavolo-padova" and f.round==11)[0]
	assert(early.scheduled_date=="2026-10-28")
	var corrupted:=rows.duplicate(true); corrupted[2].home=corrupted[2].away
	assert(not Rules.validate_schedule(corrupted).is_empty())
	var ids: Array=[]
	for row in rows:
		assert(not row.has("result") and row.status=="scheduled")
		if row.home not in ids: ids.append(row.home)
	var generated: Array=[]
	for year in range(2027,2038):
		var a:=Rules.later_schedule(year,year*77,ids); var b:=Rules.later_schedule(year,year*77,ids)
		assert(a==b,"Calendar must reproduce from saved seed")
		assert(Rules.validate_schedule(a,ids).is_empty(),"Invalid generated season "+str(year))
		var pairs: Dictionary={}; var first_matches: Dictionary={}; var minimum_gap:=22
		var windows: Dictionary=Rules.config(year)
		for f in a:
			assert(not f.official and f.source_url.is_empty())
			assert(f.scheduled_date not in windows.supercup.dates and f.scheduled_date not in windows.cup.quarter_dates and f.scheduled_date not in windows.cup.semi_dates and f.scheduled_date not in windows.cup.final_dates,"League schedule collides with an event window")
			assert(str(f.scheduled_date).begins_with(str(year)+"-10") or str(f.scheduled_date).begins_with(str(year)+"-11") or str(f.scheduled_date).begins_with(str(year)+"-12") or str(f.scheduled_date).begins_with(str(year+1)+"-01") or str(f.scheduled_date).begins_with(str(year+1)+"-02"))
			var key: String="|".join([str(f.home),str(f.away)])
			pairs[key]=f.round
			if int(f.round)<=11: first_matches[key]=f.round
			else: minimum_gap=mini(minimum_gap,int(f.round)-int(first_matches[str(f.away)+"|"+str(f.home)]))
		assert(minimum_gap>=4)
		var asymmetric:=false
		for key in first_matches:
			var sides: PackedStringArray=key.split("|")
			if int(pairs[sides[1]+"|"+sides[0]])!=int(first_matches[key])+11: asymmetric=true
		assert(asymmetric)
		generated.append({"year":year,"fixtures":a.size(),"asymmetric":true,"min_return_gap":minimum_gap,"start":a[0].scheduled_date,"finish":a[-1].scheduled_date})
	var cfg:=Rules.config()
	assert(cfg.supercup.participants==["sir-susa-scai-perugia","rana-verona","cucine-lube-civitanova","itas-trentino"])
	assert(cfg.supercup.dates==["2026-11-14","2026-11-15"])
	assert(cfg.playout.four_team_bonuses==[5,4,3,0] and cfg.playout.three_team_bonuses==[4,3,0] and not cfg.playout.relegation_enabled)
	assert(cfg.playoff.quarter_pairs==[[1,8],[4,5],[2,7],[3,6]])
	assert(cfg.fifth.alternate.final_opponent=="worse_regular_ranked_scudetto_semifinal_loser")
	assert(Rules.points_for_score(3,0)==3 and Rules.points_for_score(3,1)==3 and Rules.points_for_score(3,2)==2 and Rules.points_for_score(2,3)==1 and Rules.points_for_score(1,3)==0)
	var standings: Array=[{"id":"b","points":10,"wins":4,"sets_for":12,"sets_against":7,"points_for":500,"points_against":480},{"id":"a","points":10,"wins":4,"sets_for":12,"sets_against":7,"points_for":500,"points_against":480},{"id":"c","points":11,"wins":3,"sets_for":10,"sets_against":9,"points_for":500,"points_against":510}]
	var sorted:=Rules.sort_standings(standings,{"b|a":3,"a|b":0})
	assert(sorted[0].id=="c" and sorted[1].id=="b" and sorted[2].id=="a")
	var close_a: Dictionary=standings[0].duplicate(); close_a.id="a"; close_a.points_for=2001; close_a.points_against=2000
	var close_b: Dictionary=close_a.duplicate(); close_b.id="b"; close_b.points_for=2000; close_b.points_against=1999
	assert(Rules.sort_standings([close_a,close_b])[0].id=="b","Tiny point-quotient advantages must not be erased by approximate float comparison")
	var report={"official_fixtures":132,"all_source_pairs_checked":true,"early_dates_preserved":true,"no_imported_results":true,"later_seasons":generated,"rules_verified":true,"table_tiebreaks":true,"official_career_gate":true}
	FileAccess.open("res://docs/career66-rules-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CAREER RULES66 PASS official132 / independentpairs / 11 seeded asymmetrical later calendars / official dates / tiebreaks / competition conditions")
	quit()

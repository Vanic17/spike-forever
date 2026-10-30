extends RefCounted
## Official first season is immutable/imported; later dates are simulated.
const SCHEDULE="res://data/competitions/superlega_2026_27.json"
const TUPLES="res://data/competitions/superlega_2026_27_source_tuples.json"
const CONFIG="res://data/competitions/rules_2026_27.json"
const DAY=86400

static func _integral_numbers(value):
	if value is Dictionary:
		for key in value: value[key]=_integral_numbers(value[key])
	elif value is Array:
		for i in value.size(): value[i]=_integral_numbers(value[i])
	elif value is float and value==floor(value): return int(value)
	return value

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value=JSON.parse_string(FileAccess.get_file_as_string(path))
	return _integral_numbers(value) if value is Dictionary else {}

static func validate_schedule(fixtures: Array,team_ids: Array=[]) -> String:
	if fixtures.size()!=132: return "Calendario incompleto: servono 132 incontri verificati."
	var rounds: Dictionary={}; var pairs: Dictionary={}; var homes: Dictionary={}; var aways: Dictionary={}; var ids: Dictionary={}
	for f in fixtures:
		if not f is Dictionary: return "Incontro non valido."
		for key in ["id","home","away","round","original_date","scheduled_date","kickoff_time"]:
			if not f.has(key): return "Incontro privo del campo "+key
		if f.home==f.away or int(f.round)<1 or int(f.round)>22: return "Abbinamento o giornata non valido."
		if not team_ids.is_empty() and (f.home not in team_ids or f.away not in team_ids): return "Squadra sconosciuta nel calendario."
		var pair: String=str(f.home)+"|"+str(f.away)
		if pairs.has(pair) or ids.has(str(f.id)): return "Incontro duplicato nel calendario."
		pairs[pair]=true; ids[str(f.id)]=true
		if not rounds.has(int(f.round)): rounds[int(f.round)]=[]
		if f.home in rounds[int(f.round)] or f.away in rounds[int(f.round)]: return "Due incontri della stessa squadra nella medesima giornata."
		rounds[int(f.round)].append(f.home); rounds[int(f.round)].append(f.away)
		homes[f.home]=int(homes.get(f.home,0))+1; aways[f.away]=int(aways.get(f.away,0))+1
	if homes.size()!=12 or aways.size()!=12 or rounds.size()!=22: return "Numero di squadre o giornate non valido."
	for club in homes:
		if homes[club]!=11 or aways.get(club,0)!=11: return "Il calendario non contiene 11 gare in casa e 11 fuori per squadra."
	for group in rounds.values():
		if group.size()!=12: return "Giornata incompleta."
	return ""

static func official_schedule() -> Dictionary:
	var data:=_read(SCHEDULE); var source:=_read(TUPLES)
	if not data.get("verified",false) or not data.get("official",false): return {"valid":false,"error":"Calendario ufficiale 2026/27 non importato o non verificato.","fixtures":[]}
	var fixtures: Array=data.get("fixtures",[])
	var error:=validate_schedule(fixtures)
	if not error.is_empty(): return {"valid":false,"error":error,"fixtures":[]}
	var tuples: Array=source.get("tuples",[])
	if tuples.size()!=132: return {"valid":false,"error":"Manca la verifica indipendente dei 132 abbinamenti.","fixtures":[]}
	var expected: Dictionary={}
	for row in tuples: expected[str(int(row[0]))+"|"+str(row[1])+"|"+str(row[2])]=true
	for f in fixtures:
		if not expected.has(str(int(f.round))+"|"+str(f.home)+"|"+str(f.away)): return {"valid":false,"error":"Calendario diverso dagli abbinamenti verificati.","fixtures":[]}
		if f.get("source_url","").is_empty() or f.get("verified_at","").is_empty() or f.get("status","")!="scheduled" or f.has("result"): return {"valid":false,"error":"Provenienza mancante o risultato reale preassegnato.","fixtures":[]}
	return {"valid":true,"error":"","fixtures":fixtures.duplicate(true),"sources":data.sources,"season":data.season,"official":true}

static func stamp(value: String) -> int: return int(Time.get_unix_time_from_datetime_string(value))
static func date_string(value: int) -> String: return Time.get_date_string_from_unix_time(value)
static func add_days(value: String,days: int) -> String: return date_string(stamp(value)+days*DAY)
static func _weekday(value: int) -> int: return int(Time.get_datetime_dict_from_unix_time(value).weekday)
static func _first_weekday(year: int,month: int,weekday: int) -> int:
	var first:=stamp("%04d-%02d-01"%[year,month])
	return first+posmod(weekday-_weekday(first),7)*DAY
static func _last_weekday(year: int,month: int,weekday: int) -> int:
	var next:=stamp("%04d-%02d-01"%[year+1 if month==12 else year,1 if month==12 else month+1])-DAY
	return next-posmod(_weekday(next)-weekday,7)*DAY
static func _dates(base: int,offsets: Array) -> Array:
	var result: Array=[]
	for offset in offsets: result.append(date_string(base+int(offset)*DAY))
	return result

static func config(year: int=2026) -> Dictionary:
	var value:=_read(CONFIG)
	if not value.is_empty():
		value.cup.semi_dates=[value.cup.semi_date]; value.cup.final_dates=[value.cup.final_date]
		value.fifth.challenge_dates=value.fifth.alternate_final_dates.duplicate()
	if value.is_empty() or year==2026: return value
	value.season="%d/%02d"%[year,(year+1)%100]; value.official=false; value.verified_at=""
	var next:=year+1; var march:=_first_weekday(next,3,0); var semi:=march+28*DAY
	value.playoff.quarter_dates=_dates(march,[0,7,10,14,21]); value.playoff.semi_dates=_dates(semi,[0,3,7,14,21]); value.playoff.final_dates=_dates(semi+24*DAY,[0,4,7,10,13])
	value.playout.dates=_dates(march+7*DAY,[0,7,14,21,28,35])
	value.fifth.semi_dates=_dates(semi,[0,3,7]); value.fifth.final_dates=_dates(semi,[14,21,24]); value.fifth.group_dates=_dates(semi,[0,3,7,14,21,24]); value.fifth.alternate_final_dates=_dates(semi,[27,30,35])
	value.fifth.alternate.group_dates=value.fifth.group_dates.duplicate(); value.fifth.alternate.final_dates=value.fifth.alternate_final_dates.duplicate()
	var cup_final:=_first_weekday(next,2,0)
	value.cup.quarter_dates=["%d-12-30"%year]; value.cup.semi_date=date_string(cup_final-DAY); value.cup.final_date=date_string(cup_final)
	value.cup.semi_dates=[value.cup.semi_date]; value.cup.final_dates=[value.cup.final_date]; value.fifth.challenge_dates=value.fifth.alternate_final_dates.duplicate()
	var super_final:=_first_weekday(year,11,0)+7*DAY
	value.supercup.dates=_dates(super_final,[-1,0]); value.supercup.participants=[]; value.supercup.pairs=[]; value.supercup.venue="Campo neutro · calendario simulato"
	return value

static func later_schedule(year: int,seed_value: int,team_ids: Array) -> Array:
	if team_ids.size()!=12: return []
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
	var ring:=team_ids.duplicate()
	for i in range(11,0,-1):
		var j:=rng.randi_range(0,i); var swap=ring[i]; ring[i]=ring[j]; ring[j]=swap
	var rounds: Array=[]
	for round_no in 11:
		var pairs: Array=[]
		for i in 6:
			var a=ring[i]; var b=ring[11-i]
			pairs.append([a,b] if (round_no+i)%2==0 else [b,a])
		rounds.append(pairs)
		var last=ring.pop_back(); ring.insert(1,last)
	var dates: Array=[]
	var first:=stamp("%d-10-15"%year); first+=posmod(-_weekday(first),7)*DAY
	var last_sunday:=_last_weekday(year+1,2,0)
	var cfg:=config(year); var skip: Array=[stamp(cfg.supercup.dates[1]),stamp(cfg.cup.final_date),stamp(cfg.cup.quarter_dates[0])]
	for day in range(first,last_sunday+1,7*DAY):
		if day not in skip: dates.append(day)
	for midweek in [_first_weekday(year,11,3),_first_weekday(year,12,3),_first_weekday(year+1,1,3)+7*DAY,_last_weekday(year+1,2,3)]: dates.append(midweek)
	# Some years have only nineteen Sundays in the October-February window.
	# Add a credible midweek round instead of dropping a league fixture.
	for extra in [_last_weekday(year,11,3),_first_weekday(year,12,3)+14*DAY,_last_weekday(year+1,1,3)]:
		if dates.size()<22 and extra not in dates: dates.append(extra)
	dates.sort()
	if dates.size()!=22: return []
	var offset:=rng.randi_range(4,7); var fixtures: Array=[]
	for round_no in 22:
		var source_round: int=round_no if round_no<11 else posmod(round_no-11+offset,11)
		for pair in rounds[source_round]:
			var home=pair[0] if round_no<11 else pair[1]; var away=pair[1] if round_no<11 else pair[0]
			var d:=date_string(dates[round_no]); var number:=fixtures.size()+1
			fixtures.append({"id":"sl%d-%03d"%[year,number],"competition":"regular","round":round_no+1,"home":home,"away":away,"original_date":d,"scheduled_date":d,"kickoff_time":"18:00" if _weekday(dates[round_no])==0 else "20:30","source_url":"","verified_at":"","official":false,"status":"scheduled","seed":seed_value})
	return fixtures

static func points_for_score(sets_for: int,sets_against: int) -> int:
	var winning_sets:=maxi(sets_for,sets_against)
	if winning_sets not in [2,3]: return 0
	var deciding:=mini(sets_for,sets_against)==winning_sets-1
	return (2 if deciding else 3) if sets_for>sets_against else (1 if deciding else 0)

static func ratio(numerator: float,denominator: float) -> float:
	return numerator/denominator if denominator>0 else (1000000.0 if numerator>0 else 0.0)

static func _ratio_compare(n_a: int,d_a: int,n_b: int,d_b: int) -> int:
	# Exact integer cross-products: close point quotients can differ by less
	# than is_equal_approx's tolerance and still determine a legal ranking.
	if d_a==0 or d_b==0:
		var a:=ratio(n_a,d_a); var b:=ratio(n_b,d_b)
		return 0 if a==b else (1 if a>b else -1)
	var left:=n_a*d_b; var right:=n_b*d_a
	return 0 if left==right else (1 if left>right else -1)

static func _primary_compare(a: Dictionary,b: Dictionary) -> int:
	for key in ["points","wins"]:
		if int(a.get(key,0))!=int(b.get(key,0)): return 1 if int(a.get(key,0))>int(b.get(key,0)) else -1
	for pair in [["sets_for","sets_against"],["points_for","points_against"]]:
		var comparison:=_ratio_compare(int(a.get(pair[0],0)),int(a.get(pair[1],0)),int(b.get(pair[0],0)),int(b.get(pair[1],0)))
		if comparison!=0: return comparison
	return 0

static func sort_standings(rows: Array,head_to_head: Dictionary={}) -> Array:
	var result:=rows.duplicate(true)
	var direct_totals: Dictionary={}
	for a in result:
		var id: String=str(a.get("team_id",a.get("id",""))); direct_totals[id]=0
		for b in result:
			var other: String=str(b.get("team_id",b.get("id","")))
			if id!=other and _primary_compare(a,b)==0: direct_totals[id]+=int(head_to_head.get(id+"|"+other,0))
	result.sort_custom(func(a,b):
		var primary:=_primary_compare(a,b)
		if primary!=0: return primary>0
		var a_id: String=str(a.get("team_id",a.get("id",""))); var b_id: String=str(b.get("team_id",b.get("id","")))
		if direct_totals[a_id]!=direct_totals[b_id]: return direct_totals[a_id]>direct_totals[b_id]
		return a_id<b_id)
	for i in result.size():
		result[i].position=i+1; result[i].set_ratio=ratio(float(result[i].get("sets_for",0)),float(result[i].get("sets_against",0))); result[i].point_ratio=ratio(float(result[i].get("points_for",0)),float(result[i].get("points_against",0)))
	return result

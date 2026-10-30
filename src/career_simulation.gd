extends RefCounted
## Estimated match events use one seeded RNG and the same MatchResult schema as play.
const KEYS=["appearances","sets_played","points","attack_attempts","attack_kills","aces","serve_attempts","serve_errors","blocks","receptions","reception_positive","reception_perfect","digs","sets","mvp"]
static func empty_stats() -> Dictionary:
	var row: Dictionary={}
	for key in KEYS: row[key]=0
	return row
static func _inc(rows: Dictionary,id: String,key: String,amount: int=1) -> void:
	if not rows.has(id): rows[id]=empty_stats()
	rows[id][key]=int(rows[id].get(key,0))+amount
static func _choose(manager,squad: Array,weights: Dictionary,skill: String="") -> String:
	var total:=0.0; var choices: Array=[]
	for p in squad:
		var w: float=weights.get(p.get("assigned_role",p.role),1.0)
		if manager.state.options.use_player_stats and not skill.is_empty(): w*=.55+float(p.ratings.get(skill,85))/100.0
		choices.append([p.id,w]); total+=w
	var roll: float=manager.rng.randf()*total
	for pair in choices:
		roll-=float(pair[1])
		if roll<=0: return str(pair[0])
	return str(choices[-1][0])
static func strength(manager,squad: Array) -> float:
	var total:=0.0
	for p in squad:
		var value:=85.0
		if manager.state.options.use_player_stats:
			value=0
			for key in ["battuta","ricezione","difesa","palleggio","schiacciata","muro"]: value+=float(p.ratings.get(key,85))/6.0
		var condition: Dictionary=manager.player_condition(p.id)
		if manager.state.options.fatigue: value*=1.0-.085*pow(float(condition.fatigue)/100,1.65)
		value+=float(condition.form)*.24
		total+=value
	return total/maxi(1,squad.size())
static func play(manager,fixture: Dictionary) -> Dictionary:
	var teams: Array=[manager.lineup(fixture.home),manager.lineup(fixture.away)]
	if teams[0].size()!=7 or teams[1].size()!=7: return {}
	var strengths: Array=[strength(manager,teams[0])+(0.0 if fixture.get("neutral",false) else 1.8),strength(manager,teams[1])]
	var base: float=clampf(.5+(strengths[0]-strengths[1])*.009,.27,.73)
	var players: Dictionary={}; var sets: Array=[0,0]; var set_scores: Array=[]
	var team_stats: Array=[{"aces":0,"blocks":0,"errors":0},{"aces":0,"blocks":0,"errors":0}]
	var duration:=0.0; var total_points:=0
	var detailed: bool=manager.state.options.simulation_detail in [1,"detailed","dettagliata"]
	var point_log: Array=[]
	while maxi(sets[0],sets[1])<3:
		var points: Array=[0,0]; var target:=15 if set_scores.size()==4 else 25
		var serving: int=manager.rng.randi_range(0,1)
		var shape: float=manager.rng.randf_range(-.075,.075)
		for squad in teams:
			for p in squad: _inc(players,p.id,"sets_played")
		while maxi(points[0],points[1])<target or absi(points[0]-points[1])<2:
			var winner:=0 if manager.rng.randf()<clampf(base+shape,.22,.78) else 1
			var loser:=1-winner; var reason: float=manager.rng.randf()
			var action:="error"
			var server: String=_choose(manager,teams[serving].slice(0,6),{"setter":1,"outside_hitter":1,"opposite":1,"middle_blocker":1},"battuta")
			_inc(players,server,"serve_attempts")
			var passer: String=_choose(manager,teams[1-serving],{"libero":4.0,"outside_hitter":2.2,"opposite":.12,"setter":.07,"middle_blocker":.12},"ricezione")
			_inc(players,passer,"receptions")
			var positive: bool=manager.rng.randf()<.70
			if positive: _inc(players,passer,"reception_positive")
			if positive and manager.rng.randf()<.54: _inc(players,passer,"reception_perfect")
			if reason<.055 and winner==serving:
				action="ace"
				_inc(players,server,"aces"); _inc(players,server,"points"); team_stats[winner].aces+=1
			elif reason<.11:
				action="block"
				var blocker: String=_choose(manager,teams[winner].slice(0,6),{"middle_blocker":3,"outside_hitter":1.3,"opposite":1.6,"setter":.8},"muro")
				_inc(players,blocker,"blocks"); _inc(players,blocker,"points"); team_stats[winner].blocks+=1
				var hitter: String=_choose(manager,teams[loser].slice(0,6),{"outside_hitter":3,"opposite":3.5,"middle_blocker":1.8,"setter":.05},"schiacciata")
				_inc(players,hitter,"attack_attempts")
			elif reason<.78:
				action="attack"
				var hitter: String=_choose(manager,teams[winner].slice(0,6),{"outside_hitter":3,"opposite":3.5,"middle_blocker":1.8,"setter":.05},"schiacciata")
				_inc(players,hitter,"attack_attempts"); _inc(players,hitter,"attack_kills"); _inc(players,hitter,"points")
				var setter: String=_choose(manager,teams[winner],{"setter":20,"libero":2,"outside_hitter":.1,"opposite":.1,"middle_blocker":.1},"palleggio")
				_inc(players,setter,"sets")
				# Estimated rallies often contain a defended attack before the
				# winning swing. Counting only the final kill yielded implausible
				# 90% attack percentages despite correct total scoring.
				if manager.rng.randf()<.66:
					var other_hitter: String=_choose(manager,teams[loser].slice(0,6),{"outside_hitter":3,"opposite":3.5,"middle_blocker":1.8,"setter":.05},"schiacciata")
					_inc(players,other_hitter,"attack_attempts")
					var digger: String=_choose(manager,teams[winner],{"libero":4,"outside_hitter":2,"opposite":1,"middle_blocker":.4,"setter":1.0},"difesa")
					_inc(players,digger,"digs")
				if manager.rng.randf()<.28: _inc(players,hitter,"attack_attempts")
				if manager.rng.randf()<.5:
					var defender: String=_choose(manager,teams[loser],{"libero":4,"outside_hitter":2,"opposite":1,"middle_blocker":.4,"setter":1.0},"difesa")
					_inc(players,defender,"digs")
			else:
				team_stats[loser].errors+=1
				if loser==serving and manager.rng.randf()<.45: _inc(players,server,"serve_errors")
			points[winner]+=1; serving=winner; total_points+=1
			if detailed: point_log.append({"set":set_scores.size()+1,"score":points.duplicate(),"winner":fixture.home if winner==0 else fixture.away,"action":action})
		var winner:=0 if points[0]>points[1] else 1
		sets[winner]+=1; set_scores.append(points)
		duration+=float(points[0]+points[1])*.29+manager.rng.randf_range(3.5,5.5)
	var mvp:=""; var best:=-INF
	for id in players:
		players[id].appearances=1
		var score: float=players[id].points+players[id].digs*.16+players[id].sets*.06
		if score>best: best=score; mvp=id
	if not mvp.is_empty(): players[mvp].mvp=1
	return {"fixture_id":fixture.id,"home":fixture.home,"away":fixture.away,"winner":fixture.home if sets[0]>sets[1] else fixture.away,"sets":sets,"set_scores":set_scores,"players":players,"team_stats":team_stats,"duration_minutes":snappedf(duration,.1),"mvp":mvp,"stats_source":"estimated","source":"simulated","total_points":total_points,"point_log":point_log,"simulation_detail":"detailed" if detailed else "quick"}

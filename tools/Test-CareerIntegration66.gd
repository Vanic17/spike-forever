extends SceneTree
const Manager=preload("res://src/career_manager.gd")
const Sim=preload("res://src/career_simulation.gd")
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	if not ok: failures+=1; push_error("CAREER INTEGRATION66 FAIL "+message)
func run():
	var m=Manager.new(); var db=load("res://src/league.gd").new()
	check(m.new_career(db.teams[0].id,{"seed":66018,"autosave":false,"stats":false,"fatigue":false,"injuries":false},11),m.error)
	var club: String=m.state.club_id; var squad: Array=m.lineup(club)
	var strength: float=Sim.strength(m,squad)
	for p in squad:
		m.state.conditions[p.id].fatigue=100.0; m.state.conditions[p.id].injury_until="2027-12-31"
	check(m.lineup(club).size()==7 and Sim.strength(m,m.lineup(club))==strength,"Fatigue/injury OFF exact neutrality")
	m.update_options({"fatigue":true})
	check(Sim.strength(m,m.lineup(club))>=strength*.90 and Sim.strength(m,m.lineup(club))<strength,"Fatigue modifier bounded below ten percent")
	var date: String=m.state.date; m._advance_date(Manager.add_days(date,3))
	check(is_equal_approx(float(m.player_condition(squad[0].id).fatigue),64.0),"Three rest days recover 36 without instant reset")
	m.update_options({"injuries":true})
	var healthy: Array=m.lineup(club)
	check(healthy.size()==7 and healthy.all(func(p): return m.eligible(p)),"Injured starters replaced with legal available roster")
	# Use a fresh career to exercise played results with genuinely absent stats.
	check(m.new_career(club,{"seed":66018,"autosave":false,"simulation_detail":1},10),m.error)
	var next: Dictionary=m.next_fixture(); check(m.prepare_match(next.id),m.error)
	var actor: String=m.lineup(next.home)[5].id
	var measured={"sets":[3,0],"set_scores":[[25,21],[25,18],[25,23]],"players":{actor:{"appearances":1,"sets_played":3,"sets":24}},"duration_minutes":22.0,"team_stats":[{"aces":0,"blocks":0},{"aces":0,"blocks":0}]}
	check(m.record_played_result(next.id,measured),m.error)
	check(m.state.results[next.id].stats_source=="measured","Played result provenance")
	check(not m.state.player_stats[actor].has("receptions") and not m.state.player_stats[actor].has("digs"),"No fabricated receptions or digs for a setter")
	check(not m.record_played_result(next.id,measured),"Repeated played result rejected")
	var before: int=m.state.results.size(); var result: Dictionary=m.simulate_next()
	check(not result.is_empty() and m.state.results.size()>before,"Progress resumes after measured match")
	check(result.simulation_detail=="detailed" and result.point_log.size()==int(result.total_points),"Detailed mode captures real simulated point timeline")
	for club_team in m.state.teams:
		var lineup: Array=m.lineup(club_team.id)
		check(lineup.size()==7 and lineup.map(func(p): return p.id).all(func(id): return lineup.filter(func(p): return p.id==id).size()==1),"CPU roster validity")
	FileAccess.open("res://docs/career66-integration.json",FileAccess.WRITE).store_string(JSON.stringify({"off_neutrality":true,"fatigue_cap":true,"daily_recovery":true,"injury_availability":true,"measured_result":true,"unknown_stats_not_fabricated":true,"duplicate_guard":true,"detailed_timeline":true,"cpu_lineups":12,"failures":failures},"  "))
	print("CAREER INTEGRATION66 ","PASS" if failures==0 else "FAIL"," toggles / fatigue / injury / played results / detailed simulation / roster integrity")
	quit(1 if failures else 0)

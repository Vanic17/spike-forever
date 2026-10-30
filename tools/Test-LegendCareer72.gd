extends SceneTree
const Legend=preload("res://src/legend_career.gd")
const League=preload("res://src/league.gd")
const Master=preload("res://src/career_manager.gd")
const Overall=preload("res://src/player_overall.gd")
var failures:=0
var assertions:=0

func _initialize(): call_deferred("run")

func check(ok: bool,message: String):
	assertions+=1
	if not ok: failures+=1; push_error("LEGEND72 FAIL "+message)

func profile(role: String="outside_hitter") -> Dictionary:
	var p: Dictionary=Legend.new().default_profile(); p.name="Atleta di prova"; p.number=72; p.role=role
	return p

func result_for(m,productive: bool=true) -> Dictionary:
	var f: Dictionary=m.next_fixture()
	if f.is_empty(): return {}
	var side:=0 if f.home==m.state.club_id else 1
	var needed:=int(m.engine.best_of()/2)+1; var sets: Array=[0,0]; var scores: Array=[]
	sets[side]=needed
	for _i in needed: scores.append([25,16] if side==0 else [16,25])
	var stats: Dictionary={"serves":15,"aces":3,"errors":0,"attacks":25,"kills":20,"digs":12,"receptions":18,"sets":12,"assists":10,"blocks":4,"touches":100,"minutes":45} if productive else {}
	return {"fixture_id":f.id,"sets":sets,"set_scores":scores,"won":true,"performance":stats}

func identity_count(m) -> int:
	var count:=0
	for club in m.state.teams:
		for player in club.roster: count+=int(player.id==m.state.profile.id)
	return count

func run():
	var user_path:=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(user_path.contains("legend72-appdata"),"Tests require isolated workspace APPDATA (legend72-appdata)")
	if not user_path.contains("legend72-appdata"): quit(2); return
	var source_before:=FileAccess.get_sha256("res://assets/gameplay/league.json")
	var overrides_existed:=FileAccess.file_exists(League.PATH)
	var overrides_before:=FileAccess.get_sha256(League.PATH) if overrides_existed else ""
	var master=Master.new(); var db=League.new()
	check(master.new_career(str(db.teams[0].id),{"seed":72001,"autosave":false},11),master.error)
	var master_before:=FileAccess.get_sha256(master.repository.path(11))
	var m=Legend.new(); var weak: Array=m.starter_clubs()
	check(weak.size()==3,"Exactly three starter clubs")
	var sorted: Array=[]
	for club in db.teams:
		var total:=0.0; var lineup: Array=db.lineup(club)
		for player in lineup: total+=Overall.calculate(player.ratings,str(player.role))
		sorted.append({"id":club.id,"strength":total/maxi(1,lineup.size())})
	sorted.sort_custom(func(a,b): return a.strength<b.strength if a.strength!=b.strength else a.id<b.id)
	check(weak.map(func(club): return club.id)==sorted.slice(0,3).map(func(club): return club.id),"Starter selection derived from current role-weighted database lineups")
	check(not m.new_career(profile(),str(sorted[-1].id),{},1),"Strong club rejected by backend")
	var bad:=profile(); bad.ratings.battuta=99
	check(not m.new_career(bad,str(weak[0].id),{},1),"Per-attribute initial cap is enforced")
	bad=profile()
	for key in Legend.STAT_KEYS: bad.ratings[key]=65
	check(not m.new_career(bad,str(weak[0].id),{},1),"Six-attribute creation budget is enforced")
	bad=profile(); bad.ratings.difesa=-1
	check(not m.new_career(bad,str(weak[0].id),{},1),"Negative creation rating rejected")
	bad=profile(); bad.ratings.difesa=50.5
	check(not m.new_career(bad,str(weak[0].id),{},1),"Fractional creation rating rejected")
	bad=profile(); bad.appearance.hair_style="unknown"
	check(not m.new_career(bad,str(weak[0].id),{},1),"Unsupported appearance rejected")
	for role in Legend.ROLES:
		var role_manager=Legend.new()
		check(role_manager.new_career(profile(role),str(weak[0].id),{"seed":72002,"autosave":false,"best_of":3},2),role_manager.error)
		var config: Dictionary=role_manager.launch_config()
		check(not config.is_empty(),role_manager.error)
		if not config.is_empty():
			check(config.club_lineup.size()==7 and config.opponent_lineup.size()==7,"Legal seven-player lineups for "+role)
			check(config.club_lineup.filter(func(player): return player.id==role_manager.state.profile.id).size()==1,"Created "+role+" appears exactly once in match lineup")
			check(config.player.role==role and config.best_of==3 and config.points==25,"Player role and match options are preserved")
		role_manager.cancel_match()
	check(m.new_career(profile(),str(weak[0].id),{"seed":72003,"autosave":false,"best_of":3},1),m.error)
	check(m.overall()<=Legend.INITIAL_CAP,"Real weighted initial overall cap")
	check(identity_count(m)==1,"Initial identity belongs to one roster")
	check(m.repository.path(1).begins_with("user://legend72/"),"Legend save namespace is separate")
	check(not m.upgrade_attribute("battuta"),"Cannot upgrade without earned points")
	var no_stats:=result_for(m,false)
	check(m.complete_match(no_stats),m.error)
	check(int(m.state.xp)==0 and int(m.state.skill_points)==0 and float(m.state.reputation)==0,"Team win without measured actions earns no personal progression")
	var invalid:=result_for(m); invalid.performance.kills=26
	var before_results: int=m.state.results.size()
	check(not m.complete_match(invalid) and m.state.results.size()==before_results,"Impossible kill count rejected without recording result")
	var first:=result_for(m)
	check(m.complete_match(first),m.error)
	var xp_after: int=m.state.xp; var rep_after: float=m.state.reputation; var history_after: int=m.state.match_history.size()
	check(xp_after>0 and int(m.state.skill_points)>0 and rep_after>0,"Real measured performance earns XP, spendable skills and reputation")
	check(not m.complete_match(first),"Replay cannot claim a second reward")
	check(int(m.state.xp)==xp_after and float(m.state.reputation)==rep_after and m.state.match_history.size()==history_after,"Duplicate match leaves XP, reputation and history unchanged")
	var rating_before: int=m.state.profile.ratings.battuta; var skill_before: int=m.state.skill_points; var cost: int=m.attribute_cost("battuta")
	check(m.upgrade_attribute("battuta"),m.error)
	check(int(m.state.profile.ratings.battuta)==rating_before+1 and int(m.state.skill_points)==skill_before-cost,"Skill spending changes rating and consumes correct budget")
	check(int(m.engine.player(str(m.state.profile.id)).ratings.battuta)==rating_before+1,"Roster and profile share upgraded ratings")
	check(m.update_appearance({"hair_style":"ricci","skin_tone":"ebano","beard":"corta"}),m.error)
	check(m.engine.player(str(m.state.profile.id)).appearance.hair_style=="ricci","Career outfit updates the roster identity")
	check(not m.update_appearance({"skin_tone":"unknown"}),"Invalid outfit cannot modify the profile")
	var poor=Legend.new()
	check(poor.new_career(profile(),str(weak[0].id),{"seed":72003,"autosave":false,"best_of":3},3),poor.error)
	var poor_result:=result_for(poor); poor_result.performance={"serves":15,"errors":15,"touches":15}
	check(poor.complete_match(poor_result),poor.error)
	check(int(poor.state.xp)<xp_after and float(poor.last_result.rating)<float(m.last_result.rating),"Errors and ineffective actions earn less than productive performance")
	for _i in 5:
		check(m.complete_match(result_for(m)),m.error)
	check(not m.state.offers.is_empty(),"Strong performances generate stronger-club offers")
	if not m.state.offers.is_empty():
		var offer: Dictionary=m.state.offers[0]; var old_club: String=m.state.club_id; var player_id: String=m.state.profile.id
		var old_strength:=0.0
		for club in sorted:
			if club.id==old_club: old_strength=club.strength
		check(float(offer.strength)>old_strength,"Offered club is stronger in baseline DB, independent of custom-player replacement")
		check(m.accept_offer(str(offer.id)),m.error)
		check(m.state.club_id==offer.club_id and m.state.contract.club_id==offer.club_id and m.state.profile.id==player_id,"Transfer updates club and contract while retaining player identity")
		check(identity_count(m)==1 and not m.team(old_club).roster.any(func(player): return player.id==player_id),"Transfer removes the old roster identity")
		check(not m.accept_offer(str(offer.id)),"Accepted offer cannot be applied twice")
		var config: Dictionary=m.launch_config()
		check(not config.is_empty() and config.club.id==offer.club_id,"Next match uses transferred club")
		m.cancel_match()
	check(m.save(),m.error)
	var clone=Legend.new(); check(clone.load_career(1),clone.error)
	check(JSON.stringify(JSON.parse_string(JSON.stringify(clone.state)))==JSON.stringify(JSON.parse_string(JSON.stringify(m.state))),"Save/reload preserves independent career, ratings, rewards, transfers and RNG")
	check(identity_count(clone)==1,"Reload preserves exactly one player identity")
	clone.state.skill_points=100; clone.state.profile.ratings.battuta=99
	check(not clone.upgrade_attribute("battuta") and int(clone.state.skill_points)==100,"In-career attribute cap rejects upgrades without charging points")
	check(clone.load_career(1),clone.error)
	check(m.list_saves().any(func(row): return row.slot==1 and row.mode=="legend72" and row.player_name=="Atleta di prova"),"Save browser identifies player career")
	# Four complete seasons cover cup draws, elimination, renewals and generated calendars.
	var season_rows: Array=[]
	for season in 4:
		var guard:=0; var matches_before: int=m.state.match_history.size()
		while not m.state.complete and guard<100:
			guard+=1
			var next: Dictionary=m.next_fixture()
			if next.is_empty(): break
			check(m.complete_match(result_for(m)),"Season "+str(m.state.season)+": "+m.error)
		check(m.state.complete,"All competitions finish in season "+str(m.state.season))
		check(m.state.results.size()==m.state.fixtures.size(),"Every fixture has one result")
		check(m.standings().all(func(row): return row.played==22),"Every club plays all 22 regular-season fixtures")
		check(m.state.archives.size()==season+1,"One immutable archive for every completed season")
		check(m.state.competitions.values().all(func(competition): return competition.status=="complete"),"Cup, Supercup, league and postseason all finish")
		var own_fixtures: Array=m.state.fixtures.filter(func(f): return m.state.club_id in [f.home,f.away])
		for f in own_fixtures:
			if season>0: check(f.result.get("stats_source","")=="measured","Dynamic cups never simulate a player fixture: "+str(f.id))
		season_rows.append({"season":m.state.season,"fixtures":m.state.fixtures.size(),"player_matches":m.state.match_history.size()-matches_before,"champions":m.state.archives[-1].champions})
		check(identity_count(m)==1,"No duplicated player after full season")
		if season<3:
			var old_xp: int=m.state.xp
			check(m.next_season(),m.error)
			check(int(m.state.xp)==old_xp and m.state.contract.expires_season>=m.state.season,"Season transition retains progression and renews expiring contract")
	check(m.save(),m.error); check(m.save(),m.error)
	FileAccess.open(m.repository.path(1),FileAccess.WRITE).store_string("deliberately corrupted legend test")
	check(clone.load_career(1) and clone.repository.recovered_backup,"Checksummed backup recovery")
	check(FileAccess.get_sha256("res://assets/gameplay/league.json")==source_before,"Base database remains byte-for-byte unchanged")
	check(FileAccess.file_exists(League.PATH)==overrides_existed and (not overrides_existed or FileAccess.get_sha256(League.PATH)==overrides_before),"Roster editor overrides remain untouched")
	check(FileAccess.get_sha256(master.repository.path(11))==master_before,"Master League save remains byte-for-byte unchanged")
	FileAccess.open("res://docs/legend72-engine.json",FileAccess.WRITE).store_string(JSON.stringify({"assertions":assertions,"failures":failures,"starter_clubs":weak.map(func(club): return {"id":club.id,"strength":club.strength}),"seasons":season_rows,"separate_saves":true,"base_db_unchanged":true,"backup_recovery":true,"no_duplicate_rewards":true,"no_duplicate_identity":true},"  "))
	print("LEGEND72 ","PASS" if failures==0 else "FAIL"," assertions=",assertions," seasons=",season_rows.size()," separate saves / creation caps / measured progress / transfer identity / dynamic cups")
	quit(1 if failures else 0)

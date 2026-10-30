extends SceneTree
const Overall=preload("res://src/player_overall.gd")
const League=preload("res://src/league.gd")
func _initialize(): call_deferred("run")
func run():
	var sample={"battuta":80,"ricezione":70,"difesa":60,"palleggio":90,"schiacciata":50,"muro":40}
	var expected={"setter":73,"opposite":58,"outside_hitter":61,"middle_blocker":55,"libero":68}
	for role in Overall.WEIGHTS:
		var sum=0
		for weight in Overall.WEIGHTS[role]: sum+=weight
		assert(sum==100 and Overall.calculate(sample,role)==expected[role])
		for value in [0,50,99]:
			var flat={}
			for key in Overall.KEYS: flat[key]=value
			assert(Overall.calculate(flat,role)==value)
	var db=League.new(); var count=0
	for team in db.teams:
		for player in team.roster:
			assert(int(player.ratings.generale)==Overall.calculate(player.ratings,player.role)); count+=1
	var p=db.teams[0].roster[0]; p.name="Test unchanged identity"; p.ratings.difesa=89; p.role="outside_hitter"
	assert(db.save(p)==OK)
	var saved=JSON.parse_string(FileAccess.get_file_as_string(League.PATH)); saved[p.id].ratings.generale=0
	FileAccess.open(League.PATH,FileAccess.WRITE).store_string(JSON.stringify(saved))
	var again=League.new(); var edited=again.teams[0].roster.filter(func(player): return player.id==p.id)[0]
	assert(edited.name==p.name and edited.ratings.difesa==89 and edited.ratings.generale==Overall.calculate(edited.ratings,edited.role),"Legacy OVR replaced, actual local edits retained")
	var m=load("res://src/career_manager.gd").new(); assert(m.new_career(db.teams[0].id,{"seed":67001,"autosave":false},9))
	for team in m.state.teams:
		for player in team.roster: player.ratings.generale=0
	var fixtures=m.state.fixtures.duplicate(true); var date=m.state.date; assert(m.save())
	var copy=load("res://src/career_manager.gd").new(); assert(copy.load_career(9))
	for team in copy.state.teams:
		for player in team.roster: assert(player.ratings.generale==Overall.calculate(player.ratings,player.role))
	assert(copy.state.date==date and JSON.stringify(JSON.parse_string(JSON.stringify(copy.state.fixtures)))==JSON.stringify(JSON.parse_string(JSON.stringify(fixtures))),"Existing career migration changes OVR only")
	var lineup=again.lineup(again.teams[0]); var sanitized=load("res://src/online_session.gd").sanitize_choice({"club":again.teams[0].id,"roster":lineup,"bench":again.teams[0].roster},again)
	assert(not sanitized.is_empty())
	for player in sanitized.roster+sanitized.bench: assert(player.ratings.generale==Overall.calculate(player.ratings,player.role))
	FileAccess.open("res://docs/overall67-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"weights":Overall.WEIGHTS,"sample_expected":expected,"database_players":count,"all_zero_and_99":true,"local_edits_preserved":true,"career_migration":true,"online_recomputed":true},"  "))
	print("OVERALL67 PASS 5 roles / exact weights and rounding / ",count," players / local edits / saved career / online"); quit()


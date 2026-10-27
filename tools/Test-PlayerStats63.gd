extends SceneTree
const Stats=preload("res://src/player_stats_gameplay.gd")
const Original=preload("res://src/block_response.gd")
func _initialize(): call_deferred("run")
func run():
	var rows: Array=[]
	for value in [55,75,85,95,99]:
		var q:=Stats.touch_quality(.8,value)
		assert(is_equal_approx(q,.8+(value-85)*.005))
		assert(Stats.touch_quality(0,value)==0 and Stats.touch_quality(1,value)==1)
		rows.append({"stat":value,"input80":q*100,"input0":Stats.touch_quality(0,value),"input100":Stats.touch_quality(1,value)})
	for pair in [[99,65,40],[95,70,45],[90,75,50],[85,80,55],[80,85,60],[75,90,65],[70,95,70],[65,100,75],[60,101,80],[55,101,85]]:
		assert(Stats.set_grade(pair[2]/100.0,pair[0])==1)
		assert(Stats.set_grade((pair[2]-.01)/100.0,pair[0])==0)
		if pair[1]<=100:
			assert(Stats.set_grade(pair[1]/100.0,pair[0])==2)
			assert(Stats.set_grade((pair[1]-.01)/100.0,pair[0])==1)
		else: assert(Stats.set_grade(1,pair[0])==1)
	for point in Stats.settings().attack_speed: assert(is_equal_approx(Stats.curve("attack_speed",point[0]),point[1]))
	assert(is_equal_approx(Stats.curve("attack_speed",87.5),1.265))
	assert(is_equal_approx(Stats.curve("serve_green_low",75),.9925))
	assert(not Stats.perfect(.99249,.9925) and Stats.perfect(.9925,.9925) and not Stats.perfect(1.001,.9925))
	var db=load("res://src/league.gd").new(); var count:=0
	for team in db.teams:
		for p in team.roster:
			for key in Stats.KEYS: assert(p.ratings.has(key) and p.ratings[key]>=0 and p.ratings[key]<=99)
			count+=1
	# Old saves used to replace the entire ratings dictionary, losing new stats.
	var old: Dictionary=db.teams[0].roster[0].duplicate(true); old.ratings.erase("difesa"); old.ratings.ricezione=17
	var fixture=FileAccess.open("user://roster-overrides.json",FileAccess.WRITE); fixture.store_string(JSON.stringify({old.id:old})); fixture.close()
	var migrated=load("res://src/league.gd").new(); assert(migrated.teams[0].roster[0].ratings.ricezione==17 and migrated.teams[0].roster[0].ratings.has("difesa"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://roster-overrides.json"))
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	g.use_player_stats=true; g.hitter=0; g.server=0; g.destination=0
	g.players[0].roster_identity={"ratings":{"schiacciata":95}}; g.players[0].libero_active=false
	var times: Array=[]
	for grade in 3:
		g.stats_set_grade=grade; times.append(g.charge_seconds("attack"))
		assert(is_equal_approx(g.PlayerStats.green_low(g,false),[.99,.97,.95][grade]))
	assert(times[0]==times[1] and times[1]==times[2] and is_equal_approx(times[0],g.Timing.ATTACK_CHARGE_SECONDS))
	g.players[0].roster_identity.ratings.schiacciata=55
	assert(is_equal_approx(g.charge_seconds("attack"),g.Timing.ATTACK_CHARGE_SECONDS/1.8))
	g.destination=1; g.stats_release_flight=.17
	assert(g.charge_seconds("attack")<.17 and g.charge_seconds("attack")>.09)
	g.players[0].libero_identity={"ratings":{"difesa":93}}; g.players[0].libero_active=true
	assert(Stats.rating(g,0,"difesa")==93)
	g.use_player_stats=false
	assert(g.charge_seconds("attack")==g.Timing.ATTACK_CHARGE_SECONDS and g.charge_seconds("serve")==g.Timing.SERVE_CHARGE_SECONDS)
	var selection={"club":db.teams[0].id,"roster":db.lineup(db.teams[0])}
	var clean: Dictionary=load("res://src/online_session.gd").sanitize_choice(selection,db)
	assert(clean.roster.size()==7)
	for p in clean.roster:
		for key in Stats.KEYS: assert(p.ratings.has(key))
	selection.roster[0].ratings.difesa=NAN
	assert(load("res://src/online_session.gd").sanitize_choice(selection,db).is_empty())
	var rng=RandomNumberGenerator.new(); var blocks: Array=[]
	# The canonical eligible contact distribution is reported separately from
	# glancing contacts, physical flight outcomes and actual scoreboard points.
	for value in [55,75,85,95,99]:
		rng.seed=63003; var tally={"stuff_block":0,"block_touch":0,"block_tool":0}; var baseline=tally.duplicate()
		for trial in 1000:
			var incoming:=Vector3(rng.randf_range(-5,5),-3,rng.randf_range(22,36))
			var variation:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1))
			var strength:=rng.randf_range(.55,1); var quality:=rng.randf_range(.65,1); var edge:=rng.randf_range(-.85,.85)
			var original:=Original.solve(incoming,0,strength,quality,edge,variation); baseline[original.kind]+=1
			var roll:=rng.randf(); var response:=Stats.block(incoming,0,strength,quality,edge,variation,value,roll)
			tally[response.kind]+=1; assert(response.velocity.is_finite())
			var mirrored:=Stats.block(Vector3(-incoming.x,incoming.y,-incoming.z),1,strength,quality,-edge,Vector3(-variation.x,variation.y,variation.z),value,roll)
			# At exactly zero edge, the tool side is arbitrary. This sample has no zero edges.
			assert(response.kind==mirrored.kind and Vector3(-response.velocity.x,response.velocity.y,-response.velocity.z).distance_to(mirrored.velocity)<.001)
		assert(absf(tally.stuff_block/1000.0-Stats.curve("block_stuff",value))<.045)
		assert(absf(tally.block_touch/1000.0-.30)<.045)
		blocks.append({"stat":value,"samples":1000,"actual":tally,"baseline_same_contacts":baseline})
	var glance:=Stats.block(Vector3(0,-3,30),0,1,1,1.2,Vector3.ZERO,99,0)
	assert(glance.kind==Original.solve(Vector3(0,-3,30),0,1,1,1.2).kind)
	var broad={"stuff_block":0,"block_touch":0,"block_tool":0}; rng.seed=63010
	for trial in 10000:
		var response:=Original.solve(Vector3(rng.randf_range(-9,9),rng.randf_range(-8,1),rng.randf_range(18,38)),0,rng.randf_range(.18,1),rng.randf_range(.6,1),rng.randf_range(-1.25,1.25),Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)))
		broad[response.kind]+=1
	g.use_player_stats=true; g.last_touch=0; g.block_checked=false; g.clock_time=10; g.block_time=1
	var velocity:=Vector3(0,-3,30); g.ball_vel=velocity; g.ball_pos=Vector3(0,3,0)
	g.try_block(); assert(not g.block_checked and g.ball_vel==velocity,"Stats must not rescue a late jump")
	g.block_time=9.8; g.ball_pos=Vector3(100,3,100)
	g.try_block(); assert(not g.block_checked and g.ball_vel==velocity,"Stats must not touch a ball outside reach")
	FileAccess.open("res://docs/stats63-formulas.json",FileAccess.WRITE).store_string(JSON.stringify({"quality":rows,"database_players":count,"block_distributions":blocks,"baseline_broad_contacts_10000":broad,"invalid_blocks_unchanged":true,"thresholds":true,"bar_window_independent":true,"old_save_migration":true,"libero_identity":true,"network_sanitization":true},"  "))
	print("PLAYER STATS63 PASS players=",count," samples=5000 quality/thresholds/curves/green/bar/libero/migration/network")
	g.free(); quit()

extends SceneTree
var errors: Array=[]
var checks:=0
func check(value: bool,label: String):
	checks+=1
	if not value:errors.append(label);push_error("REVIEW103 "+label)
func _initialize():call_deferred("run")
func run():
	assert("review103" in OS.get_environment("APPDATA"))
	var League=preload("res://src/league.gd")
	var invalid:=FileAccess.open(League.PATH,FileAccess.WRITE);invalid.store_string("{invalid-personal-file");invalid.close()
	check(preload("res://src/dominant_hand103.gd").apply({},League.PATH)==ERR_INVALID_DATA,"malformed personal DB is never replaced")
	check(FileAccess.get_file_as_string(League.PATH)=="{invalid-personal-file","malformed DB retained byte for byte")
	var sentinel: Dictionary={"_lineups":{"custom":["keep"]},"sir-susa-scai-perugia-04":{"name":"PERSONALE","height_cm":199,"condition_form":"D","dominant_hand":"right","ratings":{"difesa":21}},"custom-player":{"dominant_hand":"left","name":"CUSTOM"}}
	var f:=FileAccess.open(League.PATH,FileAccess.WRITE);f.store_string(JSON.stringify(sentinel));f.close()
	var C=preload("res://src/condition99.gd")
	var db=League.new();var saved=JSON.parse_string(FileAccess.get_file_as_string(League.PATH))
	var patch=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/dominant_hand103.json"))
	for id in sentinel:
		var previous: Dictionary=JSON.parse_string(JSON.stringify(sentinel[id]));var current: Dictionary=saved[id].duplicate(true)
		if patch.players.has(id):previous.erase("dominant_hand");current.erase("dominant_hand")
		check(previous==current,"only handedness may change in personal data "+id)
	check(FileAccess.get_file_as_string(preload("res://src/dominant_hand103.gd").BACKUP)==JSON.stringify(sentinel),"exact backup")
	var left_id: String="itas-trentino-01"
	for id in patch.players:
		check(saved[id].dominant_hand==patch.players[id].dominant_hand,"researched hand "+id)
		if patch.players[id].dominant_hand=="left":left_id=id
	saved[left_id].dominant_hand="right"
	f=FileAccess.open(League.PATH,FileAccess.WRITE);f.store_string(JSON.stringify(saved));f.close()
	var after_edit:=FileAccess.get_file_as_string(League.PATH);db=League.new()
	check(FileAccess.get_file_as_string(League.PATH)==after_edit,"one-off patch never overwrites later user hand edits")
	var classes: Dictionary={};var setters: Array=[]
	for team in db.teams:
		for p in team.roster:
			if p.role=="setter":classes[C.form(p)]=true;setters.append({"name":p.name,"form":C.form(p)})
	check(classes.size()>=3,"setter classes are not flattened to C")
	check(C.form({"id":"vero-volley-monza-07"})=="A","international setter evidence loaded")
	check(C.form({"id":"vero-volley-monza-07","condition_form":"D"})=="D","explicit form override preserved")
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	await process_frame
	var Short=preload("res://src/short_attack103.gd")
	var fast_count:=0;var planning_us:=0
	for team in 2:
		g.possession=team;g.hitter_action="attack";g.incoming_kind="spike";g.attack_tip=false;g.out_of_system=1
		var side: float=1 if team==0 else -1
		g.ball_pos=Vector3(-3.4*side,3.0,side)
		for x in [-3.85,0,3.85]:
			g.aim=Vector2(signf(x),1)
			var target:=Vector3(x,.105,-side*3.3)
			var baseline: float=preload("res://src/winning_shot.gd").flight_seconds(g,target,.43,2.543)
			var start:=Time.get_ticks_usec();var hit: Dictionary=Short.solve(g,target,baseline,1);planning_us=maxi(planning_us,Time.get_ticks_usec()-start)
			check(hit.seconds<=baseline,"downward attack never slowed")
			if hit.has("spin"):
				fast_count+=1;check(Short.clear(g.ball_pos,target,hit.seconds,hit.spin),"accelerated spinning ball clears tape on both sides")
			g.attack_tip=true;check(Short.solve(g,target,baseline,1).seconds==baseline,"tips untouched");g.attack_tip=false
	check(fast_count>=4,"actual boost occurs in short left/centre/right attacks")
	var T=preload("res://src/tactics.gd")
	for serving_team in 2:
		g.server=serving_team
		for rotation in 6:
			g.rotations=[rotation,rotation];g.rally_lanes.reset(g.rotations,g.server)
			for team in 2:
				for i in range(team*6,team*6+6):
					var point: Vector3=T.serve_position_for(g,i,team,rotation,team==g.server)
					if rotation==0 and team==g.server and i%6==2:
						check(point.x*(1 if team==0 else -1)>3,"serving P1 opposite already Z2")
						check(T.attacker_for(g,team,2,team*6+5)==i,"back set selects near-side opposite")
						check(T.wing_for(g,i)==1,"rally lane stays on right pin")
					elif rotation==0 and team==g.server and i%6==0:check(point.x*(1 if team==0 else -1)<-3,"OH moved consistently to Z4")
					elif not (rotation==0 and team==g.server):check(point==T.serve_position(i,team,rotation,team==g.server),"all other ready formations unchanged")
	# Build both skinned outfits and check all skin weights/bones.
	var benches=g.arena_visuals.get_node_or_null("TeamBenches")
	check(benches!=null,"benches built")
	if benches!=null:
		for entry in benches.actors:
			if not entry.coach:continue
			var suit=entry.actor.visual_root.get_node_or_null("CoachSuit103")
			check(suit!=null,"coach wears shirt and jacket")
			if suit==null:continue
			check(suit.mesh.get_surface_count()==4,"jacket/shirt/trousers/lapels")
			for s in suit.mesh.get_surface_count():
				var a: Array=suit.mesh.surface_get_arrays(s)
				check(a[Mesh.ARRAY_BONES].size()==a[Mesh.ARRAY_VERTEX].size()*4,"all suit vertices skinned")
	var report: Dictionary={"pass":errors.is_empty(),"checks":checks,"errors":errors,"setters":setters,"boosted_trajectories":fast_count,"maximum_extra_planning_us":planning_us}
	f=FileAccess.open("res://docs/review103-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("REVIEW103 ","PASS" if errors.is_empty() else "FAIL"," ",checks," checks");quit(0 if errors.is_empty() else 1)

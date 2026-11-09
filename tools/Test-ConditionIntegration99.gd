extends SceneTree
const C=preload("res://src/condition99.gd")
const Manager=preload("res://src/career_manager.gd")
const Sim=preload("res://src/career_simulation.gd")
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message);push_error("CONDITION99 "+message)
func _initialize():call_deferred("run")
func run():
	assert("condition99" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g)
	g.set_process(false);g.set_physics_process(false);g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	await process_frame
	var start=g.get_children().filter(func(n):return n.get_script()==load("res://src/start_menu.gd"))[0]
	var clubs=start.clubs
	var teams: Array=[clubs.db.teams[0],clubs.db.teams[1]]
	var squads: Array=[clubs.db.lineup(teams[0]),clubs.db.lineup(teams[1])]
	var ledger: Dictionary=C.fresh(99427,"integration99")
	C.ensure(ledger,teams[0].roster+teams[1].roster)
	for side in 2:
		for i in 6:g.players[side*6+i].set_roster_identity(squads[side][i],squads[side][6],{}, {})
	g.match_management.configure_rosters(teams,squads,{}, {"condition99":ledger,"fatigue":false})
	for enabled in [false,true]:
		g.use_player_stats=enabled
		for index in 12:
			var p=g.players[index]
			for libero in [false,true]:
				p.libero_active=libero
				var person: Dictionary=p.libero_identity if libero else p.roster_identity
				var before: Dictionary=person.duplicate(true)
				for code in C.settings().arrows:
					g.form99.arrows[person.id]=code
					for key in C.KEYS:
						var base: float=float(person.ratings[key])
						var expected: float=C.effective(base,code) if enabled else base
						check(g.PlayerStats.rating(g,index,key)==expected,"single effective modifier / toggles / libero")
				check(person==before,"identity immutable")
			p.libero_active=false
	var exported: Dictionary=g.match_management.export_state()
	var frozen: Dictionary=g.form99.duplicate(true)
	g.form99={};g.match_management.import_state(exported)
	check(g.form99==frozen,"management export/import preserves all arrows")
	var m=Manager.new()
	check(m.new_career(str(teams[0].id),{"seed":99427,"autosave":false,"stats":true,"fatigue":false,"injuries":false},9),"new isolated career")
	check(m.save(),"initial isolated save")
	var fixture: Dictionary=m.next_fixture();var file: String=m.repository.path(9);var hash: String=FileAccess.get_sha256(file)
	var rng_state: int=m.rng.state
	var first: Dictionary=m.match_forms99(str(fixture.id)).duplicate(true)
	check(m.rng.state==rng_state,"condition RNG does not perturb simulation RNG")
	check(FileAccess.get_sha256(file)==hash,"viewing formation never rewrites career save")
	var clone=Manager.new();check(clone.load_career(9),"load isolated old career")
	check(clone.match_forms99(str(fixture.id))==first,"sidecar restores exact arrows after cancel/reload")
	check(FileAccess.get_sha256(file)==hash,"memory migration never rewrites saved career")
	var squad: Array=m.lineup(str(fixture.home));var all_up: Dictionary=first.duplicate(true);var all_down: Dictionary=first.duplicate(true)
	for p in squad:all_up.arrows[p.id]="UP";all_down.arrows[p.id]="DOWN"
	check(Sim.strength(m,squad,all_up)>Sim.strength(m,squad,all_down),"simulation uses effective stats")
	m.state.options.use_player_stats=false
	check(Sim.strength(m,squad,all_up)==Sim.strength(m,squad,all_down),"simulation stats OFF exact neutrality")
	var result: Dictionary=Sim.play(m,fixture)
	check(result.condition99==first,"simulation result keeps fixed ledger")
	check(FileAccess.get_sha256(file)==hash,"simulation helper does not overwrite career file")
	FileAccess.open("res://docs/condition99-integration.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors},"  "))
	print("CONDITION99 INTEGRATION ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)

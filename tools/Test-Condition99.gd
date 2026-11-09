extends SceneTree
const C=preload("res://src/condition99.gd")
var errors: Array=[]
func check(ok: bool,label: String):
	if not ok:errors.append(label);print("FAIL99 ",label)
func _initialize():
	assert("condition99" in OS.get_environment("APPDATA"))
	var distributions: Dictionary={}
	for stable in ["A","B","C","D"]:
		var weights: Array=C.settings().classes[stable];var total:=0
		for w in weights:check(float(w)>0,"all five arrows possible for "+stable);total+=int(w)
		check(total==100,"weights sum to 100")
		var random:=RandomNumberGenerator.new();random.seed=994421
		var counts: Dictionary={}
		for trial in 100000:
			var code: String=C.draw(random,stable);counts[code]=int(counts.get(code,0))+1
		for i in 5:check(absf(float(counts.get(C.settings().arrows[i],0))/1000-float(weights[i]))<1,"observed weights "+stable)
		distributions[stable]=counts
	var original: Dictionary={"id":"custom-99","condition_form":"A","name":"PERSONALE","role":"opposite","ratings":{"battuta":80,"ricezione":70,"difesa":75,"palleggio":40,"schiacciata":85,"muro":79}}
	var snapshot:=JSON.stringify(original)
	var ledger: Dictionary=C.fresh(99117,"test-only99")
	C.ensure(ledger,[original]);var frozen: Dictionary=ledger.duplicate(true)
	original.condition_form="D";C.ensure(ledger,[original]);check(ledger==frozen,"class edits do not reroll existing match")
	original.condition_form="A"
	check(C.store(ledger)==OK,"sidecar written");check(C.read("test-only99")==ledger,"exact save/load")
	var values: Array=[89,88,85,82,81]
	for i in 5:
		check(C.effective(85,C.settings().arrows[i])==values[i],"reduced percent modifiers")
		check(C.effective(99,C.settings().arrows[i])<=99 and C.effective(0,C.settings().arrows[i])>=1,"bounds")
		ledger.arrows[original.id]=C.settings().arrows[i]
		check(C.ratings(original,ledger)==C.ratings(original,ledger),"no repeated application")
		check(C.icon(C.settings().arrows[i])!=null,"color arrow icon")
	check(JSON.stringify(original)==snapshot,"base ratings unmodified")
	var base_hash: String=FileAccess.get_sha256("res://assets/gameplay/league.json")
	var db=preload("res://src/league.gd").new()
	var players:=0
	for team in db.teams:
		for p in team.roster:players+=1;check(str(p.condition_form) in ["A","B","C","D"],"valid runtime class")
	check(base_hash==FileAccess.get_sha256("res://assets/gameplay/league.json"),"base DB not written")
	check(C.migrate(db.teams).missing==0,"idempotent memory migration")
	FileAccess.open("res://docs/condition99-core-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"errors":errors,"distributions":distributions,"players":players},"  "))
	print("CONDITION99 CORE ","PASS" if errors.is_empty() else "FAIL"," players=",players," errors=",errors);quit(0 if errors.is_empty() else 1)

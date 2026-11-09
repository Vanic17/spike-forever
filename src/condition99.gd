extends RefCounted
## Stable DB class and immutable per-match condition. Never writes the roster
## or a career save; resumable ledgers have their own checksummed user folder.
const KEYS=["battuta","ricezione","difesa","palleggio","schiacciata","muro"]
const FOLDER="user://condition99/matches"
static var config: Dictionary={}
static var researched: Dictionary={}
static var textures: Dictionary={}
static var migration_logged:=false
static var translated:=false

static func settings() -> Dictionary:
	if config.is_empty():config=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/condition99.json"))
	if not translated:
		translated=true
		var english:=Translation.new();english.locale="en"
		var messages: Dictionary={"Ottima":"Excellent","Buona":"Good","Normale":"Normal","Scarsa":"Poor","Pessima":"Very poor","Forma":"Form","FORMA / COSTANZA":"FORM / CONSISTENCY","CONFERMA SQUADRA / FORMAZIONE":"CONFIRM TEAM / LINEUP","CONDIZIONE DELLA PARTITA / ROSA COMPLETA":"MATCH CONDITION / FULL SQUAD","CONDIZIONE GIOCATORI":"PLAYER CONDITION"}
		for key in messages:english.add_message(key,messages[key])
		TranslationServer.add_translation(english)
	return config
static func defaults() -> Dictionary:
	if researched.is_empty():
		var value=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/player_forms99.json"))
		if value is Dictionary:researched=value
	return researched.get("players",{})
static func form(person: Dictionary) -> String:
	if person.has("condition_form"):
		return str(person.condition_form) if str(person.condition_form) in ["A","B","C","D"] else "C"
	var id: String=str(person.get("database_id",person.get("id","")))
	return str(defaults().get(id,{}).get("condition_form","C"))
static func migrate(teams: Array) -> Dictionary:
	settings()
	var report: Dictionary={"missing":0,"invalid":0,"researched":0,"fallback":0,"writes":0}
	for team in teams:
		for p in team.get("roster",[]):
			if not p.has("condition_form"):
				report.missing+=1;p.condition_form=form(p)
				if defaults().get(str(p.id),{}).get("eligible",false):report.researched+=1
				else:report.fallback+=1
			elif str(p.condition_form) not in ["A","B","C","D"]:report.invalid+=1;p.condition_form="C"
	if not migration_logged:
		migration_logged=true;print("CONDITION99 in-memory migration ",report)
	return report
static func fresh(seed_value: int=-1,match_key: String="") -> Dictionary:
	if seed_value<0:
		var random:=RandomNumberGenerator.new();random.randomize();seed_value=random.randi()
	return {"schema":1,"seed":str(seed_value),"match_key":match_key,"arrows":{},"forms":{}}
static func draw(random: RandomNumberGenerator,stable_form: String) -> String:
	var weights: Array=settings().classes.get(stable_form,settings().classes.C)
	var roll: float=random.randf()*100.0
	for i in weights.size():
		roll-=float(weights[i])
		if roll<0:return str(settings().arrows[i])
	return "DOWN"
static func ensure(ledger: Dictionary,people: Array) -> int:
	if ledger.is_empty():ledger.merge(fresh(),true)
	if not ledger.get("arrows") is Dictionary:ledger.arrows={}
	if not ledger.get("forms") is Dictionary:ledger.forms={}
	var generated:=0
	for person in people:
		var id: String=str(person.get("id",""))
		if id.is_empty() or ledger.arrows.has(id):continue
		var stable: String=form(person)
		var random:=RandomNumberGenerator.new()
		random.seed=(str(ledger.get("seed","0"))+"|"+id).sha256_text().substr(0,12).hex_to_int()
		ledger.arrows[id]="NEUTRAL" if ledger.get("corrupt",false) else draw(random,stable)
		ledger.forms[id]=stable;generated+=1
	return generated
static func arrow(ledger: Dictionary,id: String) -> String:
	var value: String=str(ledger.get("arrows",{}).get(id,"NEUTRAL"))
	return value if value in settings().arrows else "NEUTRAL"
static func modifier(code: String) -> float:
	var i: int=settings().arrows.find(code)
	return float(settings().modifiers[maxi(0,i)]) if i>=0 else 0.0
static func effective(base: float,code: String) -> int:
	return clampi(roundi(clampf(base,0,99)*(1.0+modifier(code))),1,99)
static func ratings(person: Dictionary,ledger: Dictionary) -> Dictionary:
	var result: Dictionary=person.get("ratings",{}).duplicate(true)
	var code: String=arrow(ledger,str(person.get("id","")))
	for key in KEYS:result[key]=effective(float(result.get(key,85)),code)
	result.generale=preload("res://src/player_overall.gd").calculate(result,str(person.get("role","outside_hitter")))
	return result
static func skill(person: Dictionary,key: String,ledger: Dictionary,enabled: bool=true) -> float:
	var base: float=float(person.get("ratings",{}).get(key,85))
	return float(effective(base,arrow(ledger,str(person.get("id",""))))) if enabled and not ledger.is_empty() else base
static func label(code: String) -> String:
	var i: int=settings().arrows.find(code)
	if i<0:i=2
	return str(settings().symbols[i])+" "+str(TranslationServer.translate(settings().labels[i]))
static func icon(code: String) -> Texture2D:
	if textures.has(code):return textures[code]
	var i: int=settings().arrows.find(code)
	if i<0:i=2
	var svg: String='<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><path fill="#%s" stroke="#081323" stroke-width="1.2" transform="rotate(%d 14 14)" d="M14 2 L3 13 H9 V25 H19 V13 H25 Z"/></svg>'%[settings().colors[i],i*45]
	var image:=Image.new();image.load_svg_from_string(svg,2.0)
	textures[code]=ImageTexture.create_from_image(image);return textures[code]
static func summary(person: Dictionary,ledger: Dictionary,enabled: bool=true) -> String:
	var values: Dictionary=ratings(person,ledger) if enabled else person.get("ratings",{})
	return "%s · %s · GEN %d · %s"%[str(int(person.get("jersey_number",0))),str(person.get("name","")),int(values.get("generale",0)),label(arrow(ledger,str(person.get("id",""))))]
static func path(match_key: String) -> String:return FOLDER+"/"+match_key.sha256_text()+".json"
static func read(match_key: String) -> Dictionary:
	var target: String=path(match_key)
	if not FileAccess.file_exists(target):return {}
	var envelope=JSON.parse_string(FileAccess.get_file_as_string(target))
	if envelope is Dictionary and envelope.get("payload") is String and str(envelope.get("sha256",""))==str(envelope.payload).sha256_text():
		var value=JSON.parse_string(envelope.payload)
		if value is Dictionary and value.get("match_key","")==match_key and value.get("arrows") is Dictionary:
			value.schema=int(value.get("schema",1));return value
	push_warning("CONDITION99 invalid match ledger; neutral fallback without reroll")
	var neutral:=fresh(0,match_key);neutral.corrupt=true;return neutral
static func store(ledger: Dictionary) -> Error:
	var key: String=str(ledger.get("match_key",""))
	if key.is_empty():return OK
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	var target: String=path(key);var payload:=JSON.stringify(ledger)
	var file:=FileAccess.open(target+".tmp",FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema":1,"sha256":payload.sha256_text(),"payload":payload}));file.flush();file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(target+".tmp"),ProjectSettings.globalize_path(target))

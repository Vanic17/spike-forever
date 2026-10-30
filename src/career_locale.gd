extends RefCounted
## UI resources only; persisted names, IDs and editorial save data stay intact.
static var installed:=false
static func ensure() -> void:
	if installed: return
	installed=true
	var english=Translation.new(); english.locale="en"
	for line in FileAccess.get_file_as_string("res://assets/ui/en66_career.tsv").split("\n",false):
		var entry: PackedStringArray=line.trim_suffix("\r").split("\t",true,1)
		if entry.size()==2: english.add_message(entry[0].replace("\\n","\n"),entry[1].replace("\\n","\n"))
	TranslationServer.add_translation(english)

static func text(value: String) -> String:
	ensure()
	if not TranslationServer.get_locale().begins_with("en"): return value
	var direct: String=TranslationServer.translate(value)
	if direct!=value: return direct
	for prefix in ["ROSA / ","FORMAZIONE / ","SQUADRA / ","GIOCATORE / ","ALLENATORE · ","Allenatore virtuale · SuperLega · ","Campione: ","Recupero fino al ","CONDIZIONE · ","FORMA  ","PARZIALI   ","Giornata ","Infortunio simulato: ","Vincente: ","AL MEGLIO DELLE ","CERCA: "]:
		if value.begins_with(prefix): value=str(TranslationServer.translate(prefix))+value.substr(prefix.length()); break
	for metric in ["Presenze","Set giocati","Punti","Attacchi vincenti","Attacchi tentati","Errori in battuta","Muri punto","Ricezioni","Difese","Alzate"]:
		if value.begins_with(metric+"   "): value=str(TranslationServer.translate(metric))+value.substr(metric.length()); break
	for pair in [[" · GEN "," · OVR "],[" / GEN "," / OVR "],["  /  GEN ","  /  OVR "],[" · COND "," · FIT "],["  ·  COND ","  ·  FIT "],[" · FORMA "," · FORM "],["  ·  FORMA ","  ·  FORM "],["   ·   Punti ","   ·   Points "],["   ·   Muri ","   ·   Blocks "],[" gare"," matches"],[" · rientro "," · return "]]: value=value.replace(pair[0],pair[1])
	return value

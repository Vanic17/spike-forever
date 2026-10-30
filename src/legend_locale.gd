extends RefCounted
static var installed:=false
static func ensure() -> void:
	if installed: return
	installed=true
	var english:=Translation.new(); english.locale="en"
	for line in FileAccess.get_file_as_string("res://assets/ui/en72_legend.tsv").split("\n",false):
		var entry:=line.trim_suffix("\r").split("\t",true,1)
		if entry.size()==2: english.add_message(entry[0].replace("\\n","\n"),entry[1].replace("\\n","\n"))
	TranslationServer.add_translation(english)
static func text(value: String) -> String:
	ensure()
	if not TranslationServer.get_locale().begins_with("en"): return value
	var translated:=str(TranslationServer.translate(value))
	if translated!=value: return translated
	# Contact feedback adds percentages; score notices add the chosen club name.
	if " · " in value:
		var parts:=value.split(" · ")
		for i in parts.size(): parts[i]=str(TranslationServer.translate(parts[i]))
		return " · ".join(parts)
	if value.begins_with("VITTORIA "): return "WIN · "+value.trim_prefix("VITTORIA ")
	return value

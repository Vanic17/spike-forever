extends RefCounted
static var installed:=false
static var english_text: Dictionary={}
static func ensure() -> void:
	if installed: return
	installed=true
	var english:=Translation.new(); english.locale="en"
	for path in ["res://assets/ui/en72_legend.tsv","res://assets/ui/en75_legend.tsv"]:
		for line in FileAccess.get_file_as_string(path).split("\n",false):
			var entry:=line.trim_suffix("\r").split("\t",true,1)
			if entry.size()==2:
				var source:=entry[0].replace("\\n","\n"); var target:=entry[1].replace("\\n","\n")
				english.add_message(source,target); english_text[source]=target
	TranslationServer.add_translation(english)
static func text(value: String) -> String:
	ensure()
	if not TranslationServer.get_locale().begins_with("en"): return value
	# A global fragment translator may also know one word in a career string.
	# Prefer the complete career sentence over that partial translation.
	if english_text.has(value): return str(english_text[value])
	var translated:=str(TranslationServer.translate(value))
	if translated!=value: return translated
	# Contact feedback adds percentages; score notices add the chosen club name.
	if " · " in value:
		var parts:=value.split(" · ")
		for i in parts.size(): parts[i]=str(english_text.get(parts[i],TranslationServer.translate(parts[i])))
		return " · ".join(parts)
	if value.begins_with("VITTORIA "): return "WIN · "+value.trim_prefix("VITTORIA ")
	return value

extends Translation
## Native Godot translation notifications update Controls; no per-frame UI crawl.
static var catalogue: Dictionary={}
static var fragments: Array=[]
static var templates: Array=[]
static var cache: Dictionary={}
const IT={"PLAYER PROFILE":"PROFILO GIOCATORE","outside_hitter":"Banda","middle_blocker":"Centrale","opposite":"Opposto","setter":"Palleggiatore","libero":"Libero"}
static func escape(value: String) -> String:
	var output:=""
	for character in value:
		if character in "\\.^$|?*+()[]{}": output+="\\"
		output+=character
	return output
func _init():
	if not catalogue.is_empty(): return
	var source:=FileAccess.get_file_as_string("res://assets/ui/en53.tsv")
	var tokens=RegEx.new(); tokens.compile("%[-+0-9.]*[dfs]")
	for line in source.split("\n"):
		if line.is_empty() or line.begins_with("#"): continue
		var parts:=line.split("\t",true,1)
		if parts.size()!=2: continue
		var key: String=parts[0].replace("\\n","\n"); var translated: String=parts[1].trim_suffix("\r").replace("\\n","\n")
		catalogue[key]=translated
		var found=tokens.search_all(key)
		if not found.is_empty():
			var pattern:="^"; var cursor:=0
			for item in found: pattern+=escape(key.substr(cursor,item.get_start()-cursor))+"(.+?)"; cursor=item.get_end()
			pattern+=escape(key.substr(cursor))+"$"
			var matcher=RegEx.new(); matcher.compile(pattern.replace("%%","%"))
			templates.append({"regex":matcher,"text":translated,"tokens":tokens})
		elif key.length()>=3:
			var fragment:=key.strip_edges()
			var matcher=RegEx.new(); matcher.compile("(?<![\\p{L}\\p{N}_])"+escape(fragment)+"(?![\\p{L}\\p{N}_])")
			fragments.append({"source":fragment,"text":translated.strip_edges(),"regex":matcher})
	fragments.sort_custom(func(a,b): return a.source.length()>b.source.length())
static func english(source: String) -> String:
	if catalogue.has(source): return catalogue[source]
	if cache.has(source): return cache[source]
	var output:=source
	for item in templates:
		var match_value=item.regex.search(source)
		if match_value==null: continue
		var cursor:=0; var group:=1; output=""
		for token in item.tokens.search_all(item.text):
			output+=item.text.substr(cursor,token.get_start()-cursor)+match_value.get_string(group)
			group+=1; cursor=token.get_end()
		output+=item.text.substr(cursor); output=output.replace("%%","%")
		break
	if output==source:
		for item in fragments:
			if item.source in output: output=item.regex.sub(output,item.text,true)
	if cache.size()>4096: cache.clear()
	cache[source]=output
	return output
func _get_message(source: StringName,_context: StringName) -> StringName:
	if locale.begins_with("it"): return StringName(IT.get(String(source),String(source)))
	var value:=english(String(source))
	return StringName(value) if value!=String(source) else &""

extends SceneTree
func _initialize() -> void:
	# Run only with an isolated APPDATA, never against the user's roster.
	assert(OS.get_user_data_dir().contains("tests47-roaming"))
	var path:="user://roster-overrides.json"
	var fixture={"allianz-milano-01":{"id":"allianz-milano-01","name":"LOCAL NAME 47","jersey_number":87,"appearance":{"hair_color":null,"skin_tone":null}},"allianz-milano-02":{"id":"allianz-milano-02","appearance":{"hair_length":"pelato","skin_tone":"scura"}}}
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(fixture))
	var db=load("res://src/league.gd").new()
	var first: Dictionary=db.teams[0].roster[0]; var second: Dictionary=db.teams[0].roster[1]
	assert(first.name=="LOCAL NAME 47" and first.jersey_number==87)
	assert(first.appearance.hair_style=="sfumati" and first.appearance.hair_color=="nero","Old unspecified appearance fields must inherit the new reviewed defaults")
	assert(second.appearance.hair_style=="pelato" and second.appearance.skin_tone=="scura","Legacy explicit appearance edits must remain authoritative")
	print("PROFILE OVERRIDES47 PASS: names/numbers retained, null legacy defaults refreshed, explicit legacy cosmetics retained")
	quit()

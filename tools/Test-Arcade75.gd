extends "res://tools/Test-LegendInputs75.gd"
func run():
	var path: String=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(path.contains("/.runtime/") and path.contains("legend75"),"isolated user data")
	if not failures.is_empty(): quit(2); return
	for role in Career.ROLES:
		var profile:=manager.default_profile(); profile.role=role
		check(Career.Overall.calculate(profile.ratings,role)==75,"creation OVR75 "+role)
		check(manager.validate_profile(profile).is_empty(),"creation valid "+role)
	var assist=preload("res://src/legend_contact.gd")
	for early in [.0,.10,.20]: check(assist.quality(early)==1,"perfect forgiving reception "+str(early))
	check(assist.quality(.5)>.70 and assist.quality(-.12)>.70,"imperfect inputs remain playable")
	check(assist.label(-.06)=="PERFETTA","late perfect feedback matches widened window")
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false; game.replay.enabled=false
	for p in game.players: p.set_process(false); p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): child.set_process(false); child.panel.hide(); child.play_hub.hide(); child.legend_menu.hide()
	await settle()
	var attack_cases: Array=[]
	for offset in [-.28,-.20,.0,.20,.28,.40]:
		var p=attack_scene(); check(adapter.jump(),"manual jump starts")
		p.animation_time=p.clips.attack.contact_time+offset
		game.armed=true
		var allowed: bool=adapter.contact_allowed(adapter.controlled_index,"attack")
		check(allowed==(absf(offset)<=.32),"arcade jump contact tolerance "+str(offset))
		attack_cases.append({"offset":offset,"allowed":allowed})
	var p=attack_scene(); game.armed=true
	check(not adapter.contact_allowed(adapter.controlled_index,"attack"),"no attack without manual jump")
	var snapshot: Dictionary=manager.state.duplicate(true); var slot:=12
	check(manager.save(),"career save")
	var loaded=Career.new()
	var loaded_ok: bool=loaded.load_career(slot)
	check(loaded_ok,"career reload: "+loaded.error)
	if loaded_ok:
		for stat in Career.STAT_KEYS: check(int(loaded.state.profile.ratings[stat])==int(snapshot.profile.ratings[stat]),"saved statistic preserved: "+stat)
	# Existing careers from the former lower preset are never rebalanced.
	for stat in Career.STAT_KEYS: loaded.state.profile.ratings[stat]=50
	check(loaded.save(),"legacy low-value career saves")
	var legacy=Career.new(); check(legacy.load_career(slot),"legacy low-value career reloads")
	check(legacy.overall()==50,"update never upgrades or rewrites an existing player")
	var updater=preload("res://src/update_client.gd")
	check("DNS" in updater.request_error(HTTPRequest.RESULT_CANT_RESOLVE,0),"DNS diagnostic")
	check("TLS" in updater.request_error(HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR,0),"TLS diagnostic")
	check("HTTP" in updater.request_error(HTTPRequest.RESULT_CANT_CONNECT,0),"HTTP0 diagnostic")
	check(updater.compare_versions("v0.75.0","0.20.0")==1,"update version skips supported")
	FileAccess.open("res://docs/arcade75-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"attack_cases":attack_cases,"failures":failures},"  "))
	print("ARCADE75 ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures)
	game.free(); quit(0 if failures.is_empty() else 1)

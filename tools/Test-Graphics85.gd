extends SceneTree
var game
var failures: Array[String]=[]
var checks:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);push_error("GRAPHICS85 "+label)
func fingerprint() -> Array:
	return [game.clock_time,game.ball_pos,game.ball_vel,game.rng.state,game.scores.duplicate(),game.rotations.duplicate(),game.players.map(func(p):return [p.transform,p.animation_time,p.clip_name,p.left_handed,p.velocity])]
func run():
	check(ProjectSettings.globalize_path("user://").contains("graphics85"),"isolated preferences")
	if not failures.is_empty():quit(2);return
	var legacy:=ConfigFile.new();legacy.set_value("settings","preset",0);legacy.set_value("settings","width",1280);legacy.set_value("settings","height",720);legacy.save("user://settings.cfg")
	FileAccess.open("user://roster-overrides.json",FileAccess.WRITE).store_string("{\"_graphics85_canary\":true}")
	var canary: String=FileAccess.get_sha256("user://roster-overrides.json")
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.match_audio.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	await process_frame;await process_frame;await process_frame
	var service=game.preferences;var visuals=game.arena_visuals.get_node("VisualUpgrade85")
	check(visuals.built,"visual build completes")
	check(service.data.arena_lighting==0 and service.data.material_detail==0 and service.data.reflections==0,"legacy low preset migrates only new keys")
	check(service.data.width==1280 and service.data.height==720,"legacy video values retained")
	var before:=fingerprint()
	for preset in 4:
		var values: Dictionary=service.data.duplicate();values.merge(service.PRESETS[preset],true);values.preset=preset
		check(service.apply(values,false),"apply preset "+str(preset))
		check(fingerprint()==before,"preset does not mutate simulation "+str(preset))
		check(Engine.physics_ticks_per_second==120,"physics stays at 120 Hz")
		check(visuals.probe.visible==(preset>=2),"probe scales by preset")
		check(visuals.key_light.light_angular_distance==0,"stable PCF hair shadows")
		check(visuals.court_lights[0].visible==(preset>0),"ceiling lights scale by preset")
		check(service.save_config()==OK,"save graphical preferences")
		var reloaded=load("res://src/app_settings.gd").new();reloaded.load_config()
		check(reloaded.data.arena_lighting==preset and reloaded.data.material_detail==preset,"saved detail restored")
		reloaded.free()
	check(FileAccess.get_sha256("user://roster-overrides.json")==canary,"database overrides untouched")
	game.arena_contacts.build()
	check(game.arena_contacts.shapes.size()==1401,"no decorative collision volumes added")
	var count: int=game.arena_visuals.crowd_instance_count
	check(count==1280,"spectator count retained")
	for node in game.arena_visuals.get_children():
		if node is MultiMeshInstance3D and node.has_meta("spectators"):check(is_equal_approx(node.lod_bias,.8),"crowd LOD retained")
	var kits=load("res://src/club_kits.gd");var db=load("res://src/league.gd").new()
	for club in db.teams:
		for variant in ["home","away"]:
			var selected: Dictionary=kits.selection(club.id,variant);var squad: Array=db.lineup(club)
			var player=game.players[0];var bones: int=player.skeleton.get_bone_count();var body_mesh: Mesh=player.body_parts.body.mesh
			player.set_roster_identity(squad[0],squad[6],selected,kits.selection(club.id,variant,true))
			check(player.skeleton.get_bone_count()==bones and player.body_parts.body.mesh==body_mesh,"rig and body geometry preserved")
			check(player.roster_identity.id==squad[0].id and player.left_handed==(squad[0].dominant_hand=="left"),"identity and handedness preserved")
			check(player.cloth_material.get_shader_parameter("fabric")!=null and player.cloth_material.get_shader_parameter("identity")!=null,"kit and number/name textures preserved")
			check(player.cloth_material.get_shader_parameter("ink")==Color(selected.ink),"kit print colour preserved")
	var report: Dictionary={"pass":failures.is_empty(),"checks":checks,"failures":failures,"spectators":count,"collision_proxies":game.arena_contacts.shapes.size(),"legacy_settings":true,"database_unchanged":FileAccess.get_sha256("user://roster-overrides.json")==canary}
	FileAccess.open("res://docs/graphics85-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAPHICS85 TEST ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

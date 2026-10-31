extends SceneTree
## Native main.tscn parity: the career adapter must not own a second simulation.
## Run without --fallback-test (main._ready uses that flag for its own autorun).
const LegendCareer=preload("res://src/legend_career.gd")
const Kits=preload("res://src/club_kits.gd")

class AdapterGuard extends "res://src/legend_match.gd":
	var legacy_step_calls:=0
	func step(_dt: float) -> void:
		legacy_step_calls+=1
		push_error("Shared engine regression: main delegated physics into legend_match.step")

var exhibition
var career_game
var checks:=0
var failures: Array[String]=[]
var report: Dictionary={}

func animation_trees(node: Node) -> int:
	var count:=1 if node is AnimationTree else 0
	for child in node.get_children(): count+=animation_trees(child)
	return count

func joystick_axis(axis: int,value: float) -> InputEventJoypadMotion:
	var input:=InputEventJoypadMotion.new(); input.axis=axis; input.axis_value=value; return input

func native_pose_benchmark():
	var times: Array=[[],[]]
	var games: Array=[exhibition,career_game]
	for game in games:
		game.self_test=false
		for avatar in game.players: avatar.render_at_draw=false
	for frame in 120:
		for index in 2:
			var began:=Time.get_ticks_usec(); games[index].step(1.0/60.0); times[index].append(Time.get_ticks_usec()-began)
	var summaries: Array=[]
	for samples in times:
		var sum:=0.0
		for value in samples: sum+=value
		samples.sort(); summaries.append({"mean_us":sum/samples.size(),"p95_us":samples[int(samples.size()*.95)]})
	var diff:=first_difference(snapshot(exhibition),snapshot(career_game))
	check(diff.is_empty(),"native pose evaluation also preserves identical ball, roots and animation clocks: "+JSON.stringify(diff))
	var finite:=true
	for game in games:
		for avatar in game.players:
			for pose in avatar.last_pose:
				if not pose.origin.is_finite() or not pose.basis.x.is_finite(): finite=false
		game.self_test=true
	check(finite,"all native skeleton transforms stay finite in both modes")
	report.native_pose={"samples":120,"avatars_per_scene":12,"exhibition":summaries[0],"career":summaries[1],"scope":"CPU shared simulation plus twelve complete native poses at 60 Hz; no stadium renderer/GPU FPS","mismatch":diff}

func test_manual_adapter(adapter,config: Dictionary):
	adapter.stop(); adapter.set("test_ai_driver",false)
	var tree_count:=animation_trees(career_game)
	check(adapter.start(config),"manual shared career starts after parity comparison")
	check(animation_trees(career_game)==tree_count,"manual ownership adds no second pose tree or hidden animated AI clone")
	var controlled: int=adapter.controlled_index
	check(adapter.owns(controlled),"only the created player is manually owned")
	var other:=0
	for index in 12:
		if index!=controlled and adapter.owns(index): other+=1
	check(other==0,"the other eleven athletes remain under exhibition AI")
	var player=career_game.players[controlled]
	var origin: Vector3=player.position
	for frame in 24: career_game.step(1.0/120.0)
	check(player.position.distance_to(origin)<.001,"no-input user does not chase the ball or AI formation")
	career_game._unhandled_input(joystick_axis(JOY_AXIS_LEFT_X,.85))
	var maximum_step:=0.0
	for frame in 70:
		var before: Vector3=player.position; career_game.step(1.0/120.0)
		maximum_step=maxf(maximum_step,player.position.distance_to(before))
	check(player.position.distance_to(origin)>.20,"main input routes LS to manual movement on the shared court")
	check(maximum_step<.14,"manual movement stays bounded without teleporting between animation targets")
	career_game._unhandled_input(joystick_axis(JOY_AXIS_LEFT_X,0))
	for frame in 55: career_game.step(1.0/120.0)
	var stopped: Vector3=player.position
	for frame in 20: career_game.step(1.0/120.0)
	check(player.position.distance_to(stopped)<.015,"released LS brakes instead of resuming automatic pursuit")
	# Moving the visual recommendation is read-only with respect to gameplay.
	var before_ring:=snapshot(career_game); var ideal:=Vector3(-2.3,0,4.2)
	adapter.set_recommendation(ideal)
	check(first_difference(before_ring,snapshot(career_game)).is_empty(),"the AI guide changes neither ball, player state nor match RNG")
	var recommendation=adapter.get("recommended_position")
	check(recommendation is Vector3 and recommendation.distance_to(ideal)<.001,"the guide exposes the real current shared tactical target")
	var guide=adapter.get("guide")
	var marker=guide.get("ring") if is_instance_valid(guide) else null
	check(marker is MeshInstance3D,"the position guide is a small 3D marker, not a shadow simulation")
	if marker is MeshInstance3D:
		var material=marker.material_override
		var alpha:=0.0
		if material is StandardMaterial3D:
			alpha=material.albedo_color.a
			if material.vertex_color_use_as_albedo:
				var maximum:=0.0
				for color in marker.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]: maximum=maxf(maximum,color.a)
				alpha*=maximum
		check(material is StandardMaterial3D and material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED and alpha>0 and alpha<.7,"the position ring uses a semitransparent material")
		guide.sync_from_game()
		check(guide.visible and Vector2(guide.global_position.x-ideal.x,guide.global_position.z-ideal.z).length()<.001,"visible ring follows the exact shared recommendation at floor height")
	check(adapter.legacy_step_calls==0,"manual play never calls the removed separate simulation")
	report.manual={"controlled":controlled,"maximum_step":maximum_step,"animation_trees":tree_count,"legacy_step_calls":adapter.legacy_step_calls}
	adapter.stop()
	check(not adapter.active and not adapter.owns(controlled),"leaving career releases manual ownership for exhibition")

func _initialize(): call_deferred("run")

func check(value: bool,message: String):
	checks+=1
	if not value: failures.append(message); push_error("LEGEND SHARED73 "+message)

func make_game():
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	game.match_audio.enabled=false; game.replay.enabled=false
	for avatar in game.players: avatar.set_process(false)
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):
			child.startup_scan=false; child.installed_version="999.0.0"; child.hide()
	return game

func configure_exhibition(game, config: Dictionary):
	var squads: Array=[config.club_lineup,config.opponent_lineup]
	var clubs: Array=[config.club,config.opponent]
	for team in 2:
		var variant: String="home" if str(clubs[team].id)==str(config.home_club_id) else "away"
		for slot in 6:
			game.players[team*6+slot].set_roster_identity(squads[team][slot],squads[team][6],Kits.selection(str(clubs[team].id),variant),Kits.selection(str(clubs[team].id),variant,true))
		game.team_names[team]=str(clubs[team].get("name",""))
	game.match_management.configure_rosters(clubs,squads,{},config.options)
	game.use_player_stats=true; game.match_best_of=int(config.best_of); game.match_points=int(config.points); game.difficulty=int(config.options.difficulty)
	game.set_home_club(str(config.home_club_id),0 if config.home_club_id==config.club.id else 1)
	game.scores=[0,0]; game.sets=[0,0]; game.rotations=[0,0]; game.server=int(config.first_server)
	game.paused=false; game.match_finished=false; game.gallery=false; game.demo=true; game.started=true
	game.clock_time=0; game.phase_time=0; game.test_contacts=0; game.test_points=0
	game.attack_serial=0; game.shot_serial=0; game.rally_serial=0; game.test_rallies=0; game.contact_log.clear(); game.rally_events.clear(); game.play_log.clear()
	game.rng.seed=int(config.seed)
	game.reset_rally()

func snapshot(game) -> Dictionary:
	var state: Dictionary={}
	for field in ["phase","phase_time","clock_time","scores","sets","rotations","touches","server","possession","receiver","setter","hitter","planned_hitter","planned_direction","destination","fast_set","setter_action","hitter_action","ball_pos","ball_vel","flight_target","flight_left","flight_spin","flight_gravity","incoming_kind","incoming_power","pass_quality","set_quality","armed","charging","charge","test_contacts","test_points"]:
		var value=game.get(field)
		state[field]=value.duplicate(true) if value is Array or value is Dictionary else value
	state.rng=str(game.rng.state)
	var avatars: Array=[]
	for p in game.players:
		avatars.append({"position":p.position,"velocity":p.velocity,"target":p.target,"steering_target":p.steering_target,"yaw":p.rotation.y,"clip":p.clip_name,"time":p.animation_time,"speed":p.animation_speed,"loop":p.looping,"variants":p.variant_names.duplicate(true),"libero":p.libero_active})
	state.players=avatars
	return state

func first_difference(expected: Dictionary,actual: Dictionary) -> Dictionary:
	for key in expected:
		if key=="players":
			for index in expected.players.size():
				for field in expected.players[index]:
					if expected.players[index][field]!=actual.players[index][field]:
						return {"key":"player[%d].%s"%[index,field],"exhibition":str(expected.players[index][field]),"career":str(actual.players[index][field])}
		elif expected[key]!=actual[key]: return {"key":key,"exhibition":str(expected[key]),"career":str(actual[key])}
	return {}

func run():
	var path: String=ProjectSettings.globalize_path("user://").replace("\\","/")
	check(path.contains("legend73"),"test uses isolated workspace APPDATA")
	if not failures.is_empty(): quit(2); return
	var manager=LegendCareer.new(); var player: Dictionary=manager.default_profile(); player.name="Shared Engine 73"
	check(manager.new_career(player,str(manager.starter_clubs()[0].id),{"best_of":3,"autosave":false,"seed":194260},12),"isolated test career creates")
	var config: Dictionary=manager.launch_config()
	config.seed=194260; config.first_server=0
	config.options.seed=194260; config.options.difficulty=1; config.options.fatigue=false; config.options.injuries=false; config.options.auto_subs=false; config.options.date="2026-10-18"
	exhibition=make_game(); career_game=make_game()
	var original=career_game.legend_match
	career_game.remove_child(original); original.free()
	var adapter=AdapterGuard.new(); adapter.name="LegendMatch"; adapter.game=career_game
	career_game.legend_match=adapter; career_game.add_child(adapter)
	adapter.set("test_ai_driver",true)
	check(adapter.start(config),"shared adapter accepts real backend configuration")
	check(adapter.get("test_ai_driver")==true,"strict comparison can bypass only manual ownership, never common physics")
	career_game.demo=true; career_game.self_test=true
	configure_exhibition(exhibition,config)
	var initial:=first_difference(snapshot(exhibition),snapshot(career_game))
	check(initial.is_empty(),"canonical exhibition and career start with identical simulation state: "+JSON.stringify(initial))
	var sampled:=0; var mismatch: Dictionary={}; var phases: Dictionary={}; var begins:=Time.get_ticks_usec()
	if initial.is_empty():
		for frame in 1800:
			exhibition.step(1.0/120.0); career_game.step(1.0/120.0)
			mismatch=first_difference(snapshot(exhibition),snapshot(career_game)); sampled+=1; phases[exhibition.phase]=true
			if not mismatch.is_empty(): mismatch.frame=frame; break
	check(mismatch.is_empty(),"ball, contacts, roles, roots and native clips remain exactly equal: "+JSON.stringify(mismatch))
	check(sampled==1800,"strict state comparison covers 1800 shared physics ticks")
	check(exhibition.test_contacts>=3,"comparison includes physical contacts, not only idle frames")
	check(adapter.legacy_step_calls==0,"main never delegates physics to the removed separate simulator")
	check(exhibition.match_management.active and career_game.match_management.active,"both modes use the same measured match-management system")
	report.parity={"ticks":sampled,"seconds":exhibition.clock_time,"contacts":exhibition.test_contacts,"points":exhibition.test_points,"phases":phases.keys(),"mismatch":mismatch,"initial_difference":initial,"wall_clock_ms":(Time.get_ticks_usec()-begins)/1000.0,"legacy_step_calls":adapter.legacy_step_calls,"native_source_clips":exhibition.clips.size()}
	if initial.is_empty() and mismatch.is_empty(): native_pose_benchmark()
	test_manual_adapter(adapter,config)
	report.checks=checks; report.failures=failures
	FileAccess.open("res://docs/legend73-shared-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND SHARED73 ","PASS" if failures.is_empty() else "FAIL"," ",JSON.stringify(report))
	exhibition.free(); career_game.free(); quit(0 if failures.is_empty() else 1)

extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	await process_frame
	var bench=game.arena_visuals.get_node("TeamBenches")
	assert(bench.actors.size()==18)
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	for team in 2:
		var squad: Array=db.lineup(db.teams[team])
		for i in 6: game.players[team*6+i].set_roster_identity(squad[i],squad[6],kits.selection(db.teams[team].id,"home"),{})
	bench.sync_identity()
	game.started=true; game.paused=false
	bench._process(.1)
	var base=[]
	for entry in bench.actors:
		assert(entry.actor.pose_tree==null,"Bench must not run match AnimationTrees")
		assert(entry.actor.skeleton!=null)
		base.append(entry.actor.skeleton.get_bone_pose_rotation(entry.actor.skeleton.find_bone("Head")))
	game.phase="POINT"; game.scores=[1,0]; game.server=0
	for i in 35: bench._process(.05)
	var changed:=0
	for i in bench.actors.size():
		var entry=bench.actors[i]
		if not base[i].is_equal_approx(entry.actor.skeleton.get_bone_pose_rotation(entry.actor.skeleton.find_bone("Head"))): changed+=1
	assert(changed>=14)
	assert(bench.reaction_team==0)
	var updates: int=bench.updates
	game.paused=true; bench._process(.1); assert(bench.updates==updates)
	game.paused=false
	assert(game.arena_visuals.get_node("NetEquipment").stand.has_node("RefereeHandrail"))
	var audio=game.match_audio
	assert(audio.arena_banks.get("whistle_real",[]).size()>0)
	audio.update_match_state(true,"SERVE")
	assert(audio.event_counts.get("referee_serve",0)==1)
	for i in 30: audio.update_match_state(true,"SERVE")
	audio.update_match_state(true,"SERVE",true); audio.update_match_state(true,"SERVE",false)
	assert(audio.event_counts.get("referee_serve",0)==1,"No double whistle on pause")
	audio.point_event(false)
	assert(audio.event_counts.get("referee_point",0)==1)
	assert(audio.event_counts.get("home_celebration",0)==0)
	audio.update_match_state(true,"POINT"); audio.update_match_state(true,"SERVE")
	assert(audio.event_counts.get("referee_serve",0)==2)
	game.terminal_cpu_block=true; game.possession=1; game.resume_deflection("net")
	assert(game.phase=="LOOSE" and not game.marker.visible)
	game.reset_rally(); assert(not game.terminal_cpu_block)
	print("ARENA61 PASS: up to 16 reserves, 2 coaches, animated independent rigs, actual kits, handrail, real serve/end whistles, pause deduplication, terminal CPU cover reset")
	quit()

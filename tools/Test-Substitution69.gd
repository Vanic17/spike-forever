extends SceneTree
var game
func _initialize(): call_deferred("run")
func press(menu,action: String):
	var event:=InputEventAction.new(); event.action=action; event.pressed=true; menu._input(event)
func run():
	game=load("res://src/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.set_physics_process(false); game.self_test=true; game.match_audio.enabled=false
	await process_frame
	var db=load("res://src/league.gd").new(); var teams=[db.teams[0],db.teams[1]]; var squads=[db.lineup(teams[0]),db.lineup(teams[1])]
	var manager=game.match_management; var menu=manager.menu; var controller_cases:=0
	var lineup_ids: Array=squads[0].map(func(p): return str(p.id))
	var reserve_count: int=teams[0].roster.filter(func(p): return not str(p.id) in lineup_ids and p.role!="libero").size()
	for phase in ["SERVE","SET"]:
		for slot in [0,3,5]:
			for target in reserve_count:
				assert(manager.configure_rosters(teams,squads)); manager.lock_lineup()
				game.started=true; game.phase=phase; game.paused=true; game.charging=false; game.toss_active=false; game.match_finished=false
				for side in 2:
					for i in 6: game.players[side*6+i].set_roster_identity(squads[side][i],squads[side][6],load("res://src/club_kits.gd").selection(teams[side].id,"home"),{})
				menu.open(); menu.choose_slot(slot)
				for i in target: press(menu,"ui_down")
				var row=menu.candidates[target]; assert(root.gui_get_focus_owner()==row)
				var id: String=row.get_meta("player_id"); press(menu,"ui_accept")
				assert(menu.incoming==id and not menu.confirm_button.disabled and root.gui_get_focus_owner()==menu.confirm_button,"Every lower reserve reaches confirm, including a paused live rally")
				press(menu,"ui_accept"); assert(not menu.opened and not game.paused)
				if phase=="SET":
					assert(manager.queued_changes.size()==1 and manager.counts[0]==0 and manager.current[0][slot]!=id)
					game.phase="POINT"; manager.tick(.016); assert(manager.queued_changes.is_empty())
				assert(manager.current[0][slot]==id and manager.counts[0]==1)
				controller_cases+=1
	assert(manager.configure_rosters(teams,squads)); manager.lock_lineup(); game.started=true; game.phase="POINT"; game.paused=true; game.substitution_scene.testing=true
	var scene=game.substitution_scene; scene.set_process(false)
	var benches=game.arena_visuals.get_node("TeamBenches"); benches.sync_identity(); benches.set_process(false)
	var incoming: Dictionary=manager.bench(0).filter(func(p): return p.role=="outside_hitter")[0]
	var outgoing: String=manager.current[0][0]
	var previous_seats: Dictionary={}
	for entry in benches.actors:
		if not entry.coach: previous_seats[str(entry.actor.roster_identity.get("id",""))]=[entry.team,entry.slot]
	assert(manager.substitute(0,0,incoming.id).is_empty()); assert(scene.pending.size()==1)
	# Force the one-second bench poll before the cinematic starts, matching
	# the replay/point delay from the user's recording.
	benches.identity_key=""; benches.sync_identity()
	assert(scene.begin(),"All four routes must exist around the real coach, bench, stand and players")
	var minimum:=100.0
	for frame in ceili(float(scene.timeline.end)*40)+1:
		var time:=frame/40.0; scene.show_scene(time)
		var a: Vector3=scene.actors[0].position; var b: Vector3=scene.actors[1].position
		minimum=minf(minimum,a.distance_to(b))
		if a.distance_to(b)<.74: print("CLEARANCE69 ",time," gap=",a.distance_to(b)," a=",a," b=",b," timeline=",scene.timeline)
		assert(a.distance_to(b)>=.74,"The two substitute actors cannot pass through one another")
		assert(scene.routing.clear_point(Vector2(a.x,a.z)) and scene.routing.clear_point(Vector2(b.x,b.z)),"No path passes through coach, teammates, table or referee stand")
	scene.show_scene(float(scene.timeline.meet)+.6)
	var hands: Array=[]
	for actor in scene.actors:
		var rig: Skeleton3D=actor.skeleton; hands.append(rig.to_global(rig.get_bone_global_pose(rig.find_bone("RightHand")).origin))
	var hand_gap: float=hands[0].distance_to(hands[1]); assert(hand_gap<.18,"High-five wrists must meet in the same physical space")
	var planning: int=scene.last_planning_usec
	scene.finish(); assert(game.players[0].visible and not game.paused)
	for entry in benches.actors:
		var id: String=str(entry.actor.roster_identity.get("id",""))
		if not id.is_empty() and previous_seats.has(id) and id!=str(incoming.id) and id!=outgoing: assert(previous_seats[id]==[entry.team,entry.slot],"Other reserves keep their own seats")
	var report={"controller_cases":controller_cases,"lower_reserves_confirm":true,"live_rally_queued_not_applied":true,"bench_poll_before_scene":true,"stable_bench_seats":true,"minimum_actor_separation":minimum,"high_five_hand_gap":hand_gap,"planning_usec":planning,"paths_avoid_actual_obstacles":true,"native_cinematic_clips":load("res://src/sideline_animation.gd").bank().get_animation_list().size()}
	FileAccess.open("res://docs/substitution69-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SUBSTITUTION69 PASS ",JSON.stringify(report)); game.free(); quit()

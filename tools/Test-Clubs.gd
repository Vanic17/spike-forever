extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.gd").new(); root.add_child(game)
	await process_frame
	var menu
	for node in game.get_children():
		if node.get_script()!=null and node.get_script().resource_path.ends_with("start_menu.gd"): menu=node
	assert(menu!=null)
	var clubs=menu.clubs
	assert(clubs.db.teams.size()==12)
	for team in clubs.db.teams:
		var squad=clubs.db.lineup(team); assert(squad.size()==7,team.name)
		for i in 6: assert(squad[i].role==clubs.db.ROLES[i])
	clubs.editor(); await process_frame
	assert(clubs.inputs.name.text!="")
	clubs.inputs.name.grab_focus()
	for step in 14:
		assert(clubs.focus_editor_step(false))
	await process_frame
	await process_frame
	assert(get_root().gui_get_focus_owner() is Button,"Controller must reach Save past appearance and every rating")
	assert(clubs.editor_scroll.scroll_vertical>0,"Focused editor field must scroll into view")
	clubs.edit_lineup(); clubs.go_back(); assert(not clubs.lineup_open and clubs.visible)
	clubs.match_setup(); await process_frame
	await process_frame
	assert(clubs.settings_format.get_global_rect().end.y<=root.get_visible_rect().end.y,"Match format must stay on screen")
	assert(clubs.settings_points.get_global_rect().end.y<=root.get_visible_rect().end.y,"Match points must stay on screen")
	var start=clubs.body.get_child(clubs.body.get_child_count()-1); start.pressed.emit()
	await process_frame
	assert(game.started and not clubs.visible and not clubs.music.playing)
	assert(not game.players[0].roster_identity.is_empty())
	for p in game.players:
		assert(p.jersey_number.text.is_valid_int() or p.jersey_number.text=="?")
	game.match_best_of=3; game.match_points=25; game.sets=[1,1]; game.scores=[14,14]; game.phase="SERVE"; game.award(0,"TEST")
	assert(game.sets==[1,1])
	game.phase="SERVE"; game.award(0,"TEST"); assert(game.sets==[2,1])
	game.paused=false; game.phase="ATTACK"; game.manual_wall.jumped.assign([1]); game.block_commanded=true
	game.ball_pos=Vector3(0,3,2); game.incoming_kind="spike"
	game.send_to_court(0,Vector3(0,0.105,-6),0.7)
	assert(not game.block_commanded and game.manual_wall.jumped.is_empty(),"New opposing possession must unlock manual wall")
	game.players[5].position=Vector3(0,0,5)
	var points=[Vector3(0,0,3),Vector3(0.6,0,3),Vector3(-0.6,0,3)]
	game.court_shape.recovery_bypass.clear()
	var waypoint: Vector3=game.court_shape.route_around_recovery(game,5,Vector3(0,0,1),{4:points})
	assert(waypoint!=Vector3(0,0,1))
	assert(game.court_shape.clear_recovery_route(Vector3(0,0,5),waypoint,points,0.98),"Recovery detour must clear actual body volume")
	game.court_shape.route_around_recovery(game,5,Vector3(0,0,1),{})
	assert(not game.court_shape.recovery_bypass.has(5),"Expired fallen body must not leave a stale route")
	print("CLUBS PASS: 12 lineups / editor / setup / uniforms / jersey numbers / deciding set / music stopped")
	quit()

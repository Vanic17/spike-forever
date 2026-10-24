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
	menu.play.grab_focus()
	var play_active=menu.play.get_theme_stylebox("normal")
	var updates_dark=menu.updates.get_theme_stylebox("normal")
	menu.updates.grab_focus()
	assert(menu.play.get_theme_stylebox("normal")!=play_active and menu.updates.get_theme_stylebox("normal")!=updates_dark,"Gold selection must follow controller focus")
	assert(clubs.db.teams.size()==12)
	for team in clubs.db.teams:
		var squad=clubs.db.lineup(team); assert(squad.size()==7,team.name)
		for i in 6: assert(squad[i].role==clubs.db.ROLES[i])
	clubs.editor(); await process_frame
	assert(clubs.inputs.name.text!="")
	clubs.player_pick.grab_focus()
	var enter=InputEventAction.new(); enter.action="ui_accept"; enter.pressed=true; clubs._input(enter)
	assert(clubs.editing_details and clubs.inputs.name.has_focus())
	clubs.go_back(); assert(not clubs.editing_details and clubs.player_pick.has_focus())
	clubs.enter_details()
	clubs.inputs.name.grab_focus()
	for step in 24:
		assert(clubs.focus_editor_step(false))
		await process_frame
		var focused=get_root().gui_get_focus_owner()
		if focused is Button and focused.text=="SALVA MODIFICHE": break
	await process_frame
	await process_frame
	assert(get_root().gui_get_focus_owner() is Button,"Controller must reach Save past appearance and every rating")
	assert(clubs.editor_scroll.scroll_vertical>0,"Focused editor field must scroll into view")
	clubs.edit_lineup(); clubs.go_back(); assert(not clubs.lineup_open and clubs.visible)
	clubs.match_setup(); await process_frame
	await process_frame
	assert(clubs.settings_format.get_global_rect().end.y<=root.get_visible_rect().end.y,"Match format must stay on screen")
	assert(clubs.settings_points.get_global_rect().end.y<=root.get_visible_rect().end.y,"Match points must stay on screen")
	clubs.show_match_formation(0,clubs.db.teams[0],menu.play)
	await process_frame
	var options=clubs.formation_dialog.find_children("*","OptionButton",true,false)
	assert(options.size()==8)
	var rotation_pick=options.pop_front()
	for rotation in 6:
		rotation_pick.select(rotation); rotation_pick.item_selected.emit(rotation)
		for pick in options:
			assert(not pick.focus_neighbor_bottom.is_empty())
		var cursor: Control=rotation_pick
		for step in 5:
			if cursor==clubs.formation_dialog.get_ok_button(): break
			cursor=cursor.get_node(cursor.focus_neighbor_bottom)
		assert(cursor==clubs.formation_dialog.get_ok_button(),"Every rotation must have a downward path to Confirm")
	rotation_pick.select(3); rotation_pick.item_selected.emit(3)
	clubs.formation_dialog.confirmed.emit()
	assert(clubs.match_rotations[0]==3)
	options[-1].grab_focus()
	var down=InputEventJoypadButton.new(); down.button_index=JOY_BUTTON_DPAD_DOWN; down.pressed=true
	clubs.formation_dialog.push_input(down)
	await process_frame
	assert(clubs.formation_dialog.gui_get_focus_owner()==clubs.formation_dialog.get_ok_button(),"Controller down from libero must actually focus Confirm")
	var original: String=clubs.db.lineup(clubs.db.teams[0])[2].id
	if options[0].item_count>1:
		var next: int=(options[0].selected+1)%options[0].item_count
		options[0].select(next); options[0].item_selected.emit(next)
		clubs.formation_dialog.confirmed.emit()
		assert(clubs.match_rosters[0][2].id!=original,"Prematch substitution must reach the actual squad")
	clubs.formation_dialog.hide()
	clubs.music_queue.clear(); clubs.last_track=-1
	var played: Array=[]
	for i in 9:
		clubs.next_track(); assert(not clubs.last_track in played); played.append(clubs.last_track)
	var previous: int=clubs.last_track
	var skip=InputEventJoypadButton.new(); skip.button_index=JOY_BUTTON_RIGHT_STICK; skip.pressed=true; clubs._input(skip)
	assert(clubs.last_track!=previous and clubs.music.playing,"R3 must skip continuously across shuffled queues")
	var start=clubs.body.get_child(clubs.body.get_child_count()-1); start.pressed.emit()
	await process_frame
	assert(game.started and not clubs.visible and not clubs.music.playing)
	assert(game.rotations==[3,0],"Confirmed initial rotation must be applied to the match")
	assert(not game.players[0].roster_identity.is_empty())
	if not clubs.match_rosters[0].is_empty(): assert(game.players[2].roster_identity.id==clubs.match_rosters[0][2].id)
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

extends SceneTree
var game
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	assert("graphics90" in OS.get_environment("APPDATA"))
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false);p.render_at_draw=false
	for i in 8:await process_frame
	game.match_audio.enabled=false
	var db=load("res://src/league.gd").new();var count:=0;var protected:=0;var footwear: Dictionary={};var lengths: Dictionary={}
	var p=game.players[1];var position=p.transform;var rotations=game.rotations.duplicate();var timing=p.clips.attack.contact_time
	for team in db.teams:
		for person in team.roster:
			count+=1
			p.libero_active=false;p.set_roster_identity(person,{},load("res://src/club_kits.gd").selection(team.id,"home"),{})
			check(p.height_scale90>0 and is_equal_approx(p.height_scale90,float(person.height_cm)/189.4563),"height matches database "+person.id)
			check(p.transform==position,"height preserves actor transform "+person.id)
			var nodes: Array=p.get_meta("wear90_nodes",[])
			var pieces: Array=p.get_meta("wear90_pieces",[])
			check(pieces.size() in [2,4] and nodes.size()==1,"all players have socks in one draw "+person.id)
			if pieces.size()==4:protected+=1
			if person.role=="libero":check(pieces.size()==4,"all liberos protected "+person.id)
			for n in nodes:
				check(n.skin!=null and n.get_node(n.skeleton)==p.skeleton,"accessory bound to original rig")
			for name in pieces:lengths[name]=true
			footwear[p.get_meta("shoe_model90")]=true
	check(count==169 and protected>=150,"all 169 players and almost all protected")
	check(footwear.size()==4 and lengths.size()==10,"four shoe geometries and all fitted variants exercised")
	check(game.rotations==rotations and p.clips.attack.contact_time==timing,"rotation and animation timing preserved")
	var person: Dictionary=db.teams[0].roster[0].duplicate(true);person.height_cm=177;p.set_roster_identity(person,{},load("res://src/club_kits.gd").selection(db.teams[0].id,"home"),{})
	var low: float=p.stature_pivot90.global_basis.get_scale().y
	person.height_cm=214;p.set_roster_identity(person,{},load("res://src/club_kits.gd").selection(db.teams[0].id,"home"),{})
	check(p.stature_pivot90.global_basis.get_scale().y>low*1.2,"visible 177 versus 214cm stature")
	check(p.contact_local("attack").is_equal_approx(p.clips.attack.contact_offset*p.height_scale90),"contact height scales with rendered rig")
	p.play("idle",1,true);p.apply_pose(1.0/120)
	var foot: int=p.clips.idle.names.find("LeftFoot")
	check(p.current_joint("LeftFoot").is_equal_approx(p.pose_world84()*p.last_pose[foot].origin),"IK and contact use same world transform")
	game.started=true;game.paused=false;game.clock_time=1;game.render_smoother.reset(game);game.render_smoother.after_tick(game)
	var old: Vector3=p.position;p.position.x+=.10;game.clock_time+=1.0/120;game.render_smoother.after_tick(game);game.render_smoother.draw(game,.5)
	check(p.visual_root.global_position.is_equal_approx(old.lerp(p.position,.5)),"scaled models retain smooth interpolation")
	game.render_smoother.reset(game)
	for entry in game.arena_visuals.get_node("TeamBenches").actors:
		if not entry.coach:
			check(entry.actor.get_meta("wear90_pieces",[]).size()>=2,"bench socks and varied footwear")
	var view=load("res://src/view_controls.gd")
	check(view.origin(0)==Vector3(0,6.3,18.4) and view.origin(3)==Vector3(0,9.8,18.4),"first and third camera exchanged")
	check(view.next_camera(0)==2 and view.next_camera(2)==3 and view.next_camera(3)==0,"camera cycle preserved")
	check(view.court_direction(Vector2.LEFT,0)==Vector2.LEFT and view.court_direction(Vector2.LEFT,3)==Vector2.LEFT,"aim controls preserved")
	game.legend_match.active=false;game.started=false
	for cm in [177,195,214]:
		person.height_cm=cm;p.set_roster_identity(person,{},load("res://src/club_kits.gd").selection(db.teams[0].id,"home"),{})
		for left in [false,true]:
			p.left_handed=left;p.rotation.y=PI
			for action in ["receive","set","fast_set","attack","power","float","block"]:
				p.select_variant(action);p.reach_weight=0;p.play(action,1,false)
				game.ball_pos=p.contact_world(action)
				check(game.validate_contact(1,action),"physical palm contact at %dcm %s left=%s"%[cm,action,str(left)])
	var legacy: Dictionary=db.teams[0].roster[0].duplicate(true);var official: int=int(legacy.height_cm)
	legacy.erase("height_cm");legacy.erase("height_metadata");legacy.name="Personal name kept"
	check(db.save(legacy)==OK,"write isolated old-format fixture")
	var restored=load("res://src/league.gd").new()
	check(restored.teams[0].roster[0].height_cm==official and restored.teams[0].roster[0].name==legacy.name,"new base height merges without replacing old personal edits")
	legacy.height_cm=201;check(db.save(legacy)==OK,"save custom local height")
	restored=load("res://src/league.gd").new()
	check(restored.teams[0].roster[0].height_cm==201,"edited height persists above base data")
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):menu=child
	game.started=false;menu.show();menu.clubs.editor()
	var clubs=menu.clubs;clubs.enter_details();clubs.inputs.height.get_line_edit().grab_focus()
	var event=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_DPAD_LEFT;event.pressed=true
	var height_before: float=clubs.inputs.height.value;clubs._input(event)
	check(clubs.inputs.height.value==height_before-1,"controller edits centimetres")
	clubs.go_back();check(not clubs.editing_details and clubs.player_pick.has_focus(),"Circle returns from height editor to roster")
	var report={"pass":failures.is_empty(),"checks":checks,"players":count,"protected":protected,"shoe_models":footwear.size(),"errors":failures}
	FileAccess.open("res://docs/stature90-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("STATURE90 ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)

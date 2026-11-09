extends SceneTree
var checks:=0
func check(value: bool,message: String):
	checks+=1
	assert(value,message)
func _initialize():call_deferred("run")
func run():
	check("profile95" in OS.get_environment("APPDATA"),"isolated profile")
	var game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false)
	for actor in game.players:actor.set_process(false);actor.render_at_draw=false
	await process_frame
	var p=game.players[0];var before: int=game.rng.state
	check(p.body_parts.head.mesh.resource_path.contains("prototype_head"),"pilot uses compatible uncompressed head")
	var jump_rows: Array=[]
	for height in [170,180,195,210]:
		preload("res://src/player_stature90.gd").apply(p,{"height_cm":height})
		for action in ["attack","block","power"]:
			p.play(action,1,false);p.blend_left=0
			var peak:float=0;var foot:float=10
			for sample in 121:
				p.animation_time=p.clips[action].duration*float(sample)/120.0;p.apply_pose(0)
				peak=maxf(peak,p.current_joint("Head").y+.12*p.height_scale90)
				foot=minf(foot,minf(p.current_joint("LeftToeBase").y,p.current_joint("RightToeBase").y))
				check(p.current_hand(false).is_finite(),"finite interpolated jumping pose")
			check(absf(peak-preload("res://src/player_pose95.gd").CROWN_TARGET)<.025,"crown close to tape for "+action+" height "+str(height)+" got "+str(peak))
			check(foot>-.08,"no foot below floor "+str(foot))
			p.animation_time=p.clips[action].contact_time;p.apply_pose(0)
			check(p.current_hand(false).distance_to(p.contact_world(action))<.19,"contact planner follows new jump")
			jump_rows.append({"height_cm":height,"action":action,"crown_peak_m":peak,"lowest_toe_m":foot})
	preload("res://src/player_stature90.gd").apply(p,{"height_cm":189.4563})
	var variants:=0
	for name in game.clips:
		if not preload("res://src/player_pose95.gd").jumping(name):continue
		var clip=game.clips[name];var peak:float=0
		for sample in 81:
			var pose: Array[Transform3D]=p.normalized_pose("source:"+name,clip.duration*float(sample)/80.0,false)
			peak=maxf(peak,pose[clip.names.find("Head")].origin.y+.12)
		check(absf(peak-preload("res://src/player_pose95.gd").CROWN_TARGET)<.04,"same jump scale for variant "+name+" got "+str(peak))
		variants+=1
	for level in 4:
		p.get_meta("visual_quality89").quality(level)
		check(not p.body_parts.head.mesh.resource_path.contains("quality89/head"),"no compressed scan in any quality preset")
	for actor in game.players:
		actor.play("relaxed",1,true);actor.blend_left=0;actor.animation_time=.3;actor.apply_pose(0)
		var body=actor.model_bank.body
		for bone in body.names.size():
			if body.names[bone] not in ["Jaw","Nostril_L","CheekBone_R"]:continue
			check(actor.skeleton.get_bone_pose(bone).is_equal_approx(body.rest[bone]),"neutral facial proportions "+body.names[bone])
	for left in [false,true]:
		p.left_handed=left;p.play("attack",1,false);p.blend_left=0
		for offset in [-.12,0,.12]:
			p.wrist_tip_variant="";p.animation_time=p.clips.attack.contact_time+offset;p.apply_pose(0)
			var elbow: Vector3=p.current_joint("LeftForeArm" if left else "RightForeArm");var hand: Vector3=p.current_hand(false)
			p.wrist_tip_variant="attack_wrist94";p.apply_pose(0)
			if offset==0:check(p.current_hand(false).distance_to(hand)<.001,"tip keeps exact contact")
			else:check(p.current_joint("LeftForeArm" if left else "RightForeArm").distance_to(elbow)>.015,"tip changes the arm, not only wrist")
	check(game.rng.state==before,"presentation consumes no gameplay RNG")
	FileAccess.open("res://docs/player-pose95-validation"+("" if p.native_animation_enabled else "-fallback")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"checks":checks,"jumps":jump_rows,"both_hands":true,"jump_variants":variants},"  "))
	print("PLAYER POSE95 PASS ",checks);quit()

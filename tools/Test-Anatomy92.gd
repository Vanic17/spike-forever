extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	assert("anatomy92" in OS.get_environment("APPDATA"))
	var game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false);game.match_audio.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	for i in 4:await process_frame
	var actor=game.players[1];var V=load("res://src/anatomical_player92.gd");var A=load("res://src/player_visual91.gd");var kits=load("res://src/club_kits.gd")
	var db=load("res://src/league.gd").new();var count:=0;var skeleton=actor.skeleton
	var transform: Transform3D=actor.transform;var rests: Array=[]
	for bone in skeleton.get_bone_count():rests.append(skeleton.get_bone_rest(bone))
	for team in db.teams:
		for person in team.roster:
			count+=1;var original: Dictionary=person.duplicate(true)
			actor.libero_active=false;actor.set_roster_identity(person,{},kits.selection(team.id,"home"),{})
			check(actor.has_meta("anatomical92"),"new layer "+person.id)
			check(actor.body_parts.body.mesh==V.mesh("skin_l2"),"continuous anatomical skin "+person.id)
			check(person==original and actor.roster_identity==original,"identity preserved "+person.id)
			check(actor.transform==transform and actor.skeleton==skeleton,"actor transform and rig unchanged")
			var cfg: Dictionary=actor.get_meta("blender91_identity")
			check(cfg.raw_appearance==person.appearance and cfg.height_cm==person.height_cm,"appearance and stature preserved")
			check(actor.body_parts.hair.visible==(cfg.hair!="pelato"),"baldness preserved")
			check(actor.body_parts.beard.visible==(cfg.beard in ["corta","piena"]),"beard preserved")
	for bone in skeleton.get_bone_count():check(rests[bone]==skeleton.get_bone_rest(bone),"unchanged bind rest "+str(bone))
	for action in ["idle","receive","set","fast_set","attack","power","float","block"]:
		actor.play(action,1,action=="idle");actor.animation_time=.2;actor.apply_pose(0)
		var pose: Array=[]
		for bone in skeleton.get_bone_count():pose.append(skeleton.get_bone_pose(bone))
		var contact: Vector3=actor.contact_world("attack");A.apply(actor)
		for bone in skeleton.get_bone_count():check(pose[bone]==skeleton.get_bone_pose(bone),"no animation writer "+action)
		check(contact.is_equal_approx(actor.contact_world("attack")),"no gameplay contact change "+action)
	var quality=actor.get_meta("visual_quality89");var counts: Array=[]
	var face_arrays: Array=V.mesh("skin_l2").surface_get_arrays(0);var jaw_samples:=0;var jaw_aligned:=true
	check(skeleton.get_bone_name(6)=="Head","original Head bone binding")
	for i in face_arrays[Mesh.ARRAY_VERTEX].size():
		var p: Vector3=face_arrays[Mesh.ARRAY_VERTEX][i]
		if p.y>1.625 and p.y<1.75 and absf(p.x)<.12:
			var head_weight:=0.0
			for j in 4:
				if face_arrays[Mesh.ARRAY_BONES][i*4+j]==6:head_weight+=face_arrays[Mesh.ARRAY_WEIGHTS][i*4+j]
			if absf(head_weight-1)>.0001:jaw_aligned=false
			jaw_samples+=1
	check(jaw_samples>1000 and jaw_aligned,"mandible and facial grooms remain on the same rigid head")
	for level in [0,1,2]:
		quality.detail=level;A.apply(actor);var m: Mesh=actor.body_parts.body.mesh;counts.append(m.surface_get_array_index_len(0)/3)
	check(counts[0]<counts[1] and counts[1]<counts[2],"three actual geometric detail levels")
	var result={"pass":failures.is_empty(),"checks":checks,"players":count,"triangles":counts,"original_bones":skeleton.get_bone_count(),"errors":failures,"visual_approval":false,"prototype_only":true}
	FileAccess.open("res://docs/anatomy92-validation.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("ANATOMY92 TEST ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)

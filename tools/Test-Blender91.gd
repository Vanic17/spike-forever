extends SceneTree
var checks:=0
var errors: Array[String]=[]
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
	assert("blender91" in OS.get_environment("APPDATA"))
	var V=load("res://src/player_visual91.gd")
	check(V.available(),"validated visual library available")
	var game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.self_test=true;game.set_process(false);game.set_physics_process(false);game.match_audio.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	for i in 4:await process_frame
	var actor=game.players[1];var rig=actor.skeleton
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/blender91-identities.json"))
	var kit_api=load("res://src/club_kits.gd");var ids: Dictionary={};var forms: Dictionary={}
	var initial_transform: Transform3D=actor.transform;var contact_time: float=actor.clips.attack.contact_time
	var rest: Array=[]
	for bone in rig.get_bone_count():rest.append(rig.get_bone_rest(bone))
	check(rest.size()==115,"original 115-bone rig")
	for row in manifest.players:
		var person: Dictionary=row.effective;var kit=kit_api.selection(row.team_id,"home")
		actor.libero_active=false;actor.set_roster_identity(person,{},kit,{})
		var cfg: Dictionary=actor.get_meta("blender91_identity",{})
		check(cfg.get("raw_appearance")==person.appearance,"exact appearance "+row.id)
		check(cfg.get("id")==row.id and cfg.get("height_cm")==person.height_cm,"ID and height "+row.id)
		check(actor.body_parts.hair.visible==(cfg.hair!="pelato"),"bald/hair visibility "+row.id)
		check(actor.body_parts.beard.visible==(cfg.beard in ["corta","piena"]),"beard visibility "+row.id)
		check(actor.body_parts.head.mesh==V.mesh("head_v%02d_l2"%cfg.head_variant),"native head mesh "+row.id)
		check(actor.body_parts.head.material_override.albedo_texture==V.Assets.texture("scan_albedo91.png"),"scan UV atlas survives identity callbacks "+row.id)
		check(actor.transform==initial_transform and actor.skeleton==rig,"identity never moves actor or changes rig "+row.id)
		for key in ["head","body","cloth","eyes","shoes"]:
			var node: MeshInstance3D=actor.body_parts[key]
			check(node.skin!=null and node.get_node(node.skeleton)==rig,"original skin binding "+key)
		ids[row.id]=true;forms[cfg.head_variant]=true
	check(ids.size()==169 and forms.size()==8,"all players / eight deterministic face shapes")
	for bone in rig.get_bone_count():check(rest[bone]==rig.get_bone_rest(bone),"unchanged bone rest "+str(bone))
	check(actor.clips.attack.contact_time==contact_time,"original contact timing")
	var quality=actor.get_meta("visual_quality89");var tri_counts: Array=[]
	for level in 4:
		quality.detail=level;V.apply(actor)
		check(actor.body_parts.body.mesh==V.mesh("body_l"+str(level)),"real geometry LOD "+str(level))
		tri_counts.append(V.library.parts["body_l"+str(level)].triangles)
	check(tri_counts[0]<tri_counts[1] and tri_counts[1]<tri_counts[2] and tri_counts[2]<tri_counts[3],"four progressively lighter meshes")
	quality.detail=2;V.apply(actor)
	var example: Dictionary=manifest.players[0].effective.duplicate(true)
	for cm in [177,195,214]:
		example.height_cm=cm;actor.set_roster_identity(example,{},kit_api.selection(manifest.players[0].team_id,"home"),{})
		for left in [false,true]:
			actor.left_handed=left
			for action in ["idle","receive","set","fast_set","attack","power","float","block"]:
				actor.play(action,1,action=="idle");actor.animation_time=.2;actor.apply_pose(0)
				var before: Array=[]
				for bone in rig.get_bone_count():before.append(rig.get_bone_pose(bone))
				V.apply(actor)
				var untouched:=true
				for bone in rig.get_bone_count():
					if before[bone]!=rig.get_bone_pose(bone):untouched=false
				check(untouched,"presentation never writes animation pose %d %s %s"%[cm,left,action])
				check(actor.current_joint("Head").is_finite(),"finite animated head")
	var head_mesh: Mesh=actor.body_parts.head.mesh
	V.enabled=false;V.apply(actor);check(actor.body_parts.head.mesh==head_mesh and not V.available(),"fallback switch bypasses visual writer")
	V.enabled=true
	var result={"pass":errors.is_empty(),"checks":checks,"players":ids.size(),"face_variants":forms.size(),"body_lod_triangles":tri_counts,"errors":errors}
	FileAccess.open("res://docs/blender91-validation.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("BLENDER91 TEST ",JSON.stringify(result));quit(0 if errors.is_empty() else 1)

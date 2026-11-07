extends SceneTree
var game
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok and not errors.has(message):errors.append(message);push_error(message)
func _initialize():call_deferred("run")
func fingerprint() -> Array:
	return [game.rng.state,game.ball_pos,game.ball_vel,game.phase,game.rotations.duplicate(),game.scores.duplicate(),game.players.map(func(p):return [p.position,p.animation_time,p.contact_world("attack")])]
func run():
	assert("graphics86" in OS.get_environment("APPDATA").to_lower(),"Use an isolated graphics86 profile")
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.self_test=true;game.set_process(false);game.set_physics_process(false)
	for p in game.players:p.set_process(false)
	await process_frame;await process_frame;await process_frame
	var visual=game.arena_visuals.get_node("VisualUpgrade85/VisualUpgrade86")
	var baseline=fingerprint()
	check(game.players.filter(func(p):return p.has_meta("visual_prototype86")).size()==1,"Exactly one prototype athlete")
	var reference_bones: Array=game.models.body.names
	for p in game.players:
		check(p.skeleton.get_bone_count()==reference_bones.size(),"Bone count preserved")
		for i in reference_bones.size():check(p.skeleton.get_bone_name(i)==reference_bones[i],"Bone names and ordering preserved")
	var skin_cases:=0
	var deviations: Dictionary={}
	for part in visual.prototype.meshes:
		var mesh: ArrayMesh=visual.prototype.meshes[part]
		var original: ArrayMesh=visual.prototype.originals[part]
		check(mesh.get_surface_count()==original.get_surface_count(),"Mesh materials retained")
		for surface in mesh.get_surface_count():
			var a: Array=mesh.surface_get_arrays(surface);var vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=a[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX];var edge_reference: Dictionary={}
			for face in range(0,indices.size(),12):
				edge_reference[indices[face+1]]=[indices[face],indices[face+4]]
				edge_reference[indices[face+5]]=[indices[face+4],indices[face+8]]
				edge_reference[indices[face+2]]=[indices[face+8],indices[face]]
			check(bones.size()==vertices.size()*4 and weights.size()==bones.size(),"Valid skin buffers")
			for v in vertices.size():
				var sum:=0.0
				for k in 4:
					check(bones[v*4+k]>=0 and bones[v*4+k]<reference_bones.size(),"Skin bone index valid")
					check(is_finite(weights[v*4+k]) and weights[v*4+k]>=0,"Finite skin weights");sum+=weights[v*4+k]
				check(abs(sum-1.0)<.0001 and vertices[v].is_finite(),"Normalized skin weights and finite vertices")
				if v%97==0:
					for action in ["idle","receive","set","attack","block","power"]:
						var actor=game.players[0]
						if not actor.clips.has(action):continue
						var clip=actor.clips[action]
						for fraction in [.0,.35,.65,1.0]:
							var pose: Array=actor.normalized_pose(action,clip.duration*fraction,false)
							var point:=Vector3.ZERO
							for k in 4:
								if weights[v*4+k]<=0:continue
								var bone: int=bones[v*4+k];var animation_bone: int=clip.names.find(reference_bones[bone])
								var rest: Transform3D=actor.skeleton.get_bone_global_rest(bone)
								if animation_bone>=0:point+=pose[animation_bone]*rest.affine_inverse()*vertices[v]*weights[v*4+k]
							check(point.is_finite() and point.length()<4.0,"Prototype deforms inside athletic bounds");skin_cases+=1
							if edge_reference.has(v):
								var expected:=Vector3.ZERO
								for endpoint in edge_reference[v]:
									for k in 4:
										if weights[endpoint*4+k]<=0:continue
										var bone: int=bones[endpoint*4+k];var animation_bone: int=clip.names.find(reference_bones[bone])
										var rest: Transform3D=actor.skeleton.get_bone_global_rest(bone)
										if animation_bone>=0:expected+=pose[animation_bone]*rest.affine_inverse()*vertices[endpoint]*weights[endpoint*4+k]*.5
								var drift:=point.distance_to(expected)
								deviations[part]=maxf(float(deviations.get(part,0.0)),drift)
								check(drift<.012,"Refined edges remain within 12mm of original deformed edge")
	for preset in 4:
		var values: Dictionary=game.preferences.data.duplicate();values.merge(game.preferences.PRESETS[preset],true)
		values.exposure=1.1;game.preferences.apply(values,false)
		check(fingerprint()==baseline,"Graphical presets do not change simulation or contacts")
		check(Engine.physics_ticks_per_second==120,"120Hz preserved")
		check(is_equal_approx(visual.base.world.environment.tonemap_exposure,1.1),"Exposure preference respected")
		check(game.preferences.save_config()==OK,"Settings save")
		check(game.players[0].body_parts.head.mesh==visual.prototype.meshes.head if preset>=2 else game.players[0].body_parts.head.mesh==visual.prototype.originals.head,"Geometry quality is reversible")
	var league=load("res://src/league.gd").new()
	var appearance_service=load("res://src/player_appearance.gd")
	var assets=load("res://src/source_assets.gd")
	for beard in ["piena","nessuna"]:
		for hair in ["corti","pelato"]:
			var appearance={"skin_tone":"olivastra","hair_style":hair,"hair_color":"nero","beard":beard}
			appearance_service.apply(game.players[0],appearance)
			var m: StandardMaterial3D=game.players[0].body_parts.head.material_override
			var expected: String="T_Char_Head_Caucasian_M_01_Base.png" if beard=="piena" else ("T_Char_Head_M_Coach02_Base.png" if hair=="pelato" else "T_Char_Head_Caucasian_M_02_Base.png")
			check(m.albedo_texture==assets.texture(expected),"Bearded, clean and bald appearance retained")
			check(m.albedo_color==appearance_service.SKIN.olivastra,"Database skin tint retained")
			visual.prototype.quality(2)
			check(m.albedo_texture==assets.texture(expected),"Appearance survives quality changes")
	for club in league.teams:
		game.set_home_club(club.id,0)
		var profile: Dictionary=load("res://src/arena_profiles.gd").profile(club.id)
		check(game.arena_visuals.court_material.albedo_color.is_equal_approx(Color(profile.court)),"One sRGB conversion for "+club.id)
		check(game.arena_visuals.free_zone_material.albedo_color.is_equal_approx(Color(profile.free_zone)),"Arena pigments preserved")
	game.arena_contacts.build()
	var collision_fingerprint: Array=game.arena_contacts.shapes.map(func(s):return [str(s.bounds),s.kind,s.bounce])
	check(game.arena_contacts.shapes.size()==1401,"Same scenery proxy count")
	check(game.arena_visuals.crowd_instance_count==1280,"Same spectator count")
	var geometry: Array=[]
	for child in game.arena_visuals.get_children():
		if child is MultiMeshInstance3D and child.has_meta("spectators"):check(is_equal_approx(child.lod_bias,.8),"Crowd LOD preserved")
	var report={"pass":errors.is_empty(),"checks":checks,"errors":errors,"skin_samples":skin_cases,"max_edge_deviation_m":deviations,"prototypes":1,"spectators":1280,"collision_proxies":collision_fingerprint,"cases":"6 action families x 4 poses, four presets, twelve arenas, original bone names/order/contact points"}
	FileAccess.open("res://docs/graphics86-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAPHICS86 TEST ","PASS" if errors.is_empty() else "FAIL",errors);game.free();quit(0 if errors.is_empty() else 1)

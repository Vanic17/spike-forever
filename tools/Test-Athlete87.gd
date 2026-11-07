extends SceneTree
var game
var checks:=0
func check(value: bool,message: String):
	checks+=1
	assert(value,message)
func _initialize():call_deferred("run")
func state():return [game.rng.state,game.ball_pos,game.ball_vel,game.phase,game.rotations.duplicate(),game.scores.duplicate(),game.players.map(func(p):return [p.transform,p.animation_time,p.clip_name,p.contact_world("attack"),p.contact_world("set")])]
func run():
	assert("athlete87" in OS.get_environment("APPDATA").to_lower())
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true
	for p in game.players:p.set_process(false)
	await process_frame;await process_frame
	check(game.players.filter(func(p):return p.has_meta("visual_prototype87")).size()==1,"Only one pilot")
	var actor=game.players[0];var visual=actor.get_meta("visual_prototype87");var snapshot=state()
	var others=game.players.slice(1).map(func(p):return p.body_parts.head.mesh)
	for level in [0,1,2,3,2]:
		visual.quality(level)
		check(state()==snapshot,"Visual changes do not change gameplay or contacts")
	for i in others.size():check(game.players[i+1].body_parts.head.mesh==others[i],"Other athletes untouched")
	check(actor.body_parts.cloth.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]!=null,"Name and jersey print UV retained")
	var sampled:=0
	for part in visual.meshes:
		var mesh: ArrayMesh=visual.meshes[part]
		for surface in mesh.get_surface_count():
			var a=mesh.surface_get_arrays(surface);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var b: PackedInt32Array=a[Mesh.ARRAY_BONES];var w: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			for i in v.size():
				var total:=0.0
				for k in 4:
					check(b[i*4+k]>=0 and b[i*4+k]<actor.skeleton.get_bone_count(),"Bone IDs compatible")
					check(is_finite(w[i*4+k]) and w[i*4+k]>=0,"Finite weights");total+=w[i*4+k]
				check(absf(total-1)<.0001 and v[i].is_finite(),"Valid weighted vertex")
				if i%113!=0:continue
				for action in ["idle","receive","set","attack","block","power","dive"]:
					if not actor.clips.has(action):continue
					var clip=actor.clips[action]
					for fraction in [0.0,.25,.5,.75,1.0]:
						var pose: Array=actor.normalized_pose(action,clip.duration*fraction,false);var point:=Vector3.ZERO
						for k in 4:
							if w[i*4+k]==0:continue
							var index: int=b[i*4+k];var bone_name: String=actor.skeleton.get_bone_name(index);var animation_bone: int=clip.names.find(bone_name)
							check(animation_bone>=0,"Animation supports skin bone")
							point+=pose[animation_bone]*actor.skeleton.get_bone_global_rest(index).affine_inverse()*v[i]*w[i*4+k]
						check(point.is_finite() and point.length()<4,"Finite athletic deformation");sampled+=1
	var shoe_colors: Dictionary={}
	for p in game.players:shoe_colors[str(p.body_parts.shoes.material_override.albedo_color)]=true
	check(shoe_colors.size()>3,"Independent footwear variants")
	FileAccess.open("res://docs/athlete87-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"checks":checks,"pose_samples":sampled,"bone_count":actor.skeleton.get_bone_count(),"pilot_count":1,"shoe_color_variants":shoe_colors.size(),"gameplay_state_unchanged":state()==snapshot,"scope":"presentation only; skinned vertex samples across seven existing actions; other eleven athlete heads unchanged"},"  "))
	print("ATHLETE87 TEST PASS ",checks," checks / ",sampled," pose samples");quit()

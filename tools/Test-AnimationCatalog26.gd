extends SceneTree
const Expansion=preload("res://src/animation_expansion.gd")
const Variety=preload("res://src/animation_variety.gd")
const Converter=preload("res://src/psa_animation_library.gd")
const Avatar=preload("res://src/avatar.gd")
var failed:=false
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failed=true
		push_error(message)
func _initialize() -> void: call_deferred("run")
func digest(path: String) -> String:
	var context=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.started=true
	game.self_test=true
	game.demo=false
	game.set_process(false)
	game.set_physics_process(false)
	var selected: Dictionary={}
	for serial in 360:
		for local in [Vector3(-1.4,0,0),Vector3(0,0,0),Vector3(1.4,0,0),Vector3(0,0,1.5)]:
			for incoming in ["serve","spike","tip"]:
				selected[Variety.receive(local,2.0,incoming,serial)]=true
				selected[Variety.diving(local,incoming,serial)]=true
		for back in [false,true]:
			for speed in [0.0,2.5]:
				for quality in [0.6,1.0]:
					selected[Variety.setting(back,speed,quality,serial)]=true
					selected[Variety.fast_setting(back,speed,quality,serial,Variety.setting(back,speed,quality,serial))]=true
		for direction in 4:
			for quality in [0.6,1.0]: selected[Variety.attack(direction,quality,serial)]=true
		for speed in [Vector3(-2,0,0),Vector3.ZERO,Vector3(2,0,0)]:
			for index in 12: selected[Variety.blocking(speed,index,serial)]=true
	for p in game.players:
		for action in ["idle","ready","relaxed","block_ready","run","walk","backwalk","backpedal","shuffle_left","shuffle_right","cross_left","cross_right"]: selected[p.variant_names.get(action,action)]=true
		p.block_ready_stance=true
		for side in [-1,1]:
			p.velocity=p.global_basis*Vector3(side*2.0,0,0)
			selected[p.choose_gait(2.0,"idle")]=true
		p.block_ready_stance=false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/active/new_animations_26.json"))
	var seen_hashes: Dictionary={}
	var seen_motion: Dictionary={}
	for name in Converter.CLIPS:
		if name in Expansion.CLIPS: continue
		seen_hashes[digest("res://assets/active/"+name+".psa")]=name
		seen_motion[hash([game.clips[name].positions,game.clips[name].rotations])]=name
	var maximum_native_error:=0.0
	var maximum_limb_error:=0.0
	var maximum_gap:=0.0
	var maximum_pop:=0.0
	var contacts:=0
	var counts: Dictionary={}
	for name in Expansion.CLIPS:
		var family: String=Expansion.FAMILIES[name]
		counts[family]=counts.get(family,0)+1
		check(selected.has(name),"Catalog performance is unreachable: "+name)
		check(Converter.CLIPS.has(name) and game.clips.has(name),"Catalog missing native/runtime clip: "+name)
		var hash_value:=digest("res://assets/active/"+name+".psa")
		check(not seen_hashes.has(hash_value),"Duplicate PSA source: "+name)
		seen_hashes[hash_value]=name
		check(hash_value==manifest[name].sha256,"Source hash differs from inventory: "+name)
		var original: String="res://assets/spike/Game/CharactersV1/Animations/"+Expansion.SOURCES[name]
		if FileAccess.file_exists(original): check(hash_value==digest(original),"Original licensed source changed: "+name)
		var clip=game.clips[name]
		var motion_hash: int=hash([clip.positions,clip.rotations])
		check(not seen_motion.has(motion_hash),"Keyframes duplicate an existing source: "+name)
		seen_motion[motion_hash]=name
		check(clip.names==game.clips.idle.names and clip.parents==game.clips.idle.parents,"Rig/hierarchy differs: "+name)
		for mode in [false,true]:
			Avatar.native_animation_enabled=mode
			for index in [0,6]:
				var p=game.players[index]
				p.render_at_draw=false
				p.play("idle",1,true)
				p.select_variant(family,name)
				p.rotation.y=PI if index<6 else 0.0
				p.dive_yaw=p.rotation.y
				p.setting_yaw=-PI/2 if index<6 else PI/2
				if family in ["set","fast_set"]: p.rotation.y=p.setting_yaw
				p.reach_weight=0
				if family in ["receive","set","fast_set","attack","block","dive"]:
					for spot in [Vector3(-2.8,0,5),Vector3(0,0,1.5),Vector3(2.8,0,3.2)]:
						game.ball_pos=Vector3(spot.x,game.contact_height(family),spot.z*(1 if index<6 else -1))
						p.position=p.stance_for_contact(family,game.ball_pos)
						var before: int=game.contact_log.size()
						check(game.validate_contact(index,family),"Scheduled contact missed: "+name+" native="+str(mode))
						if game.contact_log.size()>before:
							maximum_gap=maxf(maximum_gap,game.contact_log[-1].gap)
							contacts+=1
				for frame in 7:
					var time: float=clip.duration*(frame+0.37)/7.0
					var native: Array[Transform3D]=p.normalized_pose("source:"+name,time,false)
					var source: Array[Transform3D]=p.psa_normalized_pose("source:"+name,time,false)
					var first: Array[Transform3D]=p.psa_normalized_pose("source:"+name,0,false)
					for bone in native.size():
						check(native[bone].origin.is_finite() and native[bone].basis.is_finite(),"Non-finite joint: "+name)
						maximum_native_error=maxf(maximum_native_error,native[bone].origin.distance_to(source[bone].origin))
					for side in ["Left","Right"]:
						for pair in [["UpLeg","Leg"],["Leg","Foot"],["Arm","ForeArm"],["ForeArm","Hand"]]:
							var a: int=clip.names.find(side+pair[0])
							var b: int=clip.names.find(side+pair[1])
							maximum_limb_error=maxf(maximum_limb_error,absf(native[a].origin.distance_to(native[b].origin)-first[a].origin.distance_to(first[b].origin)))
				p.reach_weight=0
				p.play("run",1,true)
				p.velocity=Vector3(0.7,0,0)
				for frame in 6: p.tick(1.0/120.0,false,true)
				var previous: Array[Transform3D]=p.last_pose.duplicate()
				var root_before: Vector3=p.position
				p.play(family,1,false)
				p.apply_pose(0)
				for bone in previous.size(): maximum_pop=maxf(maximum_pop,previous[bone].origin.distance_to(p.last_pose[bone].origin))
				check(p.position==root_before,"Visual clip changed real actor root: "+name)
		check(game.players[0].pose_tree.library.get_animation(name).get_meta("contact_time")==clip.contact_time,"Native contact event differs: "+name)
	check(maximum_native_error<0.0002,"Native/PSA orientation, scale or root discrepancy")
	check(maximum_limb_error<0.005,"Clip distorted limb lengths")
	check(maximum_gap<=0.18,"Clip exceeded existing contact tolerance")
	check(maximum_pop<0.0002,"Clip snapped from a moving entry pose")
	var report: Dictionary={"checks":checks,"new_clips":Expansion.CLIPS.size(),"total_clips":Converter.CLIPS.size(),"counts":counts,"contacts":contacts,"maximum_native_error_m":maximum_native_error,"maximum_limb_error_m":maximum_limb_error,"maximum_gap_m":maximum_gap,"maximum_transition_pop_m":maximum_pop}
	var f=FileAccess.open("res://docs/v26-animation-catalog-report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("ANIMATION CATALOG26 ","FAIL" if failed else "PASS",": ",JSON.stringify(report))
	game.free()
	quit(1 if failed else 0)

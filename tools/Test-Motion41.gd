extends SceneTree
const Motion = preload("res://src/motion_prototypes.gd")
const Avatar = preload("res://src/avatar.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = load("res://src/main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var p = g.players[0]
	assert(g.clips.size()==136 and p.pose_tree.initialized)
	var checked := 0
	var maximum_parity := 0.0
	var maximum_joint_error := 0.0
	var worst_joint := ""
	for index in Motion.NAMES.size():
		var name: String = Motion.NAMES[index]
		var action := "dive" if index==0 else "attack"
		var clip = g.clips[name]
		var source = g.clips[Motion.AUTHORS[index].SOURCE]
		assert(p.pose_tree.library.has_animation(name))
		assert(clip.contact_time==source.contact_time and clip.recovery_end==source.recovery_end and clip.duration==source.duration)
		assert(clip.names==source.names and clip.parents==source.parents)
		p.select_variant(action,name)
		p.clip_name="idle"; p.looping=true; p.reach_weight=0
		for frame in 91:
			var t: float = clip.duration*float(frame)/90.0
			assert(clip.root_motion(t).distance_to(source.root_motion(t))<0.000001,"The gameplay displacement must be identical")
			# Verify authored segment lengths at baked keys. Between keys the
			# source also animates translations of muscles and IK effectors.
			var key_time: float=minf(clip.frames-1,floor(t*clip.fps))/clip.fps
			var old_pose: Array[Transform3D]=Motion.normalized(source,Motion.AUTHORS[index].source_time(key_time,clip.contact_time,clip.duration))
			var key_pose: Array[Transform3D]=Motion.normalized(clip,key_time)
			var fallback: Array[Transform3D]=Motion.normalized(clip,t)
			var native: Array[Transform3D]=p.pose_tree.sample(name,t,false)
			for bone in clip.names.size():
				assert(fallback[bone].origin.is_finite() and native[bone].origin.is_finite())
				maximum_parity=maxf(maximum_parity,fallback[bone].origin.distance_to(native[bone].origin))
				assert(fallback[bone].basis.get_rotation_quaternion().angle_to(native[bone].basis.get_rotation_quaternion())<0.0025)
				var parent: int=clip.parents[bone]
				if parent>=0 and parent<bone:
					var old_length: float=old_pose[bone].origin.distance_to(old_pose[parent].origin)
					var new_length: float=key_pose[bone].origin.distance_to(key_pose[parent].origin)
					if absf(new_length-old_length)>maximum_joint_error:
						maximum_joint_error=absf(new_length-old_length)
						worst_joint=str([name,clip.names[bone],t,new_length,old_length])
			checked+=1
		# Both backends retain the exact event and the real visible contact IK.
		for native in [true,false]:
			Avatar.native_animation_enabled=native
			for offset in [Vector3.ZERO,Vector3(0.10,0.04,0.05),Vector3(-0.10,-0.03,-0.04)]:
				p.motion_lock=0; p.looping=true; p.clip_name="idle"
				p.select_variant(action,name)
				g.ball_pos=p.contact_world(action)+offset
				assert(g.validate_contact(0,action),"New performance must make the unchanged 18cm hand/ball check")
	Avatar.native_animation_enabled=true
	assert(maximum_parity<0.001,"Native and PSA-derived fallbacks must match below one millimetre")
	print("MOTION41 length diagnostic ",maximum_joint_error," ",worst_joint)
	assert(maximum_joint_error<0.001,"Authored animation must retain bone lengths")
	Motion.enabled=false
	assert(Motion.attack_variant("attack_line",0,1)=="attack_line")
	assert(Motion.dive_variant("dive",Vector3(0,0.6,1),Vector3(0,-4,10),0.6,0.3)=="dive")
	Motion.enabled=true
	assert(Motion.attack_variant("attack_line",1,1)=="attack_line","Middle keeps its quick attack")
	assert(Motion.attack_variant("attack_line",0,0.4)=="attack_line","Bad passes keep an emergency performance")
	assert(Motion.dive_variant("dive",Vector3(1.5,0.6,0.8),Vector3(0,-4,10),0.6,0.3)=="dive","Sideways balls keep a sideways PSA")
	assert(Motion.dive_variant("dive",Vector3(0,0.6,-1),Vector3(0,-4,10),0.6,0.3)=="dive","No forward dive to a ball behind")
	# Actual queued defensive action, actor travel, recovery and a real contact.
	g.reset_rally(); g.receiver=4; g.possession=0; g.incoming_kind="spike"; g.input_quality=1; g.shot_serial=5
	var defender=g.players[4]
	defender.position=Vector3(0,0,5.5); defender.rotation.y=PI
	var contact:=Vector3(0,g.contact_height("dive"),4.6)
	g.ball_pos=contact+Vector3(0,1.6,-3)
	g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,contact,0.30,Vector3.ZERO)
	g.flight_spin=Vector3.ZERO
	assert(g.queue_recovery(true),"Forward emergency ball must queue an actual recovery")
	assert(defender.variant_names.dive=="dive_authored41" and g.dive_motions.has(4))
	var seconds: float=g.flight_left
	for frame in int(ceil(seconds*120)):
		g.advance_dive_body(4,minf(1.0/120,seconds-float(frame)/120))
	g.ball_pos=g.flight_target
	assert(g.validate_contact(4,"dive"),"Integrated authored dive must meet the ball")
	for frame in 400:
		if not g.dive_motions.has(4): break
		g.advance_dive_body(4,1.0/120)
	assert(not g.dive_motions.has(4) and defender.motion_lock==0,"Floor recovery must release the actor")
	# All rotations retain the same eligible hitter; only the performance changes.
	var plays:=0
	for team in 2:
		for rotation in 6:
			for direction in [0,2,3]:
				g.rotations=[rotation,rotation]; g.reset_rally(); g.possession=team; g.setter=team*6+5
				g.pass_quality=0.95; g.shot_serial=1; g.planned_visual_key=""; g.plan_attack(direction,false)
				if g.planned_hitter>=0 and g.planned_direction in [0,2,3]:
					var original: String=g.AnimationVariety.attack(g.planned_direction,g.pass_quality,g.shot_serial)
					var expected: String="attack_adaptive41" if original==Motion.Attack.SOURCE else original
					assert(g.players[g.planned_hitter].variant_names.attack==expected)
					if expected=="attack_adaptive41": plays+=1
	assert(plays>0,"Authored spike must be selected in an actual planned play")
	print("MOTION41 PASS samples=",checked," parity_m=",maximum_parity," bone_length_error_m=",maximum_joint_error," real_queued_dive_and_recovery=true native_and_PSA_contacts=12 contextual_attack_plans=",plays)
	g.free(); quit()

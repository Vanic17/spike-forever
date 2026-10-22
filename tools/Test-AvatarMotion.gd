extends SceneTree
const Avatar = preload("res://src/avatar.gd")
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var bank: Dictionary = {}
	var sources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/active/sources.json"))
	for action in sources:
		var clip = PSA.new()
		assert(clip.load_file("res://assets/active/"+action+".psa"))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(action)
		bank[action]=clip
	var body=PSK.new()
	assert(body.load_file("res://assets/active/body.psk"))
	var athlete=Avatar.new()
	root.add_child(athlete)
	athlete.setup(bank,0,1,{"body":body})
	athlete.render_at_draw=false
	athlete.look_target=Vector3(0,1.4,4)
	athlete.velocity=Vector3(0,0,2.2)
	athlete.play("run",1,true)
	for i in 30: athlete.tick(1.0/120.0,false,true)
	var worst_transition:=0.0
	for action in ["walk","shuffle_left","cross_left","backpedal","receive","ready","run","shuffle_right","cross_right","relaxed","run"]:
		for frame in 6: athlete.tick(1.0/120.0,false,true)
		var previous: Array[Transform3D]=athlete.last_pose.duplicate()
		athlete.play(action,1,true)
		athlete.apply_pose(0)
		for bone in previous.size():
			worst_transition=maxf(worst_transition,previous[bone].origin.distance_to(athlete.last_pose[bone].origin))
	assert(worst_transition<0.0001,"Interrupting an unfinished animation blend must preserve the visible skeleton")
	var limb_error:=0.0
	var skin_error:=0.0
	for action in ["run","walk","shuffle_left","shuffle_right","cross_left","cross_right","backpedal","receive","dive","float","power","attack","block"]:
		var initial: Array[Transform3D]=athlete.normalized_pose(action,0,false)
		for frame in 40:
			var pose: Array[Transform3D]=athlete.normalized_pose(action,bank[action].duration*float(frame)/39.0,false)
			for side in ["Left","Right"]:
				for pair in [["UpLeg","Leg"],["Leg","Foot"],["Arm","ForeArm"],["ForeArm","Hand"]]:
					var a: int=bank[action].names.find(side+pair[0])
					var b: int=bank[action].names.find(side+pair[1])
					limb_error=maxf(limb_error,absf(pose[a].origin.distance_to(pose[b].origin)-initial[a].origin.distance_to(initial[b].origin)))
		athlete.prepare_contact(action,0)
		athlete.skeleton.force_update_all_bone_transforms()
		for bone in body.names.size():
			var source_bone: int=athlete.animation_bones[bone]
			if source_bone>=0: skin_error=maxf(skin_error,athlete.skeleton.get_bone_global_pose(bone).origin.distance_to(athlete.last_pose[source_bone].origin))
	assert(limb_error<0.005,"The imported hierarchy must preserve arms and legs through all source actions")
	assert(skin_error<0.0002,"The skinned model must follow the sampled source hierarchy")
	var receiving: Array[Transform3D]=athlete.normalized_pose("receive",bank.receive.contact_time,false)
	var stepping: Array[Transform3D]=athlete.normalized_pose("run",0.2,true)
	var combined: Array[Transform3D]=athlete.layer_legs(receiving,stepping,1.0,bank.receive.parents,bank.receive.names)
	for side in ["Left","Right"]:
		var foot: int=bank.receive.names.find(side+"Foot")
		assert(combined[foot].origin.distance_to(stepping[foot].origin)<0.005,"Precontact running legs must retain their supporting pelvis instead of sinking into a squat")
	for direction in [-1.0,1.0]:
		athlete.contact_scheduled=false
		athlete.play("ready",1,true)
		athlete.gait_change_age=1.0
		athlete.velocity=Vector3(direction*2.5,0,0)
		athlete.locomotion(2.5,1.0/60.0)
		var travel: Vector3=bank[athlete.clip_name].root_motion(bank[athlete.clip_name].duration)
		assert(travel.x*direction>0,"Lateral footwork must run in the same direction as the moving actor")
	var dive=bank.dive
	var minimum_torso:=INF
	var minimum_head:=INF
	for frame in 120:
		var pose: Array[Transform3D]=athlete.normalized_pose("dive",dive.duration*float(frame)/119.0,false)
		minimum_torso=minf(minimum_torso,pose[dive.names.find("Spine2")].origin.y)
		minimum_head=minf(minimum_head,pose[dive.names.find("Head")].origin.y)
	var finish: Array[Transform3D]=athlete.normalized_pose("dive",dive.duration,false)
	assert(minimum_torso<0.25 and minimum_head<0.35,"The recovery animation must actually dive onto the floor")
	assert(finish[dive.names.find("Spine2")].origin.y>1.1,"A diving player must return upright before locomotion resumes")
	assert(dive.recovery_end>dive.contact_time+1.7,"The floor slide and rise must remain committed after contact")
	var root_distances: Dictionary={}
	for action in ["float","power"]:
		root_distances[action]=bank[action].root_motion(bank[action].contact_time).length()
		assert(root_distances[action]>3.0,"A source serve needs an actual run-up rather than a jump on the spot")
	var report:={"interrupted_blend_max_joint_displacement_m":worst_transition,"source_limb_length_max_error_m":limb_error,"skinned_skeleton_max_error_m":skin_error,"dive_minimum_torso_height_m":minimum_torso,"dive_minimum_head_height_m":minimum_head,"dive_floor_and_getup_preserved":true,"serve_source_root_contact_distance_m":root_distances}
	var output=FileAccess.open("res://docs/avatar-motion-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("AVATAR MOTION PASS: continuous interrupted blends / stable limbs / full-floor dive and getup / serve root travel=",root_distances)
	athlete.queue_free()
	quit()

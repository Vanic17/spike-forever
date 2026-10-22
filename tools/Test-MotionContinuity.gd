extends SceneTree
const Avatar = preload("res://src/avatar.gd")
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var bank: Dictionary={}
	var sources: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/active/sources.json"))
	for action in sources:
		var clip=PSA.new()
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
	athlete.look_target=Vector3(0,2,6)
	var largest_switch:=0.0
	var highest_joint_speed:=0.0
	var contact_gap:=0.0
	var worst_gait_seam:=0.0
	var cases:=0
	for gait in ["walk","run","shuffle_left","shuffle_right","cross_left","cross_right","backwalk","backpedal"]:
		athlete.travel_blend_left=0
		athlete.travel_animation_name=gait
		athlete.travel_animation_time=bank[gait].duration-0.0001
		var before_seam: Array[Transform3D]=athlete.travel_pose()
		athlete.travel_animation_time=bank[gait].duration+0.0001
		var after_seam: Array[Transform3D]=athlete.travel_pose()
		for joint in ["LeftLeg","LeftFoot","RightLeg","RightFoot"]:
			var j: int=bank.idle.names.find(joint)
			worst_gait_seam=maxf(worst_gait_seam,before_seam[j].origin.distance_to(after_seam[j].origin))
	assert(worst_gait_seam<0.002,"A looping step must not reset a knee or ankle during contextual preparation")
	for fps in [30,60,120]:
		var dt:=1.0/float(fps)
		for action in ["receive","set","fast_set","attack"]:
			athlete.play("run",1,true)
			athlete.velocity=Vector3(0,0,2.5)
			athlete.travel_change_age=1.0
			for warmup in fps/2:
				athlete.locomotion(2.5,dt)
				athlete.tick(dt,false,true)
			athlete.prepare_contact(action,0.65)
			athlete.tick(dt,false,true)
			for direction in [Vector3(2.5,0,0),Vector3(-2.5,0,0),Vector3(0,0,-2.5),Vector3(0,0,2.5)]:
				# Retarget halfway through a prepared gesture. The ball event and
				# primary action must stay fixed while support feet change course.
				athlete.travel_change_age=1.0
				var before: Array[Transform3D]=athlete.travel_pose()
				athlete.velocity=direction
				athlete.prepare_contact(action,0.65)
				athlete.locomotion(direction.length(),dt)
				var after: Array[Transform3D]=athlete.travel_pose()
				for joint in ["LeftUpLeg","LeftLeg","LeftFoot","RightUpLeg","RightLeg","RightFoot"]:
					var j: int=bank.idle.names.find(joint)
					largest_switch=maxf(largest_switch,before[j].origin.distance_to(after[j].origin))
				assert(athlete.clip_name==action,"A directional foot correction must preserve the contextual contact action")
				for frame in fps/3:
					var previous: Array[Transform3D]=athlete.last_pose.duplicate()
					athlete.prepare_contact(action,0.65)
					athlete.locomotion(direction.length(),dt)
					athlete.tick(dt,false,true)
					for joint in ["LeftLeg","LeftFoot","RightLeg","RightFoot"]:
						var j: int=bank.idle.names.find(joint)
						highest_joint_speed=maxf(highest_joint_speed,previous[j].origin.distance_to(athlete.last_pose[j].origin)/dt)
				var source_travel: Vector3=bank[athlete.travel_animation_name].root_motion(bank[athlete.travel_animation_name].duration)
				assert(source_travel.dot(direction)>0,"Prepared footwork must travel with the actor instead of continuing the preceding route")
				cases+=1
			athlete.reach_weight=0
			athlete.prepare_contact(action,0)
			var actual: Vector3=(athlete.current_hand(true)+athlete.current_hand(false))*0.5+Vector3(0,0.07,0) if action in ["receive","set","fast_set"] else athlete.current_hand(false)
			contact_gap=maxf(contact_gap,actual.distance_to(athlete.contact_world(action)))
	assert(largest_switch<0.0002,"A change of support direction must begin from the displayed leg pose")
	assert(highest_joint_speed<12.0,"Directional transitions must not teleport a knee or ankle")
	assert(contact_gap<0.006,"Preparing the feet must not change the original ball-contact event")
	var report:={"directional_preparation_cases":cases,"frame_rates":[30,60,120],"leg_displacement_at_retarget_m":largest_switch,"maximum_continuous_leg_joint_speed_m_s":highest_joint_speed,"source_contact_gap_m":contact_gap,"leg_displacement_at_gait_loop_m":worst_gait_seam}
	var output=FileAccess.open("res://docs/motion-continuity-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("MOTION CONTINUITY PASS: ",cases," prepared corrections / no leg-pose reset / original contact retained / 30-60-120Hz; max joint speed=",highest_joint_speed)
	athlete.queue_free()
	quit()

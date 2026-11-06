extends SceneTree
const Motion=preload("res://src/motion_prototypes.gd")
const PSA=preload("res://src/psa.gd")
const Graph=preload("res://src/pose_animation_tree.gd")
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok and not errors.has(label):errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var bank: Dictionary={}
	var sources: Array=["idle","set","attack"]
	for author in Motion.AUTHORS:
		if not sources.has(author.SOURCE):sources.append(author.SOURCE)
	for name in sources:
		var clip=PSA.new();clip.load_file("res://assets/active/"+name+".psa");clip.load_hierarchy("res://assets/active/skeleton.psk");clip.detect_contact(name);bank[name]=clip
	Motion.register(bank)
	var graph=Graph.new();root.add_child(graph);graph.setup(bank,func(name,time,loop):return Motion.normalized(bank[name],time,loop))
	check(graph.initialized,"Native AnimationTree enabled")
	var clip=bank.set_disguise81;var source=bank.attack
	check(clip.contact_time==source.contact_time and clip.takeoff_time==source.takeoff_time,"Single original takeoff/contact clock")
	var contact=graph.sample("set_disguise81",clip.contact_time,false)
	var palms: Vector3=(contact[clip.names.find("LeftHand")].origin+contact[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
	check(palms.distance_to(clip.contact_offset)<.003,"Native two-hand contact matches event")
	var windup=graph.sample("set_disguise81",maxf(0,clip.contact_time-.30),false)
	check(windup[clip.names.find("LeftHand")].origin.distance_to(windup[clip.names.find("RightHand")].origin)>.35,"Distinct attack load before hands reunite")
	var limb_error:=0.0;var feet_error:=0.0;var rows: Array=[]
	for fps in [30,60,120,144]:
		var previous: Array[Transform3D]=[];var previous_source: Array[Transform3D]=[];var max_step:=0.0;var source_step:=0.0
		for frame in int(ceil(clip.duration*fps))+1:
			var time:=minf(clip.duration,float(frame)/fps)
			var pose=graph.sample("set_disguise81",time,false);var ref=Motion.normalized(source,time)
			for bone in pose.size():
				check(pose[bone].is_finite(),"Finite native poses")
				if clip.names[bone] in ["LeftForeArm","RightForeArm","LeftHand","RightHand","LeftLeg","RightLeg","LeftFoot","RightFoot"]:
					var parent: int=clip.parents[bone]
					limb_error=maxf(limb_error,absf(pose[bone].origin.distance_to(pose[parent].origin)-ref[bone].origin.distance_to(ref[parent].origin)))
				if clip.names[bone] in ["Hips","LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:feet_error=maxf(feet_error,pose[bone].origin.distance_to(ref[bone].origin))
				if not previous.is_empty():
					max_step=maxf(max_step,pose[bone].origin.distance_to(previous[bone].origin));source_step=maxf(source_step,ref[bone].origin.distance_to(previous_source[bone].origin))
			check(clip.root_motion(time).distance_to(source.root_motion(time))<.00001,"No independent visual root travel")
			previous=pose;previous_source=ref
		check(max_step<source_step*1.5+.07,"Continuous pose changes at "+str(fps))
		rows.append({"fps":fps,"maximum_frame_step_m":max_step,"source_frame_step_m":source_step})
	check(limb_error<.0001,"Fixed anatomical limb lengths")
	check(feet_error<.0001,"Takeoff/flight/landing legs unchanged")
	FileAccess.open("res://docs/setter81-poses.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"cases":rows,"limb_error_m":limb_error,"feet_error_m":feet_error,"contact_time":clip.contact_time,"contact_offset":clip.contact_offset,"takeoff_time":clip.takeoff_time,"failures":errors},"  "))
	print("SETTER81 POSES ","PASS" if errors.is_empty() else "FAIL",errors);graph.free();quit(0 if errors.is_empty() else 1)

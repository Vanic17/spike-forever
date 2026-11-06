extends SceneTree
const Motion=preload("res://src/motion_prototypes.gd")
const PSA=preload("res://src/psa.gd")
const Graph=preload("res://src/pose_animation_tree.gd")
const Variety=preload("res://src/animation_variety.gd")
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok and not errors.has(label):errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var bank: Dictionary={}
	for author in Motion.AUTHORS:
		var source: String=author.SOURCE
		if bank.has(source):continue
		var clip=PSA.new();check(clip.load_file("res://assets/active/"+source+".psa"),source)
		clip.load_hierarchy("res://assets/active/skeleton.psk");clip.detect_contact(source);bank[source]=clip
	var idle=PSA.new();idle.load_file("res://assets/active/idle.psa");idle.load_hierarchy("res://assets/active/skeleton.psk");idle.detect_contact("idle");bank.idle=idle
	Motion.register(bank)
	var graph=Graph.new();root.add_child(graph);graph.setup(bank,func(name,time,loop):return Motion.normalized(bank[name],time,loop))
	check(graph.initialized,"Native AnimationTree initializes")
	var limb_error:=0.0;var contact_error:=0.0;var max_step:=0.0;var samples:=0;var worst_limb: Dictionary={};var worst_step: Dictionary={}
	for index in range(18,28):
		var name: String=Motion.NAMES[index];var clip=bank[name];var source=bank[Motion.AUTHORS[index].SOURCE]
		check(graph.library.has_animation(name),"Baked native "+name)
		var contact=graph.sample(name,clip.contact_time,false)
		if name.begins_with("receive_"):
			var palms: Vector3=(contact[clip.names.find("LeftHand")].origin+contact[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
			contact_error=maxf(contact_error,palms.distance_to(clip.contact_offset))
		elif name in ["dive_platform80","dive_pancake80"]:
			var palm: Vector3=contact[clip.names.find("RightHand")].origin
			var center:=palm+Vector3(0,.105 if name=="dive_pancake80" else 0,.085)
			contact_error=maxf(contact_error,center.distance_to(clip.contact_offset))
			if name=="dive_pancake80":
				check(palm.y>.025 and palm.y<.07,"Pancake palm near floor")
				check(center.y>.105 and center.y<.24,"Ball above floor at pancake contact")
		if name.begins_with("attack_"):
			check(clip.contact_time==source.contact_time and clip.takeoff_time==source.takeoff_time,"Lateral takeoff/contact timing preserved")
		for fps in [30,60,120,144]:
			var previous: Array[Transform3D]=[];var previous_ref: Array[Transform3D]=[];var source_step:=0.0;var clip_step:=0.0
			for frame in int(ceil(clip.duration*fps))+1:
				var time:=minf(clip.duration,float(frame)/fps)
				var pose=graph.sample(name,time,false);var mapped: float=Motion.AUTHORS[index].source_time(time,clip.contact_time,clip.duration);var ref=Motion.normalized(source,mapped)
				for bone in pose.size():
					check(pose[bone].is_finite(),"Finite pose "+name)
					var parent: int=clip.parents[bone]
					if parent>=0 and parent<bone and clip.names[bone] in ["LeftForeArm","RightForeArm","LeftHand","RightHand","LeftLeg","RightLeg","LeftFoot","RightFoot"]:
						var error:=absf(pose[bone].origin.distance_to(pose[parent].origin)-ref[bone].origin.distance_to(ref[parent].origin))
						if error>limb_error:limb_error=error;worst_limb={"clip":name,"bone":clip.names[bone],"time":time,"fps":fps}
					if not previous.is_empty():
						var step: float=pose[bone].origin.distance_to(previous[bone].origin)
						clip_step=maxf(clip_step,step);source_step=maxf(source_step,ref[bone].origin.distance_to(previous_ref[bone].origin))
						if step>max_step:max_step=step;worst_step={"clip":name,"bone":clip.names[bone],"time":time,"fps":fps}
				check(clip.root_motion(time).distance_to(source.root_motion(time))<.00001,"Actor root unchanged "+name)
				previous=pose;previous_ref=ref;samples+=1
			print("CONTINUITY ",name," ",fps," shaped ",clip_step," source ",source_step)
			check(clip_step<=source_step*1.25+.04,"Pose continuity relative to source "+name+" at "+str(fps))
		if name.begins_with("dive_roll"):
			var recovered=graph.sample(name,clip.recovery_end,false)
			check(recovered[clip.names.find("Head")].origin.y>recovered[clip.names.find("Hips")].origin.y,"Roll finishes upright "+name)
	check(limb_error<.0001,"Fixed limb lengths")
	check(contact_error<.003,"Native palms match actual contact")
	var distribution: Dictionary={}
	for serial in 120:
		var selected: String=Variety.receive(Vector3(.25,1.1,.3),1,"spike",serial)
		distribution[selected]=int(distribution.get(selected,0))+1
		check(not selected.begins_with("dive_"),"Ordinary dig never picks extreme roll/pancake")
		for local in [Vector3(0,.5,.8),Vector3(1,.5,.8),Vector3(-1,.5,.8)]:
			var dive: String=Variety.diving(local,"spike",serial)
			check(not dive.contains("roll80") and not dive.contains("pancake80"),"Extreme animation excluded from ordinary dive pool")
		check(not Variety.receive(Vector3(.25,1.1,.3),1,"serve",serial).ends_with("80"),"Serve reception unchanged")
	check(int(distribution.get("receive_front75",0))==10,"Old front defence reduced to 1 in 12 eligible selections")
	FileAccess.open("res://docs/defense80-poses.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"samples":samples,"limb_error_m":limb_error,"contact_error_m":contact_error,"maximum_frame_step_m":max_step,"selection_matrix_120":distribution,"distribution_note":"Deterministic eligible selection matrix, not measured match frequency","failures":errors},"  "))
	print("WORST ",worst_limb," STEP ",worst_step)
	print("DEFENSE80 POSES ","PASS" if errors.is_empty() else "FAIL",errors);graph.free();quit(0 if errors.is_empty() else 1)

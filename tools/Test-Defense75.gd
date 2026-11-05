extends SceneTree
const Motion=preload("res://src/motion_prototypes.gd")
const Variety=preload("res://src/animation_variety.gd")
const PSA=preload("res://src/psa.gd")
const PoseGraph=preload("res://src/pose_animation_tree.gd")
var failures: Array[String]=[]
var checks:=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func _initialize(): call_deferred("run")
func run():
	var bank: Dictionary={}
	for source in ["idle","set","receive_low","receive_left_step","receive_right_step","dive_v26_01","dive_v26_06","attack_v26_01"]:
		var clip=PSA.new(); check(clip.load_file("res://assets/active/"+source+".psa"),source)
		clip.load_hierarchy("res://assets/active/skeleton.psk"); clip.detect_contact(source); bank[source]=clip
	Motion.register(bank)
	var native=PoseGraph.new(); root.add_child(native)
	native.setup(bank,func(name: String,time: float,loop: bool): return Motion.normalized(bank[name],time,loop))
	check(native.initialized,"AnimationTree initializes with new immutable clips")
	var max_length_error:=0.0; var max_contact_error:=0.0; var max_step:=0.0; var samples:=0
	for i in range(3,mini(7,Motion.NAMES.size())):
		var name: String=Motion.NAMES[i]; var clip=bank[name]; var author=Motion.AUTHORS[i]; var source=bank[author.SOURCE]
		check(native.library.has_animation(name),"Native clip "+name)
		check(clip.contact_time==source.contact_time and clip.recovery_end==source.recovery_end and clip.takeoff_time==source.takeoff_time,"unchanged event metadata "+name)
		var original:=Motion.normalized(source,source.contact_time)
		var shaped: Array[Transform3D]=author.shape(original,source.names,source.parents,source.contact_time,source.contact_time,source.duration)
		for side in (["Right"] if name=="dive_hand75" else ["Left","Right"]):
			var hand: int=source.names.find(side+"Hand")
			max_contact_error=maxf(max_contact_error,original[hand].origin.distance_to(shaped[hand].origin))
		for fps in [30,60,120,144]:
			var previous: Array[Transform3D]=[]
			for frame in int(ceil(clip.duration*fps))+1:
				var time:=minf(clip.duration,float(frame)/fps)
				var pose:=native.sample(name,time,false); var reference:=Motion.normalized(source,time)
				for bone in pose.size():
					check(pose[bone].is_finite(),"finite "+name)
					var parent: int=clip.parents[bone]
					if parent>=0 and parent<bone:
						var a:=pose[bone].origin.distance_to(pose[parent].origin); var b:=reference[bone].origin.distance_to(reference[parent].origin)
						max_length_error=maxf(max_length_error,absf(a-b))
					if not previous.is_empty(): max_step=maxf(max_step,previous[bone].origin.distance_to(pose[bone].origin))
				check(clip.root_motion(time).distance_to(source.root_motion(time))<.00001,"unchanged root travel")
				previous=pose; samples+=1
	check(max_length_error<.0001,"fixed limb lengths")
	check(max_contact_error<.00001,"contact palms preserved by authoring")
	check(Variety.receive(Vector3(1,1.6,0),2,"spike",0)=="receive_left75","left lunge selection")
	check(Variety.receive(Vector3(-1,1.6,0),2,"spike",0)=="receive_right75","right lunge selection")
	check(Variety.diving(Vector3(0,.6,.5),"spike",0)=="dive_hand75","one-hand emergency selection")
	check(not Variety.diving(Vector3(1,.6,.5),"spike",0)=="dive_hand75","no wrong-direction dive")
	var report={"pass":failures.is_empty(),"checks":checks,"samples":samples,"new_clips":4,"fps":[30,60,120,144],"maximum_bone_length_error_m":max_length_error,"author_contact_error_m":max_contact_error,"maximum_source_step_m":max_step,"failures":failures,"reference":"https://www.youtube.com/shorts/haSkiDd9P_8","method":"reference-authored PSA adaptations evaluated by AnimationTree; not calibrated motion capture"}
	FileAccess.open("res://docs/defense75-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("DEFENSE75 ",JSON.stringify(report)); native.free(); quit(0 if failures.is_empty() else 1)

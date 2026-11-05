extends SceneTree
const Motion=preload("res://src/motion_prototypes.gd")
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok and not errors.has(label):errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var bank: Dictionary={}
	for author in Motion.AUTHORS:
		var clip=preload("res://src/psa.gd").new();clip.load_file("res://assets/active/"+author.SOURCE+".psa")
		clip.load_hierarchy("res://assets/active/skeleton.psk");clip.detect_contact(author.SOURCE);bank[author.SOURCE]=clip
	Motion.register(bank)
	var rows: Array=[];var length_error:=0.0;var palm_error:=0.0
	for index in [11,12,13,14,15,16]:
		var name: String=Motion.NAMES[index];var clip=bank[name];var source=bank[Motion.AUTHORS[index].SOURCE]
		check(clip.contact_time==source.contact_time and clip.takeoff_time==source.takeoff_time,"contact and takeoff unchanged")
		var at=Motion.normalized(clip,clip.contact_time);var original=Motion.normalized(source,source.contact_time)
		if index in [11,12,15,16]:palm_error=maxf(palm_error,at[clip.names.find("RightHand")].origin.distance_to(original[clip.names.find("RightHand")].origin))
		for fps in [30,60,120,144]:
			for frame in int(ceil(clip.duration*fps))+1:
				var time:=minf(clip.duration,float(frame)/fps);var pose=Motion.normalized(clip,time);var ref=Motion.normalized(source,time)
				for bone in pose.size():
					check(pose[bone].is_finite(),"finite authored pose")
					var parent: int=clip.parents[bone]
					if parent>=0 and parent<bone and clip.names[bone]!="Hips":length_error=maxf(length_error,absf(pose[bone].origin.distance_to(pose[parent].origin)-ref[bone].origin.distance_to(ref[parent].origin)))
		if index<15:
			var raised=Motion.normalized(clip,clip.contact_time+1.10)
			var hips: float=raised[clip.names.find("Hips")].origin.y
			check(hips>.9,"upright pelvis by 1.10 seconds after dig")
			check(clip.recovery_end<=clip.contact_time+1.11,"old shoulder roll lock removed")
			rows.append({"name":name,"rise_seconds":1.10,"hips_m":hips,"recovery_end":clip.recovery_end,"old_recovery_end":source.recovery_end})
	check(length_error<.0001,"no stretching in authored recovery or attack")
	check(palm_error<.0001,"successful contact positions preserved")
	FileAccess.open("res://docs/recovery78-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"limb_error_m":length_error,"palm_error_m":palm_error,"cases":rows,"failures":errors},"  "))
	print("RECOVERY78 ","PASS" if errors.is_empty() else "FAIL",errors);quit(0 if errors.is_empty() else 1)

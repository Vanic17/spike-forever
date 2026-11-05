extends SceneTree
const Motion=preload("res://src/motion_prototypes.gd")
const PSA=preload("res://src/psa.gd")
const Graph=preload("res://src/pose_animation_tree.gd")
const Variety=preload("res://src/animation_variety.gd")
var errors: Array[String]=[]
var checks:=0
func check(ok: bool, reason: String):
	checks+=1
	if not ok and not errors.has(reason):errors.append(reason);push_error(reason)
func _initialize():call_deferred("run")
func run():
	var bank: Dictionary={}
	for author in Motion.AUTHORS:
		var clip=PSA.new();check(clip.load_file("res://assets/active/"+author.SOURCE+".psa"),"Source exists")
		clip.load_hierarchy("res://assets/active/skeleton.psk");clip.detect_contact(author.SOURCE);bank[author.SOURCE]=clip
	var idle=PSA.new();idle.load_file("res://assets/active/idle.psa");idle.load_hierarchy("res://assets/active/skeleton.psk");idle.detect_contact("idle");bank.idle=idle
	Motion.register(bank)
	var graph=Graph.new();root.add_child(graph)
	graph.setup(bank,func(name,time,loop):return Motion.normalized(bank[name],time,loop))
	check(graph.initialized,"Native AnimationTree initialized")
	var max_length:=0.0;var max_contact:=0.0;var max_step:=0.0;var samples:=0
	for index in range(9,Motion.NAMES.size()):
		var name: String=Motion.NAMES[index];var clip=bank[name];var source=bank[Motion.AUTHORS[index].SOURCE]
		check(graph.library.has_animation(name),"Baked clip "+name)
		check(clip.contact_time==source.contact_time and clip.recovery_end==source.recovery_end,"Original clock "+name)
		var at_contact=graph.sample(name,clip.contact_time,false)
		if name.begins_with("receive_slide"):
			var hands: Vector3=(at_contact[clip.names.find("LeftHand")].origin+at_contact[clip.names.find("RightHand")].origin)*.5+Vector3(0,.07,0)
			max_contact=maxf(max_contact,hands.distance_to(clip.contact_offset))
		elif name.begins_with("dive_slide"):
			var original=Motion.normalized(source,source.contact_time)
			max_contact=maxf(max_contact,at_contact[clip.names.find("RightHand")].origin.distance_to(original[clip.names.find("RightHand")].origin))
		for fps in [30,60,120,144]:
			var previous: Array[Transform3D]=[]
			for frame in int(ceil(clip.duration*fps))+1:
				var time:=minf(clip.duration,float(frame)/fps)
				var pose=graph.sample(name,time,false);var ref=Motion.normalized(source,time)
				for bone in pose.size():
					check(pose[bone].is_finite(),"Finite pose "+name)
					var parent: int=clip.parents[bone]
					if parent>=0 and parent<bone and clip.names[bone]!="Hips":
						max_length=maxf(max_length,absf(pose[bone].origin.distance_to(pose[parent].origin)-ref[bone].origin.distance_to(ref[parent].origin)))
					if not previous.is_empty():max_step=maxf(max_step,pose[bone].origin.distance_to(previous[bone].origin))
				check(clip.root_motion(time).distance_to(source.root_motion(time))<.00001,"No new actor root movement")
				previous=pose;samples+=1
		# A post-contact torso cannot invert into a shoulder somersault.
		if index>=11:
			for step in 30:
				var time:=lerpf(clip.contact_time+.15,clip.duration,float(step)/29)
				var pose=graph.sample(name,time,false)
				check(pose[clip.names.find("Head")].origin.y>pose[clip.names.find("Hips")].origin.y,"No inverted recovery "+name)
	check(max_length<.0001,"Limb lengths remain fixed")
	check(max_contact<.003,"Real palms match contact")
	var old:=0;var new_count:=0
	for serial in 100:
		var chosen:=Variety.receive(Vector3(.25,1.1,.3),1,"spike",serial)
		if chosen.begins_with("receive_slide"):new_count+=1
		else:old+=1
		check(not Variety.receive(Vector3(1,1.1,.3),1,"serve",serial).ends_with("77"),"No new automatic fall on service reception")
		check(not Variety.diving(Vector3(1,.5,.3),"spike",serial).begins_with("defense_miss"),"Failed gesture never in playable pool")
	check(new_count==20 and old==80,"Original defence retained with occasional 20 percent variant")
	FileAccess.open("res://docs/defense77-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"samples":samples,"maximum_limb_error_m":max_length,"maximum_contact_error_m":max_contact,"maximum_step_m":max_step,"new_variants":6,"new_eligible_per_100":new_count,"failures":errors},"  "))
	print("DEFENSE77 ","PASS" if errors.is_empty() else "FAIL",errors);graph.free();quit(0 if errors.is_empty() else 1)

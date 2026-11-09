extends RefCounted
## One presentation correction, shared by sampled poses and contact planning.
const CROWN_TARGET=2.64
const CROWN=.12
const STANDING_HEAD=1.774563
static var peaks: Dictionary={}
static var contacts: Dictionary={}
static var faces: Array=[]
static func jumping(name: String) -> bool:
	return name.begins_with("attack") or name=="block" or name.begins_with("block_v") or name=="power"
static func correction(actor,name: String,pose: Array[Transform3D]) -> float:
	var native: String=actor.native_clip_name(name)
	if not jumping(native):return 0.0
	var clip=actor.source_clips.get(native,actor.clips.get(name))
	if clip==null:return 0.0
	var head: int=clip.names.find("Head")
	if head<0:return 0.0
	if not peaks.has(native):
		var peak:=STANDING_HEAD
		for step in 25:
			var sample: Array[Transform3D]=actor.raw_normalized_pose(name,clip.duration*float(step)/24.0,false)
			peak=maxf(peak,sample[head].origin.y)
		peaks[native]=peak
	var peak: float=peaks[native]
	var airborne:=clampf((pose[head].origin.y-STANDING_HEAD)/maxf(.1,peak-STANDING_HEAD),0,1)
	return (CROWN_TARGET/actor.height_scale90-CROWN-peak)*airborne
static func contact_correction(actor,name: String) -> float:
	var native: String=actor.native_clip_name(name)
	if not contacts.has(native):
		contacts[native]=actor.raw_normalized_pose(name,actor.clips[name].contact_time,false)
	return correction(actor,name,contacts[native])
static func neutral_face(actor,pose: Array[Transform3D]):
	# Facial PSA channels carry incompatible expressions on several roster
	# heads. Use the mesh bind shape for the face, keeping head/neck motion.
	var body=actor.model_bank.body
	var head: int=body.names.find("Head")
	if head<0:return
	if faces.is_empty():
		for bone in body.names.size():
			if bone==head:continue
			var ancestor: int=body.parents[bone];var facial:=false
			for hop in 20:
				if ancestor==head:facial=true;break
				if ancestor<=0:break
				ancestor=body.parents[ancestor]
			if not facial:continue
			var index: int=actor.animation_bones[bone]
			var parent: int=actor.animation_bones[body.parents[bone]]
			if index>=0 and parent>=0:faces.append([index,parent,body.rest[bone]])
	for entry in faces:pose[entry[0]]=pose[entry[1]]*entry[2]

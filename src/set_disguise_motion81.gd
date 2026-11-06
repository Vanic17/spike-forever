extends RefCounted
## One jumping performance: spike load -> two-hand overhead release -> landing.
## Only upper-body local rotations are blended; source legs/root own the jump.
const SOURCE:="attack"
const PSA=preload("res://src/psa.gd")
const PSK=preload("res://src/psk.gd")
const Shape=preload("res://src/dive_motion41.gd")
static var overhead
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func set_pose(time: float) -> Array[Transform3D]:
	if overhead==null:
		overhead=PSA.new();overhead.load_file("res://assets/active/set.psa");overhead.load_hierarchy("res://assets/active/skeleton.psk");overhead.detect_contact("set")
	var source_time:=clampf(overhead.contact_time+time*.85,0,overhead.duration)
	var pose: Array[Transform3D]=overhead.pose(source_time,false)
	for bone in pose.size():pose[bone]=PSK.to_godot(pose[bone])
	return pose
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result: Array[Transform3D]=pose.duplicate()
	var load: float=Shape._bell(time,maxf(0,contact-.48),contact-.25,contact-.10)
	for change in [["Spine2",Vector3.UP,-.16*load],["RightArm",Vector3.UP,.18*load]]:
		var bone:=names.find(change[0])
		if bone>=0:Shape._rotate_subtree(result,parents,bone,change[1],change[2])
	var weight:=smoothstep(maxf(0,contact-.23),contact-.025,time)*(1-smoothstep(contact+.20,minf(duration,contact+.65),time))
	var reference:=set_pose(time-contact)
	var blended: Array[Transform3D]=[]
	for bone in result.size():
		var local:=result[bone];var parent: int=parents[bone]
		if parent>=0 and parent<bone:local=result[parent].affine_inverse()*local
		var ancestor:=bone;var upper:=false
		while ancestor>0:
			if names[ancestor]=="Spine":upper=true;break
			ancestor=parents[ancestor]
		if upper and parent>=0 and parent<bone:
			var target:=reference[parent].affine_inverse()*reference[bone]
			local.basis=Basis(local.basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(),weight))
		blended.append(blended[parent]*local if parent>=0 and parent<bone else local)
	# Hands reunite over the forehead at the top of the same attack jump.
	# Segment lengths stay fixed; the resulting palms define the contact event.
	var center: Vector3=pose[names.find("RightHand")].origin
	center.x=pose[names.find("Hips")].origin.x;center.y-=.07
	for side in ["Left","Right"]:
		preload("res://src/defense_platform80.gd").arm(blended,names,parents,side,center+Vector3(.105 if side=="Left" else -.105,0,0),weight,false)
	return blended

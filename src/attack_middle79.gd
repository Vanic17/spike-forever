extends RefCounted
const SOURCE:="attack_v26_01"
const Shape=preload("res://src/dive_motion41.gd")
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result=preload("res://src/attack_reference78.gd").shape(pose,names,parents,time,contact,duration)
	var load:=Shape._bell(time,maxf(0,contact-.4),contact-.16,contact-.01)
	var air:=Shape._bell(time,contact-.10,contact+.025,minf(duration,contact+.20))
	for change in [["Spine2",Vector3.UP,-.18*load],["RightArm",Vector3.UP,.14*load],["LeftUpLeg",Vector3.RIGHT,-.20*air]]:
		var bone:=names.find(change[0])
		if bone>=0:Shape._rotate_subtree(result,parents,bone,change[1],change[2])
	return result

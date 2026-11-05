extends RefCounted
## emqBnve9wd8: forward run, long arm backswing, bow-and-arrow load,
## high contact and relaxed cross-body follow-through. No ball/root writes.
const SOURCE:="attack_pin_left"
const Shape=preload("res://src/dive_motion41.gd")
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var swing:=Shape._bell(time,0,contact*.28,contact*.62)
	var load:=Shape._bell(time,contact*.25,contact*.67,contact-.012)
	var follow:=Shape._bell(time,contact+.025,contact+.20,minf(duration,contact+.62))
	rotate(result,names,parents,"Spine1",Vector3.RIGHT,-.10*load+.10*follow)
	rotate(result,names,parents,"Spine2",Vector3.UP,-.20*load+.16*follow)
	for side in ["Left","Right"]:
		backswing(result,names,parents,side,swing)
	rotate(result,names,parents,"RightArm",Vector3.UP,.22*load-.20*follow)
	rotate(result,names,parents,"RightForeArm",Vector3.RIGHT,-.22*load+.20*follow)
	rotate(result,names,parents,"LeftArm",Vector3.RIGHT,-.24*load+.22*follow)
	# Wrist flexion rotates about the wrist, preserving the contact origin.
	var wrist:=Shape._bell(time,contact-.08,contact+.045,minf(duration,contact+.25))
	rotate(result,names,parents,"RightHand",Vector3.RIGHT,.20*wrist)
	return result
static func backswing(pose: Array[Transform3D],names: Array[String],parents: Array[int],side: String,weight: float):
	if weight<.00001:return
	var arm:=names.find(side+"Arm");var elbow:=names.find(side+"ForeArm");var hand:=names.find(side+"Hand")
	if mini(arm,mini(elbow,hand))<0:return
	var origin:=pose[arm].origin
	var upper:=origin.distance_to(pose[elbow].origin);var lower:=pose[elbow].origin.distance_to(pose[hand].origin)
	var lateral:=1.0 if side=="Left" else -1.0
	var goal:=origin+Vector3(lateral*.12,-.58,-.65).normalized()*(upper+lower)*.95
	var target:=pose[hand].origin.lerp(goal,weight)
	var direction: Vector3=(target-origin).normalized();var distance:=clampf(origin.distance_to(target),absf(upper-lower)+.002,upper+lower-.002)
	var pole:=Vector3(lateral*.6,.15,-.1).slide(direction).normalized()
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=origin+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
	var first:=Quaternion((pose[elbow].origin-origin).normalized(),(bend-origin).normalized())
	Shape._rotate_subtree(pose,parents,arm,first.get_axis(),first.get_angle())
	var second:=Quaternion((pose[hand].origin-pose[elbow].origin).normalized(),(origin+direction*distance-pose[elbow].origin).normalized())
	Shape._rotate_subtree(pose,parents,elbow,second.get_axis(),second.get_angle())
static func rotate(pose: Array[Transform3D],names: Array[String],parents: Array[int],name: String,axis: Vector3,angle: float):
	var bone:=names.find(name)
	if bone>=0:Shape._rotate_subtree(pose,parents,bone,axis,angle)

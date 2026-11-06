extends RefCounted
const SOURCE:="attack_pin_left"
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result=preload("res://src/attack_middle79.gd").shape(pose,names,parents,time,contact,duration)
	# The inherited backswing IK changes its elbow plane even at negligible
	# weight. Rebuild the arms from the untouched shoulder pose and fade the
	# rotation itself, so entering/leaving the backswing cannot pop.
	var reference=preload("res://src/attack_reference78.gd")
	var shaper=preload("res://src/dive_motion41.gd")
	var swing: float=shaper._bell(time,0,contact*.28,contact*.62)
	var load: float=shaper._bell(time,contact*.25,contact*.67,contact-.012)
	var follow: float=shaper._bell(time,contact+.025,contact+.20,minf(duration,contact+.62))
	var middle_load: float=shaper._bell(time,maxf(0,contact-.4),contact-.16,contact-.01)
	for side in ["Left","Right"]:
		var arm:=names.find(side+"Arm")
		if arm<0:continue
		var before_parent: int=parents[arm]
		for bone in result.size():
			var ancestor:=bone
			while ancestor>0 and ancestor!=arm:ancestor=parents[ancestor]
			if ancestor==arm:result[bone]=result[before_parent]*pose[before_parent].affine_inverse()*pose[bone]
		stable_backswing(result,names,parents,side,swing)
	reference.rotate(result,names,parents,"RightArm",Vector3.UP,.22*load-.20*follow+.14*middle_load)
	reference.rotate(result,names,parents,"RightForeArm",Vector3.RIGHT,-.22*load+.20*follow)
	reference.rotate(result,names,parents,"LeftArm",Vector3.RIGHT,-.24*load+.22*follow)
	var wrist: float=shaper._bell(time,contact-.08,contact+.045,minf(duration,contact+.25))
	reference.rotate(result,names,parents,"RightHand",Vector3.RIGHT,.20*wrist)
	return result
static func stable_backswing(pose: Array[Transform3D],names: Array[String],parents: Array[int],side: String,weight: float):
	if weight<=0:return
	var arm:=names.find(side+"Arm");var elbow:=names.find(side+"ForeArm");var hand:=names.find(side+"Hand")
	var origin:=pose[arm].origin;var upper:=origin.distance_to(pose[elbow].origin);var lower:=pose[elbow].origin.distance_to(pose[hand].origin)
	var lateral:=1.0 if side=="Left" else -1.0
	var direction:=Vector3(lateral*.12,-.58,-.65).normalized();var distance: float=(upper+lower)*.95
	var pole:=Vector3(lateral*.6,.15,-.1).slide(direction).normalized()
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=origin+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
	var first:=Quaternion.IDENTITY.slerp(Quaternion((pose[elbow].origin-origin).normalized(),(bend-origin).normalized()),weight)
	var shaper=preload("res://src/dive_motion41.gd")
	shaper._rotate_subtree(pose,parents,arm,first.get_axis(),first.get_angle())
	var second:=Quaternion.IDENTITY.slerp(Quaternion((pose[hand].origin-pose[elbow].origin).normalized(),(origin+direction*distance-pose[elbow].origin).normalized()),weight)
	shaper._rotate_subtree(pose,parents,elbow,second.get_axis(),second.get_angle())

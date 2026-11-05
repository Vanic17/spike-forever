extends "res://src/defense_motion75.gd"
## Oz93Tf6y3DE: lateral low support, folded inside knee, long outside leg.
## The matching deep PSA owns hip/foot support; upper-body preparation is
## authored and baked once, then played through the existing AnimationTree.
const SOURCE:="receive_left_step"
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	return low_shape(pose,names,parents,time,contact,duration,"Left")

static func low_shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float, support_side: String) -> Array[Transform3D]:
	var result: Array[Transform3D]=pose.duplicate()
	var weight:=smoothstep(maxf(0,contact-.42),maxf(.01,contact-.045),time)*(1-smoothstep(contact+.12,minf(duration,contact+.58),time))
	if weight<.000001: return result
	var hips:=names.find("Hips"); var support:=names.find(support_side+"Foot")
	if hips<0 or support<0: return result
	var side:=signf(pose[support].origin.x-pose[hips].origin.x)
	if side==0: side=1
	# Transfer the pelvis onto the folded knee, leaving the other leg long.
	# The scene actor/root never moves; this is ordinary local pelvis motion.
	var shift:=Vector3(side*.18,-.40,0)*weight
	for bone in result.size():
		if Shape._descendant(bone,hips,parents): result[bone].origin+=shift
	for limb in ["Left","Right"]:
		var foot:=names.find(limb+"Foot")
		if foot<0: continue
		var target:=pose[foot].origin
		if limb!=support_side: target.x-=side*.10*weight
		solve_leg(result,names,parents,limb,target,weight)
		var keep_sole: Basis=pose[foot].basis*result[foot].basis.inverse()
		var turn: Quaternion=keep_sole.get_rotation_quaternion()
		Shape._rotate_subtree(result,parents,foot,turn.get_axis(),turn.get_angle())
	var spine:=names.find("Spine1")
	if spine>=0: Shape._rotate_subtree(result,parents,spine,Vector3.RIGHT,.16*weight)
	return result

static func solve_leg(pose: Array[Transform3D], names: Array[String], parents: Array[int], side: String, target: Vector3, weight: float) -> void:
	var root:=names.find(side+"UpLeg"); var knee:=names.find(side+"Leg"); var foot:=names.find(side+"Foot")
	if mini(root,mini(knee,foot))<0: return
	var origin:=pose[root].origin
	var upper:=origin.distance_to(pose[knee].origin); var lower:=pose[knee].origin.distance_to(pose[foot].origin)
	var direction: Vector3=(target-origin).normalized()
	var distance:=clampf(origin.distance_to(target),absf(upper-lower)+.001,upper+lower-.001)
	var source_pole: Vector3=(pose[knee].origin-origin).slide(direction)
	var preferred:=Vector3(0,1,1).slide(direction).normalized()
	var pole:=source_pole.normalized().slerp(preferred,weight).normalized() if source_pole.length()>.001 else preferred
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=origin+direction*cosine*upper+pole.normalized()*sqrt(maxf(0,1-cosine*cosine))*upper
	var a:=Quaternion((pose[knee].origin-origin).normalized(),(bend-origin).normalized())
	Shape._rotate_subtree(pose,parents,root,a.get_axis(),a.get_angle())
	var b:=Quaternion((pose[foot].origin-pose[knee].origin).normalized(),(origin+direction*distance-pose[knee].origin).normalized())
	Shape._rotate_subtree(pose,parents,knee,b.get_axis(),b.get_angle())

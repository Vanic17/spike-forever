extends RefCounted
const Crowd=preload("res://src/crowd.gd")
static func pose(rig,seated: bool,gesture: String="rest",open: float=0.0,source: Array=[]) -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for i in rig.names.size():
		var local: Transform3D=source[i] if source.size()==rig.names.size() else rig.rest[i]
		result.append(result[rig.parents[i]]*local if i>0 else local)
	if seated:
		for i in result.size(): result[i].origin.y-=.48
		for side in ["Left","Right"]:
			Crowd.rotate_chain(result,rig,rig.names.find(side+"UpLeg"),Vector3(0,-.10,1),rig.names.find(side+"Leg"))
			Crowd.rotate_chain(result,rig,rig.names.find(side+"Leg"),Vector3(0,-1,.02),rig.names.find(side+"Foot"))
	var spine: int=rig.names.find("Spine")
	var chest: Vector3=result[spine].origin+Vector3(0,.20,.12)
	for side in ["Left","Right"]:
		var sign_x: float=1.0 if side=="Left" else -1.0
		var arm: int=rig.names.find(side+"Arm"); var fore: int=rig.names.find(side+"ForeArm"); var hand: int=rig.names.find(side+"Hand")
		var target:=chest+Vector3(sign_x*.28,-.25,.19)
		if gesture=="clap": target=chest+Vector3(sign_x*lerpf(.035,.28,open),.06,.25)
		elif gesture=="highfive" and side=="Right": target=chest+Vector3(0,.31,.28)
		elif gesture=="point" and side=="Right": target=chest+Vector3(.16,.13,.63)
		elif gesture=="talk": target=chest+Vector3(sign_x*(.19+.10*open),.04,.30)
		var origin: Vector3=result[arm].origin
		var upper:=origin.distance_to(result[fore].origin); var lower:=result[fore].origin.distance_to(result[hand].origin)
		var direction: Vector3=(target-origin).normalized(); var distance:=clampf(origin.distance_to(target),absf(upper-lower)+.002,upper+lower-.005)
		var pole:=Vector3(sign_x*.7,-.65,0); pole=(pole-direction*pole.dot(direction)).normalized()
		var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
		var elbow:=origin+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
		Crowd.rotate_chain(result,rig,arm,elbow-origin,fore)
		Crowd.rotate_chain(result,rig,fore,origin+direction*distance-result[fore].origin,hand)
		if gesture=="clap" or (gesture=="highfive" and side=="Right"):
			var finger: int=rig.names.find(side+"HandMiddle1")
			if finger>=0: Crowd.rotate_chain(result,rig,hand,Vector3(sign_x*.08,1,.12),finger)
	var local: Array[Transform3D]=[]
	for i in result.size(): local.append(result[rig.parents[i]].affine_inverse()*result[i] if i>0 else result[i])
	return local

static func apply(actor,a: Array,b: Array,weight: float) -> void:
	for i in a.size():
		actor.skeleton.set_bone_pose_position(i,a[i].origin.lerp(b[i].origin,weight))
		actor.skeleton.set_bone_pose_rotation(i,a[i].basis.get_rotation_quaternion().slerp(b[i].basis.get_rotation_quaternion(),weight))

extends "res://src/defense_motion75.gd"
const SOURCE:="receive_step"
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return platform(pose,names,parents,time,contact,duration)
static func platform(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var hold:=smoothstep(maxf(0,contact-.32),maxf(.01,contact-.035),time)*(1-smoothstep(contact+.08,minf(duration,contact+.38),time))
	var hips:=names.find("Hips")
	if hips<0:return result
	# A passing platform extends away from the trunk, below the shoulders.
	var center:=pose[hips].origin+Vector3(0,.10,.78)
	for side in ["Left","Right"]:
		arm(result,names,parents,side,center+Vector3(.055 if side=="Left" else -.055,0,0),hold)
		var hand:=names.find(side+"Hand");var finger:=names.find(side+"HandMiddle1")
		if hand>=0 and finger>=0 and hold>.00001:
			var from: Vector3=(result[finger].origin-result[hand].origin).normalized()
			var toward:=Vector3(-.85 if side=="Left" else .85,0,.3).normalized()
			var turn:=Quaternion.IDENTITY.slerp(Quaternion(from,toward),hold)
			Shape._rotate_subtree(result,parents,hand,turn.get_axis(),turn.get_angle())
	return result
static func arm(pose: Array[Transform3D],names: Array[String],parents: Array[int],side: String,target: Vector3,weight: float,platform_pole: bool=true):
	if weight<.00001:return
	var root:=names.find(side+"Arm");var elbow:=names.find(side+"ForeArm");var hand:=names.find(side+"Hand")
	if mini(root,mini(elbow,hand))<0:return
	var origin:=pose[root].origin;var upper:=origin.distance_to(pose[elbow].origin);var lower:=pose[elbow].origin.distance_to(pose[hand].origin)
	var goal:=pose[hand].origin.lerp(target,weight);var direction: Vector3=(goal-origin).normalized()
	var distance:=clampf(origin.distance_to(goal),absf(upper-lower)+.002,upper+lower-.002)
	var pole: Vector3=(pose[elbow].origin-origin).slide(direction).normalized()
	if platform_pole:pole=Vector3(.35 if side=="Left" else -.35,-1,.05).slide(direction).normalized()
	if pole.length_squared()<.1:pole=Vector3(1 if side=="Left" else -1,-.5,0).slide(direction).normalized()
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=origin+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
	var a:=Quaternion((pose[elbow].origin-origin).normalized(),(bend-origin).normalized())
	Shape._rotate_subtree(pose,parents,root,a.get_axis(),a.get_angle())
	var b:=Quaternion((pose[hand].origin-pose[elbow].origin).normalized(),(origin+direction*distance-pose[elbow].origin).normalized())
	Shape._rotate_subtree(pose,parents,elbow,b.get_axis(),b.get_angle())

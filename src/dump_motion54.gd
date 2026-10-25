extends RefCounted
## Two-hand disguise, left-hand extension and wrist push. Lower-body source
## supports and the contact clock remain unchanged; no actor/root writes.
const SOURCE := "set"
const Shape=preload("res://src/attack_motion41.gd")
static func source_time(time: float, _contact: float, _duration: float) -> float: return time
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var reveal:=smoothstep(contact-.30,contact-.045,time)*(1.0-smoothstep(contact+.18,minf(duration,contact+.55),time))
	var follow:=Shape._bell(time,contact-.035,contact+.13,minf(duration,contact+.52))
	Shape._rotate(result,names,parents,"Spine1",Vector3.UP,deg_to_rad(-7)*reveal)
	# Keep the opposite hand high for disguise, then lower it naturally.
	Shape._rotate(result,names,parents,"RightArm",Vector3.RIGHT,deg_to_rad(48)*reveal)
	var shoulder:=names.find("LeftArm"); var elbow:=names.find("LeftForeArm"); var hand:=names.find("LeftHand")
	if shoulder>=0 and elbow>=0 and hand>=0:
		var s: Vector3=result[shoulder].origin; var e: Vector3=result[elbow].origin; var h: Vector3=result[hand].origin
		var target:=s+Vector3(-.10,.67,.30)+Vector3(0,-.34,.15)*follow
		target=h.lerp(target,reveal)
		var upper:=s.distance_to(e); var lower:=e.distance_to(h)
		var direction: Vector3=(target-s).normalized()
		var distance:=clampf(s.distance_to(target),absf(upper-lower)+.002,upper+lower-.002)
		var pole: Vector3=e-s-direction*(e-s).dot(direction)
		if pole.length()<.001: pole=Vector3.LEFT
		var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
		var bend:=s+direction*cosine*upper+pole.normalized()*sqrt(maxf(0,1-cosine*cosine))*upper
		turn(result,parents,shoulder,Quaternion((e-s).normalized(),(bend-s).normalized()))
		turn(result,parents,elbow,Quaternion((result[hand].origin-result[elbow].origin).normalized(),(s+direction*distance-result[elbow].origin).normalized()))
		Shape._rotate(result,names,parents,"LeftHand",Vector3.RIGHT,deg_to_rad(28)*(reveal+follow*.5))
	var lift:=.30*Shape._bell(time,maxf(0,contact-.38),contact,minf(duration,contact+.42))
	for bone in result.size(): result[bone].origin.y+=lift
	return result
static func turn(pose: Array[Transform3D], parents: Array[int], bone: int, rotation: Quaternion) -> void:
	Shape._rotate_index(pose,parents,bone,rotation.get_axis(),rotation.get_angle())

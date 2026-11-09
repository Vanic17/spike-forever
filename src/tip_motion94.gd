extends RefCounted
## m9FH3qjbi18: high open hand, compact finger/wrist push, restrained follow.
## Existing takeoff, root travel, handedness mirroring and contact time remain.
const SOURCE:="attack"
const Ref=preload("res://src/attack_reference78.gd")
const Shape=preload("res://src/dive_motion41.gd")
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var reveal:=smoothstep(contact-.19,contact-.025,time)*(1-smoothstep(contact+.08,minf(duration,contact+.40),time))
	var push:=Shape._bell(time,contact-.035,contact+.055,minf(duration,contact+.22))
	var follow:=Shape._bell(time,contact+.012,contact+.13,minf(duration,contact+.42))
	# Keep the hand origin exact at contact; only basis and fingers change.
	var hand:=names.find("RightHand")
	if hand>=0:
		Ref.rotate(result,names,parents,"RightHand",result[hand].basis.x.normalized(),-.12*reveal+.50*push)
		for i in 4:
			var finger: String=["Index","Middle","Ring","Pinky"][i]
			Ref.rotate(result,names,parents,"RightHand"+finger+"1",result[hand].basis.z.normalized(),(float(i)-1.5)*.026*reveal)
	var shoulder:=names.find("RightArm");var elbow:=names.find("RightForeArm")
	if shoulder>=0 and elbow>=0 and hand>=0 and follow>.0001:
		var s: Vector3=result[shoulder].origin;var e: Vector3=result[elbow].origin;var h: Vector3=result[hand].origin
		var target:=h.lerp(s+Vector3(.08,.52,.24),follow*.62)
		var upper:=s.distance_to(e);var lower:=e.distance_to(h);var direction: Vector3=(target-s).normalized()
		var distance:=clampf(s.distance_to(target),absf(upper-lower)+.002,upper+lower-.002)
		var pole: Vector3=(e-s).slide(direction)
		if pole.length()<.001:pole=Vector3.RIGHT
		var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
		var bend:=s+direction*cosine*upper+pole.normalized()*sqrt(maxf(0,1-cosine*cosine))*upper
		var turn:=Quaternion((e-s).normalized(),(bend-s).normalized())
		Shape._rotate_subtree(result,parents,shoulder,turn.get_axis(),turn.get_angle())
		turn=Quaternion((result[hand].origin-result[elbow].origin).normalized(),(s+direction*distance-result[elbow].origin).normalized())
		Shape._rotate_subtree(result,parents,elbow,turn.get_axis(),turn.get_angle())
	return result

static func hand_layer(pose: Array[Transform3D],native: Array[Transform3D],names: Array[String],parents: Array[int],left: bool,weight: float) -> Array[Transform3D]:
	var result:=pose.duplicate();var side: String="Left" if left else "Right"
	for name in [side+"Hand",side+"HandIndex1",side+"HandMiddle1",side+"HandRing1",side+"HandPinky1"]:
		var bone:=names.find(name)
		if bone<0:continue
		var parent: int=parents[bone]
		if parent<0:continue
		var current: Quaternion=(result[parent].basis.inverse()*result[bone].basis).get_rotation_quaternion()
		var target: Quaternion=(native[parent].basis.inverse()*native[bone].basis).get_rotation_quaternion()
		var desired: Basis=result[parent].basis*Basis(current.slerp(target,weight))
		var turn: Quaternion=(desired*result[bone].basis.inverse()).get_rotation_quaternion()
		Shape._rotate_subtree(result,parents,bone,turn.get_axis(),turn.get_angle())
	return result

static func restrained_follow(pose: Array[Transform3D],names: Array[String],parents: Array[int],left: bool,time: float,contact: float,duration: float) -> Array[Transform3D]:
	# Reveal an extended arm before contact, rather than retaining the spike's
	# cocked elbow until only the wrist changes. Keep the palm contact exact.
	var reveal:=smoothstep(contact-.27,contact-.07,time)*(1-smoothstep(contact+.16,minf(duration,contact+.46),time))
	var weight:=reveal*.94
	if weight<.0001:return pose
	var result:=pose.duplicate();var side: String="Left" if left else "Right"
	var shoulder:=names.find(side+"Arm");var elbow:=names.find(side+"ForeArm");var hand:=names.find(side+"Hand")
	if mini(shoulder,mini(elbow,hand))<0:return pose
	var s: Vector3=result[shoulder].origin;var e: Vector3=result[elbow].origin;var h: Vector3=result[hand].origin
	var contact_lock:=1-smoothstep(.015,.075,absf(time-contact))
	var target:=h.lerp(s+Vector3(.14 if left else -.14,.69,.26),weight*(1-contact_lock))
	var upper:=s.distance_to(e);var lower:=e.distance_to(h);var direction: Vector3=(target-s).normalized()
	var distance:=clampf(s.distance_to(target),absf(upper-lower)+.002,upper+lower-.002)
	# Elbow opens forward/outward, not the rearward whipping spike path.
	var pole: Vector3=(e-s).lerp(Vector3(.32 if left else -.32,.12,.24),reveal*.88).slide(direction)
	if pole.length()<.001:pole=Vector3.LEFT if left else Vector3.RIGHT
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=s+direction*cosine*upper+pole.normalized()*sqrt(maxf(0,1-cosine*cosine))*upper
	var turn:=Quaternion((e-s).normalized(),(bend-s).normalized());Shape._rotate_subtree(result,parents,shoulder,turn.get_axis(),turn.get_angle())
	turn=Quaternion((result[hand].origin-result[elbow].origin).normalized(),(s+direction*distance-result[elbow].origin).normalized());Shape._rotate_subtree(result,parents,elbow,turn.get_axis(),turn.get_angle())
	return result

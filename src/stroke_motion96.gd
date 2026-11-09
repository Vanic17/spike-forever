extends RefCounted
## Authored gestures reconstructed from the supplied reference clips.
## All offsets are bind metres. No simulation, clocks or root writes.
const Shape=preload("res://src/dive_motion41.gd")
const Ref=preload("res://src/attack_reference78.gd")
static func arm(pose: Array[Transform3D],names: Array[String],parents: Array[int],side: String,target: Vector3,pole: Vector3,weight: float):
	var a:=names.find(side+"Arm");var e:=names.find(side+"ForeArm");var h:=names.find(side+"Hand")
	if mini(a,mini(e,h))<0 or weight<.0001:return
	var s:=pose[a].origin;target=pose[h].origin.lerp(target,clampf(weight,0,1))
	var upper:=s.distance_to(pose[e].origin);var lower:=pose[e].origin.distance_to(pose[h].origin)
	var direction: Vector3=(target-s).normalized();var distance:=clampf(s.distance_to(target),absf(upper-lower)+.0001,upper+lower-.0001)
	pole=pole.slide(direction).normalized()
	if pole.length_squared()<.01:pole=Vector3.RIGHT.slide(direction).normalized()
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var bend:=s+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
	var turn:=Quaternion((pose[e].origin-s).normalized(),(bend-s).normalized());Shape._rotate_subtree(pose,parents,a,turn.get_axis(),turn.get_angle())
	turn=Quaternion((pose[h].origin-pose[e].origin).normalized(),(s+direction*distance-pose[e].origin).normalized());Shape._rotate_subtree(pose,parents,e,turn.get_axis(),turn.get_angle())
static func tip(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,c: float,d: float) -> Array[Transform3D]:
	var out: Array[Transform3D]=pose.duplicate();var hand:=names.find("RightHand");var shoulder:=names.find("RightArm")
	if hand<0 or shoulder<0:return out
	var show:=Shape._bell(time,c-.28,c-.07,minf(d,c+.42))
	var follow:=smoothstep(c+.015,c+.22,time)
	var contact_lock:=1-smoothstep(.015,.09,absf(time-c))
	var target:=out[shoulder].origin+Vector3(-.14,.73,.26)+Vector3(.03,-.20,.23)*follow
	arm(out,names,parents,"Right",out[hand].origin.lerp(target,1-contact_lock),Vector3(-.30,.08,.26),show)
	Ref.rotate(out,names,parents,"RightHand",out[hand].basis.x.normalized(),-.22*show+.78*Shape._bell(time,c-.025,c+.075,minf(d,c+.31)))
	return out
static func cut(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,c: float,d: float) -> Array[Transform3D]:
	var out: Array[Transform3D]=pose.duplicate();var prep:=Shape._bell(time,c-.24,c-.09,c-.012)
	var follow:=Shape._bell(time,c+.012,c+.18,minf(d,c+.47))
	Ref.rotate(out,names,parents,"RightArm",Vector3.UP,-.18*prep)
	var a:=names.find("RightArm");var h:=names.find("RightHand")
	if a>=0 and h>=0:
		# High outside contact then fast cross-body/downward finish.
		arm(out,names,parents,"Right",out[a].origin+Vector3(.40,-.25,.42),Vector3(-.25,.1,.3),follow*.94)
		Ref.rotate(out,names,parents,"RightHand",out[h].basis.z.normalized(),-.30*prep-.35*follow)
	return out
static func second(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,c: float,d: float,kind: int) -> Array[Transform3D]:
	var side: String="Left" if kind==3 else "Right"
	var other: String="Right" if kind==3 else "Left"
	var out: Array[Transform3D]=pose.duplicate();var a:=names.find(side+"Arm");var h:=names.find(side+"Hand")
	if a<0 or h<0:return out
	var lift: float=(.43 if kind==3 else .30)*Shape._bell(time,c-.34,c,minf(d,c+.36))
	for bone in out.size():out[bone].origin.y+=lift
	var show:=smoothstep(c-.25,c-.035,time)*(1-smoothstep(c+.20,minf(d,c+.55),time))
	var release:=smoothstep(c,c+(.14 if kind==3 else .22),time)
	var direction: Vector3=Vector3(.08,.70,-.20) if kind==2 else (Vector3(-.12,.72,.16) if kind==3 else Vector3(.08,.70,.30))
	# Setter faces along the net. Local -X always points across it on either team.
	var follow: Vector3=Vector3(-.30,-.08,-.28) if kind==2 else (Vector3(-.42,-.42,.06) if kind==3 else Vector3(-.30,-.10,.32))
	arm(out,names,parents,side,out[a].origin+direction+follow*release,Vector3(-.26 if kind==3 else .26,.06,.12),show)
	var other_shoulder: int=names.find(other+"Arm")
	if other_shoulder>=0:
		var withdraw: float=show*smoothstep(c-.15,c-.025,time)
		arm(out,names,parents,other,out[other_shoulder].origin+Vector3(.18 if other=="Right" else -.18,-.22,.20),Vector3(.35 if other=="Right" else -.35,-.10,.1),withdraw)
	Ref.rotate(out,names,parents,side+"Hand",out[h].basis.z.normalized(),(-.72 if kind==3 else -.42)*show*release)
	# Fingers lead the release, not the underside of the wrist. Keep them
	# upright at contact, then fold them toward the opponent after the push.
	var digit: int=names.find(side+"HandMiddle1")
	if digit>=0:
		var finger: Vector3=(out[digit].origin-out[h].origin).normalized()
		var wanted:=Vector3(-.75*release,1.0-(1.55 if kind==3 else .65)*release,-.30 if kind==2 else .25).normalized()
		var turn:=Quaternion.IDENTITY.slerp(Quaternion(finger,wanted),show)
		Shape._rotate_subtree(out,parents,h,turn.get_axis(),turn.get_angle())
	return out
static func first(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,c: float,d: float) -> Array[Transform3D]:
	var out: Array[Transform3D]=pose.duplicate();var h:=names.find("RightHand");var other:=names.find("LeftHand")
	if h<0 or other<0:return out
	var show:=smoothstep(c-.19,c-.025,time)*(1-smoothstep(c+.12,minf(d,c+.38),time))
	var target: Vector3=(pose[h].origin+pose[other].origin)*.5+Vector3(0,.07,.015)
	arm(out,names,parents,"Right",target,Vector3(-.26,.05,.20),show)
	Ref.rotate(out,names,parents,"LeftArm",Vector3.RIGHT,.95*show)
	Ref.rotate(out,names,parents,"RightHand",out[h].basis.x.normalized(),-.24*show)
	return out
static func arm_layer(pose: Array[Transform3D],native: Array[Transform3D],names: Array[String],parents: Array[int],left: bool,weight: float) -> Array[Transform3D]:
	var out: Array[Transform3D]=pose.duplicate();var side: String="Left" if left else "Right"
	for name in [side+"Arm",side+"ForeArm",side+"Hand"]:
		var bone:=names.find(name)
		if bone<0:continue
		var parent: int=parents[bone]
		var current: Quaternion=(out[parent].basis.inverse()*out[bone].basis).get_rotation_quaternion()
		var wanted: Quaternion=(native[parent].basis.inverse()*native[bone].basis).get_rotation_quaternion()
		var turn: Quaternion=(out[parent].basis*Basis(current.slerp(wanted,weight))*out[bone].basis.inverse()).get_rotation_quaternion()
		Shape._rotate_subtree(out,parents,bone,turn.get_axis(),turn.get_angle())
	return out
static func orient_cut(pose: Array[Transform3D],names: Array[String],parents: Array[int],left: bool,inward: float,time: float,c: float,d: float):
	var side: String="Left" if left else "Right";var a:=names.find(side+"Arm")
	if a<0:return
	var follow:=Shape._bell(time,c+.012,c+.18,minf(d,c+.47))
	arm(pose,names,parents,side,pose[a].origin+Vector3(inward*.40,-.25,.42),Vector3(inward*.25,.1,.3),follow)

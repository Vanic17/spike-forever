extends "res://src/defense_motion75.gd"
## Wue2fnqT5oE: second exercise, low platform and lateral absorption.
## The torso remains facing the ball; no shoulder roll is appended.
const SOURCE:="receive_left_step"
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	return support(pose,names,parents,time,contact,duration,"Left")
static func support(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float, side: String) -> Array[Transform3D]:
	var result=preload("res://src/defense_low76.gd").low_shape(pose,names,parents,time,contact,duration,side)
	var load:=Shape._bell(time,maxf(0,contact-.32),contact+.08,minf(duration,contact+.65))
	var spine:=names.find("Spine1")
	if spine>=0:Shape._rotate_subtree(result,parents,spine,Vector3.FORWARD,(.17 if side=="Left" else -.17)*load)
	# The platform gives with the ball instead of flicking the shoulders up.
	var absorb:=Shape._bell(time,contact+.025,contact+.18,minf(duration,contact+.52))
	for limb in ["Left","Right"]:
		var arm:=names.find(limb+"Arm")
		if arm>=0:Shape._rotate_subtree(result,parents,arm,Vector3.RIGHT,.16*absorb)
	return result

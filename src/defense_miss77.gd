extends "res://src/defense_motion75.gd"
## First exercise: a long, unsuccessful lateral reach, used AFTER a miss.
const SOURCE:="dive_v26_02"
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var reach:=Shape._bell(time,maxf(0,contact-.30),contact+.06,minf(duration,contact+.28))
	var spine:=names.find("Spine1");var arm:=names.find("LeftArm")
	if spine>=0:Shape._rotate_subtree(result,parents,spine,Vector3.UP,-.16*reach)
	if arm>=0:Shape._rotate_subtree(result,parents,arm,Vector3.UP,.32*reach)
	return result

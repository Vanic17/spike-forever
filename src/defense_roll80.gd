extends "res://src/defense_motion75.gd"
const SOURCE:="dive_v26_02"
static func source_time(time: float,contact: float,duration: float) -> float:
	if time<=contact:return time
	var progress:=clampf((time-contact)/1.45,0,1)
	return lerpf(contact,duration,progress*progress*(3-2*progress))
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate();var neck:=names.find("Neck")
	if neck>=0:Shape._rotate_subtree(result,parents,neck,Vector3.RIGHT,.09*Shape._bell(time,contact+.08,contact+.50,minf(duration,contact+1.2)))
	return result

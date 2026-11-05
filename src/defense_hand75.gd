extends "res://src/defense_motion75.gd"
const SOURCE:="dive_v26_01"
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	return prepare(pose,names,parents,time,contact,duration,0.0,true)

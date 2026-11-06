extends "res://src/defense_motion75.gd"
const SOURCE:="receive_right_step"
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return preload("res://src/defense_knee80.gd").kneeling(pose,names,parents,time,contact,duration,"Right")

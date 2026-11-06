extends "res://src/defense_motion75.gd"
const SOURCE:="receive_squat"
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return preload("res://src/defense_platform80.gd").platform(pose,names,parents,time,contact,duration)

extends "res://src/defense_motion75.gd"
const SOURCE:="receive_left_step"
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return kneeling(pose,names,parents,time,contact,duration,"Left")
static func kneeling(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float,side: String) -> Array[Transform3D]:
	var result=preload("res://src/defense_low76.gd").low_shape(pose,names,parents,time,contact,duration,side)
	return preload("res://src/defense_platform80.gd").platform(result,names,parents,time,contact,duration)

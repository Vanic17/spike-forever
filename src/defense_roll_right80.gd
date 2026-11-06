extends "res://src/defense_motion75.gd"
const SOURCE:="dive_v26_04"
static func source_time(time: float,contact: float,duration: float) -> float:return preload("res://src/defense_roll80.gd").source_time(time,contact,duration)
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return preload("res://src/defense_roll80.gd").shape(pose,names,parents,time,contact,duration)

extends RefCounted
const SOURCE:="attack_pin_right"
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	return preload("res://src/attack_middle_style80.gd").shape(pose,names,parents,time,contact,duration)

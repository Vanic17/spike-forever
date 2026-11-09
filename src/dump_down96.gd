extends RefCounted
const SOURCE="set"
static func source_time(t: float,_c: float,_d: float) -> float:return t
static func shape(p: Array[Transform3D],n: Array[String],h: Array[int],t: float,c: float,d: float) -> Array[Transform3D]:return preload("res://src/stroke_motion96.gd").second(p,n,h,t,c,d,3)

extends RefCounted
## Same metre scale as the 18x9 court and database player heights.
const TOP:=2.42
const DEPTH:=1.0
const BOTTOM:=TOP-DEPTH
const WIDTH:=9.50
const CELL:=.10
const TOP_BAND:=.07
const BOTTOM_BAND:=.05
const BALL_RADIUS:=.105
static func crossing(before: Vector3,after: Vector3,velocity: Vector3) -> Dictionary:
	if before.z*after.z>=0:return {}
	var fraction:=absf(before.z)/maxf(.00001,absf(before.z-after.z))
	var point:=before.lerp(after,fraction)
	if absf(point.x)>WIDTH*.5+BALL_RADIUS or point.y>TOP+BALL_RADIUS:return {}
	return {"point":point,"under":point.y<BOTTOM-BALL_RADIUS,"over":point.y>=TOP and absf(velocity.z)>4.0}

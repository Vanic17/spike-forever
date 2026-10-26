extends RefCounted
## Contact and seal are different measurements. A sphere first touches the
## front of the hands before its centre reaches their plane; that normal
## separation must not turn a square palm hit into a weak fingertip touch.
static func palm_crossing(hit: Vector3, incoming: Vector3, left: Vector3, right: Vector3) -> Vector3:
	var crossing:=hit
	if absf(incoming.z)>1.0:
		var until_plane:=clampf(((left.z+right.z)*.5-hit.z)/incoming.z,-.035,.035)
		crossing+=incoming*until_plane
	return crossing

static func alignment(hit: Vector3, incoming: Vector3, left: Vector3, right: Vector3, forearm: bool=false) -> float:
	var crossing:=palm_crossing(hit,incoming,left,right)
	var palm:=Geometry3D.get_closest_point_to_segment(crossing,left,right)
	var tangent_gap:=Vector2(crossing.x-palm.x,crossing.y-palm.y).length()
	var core:=1.0-smoothstep(.035,.205,tangent_gap)
	# A forearm can stop the ball, but is less sealed than pressed palms.
	return lerpf(.22,.98,core)*(.80 if forearm else 1.0)

static func pressed_velocity(velocity: Vector3, point: Vector3, defender: int, gravity: float=9.81) -> Vector3:
	var outward: float=-1.0 if defender==0 else 1.0
	# Hands need not be exactly over the net. A sealed press meets the
	# tape above its top, instead of driving vertically into our own net
	# merely because the first sphere contact is a few cm behind it.
	# Only adjust the rebound angle at impact; flight and scoring stay live.
	if point.z*outward>=0 or point.y<=2.62 or velocity.z*outward<=0: return velocity
	var drop:=point.y-2.60
	var down_time:=2.0*drop/(sqrt(velocity.y*velocity.y+2.0*gravity*drop)-velocity.y)
	var through_net:=absf(point.z)/maxf(.01,down_time)*1.08
	velocity.z=outward*maxf(absf(velocity.z),minf(10.5,through_net))
	return velocity

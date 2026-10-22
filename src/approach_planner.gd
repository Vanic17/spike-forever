extends RefCounted
## Flight-time floor for the existing movement limits, not a speed multiplier.
static func seconds(player, destination: Vector3, max_speed: float) -> float:
	var delta: Vector3=destination-player.position
	delta.y=0
	var distance:=delta.length()
	if distance<0.12: return 0.0
	var initial:=clampf(player.velocity.dot(delta.normalized()),-max_speed,max_speed)
	const ACCEL:=22.0
	const BRAKE:=22.0*0.72*0.72
	var reverse:=maxf(0.0,-initial)/ACCEL
	if initial<0: distance+=initial*initial/(2.0*ACCEL)
	initial=maxf(0,initial)
	var peak:=sqrt((2.0*ACCEL*BRAKE*distance+BRAKE*initial*initial)/(ACCEL+BRAKE))
	var travel:=0.0
	if peak<initial:
		travel=initial/BRAKE+sqrt(2.0*maxf(0,initial*initial/(2.0*BRAKE)-distance)/ACCEL)
	elif peak<=max_speed:
		travel=(peak-initial)/ACCEL+peak/BRAKE
	else:
		var ramps: float=(max_speed*max_speed-initial*initial)/(2.0*ACCEL)+max_speed*max_speed/(2.0*BRAKE)
		travel=(max_speed-initial)/ACCEL+(distance-ramps)/max_speed+max_speed/BRAKE
	# The actor still needs the final stance adjustment at the end of braking.
	return reverse+travel+0.38

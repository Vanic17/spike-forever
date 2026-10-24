extends RefCounted
## Response depends on the actual contact position and the block's seal.
static func solve(incoming: Vector3, defender: int, strength: float, quality: float, edge: float, variation: Vector3=Vector3.ZERO) -> Dictionary:
	var outward: float=-1.0 if defender==0 else 1.0
	var seal:=clampf(strength*(0.55+quality*0.45),0,1)
	# Hitting an outside fingertip is not a sealed wall, even with a good
	# jump: retain the tool/deflection instead of turning it into a stuff.
	seal*=1.0-.28*smoothstep(.45,1.10,absf(edge))
	if absf(edge)>0.78 and seal<0.88:
		var lift:=lerpf(1.4,7.5,clampf(variation.y,0,1))
		return {"kind":"block_tool","velocity":Vector3(incoming.x*0.55+signf(edge)*lerpf(3.0,8.5,clampf(absf(edge),0,1))+variation.x*1.4,incoming.y*0.25+lift,incoming.z*lerpf(.42,.78,absf(variation.z))),"seal":seal}
	if seal>=0.70:
		# Pressed hands remove forward momentum and drive the ball down
		# close to the net. A flatter, deep rebound was an easy CPU dig.
		return {"kind":"stuff_block","velocity":Vector3(incoming.x*.16+variation.x*1.1,-maxf(8.5,absf(incoming.z)*lerpf(.48,.66,seal)),outward*clampf(absf(incoming.z)*.19+variation.z*1.2,3.2,7.5)),"seal":seal}
	var normal:=Vector3(clampf(edge,-1,1)*0.24,0.10,outward).normalized()
	var velocity:=incoming
	var closing:=velocity.dot(normal)
	if closing<0: velocity-=normal*closing*lerpf(0.75,1.50,seal)
	velocity*=0.66
	velocity.y+=lerpf(2.4,0.5,seal)
	velocity.x+=variation.x*2.2
	var detail:="cushion"
	if variation.y>.58:
		velocity.y=maxf(velocity.y,lerpf(4.5,8.5,variation.y)); detail="high_recycle"
	elif variation.y<-.45:
		velocity.y=minf(velocity.y,-lerpf(1.5,4.0,absf(variation.y))); detail="low_dribble"
	elif variation.z>.45:
		velocity.z+=outward*2.5; detail="turn_back"
	elif variation.z<-.45:
		velocity.z=incoming.z*.30; detail="through_fingers"
	return {"kind":"block_touch","detail":detail,"velocity":velocity,"seal":seal}

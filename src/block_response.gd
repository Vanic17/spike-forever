extends RefCounted
## Response depends on the actual contact position and the block's seal.
static func solve(incoming: Vector3, defender: int, strength: float, quality: float, edge: float) -> Dictionary:
	var outward: float=-1.0 if defender==0 else 1.0
	var seal:=clampf(strength*(0.55+quality*0.45),0,1)
	if absf(edge)>0.78 and seal<0.88:
		return {"kind":"block_tool","velocity":Vector3(incoming.x*0.55+signf(edge)*lerpf(3.0,7.0,absf(edge)),incoming.y*0.38+1.4,incoming.z*0.64),"seal":seal}
	if seal>=0.70:
		return {"kind":"stuff_block","velocity":Vector3(incoming.x*0.20,-maxf(4.5,absf(incoming.z)*0.40),outward*maxf(5.0,absf(incoming.z)*0.46)),"seal":seal}
	var normal:=Vector3(clampf(edge,-1,1)*0.24,0.10,outward).normalized()
	var velocity:=incoming
	var closing:=velocity.dot(normal)
	if closing<0: velocity-=normal*closing*lerpf(0.75,1.50,seal)
	velocity*=0.66
	velocity.y+=lerpf(2.4,0.5,seal)
	return {"kind":"block_touch","velocity":velocity,"seal":seal}

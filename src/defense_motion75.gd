extends RefCounted
## Reference haSkiDd9P_8: only final lowering/platform preparation and dig.
## Authored adaptation of compatible PSA supports, not monocular mocap.
## Contact, root travel, planted feet and the gameplay clock stay authoritative.
const Shape=preload("res://src/dive_motion41.gd")
static func source_time(time: float, _contact: float, _duration: float) -> float: return time
static func prepare(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float, lateral: float=0.0, one_hand: bool=false) -> Array[Transform3D]:
	var result:=pose.duplicate()
	# Soft anticipation is gone at the exact source contact. No extra step,
	# teleport, forced fall or new ball interception is introduced.
	var loading:=Shape._bell(time,maxf(0,contact-.42),maxf(.015,contact-.16),contact)
	var absorption:=Shape._bell(time,contact+.025,contact+.14,minf(duration,contact+.42))
	var spine:=names.find("Spine1")
	if spine>=0:
		Shape._rotate_subtree(result,parents,spine,Vector3.RIGHT,-.075*loading)
		Shape._rotate_subtree(result,parents,spine,Vector3.UP,.10*lateral*loading)
	for side in ["Left","Right"]:
		var arm:=names.find(side+"Arm")
		if arm>=0:
			Shape._rotate_subtree(result,parents,arm,Vector3.RIGHT,-.10*loading+.045*absorption)
	# The final exercise uses the right forearm/palm as a last low reach.
	# Its genuine one-hand source owns the dive and supporting hand; only
	# the free arm opens while it is clear of the floor.
	if one_hand:
		var free_arm:=names.find("LeftArm"); var hand:=names.find("LeftHand")
		if free_arm>=0 and hand>=0:
			var clear:=smoothstep(.18,.38,pose[hand].origin.y)
			var open:=Shape._bell(time,maxf(0,contact-.30),contact,minf(duration,contact+.20))
			Shape._rotate_subtree(result,parents,free_arm,Vector3.UP,.22*open*clear)
	return result

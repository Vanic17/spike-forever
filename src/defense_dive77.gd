extends "res://src/defense_motion75.gd"
const SOURCE:="dive_v26_02"
static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	return prepare(pose,names,parents,time,contact,duration,1,true)
## Bake a supported rise, bypassing the source's shoulder somersault entirely.
## Blend LOCAL joint rotations; never interpolate global limbs or a live rig.
static func recovery_pose(reference: Array[Transform3D], hold: Array[Transform3D], standing: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	var weight:=smoothstep(contact+.28,maxf(contact+.30,duration-.035),time)
	var result: Array[Transform3D]=[];result.resize(reference.size())
	for bone in reference.size():
		var parent: int=parents[bone]
		var a: Transform3D=hold[bone];var b: Transform3D=standing[bone];var ref: Transform3D=reference[bone]
		if parent>=0 and parent<bone:
			a=hold[parent].affine_inverse()*a;b=standing[parent].affine_inverse()*b;ref=reference[parent].affine_inverse()*ref
		var origin: Vector3=ref.origin if parent>=0 and parent<bone else a.origin.lerp(b.origin,weight)
		# Pelvis translation carries the rise. All articulated segment offsets
		# retain the source skeleton's lengths.
		if names[bone]=="Hips":origin=a.origin.lerp(b.origin,weight)
		var q:=a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(),weight).normalized()
		var local:=Transform3D(Basis(q),origin)
		result[bone]=result[parent]*local if parent>=0 and parent<bone else local
	return result

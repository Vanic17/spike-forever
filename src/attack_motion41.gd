extends RefCounted
## Authored hybrid spike: retain the original L-R-L supports, add a delayed
## arm load, opposing free arm and a continuous wrist/follow-through gesture.
## Input/output are complete, normalized Godot GLOBAL bone transforms.
## This module never changes a root, a gameplay deadline or a ball trajectory.
const SOURCE := "attack_line"
const MAX_ADAPT_HAND_TRAVEL := 0.14

static func source_time(time: float, contact: float, duration: float) -> float:
	var t := clampf(time, 0.0, duration)
	if t <= contact and contact > 0.001:
		var phase := t / contact
		# Hold the loading pose slightly longer, then recover the same contact
		# frame. The derivative is one at both ends, so the warp has no step.
		return t - contact * 0.036 * pow(sin(PI * phase), 2.0)
	var remaining := duration - contact
	if remaining > 0.001:
		var phase := (t - contact) / remaining
		return t + remaining * 0.018 * pow(sin(PI * phase), 2.0)
	return t

static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	if pose.is_empty(): return pose
	var result: Array[Transform3D] = pose.duplicate()
	var load := _bell(time, maxf(0.0, contact - 0.73), contact - 0.25, contact - 0.035)
	var release := _bell(time, contact - 0.16, contact + 0.065, minf(duration, contact + 0.43))
	var follow := _bell(time, contact + 0.035, minf(duration - 0.12, contact + 0.31), minf(duration, contact + 0.84))
	# Torso/shoulder coils unwind before contact: the original right-hand
	# contact position is invariant, including when evaluated on the PSA path.
	_rotate(result, names, parents, "Spine", Vector3.UP, deg_to_rad(-5.0 * load + 4.5 * follow))
	_rotate(result, names, parents, "Spine1", Vector3.RIGHT, deg_to_rad(-3.0 * load + 3.5 * follow))
	_rotate(result, names, parents, "LeftArm", Vector3.RIGHT, deg_to_rad(-11.0 * load + 9.0 * follow))
	_rotate(result, names, parents, "LeftForeArm", Vector3.UP, deg_to_rad(6.0 * load - 5.0 * follow))
	_rotate(result, names, parents, "RightArm", Vector3.UP, deg_to_rad(6.5 * load - 7.0 * follow))
	_rotate(result, names, parents, "RightForeArm", Vector3.RIGHT, deg_to_rad(-5.5 * load + 9.0 * follow))
	# A wrist snap changes hand orientation, never the contact joint origin.
	# Use the local finger-to-wrist direction to derive a stable flexion axis.
	var hand := names.find("RightHand")
	var finger := names.find("RightHandMiddle1")
	if hand >= 0 and finger >= 0:
		var fingers: Vector3 = result[finger].origin - result[hand].origin
		var flex := fingers.cross(Vector3.UP).normalized()
		if flex.length_squared() < 0.01: flex = Vector3.RIGHT
		_rotate_index(result, parents, hand, flex, deg_to_rad(13.0 * release + 4.0 * follow))
	return result

static func adapt(pose: Array[Transform3D], names: Array[String], parents: Array[int], local_ball: Vector3, weight: float) -> Array[Transform3D]:
	# Runtime reach is visual only. Existing contact IK remains the final
	# bounded solver; source feet, pelvis, root travel and timing stay intact.
	var hand := names.find("RightHand")
	var amount := clampf(weight, 0.0, 1.0)
	if hand < 0 or amount <= 0.0001 or not local_ball.is_finite(): return pose
	var delta: Vector3 = local_ball - pose[hand].origin
	if delta.length_squared() <= 0.000001: return pose
	var yaw := clampf(delta.x * 0.19, -deg_to_rad(5.0), deg_to_rad(5.0))
	var lean := clampf(delta.z * 0.18, -deg_to_rad(4.0), deg_to_rad(4.0))
	var lateral := clampf(delta.x * 0.12, -deg_to_rad(3.0), deg_to_rad(3.0))
	var result := _adapt_rotation(pose, names, parents, local_ball, yaw, lean, lateral, amount)
	var travel: float = result[hand].origin.distance_to(pose[hand].origin)
	if travel > MAX_ADAPT_HAND_TRAVEL:
		# A single bounded rescale prevents visual assistance replacing a real
		# approach step. No direct translation or bone stretching is permitted.
		result = _adapt_rotation(pose, names, parents, local_ball, yaw, lean, lateral, amount * MAX_ADAPT_HAND_TRAVEL / travel * 0.99)
	# A correction that cannot improve this particular sampled support pose
	# is discarded, rather than bending the torso away from the ball.
	if result[hand].origin.distance_squared_to(local_ball) > pose[hand].origin.distance_squared_to(local_ball): return pose
	return result

static func _adapt_rotation(pose: Array[Transform3D], names: Array[String], parents: Array[int], local_ball: Vector3, yaw: float, lean: float, lateral: float, amount: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = pose.duplicate()
	_rotate(result, names, parents, "Spine", Vector3.UP, yaw * amount * 0.55)
	_rotate(result, names, parents, "Spine1", Vector3.RIGHT, lean * amount)
	_rotate(result, names, parents, "Spine2", Vector3.FORWARD, lateral * amount)
	var hand := names.find("RightHand")
	var shoulder := names.find("RightShoulder")
	if hand >= 0 and shoulder >= 0:
		var reach: Vector3 = result[hand].origin - result[shoulder].origin
		var wanted: Vector3 = local_ball - result[shoulder].origin
		var axis := reach.cross(wanted)
		if axis.length_squared() > 0.000001 and wanted.length_squared() > 0.0001:
			_rotate_index(result, parents, shoulder, axis.normalized(), minf(reach.angle_to(wanted), deg_to_rad(3.0)) * amount)
	return result

static func _bell(time: float, start: float, peak: float, finish: float) -> float:
	if time <= start or time >= finish or peak <= start or finish <= peak: return 0.0
	if time < peak: return _smooth((time - start) / (peak - start))
	return _smooth((finish - time) / (finish - peak))

static func _smooth(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0)

static func _rotate(pose: Array[Transform3D], names: Array[String], parents: Array[int], bone: String, axis: Vector3, radians: float) -> void:
	if absf(radians) < 0.000001: return
	_rotate_index(pose, parents, names.find(bone), axis, radians)

static func _rotate_index(pose: Array[Transform3D], parents: Array[int], bone: int, axis: Vector3, radians: float) -> void:
	if bone < 0 or axis.length_squared() < 0.0001 or absf(radians) < 0.000001: return
	var pivot: Vector3 = pose[bone].origin
	var turn := Basis(axis.normalized(), radians)
	for index in range(bone, pose.size()):
		var ancestor := index
		while ancestor > bone and ancestor >= 0:
			ancestor = parents[ancestor]
		if ancestor != bone: continue
		pose[index] = Transform3D(turn * pose[index].basis, pivot + turn * (pose[index].origin - pivot))

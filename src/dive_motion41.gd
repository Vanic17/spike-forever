extends RefCounted
## Authored front dig: right-hand reach, free-arm counterbalance, elbow-led
## absorption and a supported rise. The original PSA remains untouched.
## Input and output are GLOBAL Godot-space transforms; gameplay owns root travel.
const SOURCE := "dive_v26_06"

static func source_time(time: float, contact: float, duration: float) -> float:
	var t := clampf(time, 0.0, duration)
	# Retiming is restricted to flight. Feet/hands planted during the fall and
	# rise keep their original source clock; the exact ball event is an anchor.
	if t < contact:
		t += 0.010 * _bell(t, contact * 0.67, contact * 0.84, contact - 0.016)
	elif t > contact:
		t -= 0.014 * _bell(t, contact + 0.025, contact + 0.095, contact + 0.200)
	return clampf(t, 0.0, duration)

static func shape(pose: Array[Transform3D], names: Array[String], parents: Array[int], time: float, contact: float, duration: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = pose.duplicate()
	if result.is_empty() or names.size() != result.size():
		return result
	var spine := names.find("Spine1")
	var left_arm := names.find("LeftArm")
	var left_hand := names.find("LeftHand")
	var right_hand := names.find("RightHand")
	var neck := names.find("Neck")
	if mini(mini(spine, left_arm), mini(left_hand, right_hand)) < 0:
		return result
	var t := clampf(time, 0.0, duration)
	var preparation := _bell(t, 0.015, contact * 0.38, contact - 0.065)
	var extension := _bell(t, contact * 0.48, contact + 0.005, contact + 0.180)
	var hands_free := smoothstep(0.17, 0.35, minf(pose[left_hand].origin.y, pose[right_hand].origin.y))
	# No chest correction at the contact event: its right-hand transform is
	# byte-for-byte inherited. Rotations affect only upper-body descendants.
	var event_notch := smoothstep(0.0, 0.085, absf(t - contact))
	_rotate_subtree(result, parents, spine, Vector3.UP, -0.135 * preparation * event_notch * hands_free)
	_rotate_subtree(result, parents, spine, Vector3.RIGHT, 0.055 * preparation * event_notch * hands_free)
	# Open the free arm away from the platform: a one-hand performance rather
	# than the original paired-arm dig. Fade BEFORE the palm meets the floor.
	var free_left := smoothstep(0.17, 0.35, pose[left_hand].origin.y)
	_rotate_subtree(result, parents, left_arm, Vector3.UP, 0.34 * extension * free_left)
	# Once supporting the body, alter the elbow's plane around the fixed
	# shoulder-to-palm axis. Both segment lengths AND the planted palm stay put.
	var support := _bell(t, contact + 0.18, contact + 0.49, contact + 1.27)
	if support > 0.00001:
		var palm := result[left_hand]
		var support_axis := (palm.origin - result[left_arm].origin).normalized()
		_rotate_subtree(result, parents, left_arm, support_axis, 0.29 * support)
		# The palm is on the rotation axis; restore its original orientation,
		# including fingers, to preserve the visible contact with the parquet.
		for i in result.size():
			if _descendant(i, left_hand, parents):
				result[i] = pose[i]
	# A bounded head lift follows the rebound from the floor and releases when
	# the palms leave it. It does not pull the spine, limbs or root upwards.
	if neck >= 0:
		var absorb := _bell(t, contact + 0.20, contact + 0.55, contact + 1.17)
		_rotate_subtree(result, parents, neck, Vector3.RIGHT, -0.072 * absorb)
		var rise := _bell(t, contact + 1.17, contact + 1.55, duration - 0.045)
		_rotate_subtree(result, parents, neck, Vector3.RIGHT, -0.048 * rise)
	return result

static func _bell(time: float, start: float, peak: float, finish: float) -> float:
	if finish <= start or time <= start or time >= finish:
		return 0.0
	if time <= peak:
		return smoothstep(start, peak, time)
	return 1.0 - smoothstep(peak, finish, time)

static func _descendant(index: int, ancestor: int, parents: Array[int]) -> bool:
	var cursor := index
	while cursor >= 0 and cursor < parents.size():
		if cursor == ancestor:
			return true
		var next := parents[cursor]
		if next >= cursor:
			break
		cursor = next
	return false

static func _rotate_subtree(pose: Array[Transform3D], parents: Array[int], bone: int, axis: Vector3, angle: float) -> void:
	if absf(angle) < 0.000001:
		return
	var pivot := pose[bone].origin
	var turn := Basis(Quaternion(axis.normalized(), angle))
	for i in pose.size():
		if _descendant(i, bone, parents):
			pose[i] = Transform3D(turn * pose[i].basis, pivot + turn * (pose[i].origin - pivot))

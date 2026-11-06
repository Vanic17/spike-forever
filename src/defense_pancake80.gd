extends "res://src/defense_motion75.gd"
const SOURCE:="dive_v26_06"
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,contact: float,duration: float) -> Array[Transform3D]:
	var result:=pose.duplicate()
	var weight:=smoothstep(contact-.30,contact-.045,time)*(1-smoothstep(contact+.08,minf(duration,contact+.38),time))
	var hips:=names.find("Hips");var hand:=names.find("RightHand");var finger:=names.find("RightHandMiddle1")
	if mini(hips,mini(hand,finger))<0:return result
	preload("res://src/defense_platform80.gd").arm(result,names,parents,"Right",Vector3(result[hips].origin.x-.08,.045,result[hips].origin.z+.85),weight,false)
	if weight>.00001:
		var direction: Vector3=(result[finger].origin-result[hand].origin).normalized()
		var turn:=Quaternion.IDENTITY.slerp(Quaternion(direction,Vector3(0,0,1)),weight)
		Shape._rotate_subtree(result,parents,hand,turn.get_axis(),turn.get_angle())
		for digit in ["Thumb","Index","Middle","Ring","Pinky"]:
			for joint in [1,2]:
				var parent:=names.find("RightHand"+digit+str(joint));var child:=names.find("RightHand"+digit+str(joint+1))
				if parent<0 or child<0:continue
				var from: Vector3=(result[child].origin-result[parent].origin).normalized();var flat:=Vector3(from.x,0,from.z).normalized()
				if flat.length_squared()<.1:continue
				var align:=Quaternion.IDENTITY.slerp(Quaternion(from,flat),weight)
				Shape._rotate_subtree(result,parents,parent,align.get_axis(),align.get_angle())
	return result

extends RefCounted
## Reference w6IevIgUfxY: relaxed entry, longer timing step, high backswing,
## then the existing plant/jump takes over. Feet and root remain locomotion-owned.
const SOURCE:="run"
const Arm=preload("res://src/stroke_motion96.gd")
const Ref=preload("res://src/attack_reference78.gd")
static func source_time(time: float,_contact: float,_duration: float) -> float:return time
static func shape(pose: Array[Transform3D],names: Array[String],parents: Array[int],time: float,_contact: float,duration: float) -> Array[Transform3D]:
	var out:=pose.duplicate()
	var u:=clampf(time/maxf(.001,duration),0,1)
	var load:=smoothstep(.55,.95,u)
	Ref.rotate(out,names,parents,"Spine1",Vector3.RIGHT,.12*load)
	Ref.rotate(out,names,parents,"Spine2",Vector3.RIGHT,.05*load)
	for side in ["Left","Right"]:
		var lateral:=1.0 if side=="Left" else -1.0
		var a:=names.find(side+"Arm")
		if a<0:continue
		var sweep:=Vector3(lateral*.13,lerpf(-.60,-.27,load),lerpf(.06,-.58,load))
		Arm.arm(out,names,parents,side,out[a].origin+sweep,Vector3(lateral*.40,-.10,-.20),1.0)
	return out

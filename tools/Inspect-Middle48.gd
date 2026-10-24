extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	var p=g.players[1]
	for key in ["attack","attack_decoy","attack_v26_01","attack_line","attack_angle_left","attack_turn"]:
		var c=g.clips[key]; print("MIDDLE48 CLIP ",key," takeoff=",c.takeoff_time," contact=",c.contact_time," recovery=",c.recovery_end," height=",c.contact_offset," apex=",c.jump_boost)
		for n in 6:
			var t: float=maxf(0,c.takeoff_time-.20)+n*.10
			var pose=p.normalized_pose("source:"+key,t,false)
			print("MIDDLE48 POSE ",key," t=",t," hips=",pose[c.names.find("Hips")].origin," L=",pose[c.names.find("LeftHand")].origin," R=",pose[c.names.find("RightHand")].origin," feet=",pose[c.names.find("LeftFoot")].origin.y,",",pose[c.names.find("RightFoot")].origin.y)
	g.free(); quit()

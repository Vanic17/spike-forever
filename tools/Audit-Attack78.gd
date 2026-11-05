extends SceneTree
func _initialize():
	var Motion=preload("res://src/motion_prototypes.gd")
	for name in ["attack_pin_left","attack_pin_right","dive_v26_02","dive_v26_04"]:
		var clip=preload("res://src/psa.gd").new();clip.load_file("res://assets/active/"+name+".psa")
		clip.load_hierarchy("res://assets/active/skeleton.psk");clip.detect_contact(name)
		var pose=Motion.normalized(clip,clip.duration-.025)
		print(name," contact=",clip.contact_time," takeoff=",clip.takeoff_time," end=",clip.duration," recovery=",clip.recovery_end," final_hips=",pose[clip.names.find("Hips")].origin.y)
	quit()

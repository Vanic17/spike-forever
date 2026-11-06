extends SceneTree
func _initialize():
	for name in ["dive_v26_01","dive_v26_06","dive_short","dive_v26_02","dive_v26_04"]:
		var p=preload("res://src/psa.gd").new();p.load_file("res://assets/active/"+name+".psa");p.load_hierarchy("res://assets/active/skeleton.psk");p.detect_contact(name)
		var best: Dictionary={};var cost:=INF
		for frame in p.frames:
			var t: float=float(frame)/p.fps
			if t<p.contact_time-.05 or t>p.contact_time+1.1:continue
			var pose=preload("res://src/motion_prototypes.gd").normalized(p,t)
			var hand: Vector3=pose[p.names.find("RightHand")].origin
			var head: Vector3=pose[p.names.find("Head")].origin
			if hand.y<cost and head.y>.17:cost=hand.y;best={"time":t,"hand":hand,"head":head,"hips":pose[p.names.find("Hips")].origin}
		print(name," contact=",p.contact_time," original=",p.contact_offset," duration=",p.duration," floor=",best)
	quit()

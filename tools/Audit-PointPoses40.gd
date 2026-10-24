extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	var p=g.players[2]
	for name in ["idle","relaxed","walk","run","run_right","attack_pin_left","attack_pin_right","attack_angle_left","attack_angle_right","attack_v26_01","attack_v26_02","attack_v26_03"]:
		var clip=g.clips[name]; var low:=INF; var high:=-INF
		for frame in 40:
			var pose: Array=p.normalized_pose("source:"+name,clip.duration*frame/40,true)
			var y: float=pose[clip.names.find("Head")].origin.y
			low=minf(low,y); high=maxf(high,y)
		print("POSE40 ",name," head=",low,"..",high," contact=",clip.contact_time," lead=",p.preparation_lead(name,1.12)," source=",clip.source)
	g.free(); quit()

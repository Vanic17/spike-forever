extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	for key in g.clips:
		if key.begins_with("attack_tip") or key in ["attack","attack_line","power","float"]:
			var c=g.clips[key]; print("CONTACT47 ",key," ",c.contact_offset," at=",c.contact_time," ground=",c.ground_y," center=",c.body_center)
	g.free(); quit()

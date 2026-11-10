extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("attack105" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false)
	var Motion=preload("res://src/motion_prototypes.gd")
	var library=Motion.supplement(g.clips)
	assert(library.has_animation("approach105"))
	assert(ResourceSaver.save(library,Motion.LIBRARY_PATH,ResourceSaver.FLAG_COMPRESS)==OK)
	print("BAKE105 PASS clips=",library.get_animation_list().size());quit()

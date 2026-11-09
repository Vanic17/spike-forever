extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("middle102" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false)
	var Motion=preload("res://src/motion_prototypes.gd")
	var library=Motion.supplement(g.clips)
	assert(ResourceSaver.save(library,Motion.LIBRARY_PATH,ResourceSaver.FLAG_COMPRESS)==OK)
	print("BAKE102 PASS ",library.get_animation_list().size()," native clips; first contact=",g.clips.set_first96.contact_offset);quit()

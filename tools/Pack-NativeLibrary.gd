extends SceneTree
func _initialize() -> void:
	var path: String="res://assets/active/native_all.res"
	var library=ResourceLoader.load(path,"AnimationLibrary",ResourceLoader.CACHE_MODE_IGNORE)
	assert(library is AnimationLibrary)
	var names=library.get_animation_list()
	assert(ResourceSaver.save(library,path,ResourceSaver.FLAG_COMPRESS)==OK)
	var packed=ResourceLoader.load(path,"AnimationLibrary",ResourceLoader.CACHE_MODE_IGNORE)
	assert(packed.get_animation_list()==names)
	for name in names:
		var before=library.get_animation(name)
		var after=packed.get_animation(name)
		assert(before.length==after.length and before.get_track_count()==after.get_track_count())
		assert(before.get_meta("contact_time")==after.get_meta("contact_time"))
	print("NATIVE PACK PASS: ",names.size()," clips / lossless binary resource compression / contact metadata retained")
	quit()

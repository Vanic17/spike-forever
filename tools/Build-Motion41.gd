extends SceneTree
## Bake only the two supplementary native clips; never rebuild native_all.res.
const PSA = preload("res://src/psa.gd")
const Motion = preload("res://src/motion_prototypes.gd")
func _initialize() -> void:
	var bank: Dictionary = {}
	for author in Motion.AUTHORS:
		var clip = PSA.new()
		assert(clip.load_file("res://assets/active/" + author.SOURCE + ".psa"))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(author.SOURCE)
		bank[author.SOURCE] = clip
	Motion.register(bank)
	var library := AnimationLibrary.new()
	for name in Motion.NAMES:
		assert(bank.has(name))
		library.add_animation(name, Motion.Converter.make_animation(bank[name],func(time: float): return Motion.normalized(bank[name],time)))
	library.set_meta("motion_signature",Motion.signature(bank))
	assert(ResourceSaver.save(library,Motion.LIBRARY_PATH,ResourceSaver.FLAG_COMPRESS)==OK)
	print("BUILD MOTION41 PASS clips=", library.get_animation_list(), " bytes=", FileAccess.get_file_as_bytes(Motion.LIBRARY_PATH).size())
	quit()

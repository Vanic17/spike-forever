extends SceneTree
const PSA = preload("res://src/psa.gd")
const Avatar = preload("res://src/avatar.gd")
const Converter = preload("res://src/psa_animation_library.gd")

func _initialize() -> void:
	var bank: Dictionary = {}
	for name in Converter.CLIPS:
		var clip = PSA.new()
		if not clip.load_file("res://assets/active/" + name + ".psa"):
			quit(1)
			return
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(name)
		bank[name] = clip
	var sampler = Avatar.new()
	sampler.source_clips = bank
	sampler.clips = bank
	var library := Converter.build(bank, Callable(sampler, "psa_normalized_pose"))
	var error := ResourceSaver.save(library, Converter.LIBRARY_PATH, ResourceSaver.FLAG_COMPRESS)
	sampler.free()
	print("PSA CONVERSION ", "PASS" if error == OK else "FAIL", ": ", library.get_animation_list())
	quit(0 if error == OK else 1)

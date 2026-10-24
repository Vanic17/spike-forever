extends "res://tools/Benchmark-Animation41.gd"
## Same frozen twelve-avatar workload, with only selected authored variants
## enabled. This supplements, never replaces, the original before/after run.
var prototype_set := "both"
const Motion=preload("res://src/motion_prototypes.gd")

func setup() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--prototype-set="): prototype_set=argument.trim_prefix("--prototype-set=")
	assert(prototype_set in ["none","dive","attack","both"])
	# Production registers these once in main._ready. The isolated benchmark
	# deliberately excludes main, so reproduce registration before avatar setup.
	for author in Motion.AUTHORS:
		var clip=PSA.new()
		assert(clip.load_file("res://assets/active/"+author.SOURCE+".psa"))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact("dive" if author.SOURCE.begins_with("dive") else "attack")
		bank[author.SOURCE]=clip
	Motion.register(bank)
	super.setup()
	for athlete in avatars:
		if mode=="native": assert(athlete.pose_tree!=null and athlete.pose_tree.initialized)
		if prototype_set in ["dive","both"]:
			assert(athlete.clips.has("dive_authored41"),"Dive prototype missing; do not silently benchmark its fallback")
			athlete.select_variant("dive","dive_authored41")
		if prototype_set in ["attack","both"]:
			assert(athlete.clips.has("attack_adaptive41"),"Attack prototype missing; do not silently benchmark its fallback")
			athlete.select_variant("attack","attack_adaptive41")
	print("ANIMATION41 PROTOTYPE SET ",prototype_set)

func _process(elapsed: float) -> bool:
	if avatars.is_empty(): return false
	# Give both old and authored variants the same modest, reachable contact
	# context; changing a variant must not change the simulated actor's root.
	for i in avatars.size():
		var athlete=avatars[i]
		if athlete.clip_name in ["attack","dive"]:
			athlete.reach_action=athlete.clip_name
			athlete.reach_weight=0.65
			athlete.reach_target=athlete.contact_world(athlete.clip_name)+Vector3(0.08*sin(float(frame+i*7)*0.023),0.04*cos(float(frame+i*3)*0.019),0.03)
		else:
			athlete.reach_weight=0
	return super._process(elapsed)

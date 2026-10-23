extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var exp=load("res://src/animation_expansion.gd")
	var selected: Dictionary={}
	for p in game.players:
		for action in ["idle","ready","relaxed","block_ready","walk","run","shuffle_left","shuffle_right","cross_left","cross_right","backwalk","backpedal"]:
			selected[p.variant_names.get(action,action)]=true
	for name in exp.CLIPS:
		var family: String=exp.FAMILIES[name]
		if family in ["receive","set","fast_set","attack","block","dive"]: continue
		var p=game.players[0]
		var clip=game.clips[name]
		var low:=INF
		var hips:=INF
		for frame in 61:
			var pose=p.psa_normalized_pose("source:"+name,clip.duration*frame/61.0,true)
			low=minf(low,pose[clip.names.find("Head")].origin.y)
			hips=minf(hips,pose[clip.names.find("Hips")].origin.y)
		print("STANDING ",name," head=",low," hips=",hips)
		if name=="walk_v26_01":
			assert(not selected.has(name) and low<0.8,"Known falling walk must remain quarantined")
		else:
			assert(low>1.0 and hips>0.65,"Off-ball clip collapses during its cycle: "+name)
	for p in game.players: assert(p.clips.walk==game.clips.walk,"Every athlete must use a standing walk")
	print("STANDING27 PASS: all noncontact expansion cycles sampled / 12 athletes use standing walk / falling source quarantined")
	game.free()
	quit()

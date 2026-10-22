extends SceneTree
const Intent = preload("res://src/movement_intent.gd")
const Avatar = preload("res://src/avatar.gd")
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var starts: Array[float] = []
	var roles := ["OH1","MB1","OPP","OH2","L","S"]
	for i in 6:
		var movement = Intent.new()
		movement.configure(0, i + 1)
		movement.reset(Vector3.ZERO)
		movement.observe("SET:10", roles[i], "cover", 1.0)
		var first := -1.0
		for frame in 120:
			var clock := 1.0 + frame / 120.0
			var target: Vector3 = movement.perceive(Vector3(2,0,1), clock, 1.0/120.0)
			if target.length() > 0.001 and first < 0: first = clock - 1.0
		assert(first >= 0)
		starts.append(first)
		movement.observe("RECEIVE:10", roles[i], "contact", 3.0)
		assert(movement.perceive(Vector3(-3,0,5),3.0,1.0/120.0) == Vector3(-3,0,5), "Contextual contact assistance must remain immediate")
	assert(starts.max() - starts.min() > 0.14, "Support players must not all react together")
	var unique: Dictionary = {}
	for value in starts: unique[snappedf(value,0.008333)] = true
	assert(unique.size() >= 4)
	var bank: Dictionary = {}
	for name in ["idle","walk","run","run_right","backpedal","backwalk","shuffle_left","shuffle_right","receive","set","fast_set","attack","block","ready","relaxed","block_ready"]:
		var clip = PSA.new()
		assert(clip.load_file("res://assets/active/"+name+".psa"))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(name)
		bank[name] = clip
	var body = PSK.new()
	assert(body.load_file("res://assets/active/body.psk"))
	var athlete = Avatar.new()
	root.add_child(athlete)
	athlete.setup(bank,0,1,{"body":body})
	athlete.rotation.y = PI
	athlete.velocity = Vector3(1.5,0,-1.5)
	athlete.play("run",1,true)
	athlete.tick(0.1,false,true)
	athlete.prepare_contact("receive",0.32)
	var outgoing_time: float = athlete.blend_source_time
	athlete.tick(0.04,false,true)
	assert(athlete.blend_source_time > outgoing_time, "Outgoing stride must continue through the transition")
	for frame in 30:
		athlete.tick(1.0/120.0,false,true)
		for transform in athlete.last_pose: assert(transform.origin.is_finite() and transform.basis.is_finite())
	athlete.reach_weight = 0
	athlete.prepare_contact("receive",0)
	var hands: Vector3 = (athlete.current_hand(true)+athlete.current_hand(false))*0.5+Vector3(0,0.07,0)
	assert(hands.distance_to(athlete.contact_world("receive")) < 0.005,"Visual layering must not move the real contact event")
	var report := {"support_reaction_seconds":starts,"distinct_reactions":unique.size(),"contact_assistance_immediate":true,"outgoing_animation_continues":true,"contact_event_unchanged":true}
	var output := FileAccess.open("res://docs/movement-quality-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("MOVEMENT PASS: asynchronous support=",starts," / moving outgoing animation / exact contact retained")
	athlete.queue_free()
	quit()

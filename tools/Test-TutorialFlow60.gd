extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false
	var host
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node
	var t=g.tutorial; t.open(host)
	var rows: Array=[]
	# Real, repeated serves: feedback -> automatic new ball -> completion modal.
	t.start_lesson("serve",0); t.resume()
	var last_attempt:=-1; var pressed:=false
	for frame in 3000:
		if t.modal.visible: break
		if last_attempt!=t.attempts: last_attempt=t.attempts; pressed=false
		if t.pending.is_empty() and g.phase=="SERVE":
			if not pressed: g.send_test_button(JOY_BUTTON_A); pressed=true
			if g.charging and g.current_charge()>=.75: g.send_test_button(JOY_BUTTON_A,false)
		g.step(1.0/120)
		if frame%4==0:
			for p in g.players: p.apply_pose(1.0/30)
	assert(t.successes==2 and t.attempts==2 and t.modal.visible and g.paused,"Two real successful drills must complete the lesson")
	rows.append({"case":"automatic_repetition","attempts":t.attempts,"successes":t.successes,"completion_modal":t.modal.visible})
	t.resume(); assert(t.free_practice and t.attempts==3 and not g.paused)
	g.send_test_button(JOY_BUTTON_A); assert(g.charging)
	t.show_modal(); var before: float=g.clock_time
	for frame in 5: g.step(1.0/60)
	assert(g.clock_time==before,"Pause must freeze the drill, including charge time")
	t.resume(); assert(not g.charging and t.attempts==4,"Resuming a paused charge must restart the attempt, not leave a stuck charge")
	# No input cannot award a tutorial success in the contact categories.
	for category in ["receive","attack","block"]:
		t.start_lesson(category,0); t.resume()
		for frame in 2000:
			if not t.pending.is_empty(): break
			g.step(1.0/120)
		assert(not t.pending.is_empty() and not t.pending_ok and t.successes==0,"No action button must not complete "+category)
		rows.append({"case":"no_input","category":category,"successes":t.successes})
	# Wrong set choice has a real contact, but does not count as the requested set.
	t.start_lesson("set",0); t.resume(); Input.action_press("right"); g.send_test_button(JOY_BUTTON_A)
	for frame in 600:
		if not t.pending.is_empty(): break
		g.step(1.0/120)
	Input.action_release("right")
	assert(not t.pending_ok and t.successes==0,"Wrong target must not count even when the set contacts")
	rows.append({"case":"wrong_set_direction","successes":t.successes})
	t.home(); assert(not t.active and not g.started and not g.paused)
	FileAccess.open("res://docs/tutorial60-flow.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"paused_charge_restart":true,"free_practice":true,"home":true},"  "))
	print("TUTORIAL FLOW60 PASS actual repeated serves / completion / free practice / paused charge / no-input failures / wrong set / home"); g.free(); quit()

extends SceneTree
func _initialize() -> void: call_deferred("run")
func press(button: int) -> void:
	var event=InputEventJoypadButton.new(); event.button_index=button; event.pressed=true; root.push_input(event)
	await process_frame
	event=InputEventJoypadButton.new(); event.button_index=button; event.pressed=false; root.push_input(event)
	await process_frame
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true
	var cases:=0
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
			var setter: int=team*6+5; var libero: int=-1
			for i in range(team*6,team*6+6):
				if g.Tactics.libero(i,rotation,false): libero=i
			assert(libero>=0)
			g.receiver=team*6+3
			if g.receiver==libero: g.receiver=team*6
			var point: Vector3=g.Tactics.world(team,0.8,2); point.y=2.5
			g.players[setter].position=g.players[setter].stance_for_contact("set",point)
			g.players[team*6+2].position=point*Vector3(1,0,1)
			assert(g.choose_setter(team,point,1.4)==setter,"A nearby attacker must never steal the normal second touch")
			g.receiver=setter
			assert(g.choose_setter(team,point,1.4)==libero,"The libero sets when S received; no consecutive touches")
			g.receiver=team*6+3
			if g.receiver==libero: g.receiver=team*6
			g.players[setter].play("dive",1,false); g.players[setter].animation_time=0
			g.players[libero].position=g.players[libero].stance_for_contact("set",point)
			assert(g.choose_setter(team,point,0.6)==libero,"The libero covers a setter still on the floor")
			g.players[setter].play("idle",1,true)
			cases+=3
	var menu
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	assert(menu!=null)
	menu.panel.hide(); menu.clubs.hide()
	g.started=true; g.paused=true; g.pause_menu._process(0)
	await process_frame
	assert(g.pause_menu.resume_button.has_focus())
	await press(JOY_BUTTON_DPAD_DOWN)
	assert(g.pause_menu.menu_button.has_focus(),"D-pad must reach Return to main menu")
	await press(JOY_BUTTON_A)
	assert(not g.started and not g.paused and menu.panel.visible and menu.play.has_focus(),"Xbox A / PS Cross must return to the existing menu")
	g.started=true; menu.panel.hide(); g.paused=true; g.pause_menu._process(0)
	await press(JOY_BUTTON_B)
	assert(g.started and not g.paused,"Xbox B / PS Circle must resume the paused match")
	print("SPECIALISTS PAUSE42 PASS specialist_cases=",cases," / all rotations and both teams / S priority / L backup / real controller down+A and B / existing menu reused")
	g.free(); quit()

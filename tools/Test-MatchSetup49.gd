extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1440,810); root.content_scale_size=root.size
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	var clubs=menu.clubs; var sizes: Array=[]
	for size in [Vector2i(1440,810),Vector2i(1440,720),Vector2i(1280,720),Vector2i(1280,600)]:
		root.size=size; root.content_scale_size=size; clubs.match_setup()
		await process_frame; await process_frame; await process_frame
		for control in clubs.formation_buttons+[clubs.settings_format,clubs.settings_points,clubs.setup_start]:
			var rect: Rect2=control.get_global_rect()
			assert(rect.position.y>=0 and rect.end.y<=root.get_visible_rect().end.y+.5,"Formation/settings/start must be fully visible without scrolling: "+str(size)+" "+control.text+" "+str(rect))
			var parent=control.get_parent()
			while parent!=clubs.body:
				assert(not parent is ScrollContainer,"Formation/settings/start must not live in a scroll area")
				parent=parent.get_parent()
		for side in 2:
			var formation: Button=clubs.formation_buttons[side]
			var kit: Control=formation.get_node(formation.focus_neighbor_top)
			var team: Control=kit.get_node(kit.focus_neighbor_top)
			assert(team.get_node(team.focus_neighbor_bottom)==kit and kit.get_node(kit.focus_neighbor_bottom)==formation)
			assert(formation.get_node(formation.focus_neighbor_bottom)==(clubs.settings_format if side==0 else clubs.settings_points))
			formation.grab_focus(); formation.pressed.emit(); await process_frame
			assert(clubs.formation_dialog.visible,"Both formation buttons must open their team dialog")
			var cancel=InputEventAction.new(); cancel.action="ui_cancel"; cancel.pressed=true; clubs._input(cancel)
			assert(not clubs.formation_dialog.visible and formation.has_focus(),"Circle/B must return to the visible formation button")
		sizes.append(str(size))
	# Exercise actual mapped controller events, not only neighbor metadata.
	for analog in [false,true]:
		var formation: Button=clubs.formation_buttons[0]
		var kit: Control=formation.get_node(formation.focus_neighbor_top)
		var team: Control=kit.get_node(kit.focus_neighbor_top)
		team.grab_focus()
		for expected in [kit,formation,clubs.settings_format,clubs.setup_start]:
			if analog:
				var down=InputEventJoypadMotion.new(); down.axis=JOY_AXIS_LEFT_Y; down.axis_value=1.0; Input.parse_input_event(down)
				await process_frame
				down=InputEventJoypadMotion.new(); down.axis=JOY_AXIS_LEFT_Y; down.axis_value=0; Input.parse_input_event(down)
			else:
				var down=InputEventJoypadButton.new(); down.button_index=JOY_BUTTON_DPAD_DOWN; down.pressed=true; root.push_input(down)
				await process_frame
				down=InputEventJoypadButton.new(); down.button_index=JOY_BUTTON_DPAD_DOWN; down.pressed=false; root.push_input(down)
			await process_frame
			assert(root.gui_get_focus_owner()==expected,"D-pad and left stick must reach formations, settings and Start: analog="+str(analog)+" expected="+str(expected)+" actual="+str(root.gui_get_focus_owner()))
	# Start through the real setup button, then exercise deuce and deciding
	# sets for each selectable best-of / points pair and both winners.
	var matches: Array=[]
	for best_of in [1,3,5]:
		for points in [15,25]:
			for winner in 2:
				clubs.match_setup(); await process_frame
				clubs.settings_format.select([1,3,5].find(best_of)); clubs.settings_points.select([25,15].find(points)); clubs.setup_start.pressed.emit()
				assert(game.started and game.match_best_of==best_of and game.match_points==points and not game.match_finished)
				var required: int=int(best_of/2)+1
				for set_index in best_of:
					var set_winner: int=winner if set_index==best_of-1 else (set_index%2)
					var target: int=15 if best_of>1 and set_index==best_of-1 else points
					game.scores=[target-1,target-1]
					var before: Array=game.sets.duplicate()
					game.phase="SERVE"; game.award(set_winner,"TEST")
					assert(game.sets==before and not game.match_finished,"One-point advantage never ends a set")
					game.phase="SERVE"; game.award(1-set_winner,"TEST")
					game.phase="SERVE"; game.award(set_winner,"TEST")
					assert(game.sets==before and not game.match_finished,"Extended deuce still needs two points")
					game.phase="SERVE"; game.award(set_winner,"TEST")
					assert(game.sets[set_winner]==before[set_winner]+1,"Set must finish at the selected target, or 15 in a decider")
					if set_index<best_of-1:
						assert(not game.match_finished)
						game.phase_time=4.49; game.step(.02)
						assert(game.started and game.phase=="SERVE","Non-final sets continue the same match")
				assert(game.sets[winner]==required and game.match_finished and not game.paused)
				game.pause_menu._process(0); assert(not game.pause_menu.surface.visible)
				var pause=InputEventAction.new(); pause.action="start"; pause.pressed=true; game._unhandled_input(pause)
				assert(not game.paused,"Pause cannot trap the end-of-match return")
				game.phase_time=4.49; game.step(.02)
				assert(not game.started and not game.paused and menu.panel.visible and not clubs.visible and menu.play.has_focus(),"Completed match must return automatically to home with controller focus")
				matches.append({"best_of":best_of,"points":points,"winner":winner,"decider":15 if best_of>1 else points,"home":true})
	# Early straight-set wins must finish after 2 or 3 sets, not wait for
	# all possible sets. Verify that 25-point ordinary sets do not end at 15.
	for best_of in [3,5]:
		for winner in 2:
			clubs.match_setup(); clubs.settings_format.select([1,3,5].find(best_of)); clubs.settings_points.select(0); clubs.setup_start.pressed.emit()
			for set_index in int(best_of/2)+1:
				game.scores=[0,0]; game.scores[winner]=14; game.phase="SERVE"; game.award(winner,"TEST")
				assert(game.sets[winner]==set_index,"A 25-point ordinary set must not finish at 15")
				game.scores[winner]=24; game.phase="SERVE"; game.award(winner,"TEST")
				if not game.match_finished: game.phase_time=4.49; game.step(.02)
			assert(game.match_finished and game.sets[winner]==int(best_of/2)+1)
			game.phase_time=4.49; game.step(.02); assert(not game.started and menu.panel.visible)
	FileAccess.open("res://docs/match49-report.json",FileAccess.WRITE).store_string(JSON.stringify({"layout_sizes":sizes,"controller_paths_and_circle":true,"complete_matches":matches,"straight_set_wins":4,"deuce_verified":true,"automatic_home":true},"  "))
	print("MATCH49 PASS: formations visible at 4 sizes; controller paths/Circle; 12 complete settings/winner cases; 4 early wins; deuce; deciding set 15; automatic home")
	quit()

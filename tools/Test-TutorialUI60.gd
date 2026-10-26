extends SceneTree
func _initialize(): call_deferred("run")
func send(action: String,t):
	var e=InputEventAction.new(); e.action=action; e.pressed=true; t._input(e)
func axis(device: int,value: float):
	var event=InputEventJoypadMotion.new(); event.device=device; event.axis=JOY_AXIS_LEFT_Y; event.axis_value=value; Input.parse_input_event(event); Input.flush_buffered_events()
func joy(device: int,button: int,pressed: bool):
	var event=InputEventJoypadButton.new(); event.device=device; event.button_index=button; event.pressed=pressed; Input.parse_input_event(event); Input.flush_buffered_events()
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false
	var host
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): host=node
	var t=g.tutorial; var count:=0
	for locale in ["it","en"]:
		TranslationServer.set_locale(locale)
		for size in [Vector2i(1440,810),Vector2i(1280,720),Vector2i(1280,600),Vector2i(1024,600)]:
			root.size=size; root.content_scale_size=size
			t.open(host)
			for category in 5:
				t.categories[category].grab_focus()
				await process_frame; await process_frame; await process_frame
				for control in [t.start_button,t.lesson_pick,t.back_button]+t.categories:
					var rect: Rect2=control.get_global_rect()
					assert(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=size.x+1 and rect.end.y<=size.y+1,"Tutorial controls must fit at "+str(size)+": "+str(rect))
				assert(t.categories[category].get_node(t.categories[category].focus_neighbor_right)==t.lesson_pick)
				count+=1
			for category in preload("res://src/tutorial_lessons.gd").categories():
				for index in preload("res://src/tutorial_lessons.gd").all(category.id).size():
					t.start_lesson(category.id,index)
					await process_frame; await process_frame
					for control in t.modal_buttons:
						var bounds: Rect2=control.get_global_rect()
						assert(bounds.position.x>=0 and bounds.position.y>=0 and bounds.end.x<=size.x+1 and bounds.end.y<=size.y+1,"Every lesson modal must fit: "+category.id+" "+str(index)+" "+str(size)+" "+str(bounds))
					t.open(host)
			t.start_lesson("set",8)
			await process_frame; await process_frame
			for b in t.modal_buttons:
				var rect: Rect2=b.get_global_rect()
				assert(rect.end.y<=size.y+1 and rect.end.x<=size.x+1 and rect.position.y>=0,"Modal controls must remain visible: "+str(rect))
			send("ui_cancel",t); assert(t.menu.visible and not t.active,"B/Circle from introduction must return to categories")
			t.start_lesson("set",8); t.resume()
			send("start",t); assert(t.modal.visible and g.paused)
			send("ui_cancel",t); assert(not t.modal.visible and not g.paused)
			t.open(host); send("ui_cancel",t); assert(not t.menu.visible and not t.active and host.tutorial_button.has_focus())
	# Save progress separately, restore the original match context, and keep B as dump.
	g.scores=[7,9]; g.sets=[1,2]; g.rotations=[4,5]; g.camera_mode=2; var seed: int=g.rng.state
	t.open(host); t.start_lesson("set",8); t.resume()
	assert(not t.modal.visible and t.active)
	g.send_test_button(JOY_BUTTON_B)
	assert(g.setter_dump and not t.modal.visible,"B/Circle during live setting remains the actual dump control")
	t.result(true,"fixture"); t.result(true,"duplicate"); assert(t.successes==1,"Repeated callbacks cannot award duplicate progress")
	t.pending=""; t.result(true,"second"); t.show_modal(); assert(t.successes==2)
	t.resume(); assert(t.free_practice and not g.paused)
	t.home(); assert(g.scores==[7,9] and g.sets==[1,2] and g.rotations==[4,5] and g.camera_mode==2 and g.rng.state==seed,"Practice must restore the match configuration and RNG")
	var stored=t.progress.duplicate(); t.progress.clear(); t.load_progress(); assert(t.progress==stored,"Progress must persist in user data")
	# Both standard pad mappings: left analog, Cross/A confirmation, Circle/B back.
	for device in [14,15]:
		t.open(host); t.categories[0].grab_focus()
		axis(device,1); await process_frame; await process_frame; axis(device,0); await process_frame
		assert(t.categories[1].has_focus(),"Physical left-stick UI event must select the next category")
		joy(device,JOY_BUTTON_A,true); await process_frame; joy(device,JOY_BUTTON_A,false); await process_frame
		assert(t.lesson_pick.has_focus(),"Cross/A must enter lesson selection")
		joy(device,JOY_BUTTON_B,true); await process_frame; joy(device,JOY_BUTTON_B,false); await process_frame
		assert(not t.menu.visible and host.tutorial_button.has_focus(),"Circle/B must leave categories via the actual input dispatcher")
	FileAccess.open("res://docs/tutorial60-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"category_layouts":count,"lesson_modals":280,"languages":["it","en"],"sizes":["1440x810","1280x720","1280x600","1024x600"],"back_navigation":true,"live_circle_dump":true,"progress_persistence":true,"match_restored":true},"  "))
	print("TUTORIAL UI60 PASS layouts=",count," / back / pause / Circle dump / free practice / persistence / isolation"); g.free(); quit()

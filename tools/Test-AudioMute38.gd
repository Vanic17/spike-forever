extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original:=AudioServer.is_bus_mute(0)
	var control=load("res://src/global_audio.gd").new(); control.settings_path="user://test-audio-mute38.cfg"; root.add_child(control)
	control.set_muted(false)
	var button:=InputEventJoypadButton.new(); button.button_index=JOY_BUTTON_LEFT_STICK; button.device=0; button.pressed=true
	control.handle_input(button); assert(AudioServer.is_bus_mute(0) and control.muted)
	control.handle_input(button); assert(control.muted,"Duplicate delivery from viewport/window must not toggle twice")
	button.pressed=false; control.handle_input(button); button.pressed=true; control.handle_input(button); assert(not control.muted)
	button.device=1; control.handle_input(button); assert(control.muted,"PlayStation and Xbox standard LS button both toggle Master")
	var restored=load("res://src/global_audio.gd").new(); restored.settings_path=control.settings_path; root.add_child(restored)
	assert(restored.muted and AudioServer.is_bus_mute(0),"Mute survives restart outside installed game files")
	var modal:=Window.new(); root.add_child(modal); modal.window_input.emit(button)
	assert(not restored.muted,"Mute receives controller input inside modal windows")
	AudioServer.set_bus_mute(0,original)
	print("AUDIO MUTE38 PASS: global Master / duplicate-event guard / PS-Xbox button / persistent setting / modal-window input")
	quit()

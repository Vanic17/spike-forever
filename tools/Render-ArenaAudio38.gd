extends SceneTree
## Actual Godot bus recording for mix review, not a preassembled soundtrack.
const MatchAudio = preload("res://src/match_audio.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 6, 16)
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	var audio := MatchAudio.new()
	root.add_child(audio)
	audio.random.seed = 380115
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Arena"), recorder)
	recorder.set_recording_active(true)
	audio.update_match_state(true, "SERVE")
	await create_timer(2.4).timeout
	audio.contact("serve", Vector3(0, 2.5, 8), 0.9)
	audio.update_match_state(true, "CPU_RECEIVE")
	await create_timer(0.55).timeout
	audio.movement(Vector3(-1, 0, -3), 4.5, 1.0)
	audio.contact("receive", Vector3(-1, 1, -3), 0.7)
	await create_timer(0.8).timeout
	audio.contact("set", Vector3(0, 2.6, -1.0), 0.7)
	audio.update_match_state(true, "CPU_SET")
	await create_timer(0.6).timeout
	audio.contact("attack", Vector3(3.3, 3, -0.7), 0.95)
	audio.update_match_state(true, "RECEIVE")
	await create_timer(0.45).timeout
	audio.contact("bounce", Vector3(-2, 0.1, 6), 0.9)
	audio.point_event(true)
	audio.update_match_state(true, "POINT")
	await create_timer(3.0).timeout
	audio.update_match_state(false, "POINT")
	await create_timer(0.7).timeout
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	var status := recording.save_to_wav("res://docs/arena38-mix-preview.wav")
	print("ARENA38 RENDER status=", status, " duration=", recording.get_length(), " bytes=", recording.data.size(), " events=", audio.event_counts)
	quit(0 if status == OK and recording.data.size() > 40000 else 1)

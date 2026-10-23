extends SceneTree
const MatchAudio = preload("res://src/match_audio.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var master_effects := AudioServer.get_bus_effect_count(0)
	var audio := MatchAudio.new()
	root.add_child(audio)
	audio.set_process(false)
	audio.random.seed = 380901
	check(AudioServer.get_bus_effect_count(0) == master_effects, "Arena reverb must not modify Master/menu music")
	var index := AudioServer.get_bus_index("Arena")
	check(index > 0 and AudioServer.get_bus_effect_count(index) == 2, "Separate room reverb/compressor bus")
	check(AudioServer.get_bus_effect(index, 0) is AudioEffectReverb, "Room response is real audio bus effect")
	check(AudioServer.get_bus_send(index) == &"Master", "Global Master mute also silences all arena sound")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MatchAudio.ARENA_MANIFEST))
	var expected := {"applause": 8, "drums": 6, "rhythm": 4, "crowd": 8, "interlude": 4, "horn": 6, "sneaker": 12, "whistle": 6}
	var total := 0
	var hashes := {}
	for entry in manifest.variants:
		check(not hashes.has(entry.sha256), "All variants must have distinct encoded content")
		hashes[entry.sha256] = true
		check(float(entry.true_peak_dbtp) <= -1.0, "Asset true peak must preserve headroom: " + str(entry.file))
		check(float(entry.rms_dbfs) > -60.0 and float(entry.rms_dbfs) < -10.0, "Audible normalized asset: " + str(entry.file))
		check(float(entry.duration) > 0.3 and float(entry.duration) < 8.0, "Bounded event asset length")
	for group in expected:
		check(audio.arena_banks.get(group, []).size() == expected[group], "Playable bank " + group)
		total += audio.arena_banks.get(group, []).size()
		var previous: AudioStream = null
		var seen := {}
		for n in 150:
			var selected: AudioStream = audio._choose(group, audio.arena_banks)
			check(selected != previous, "No immediate repeated arena sample: " + group)
			check(selected.get_length() > 0.3, "Decoded sample length")
			seen[selected.get_instance_id()] = true
			previous = selected
		check(seen.size() == expected[group], "Every concrete variation is reachable in bank " + group)
	check(total == 54, "Exactly 54 new concrete audio variants")
	check(not audio.match_active and audio.channel_states.is_empty(), "No arena atmosphere on main menu")
	audio.contact("attack", Vector3.ZERO)
	check(audio.event_counts.is_empty(), "Menu cannot play match foley")
	audio.update_match_state(true, "SERVE")
	check(not audio.channel_states.is_empty(), "Low-level audience starts only in match")
	audio._process(5.0)
	check(audio._motif_playing(), "An occasional pre-serve phrase starts")
	check(audio.rhythm.bus == &"Arena", "Pre-serve audio routed through arena room")
	audio.contact("serve", Vector3(0, 2.2, 9), 0.8)
	audio.update_match_state(true, "CPU_RECEIVE")
	await create_timer(0.16).timeout
	check(audio._motif_playing(), "A service no longer abruptly cuts its audience phrase")
	check(audio.event_counts.get("serve", 0) == 1, "Physical serve contact retained")
	var before: int = audio.event_counts.get("sneaker", 0)
	for n in 20: audio.movement(Vector3.ZERO, 0.0)
	check(audio.event_counts.get("sneaker", 0) == before, "Stationary players never generate shoe loops")
	for n in 20: audio.movement(Vector3(1, 0, 2), 4.5, 1.0)
	check(audio.event_counts.get("sneaker", 0) <= before + 1, "Global shoe budget prevents twelve simultaneous squeaks")
	for n in 25:
		audio._process(0.3)
		audio.movement(Vector3(1, 0, 2), 4.5, 1.0)
	check(audio.event_counts.get("sneaker", 0) > before + 3, "Running/cutting uses new source shoe gestures")
	var points := 20
	for n in points:
		audio._process(1.0)
		audio.update_match_state(true, "CPU_ATTACK")
		var whistles: int = audio.event_counts.get("referee", 0)
		audio.point_event(true)
		audio.point_event(true)
		check(audio.event_counts.get("referee", 0) == whistles + 1, "Exactly one whistle for duplicate point event")
		audio.update_match_state(true, "POINT")
		audio._process(1.4)
	check(audio.event_counts.get("referee", 0) == points and audio.event_counts.get("crowd", 0) == points, "Every home point has referee and varied crowd")
	check(audio.event_counts.get("horn", 0) > 0 and audio.event_counts.get("horn", 0) < points, "Horns are varied occasional point responses")
	var interludes: int = audio.event_counts.get("interlude", 0) + audio.event_counts.get("interlude_long", 0)
	check(interludes > 0 and interludes < points, "Interludes are occasional pauses, not continuous music")
	audio.update_match_state(true, "SERVE")
	await create_timer(0.18).timeout
	check(audio.envelopes.size() <= 10, "Continuous phrase fades remain bounded")
	audio.update_match_state(false, "SERVE")
	for player in audio.ambient_players + audio.rhythm_players + audio.reaction_players + audio.interlude_players + [audio.horn, audio.whistle]:
		check(not player.playing, "Menu return stops arena channels")
	for player in audio.voices: check(not player.playing, "Menu return stops 3D court foley")
	var count_before: Dictionary = audio.event_counts.duplicate()
	audio._process(20)
	check(audio.event_counts == count_before, "No delayed arena sound on menu")
	audio.update_match_state(true, "SERVE")
	audio._process(0.8)
	audio.update_match_state(true, "SERVE", true)
	check(audio.channel_states.is_empty(), "Pause suspends arena mix")
	audio.enabled = false
	audio.update_match_state(true, "CPU_ATTACK")
	audio.contact("attack", Vector3.ZERO)
	check(not audio.match_active, "Headless/fallback enabled flag preserved")
	print("AUDIO38 manifest=", total, " event_counts=", audio.event_counts, " master_effects=", master_effects, " failures=", failures)
	audio.queue_free()
	await process_frame
	if failures.is_empty(): print("ARENA AUDIO 38 PASS")
	quit(0 if failures.is_empty() else 1)

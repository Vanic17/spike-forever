extends SceneTree
const MatchAudio = preload("res://src/match_audio.gd")
var failures: Array[String] = []
var peak_channels := 0
var peak_envelopes := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func advance(audio: Node, seconds: float) -> void:
	var left := seconds
	while left > 0.00001:
		var dt := minf(0.05, left)
		audio._process(dt)
		peak_channels = maxi(peak_channels, audio.channel_states.size())
		peak_envelopes = maxi(peak_envelopes, audio.envelopes.size())
		left -= dt

func count(audio: Node, name: String) -> int:
	return audio.event_counts.get(name, 0)

func run() -> void:
	var original_master_effects := AudioServer.get_bus_effect_count(0)
	var audio := MatchAudio.new()
	root.add_child(audio)
	audio.set_process(false)
	audio.random.seed = 390491
	var child_count := audio.get_child_count()
	check(child_count == 28, "Fixed pool: 18 spatial voices plus 10 soundscape channels")
	check(AudioServer.get_bus_effect_count(0) == original_master_effects, "Arena effects do not alter menu music")
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("Arena")) == &"Master", "L3 Master mute covers the whole mix")
	for group in ["ambient_bed", "rhythm_long", "interlude_long", "whistle_real"]:
		check(audio.arena_banks.has(group) and not audio.arena_banks.get(group, []).is_empty(), "New long/real bank: " + group)
		if not audio.arena_banks.has(group): continue
		var previous: AudioStream = null
		var cycle := {}
		var bank_size: int = audio.arena_banks[group].size()
		for i in bank_size * 3:
			var stream: AudioStream = audio._choose(group, audio.arena_banks)
			check(stream != previous, "No immediate repeats across shuffled cycle boundaries: " + group)
			if i % bank_size == 0: cycle.clear()
			check(not cycle.has(stream.get_instance_id()), "Each soundscape selection cycle visits every distinct phrase: " + group)
			cycle[stream.get_instance_id()] = true
			previous = stream
	check(not audio.match_active and audio.channel_states.is_empty(), "Silent arena on menu")
	audio.update_match_state(true, "SERVE")
	check(audio.envelopes.size() == 1, "Arena startup is faded instead of appearing at full gain")
	for state in audio.channel_states.values(): check(state.player.volume_db <= -60, "No full-level startup jump")
	advance(audio, 5.0)
	check(audio._motif_playing(), "An occasional supporter phrase develops before service")
	var active_rhythm: AudioStreamPlayer
	for player in audio.rhythm_players:
		if audio.channel_states.has(player.get_instance_id()): active_rhythm = player
	check(active_rhythm != null, "Rhythmic layer is present")
	# Exercise a pre-serve-only phrase policy explicitly; the long timeline below
	# independently exercises the naturally selected continuing rally phrases.
	if active_rhythm: audio.channel_states[active_rhythm.get_instance_id()].continue_live = false
	var level_before := active_rhythm.volume_db if active_rhythm else -70.0
	audio.contact("serve", Vector3(0, 2.5, 9), 0.8)
	audio.update_match_state(true, "CPU_RECEIVE")
	advance(audio, 0.12)
	check(active_rhythm != null and audio.channel_states.has(active_rhythm.get_instance_id()), "A phrase is still audible 120ms after service")
	check(active_rhythm == null or active_rhythm.volume_db >= level_before - 3.5, "The beginning of an action has no abrupt cut")
	for envelope in audio.envelopes.values():
		check(envelope.duration >= 1.0, "Transition envelopes use plausible room/phrase times")
	advance(audio, 4.0)
	var before_referee := count(audio, "referee")
	var before_crowd := count(audio, "crowd")
	# A previous home horn may still be decaying during a very short next rally.
	audio._play_channel(audio.horn, "horn", -8.0)
	var before_horn := count(audio, "horn")
	var before_interlude := count(audio, "interlude") + count(audio, "interlude_long")
	audio.point_event(false)
	audio.update_match_state(true, "POINT")
	advance(audio, 3.0)
	check(count(audio, "referee") == before_referee + 1, "Away point still has referee whistle")
	check(count(audio, "crowd") == before_crowd, "No home crowd celebration on away point")
	check(count(audio, "horn") == before_horn, "No home horn on away point")
	check(not audio.channel_states.has(audio.horn.get_instance_id()), "Any preceding home horn fades away after an away point")
	check(count(audio, "interlude") + count(audio, "interlude_long") == before_interlude, "No home victory motif on away point")
	check(count(audio, "whistle_real")+count(audio,"whistle_serve")+count(audio,"whistle_point") == count(audio, "referee"), "Real supplied whistle and its breath variants replace every synthetic referee cue")
	check(count(audio, "whistle") == 0, "Old synthetic whistle remains unused when real source exists")
	var home_points := 0
	var away_points := 1
	# Twelve minutes cover different rally lengths and phase boundaries. The
	# production scheduler runs unchanged; only wall-clock waiting is accelerated.
	for rally in 48:
		audio.update_match_state(true, "SERVE")
		advance(audio, 2.0 + float(rally % 4) * 0.65)
		audio.contact("serve", Vector3(0, 2.5, 9), 0.7)
		for exchange in 1 + rally % 3:
			for phase in ["CPU_RECEIVE", "CPU_SET", "CPU_ATTACK", "RECEIVE", "SET", "ATTACK"]:
				audio.update_match_state(true, phase)
				advance(audio, 0.7 + float((rally + exchange) % 3) * 0.25)
		var home := rally % 3 != 0
		if home: home_points += 1
		else: away_points += 1
		var crowd_before := count(audio, "crowd")
		var horn_before := count(audio, "horn")
		var interlude_before := count(audio, "interlude_long") + count(audio, "interlude")
		audio.point_event(home)
		audio.point_event(home)
		audio.update_match_state(true, "POINT")
		advance(audio, 2.8)
		if not home:
			check(count(audio, "crowd") == crowd_before and count(audio, "horn") == horn_before, "Away rally never starts celebration channels")
			check(count(audio, "interlude_long") + count(audio, "interlude") == interlude_before, "Away rally never starts victory interlude")
		check(audio.get_child_count() == child_count, "No players/tweens accumulate during long matches")
	check(count(audio, "referee") == home_points + away_points, "One referee cue per point, duplicate delivery suppressed")
	check(count(audio, "home_celebration") == home_points and count(audio, "crowd") == home_points, "All and only home points celebrate")
	check(count(audio, "horn") > 0 and count(audio, "horn") < home_points, "Home horns are occasional, not an alarm at every point")
	check(count(audio, "interlude_long") > 0 and count(audio, "interlude_long") < home_points, "Longer interludes stay occasional")
	check(count(audio, "rhythm_live") > 1, "Rhythmic support can start naturally inside ongoing rallies")
	check(count(audio, "rhythm_continues") > 1, "Some pre-serve support phrases continue into play")
	check(count(audio, "rhythm_recedes") > 0, "Other phrases gradually recede when an action starts")
	check(count(audio, "ambient_bed") > 10, "Long match uses crossfaded varied ambient beds")
	check(peak_channels <= 10 and peak_envelopes <= 10, "Bounded soundscape channels and envelopes")
	check(audio.event_log.size() <= 256, "Diagnostic event history is bounded")
	audio.update_match_state(false, "POINT")
	check(audio.channel_states.is_empty() and audio.envelopes.is_empty(), "Menu return leaves no live or fading arena channels")
	for player in audio.ambient_players + audio.rhythm_players + audio.reaction_players + audio.interlude_players + [audio.horn, audio.whistle]:
		check(not player.playing, "All soundscape streams stop on menu")
	var after_menu: Dictionary = audio.event_counts.duplicate()
	advance(audio, 40.0)
	check(audio.event_counts == after_menu, "No delayed cue leaks into menu")
	audio.update_match_state(true, "SERVE")
	advance(audio, 1.0)
	audio.update_match_state(true, "SERVE", true)
	check(audio.channel_states.is_empty(), "Pause suspends continuous arena mix")
	print("AUDIO39 time=", audio.audio_clock, " home=", home_points, " away=", away_points, " peak_channels=", peak_channels, " peak_envelopes=", peak_envelopes, " events=", audio.event_counts, " failures=", failures)
	if failures.is_empty(): print("ARENA AUDIO 39 PASS")
	quit(0 if failures.is_empty() else 1)

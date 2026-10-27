extends Node
## A continuous arena soundscape; match foley and menu music keep separate buses.
const ARENA_MANIFEST := "res://assets/audio/arena/manifest.json"
const LONG_MANIFEST := "res://assets/audio/arena39/manifest.json"
const ARENA_BUS := "Arena"
const LIVE_PHASES := ["RECEIVE", "CPU_RECEIVE", "SET", "CPU_SET", "ATTACK", "CPU_ATTACK", "LOOSE"]
const SILENCE_DB := -70.0

var banks: Dictionary = {}
var arena_banks: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var crowd: AudioStreamPlayer
var rhythm: AudioStreamPlayer
var reaction: AudioStreamPlayer
var horn: AudioStreamPlayer
var whistle: AudioStreamPlayer
var interlude: AudioStreamPlayer
var ambient_players: Array[AudioStreamPlayer] = []
var rhythm_players: Array[AudioStreamPlayer] = []
var reaction_players: Array[AudioStreamPlayer] = []
var interlude_players: Array[AudioStreamPlayer] = []
var next_voice := 0
var random := RandomNumberGenerator.new()
var enabled := true
var match_active := false
var match_phase := ""
var last_choice: Dictionary = {}
var choice_queues: Dictionary = {}
var event_counts: Dictionary = {}
var event_log: Array[Dictionary] = []
var channel_states: Dictionary = {}
var envelopes: Dictionary = {}
var audio_clock := 0.0
var _ambient_index := 0
var _rhythm_index := 0
var _reaction_index := 0
var _interlude_index := 0
var _ambient_left := -1.0
var _motif_wait := -1.0
var _horn_left := -1.0
var _interlude_left := -1.0
var _shoe_cooldown := 0.0
var _step_cooldown := 0.0
var _point_cooldown := 0.0
var _rally_mix_live := false
var _home_point := false
var _audience_ducked := false
var _legacy_ambience: AudioStream
var service_whistled:=false

func _ready() -> void:
	random.randomize()
	_ensure_arena_bus()
	for action in ["receive", "set", "attack", "serve", "block", "bounce", "step", "squeak", "cheer"]:
		banks[action] = []
		for i in 3:
			var path := "res://assets/audio/%s_%d.wav" % [action, i]
			if FileAccess.file_exists(path):
				var stream := AudioStreamWAV.load_from_file(path)
				if stream: banks[action].append(stream)
	_load_manifest(ARENA_MANIFEST, "res://assets/audio/arena/")
	_load_manifest(LONG_MANIFEST, "res://assets/audio/arena39/")
	# Exact replacement supplied by the user; never shuffle older whistles in.
	var official_path:="res://assets/audio/referee62.ogg"
	if FileAccess.file_exists(official_path):
		var official_stream:=AudioStreamOggVorbis.load_from_file(official_path)
		if official_stream: arena_banks["whistle_real"]=[official_stream]
	var whistle_manifest:="res://assets/audio/referee65/manifest.json"
	if FileAccess.file_exists(whistle_manifest):
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(whistle_manifest))
		for entry in manifest.variants:
			var stream:=AudioStreamOggVorbis.load_from_file("res://assets/audio/referee65/"+str(entry.file))
			var group: String="whistle_"+str(entry.group)
			if not arena_banks.has(group): arena_banks[group]=[]
			if stream: arena_banks[group].append(stream)
	for i in 18:
		var player := AudioStreamPlayer3D.new()
		player.max_distance = 65
		player.unit_size = 12
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.max_db = 0
		player.bus = ARENA_BUS
		add_child(player)
		voices.append(player)
	for i in 2:
		ambient_players.append(_channel())
		rhythm_players.append(_channel())
		reaction_players.append(_channel())
		interlude_players.append(_channel())
	crowd = ambient_players[0]
	rhythm = rhythm_players[0]
	reaction = reaction_players[0]
	interlude = interlude_players[0]
	horn = _channel()
	whistle = _channel()
	if FileAccess.file_exists("res://assets/audio/crowd.ogg"):
		_legacy_ambience = AudioStreamOggVorbis.load_from_file("res://assets/audio/crowd.ogg")
		_legacy_ambience.loop = true

func _load_manifest(path: String, prefix: String) -> void:
	if not FileAccess.file_exists(path): return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary: return
	for entry in manifest.get("variants", []):
		var stream := AudioStreamOggVorbis.load_from_file(prefix + str(entry.file))
		if stream:
			var loudness := float(entry.get("integrated_lufs", -200.0))
			if loudness > -80.0 and loudness < 0: stream.set_meta("integrated_lufs", loudness)
			if not arena_banks.has(entry.group): arena_banks[entry.group] = []
			arena_banks[entry.group].append(stream)

func _ensure_arena_bus() -> void:
	if AudioServer.get_bus_index(ARENA_BUS) >= 0: return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, ARENA_BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, -2.0)
	var effect := AudioEffectReverb.new()
	effect.room_size = 0.82
	effect.damping = 0.66
	effect.wet = 0.16
	effect.dry = 1.0
	effect.spread = 0.85
	effect.predelay_msec = 18.0
	AudioServer.add_bus_effect(index, effect)
	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -8.0
	compressor.ratio = 3.0
	compressor.attack_us = 9000.0
	compressor.release_ms = 140.0
	AudioServer.add_bus_effect(index, compressor)

func _channel() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = ARENA_BUS
	player.volume_db = SILENCE_DB
	add_child(player)
	return player

func _choose(group: String, source_banks: Dictionary) -> AudioStream:
	if not source_banks.has(group) or source_banks[group].is_empty(): return null
	var size: int = source_banks[group].size()
	var key := ("arena:" if source_banks == arena_banks else "foley:") + group
	if not choice_queues.has(key) or choice_queues[key].is_empty():
		var queue: Array = range(size)
		for i in range(size - 1, 0, -1):
			var j := random.randi_range(0, i)
			var temporary = queue[i]; queue[i] = queue[j]; queue[j] = temporary
		if size > 1 and queue[0] == last_choice.get(key, -1):
			var j := random.randi_range(1, size - 1)
			var temporary = queue[0]; queue[0] = queue[j]; queue[j] = temporary
		choice_queues[key] = queue
	var index: int = choice_queues[key].pop_front()
	last_choice[key] = index
	return source_banks[group][index]

func _note(kind: String, group: String = "") -> void:
	event_counts[kind] = event_counts.get(kind, 0) + 1
	event_log.append({"time": audio_clock, "event": kind, "group": group, "phase": match_phase, "home_point": _home_point})
	if event_log.size() > 256: event_log.pop_front()

func _play_channel(player: AudioStreamPlayer, group: String, gain: float, pitch: float = 1.0, fade_in: float = 0.0, target_lufs: float = 0.0) -> bool:
	var stream := _choose(group, arena_banks)
	if stream == null: return false
	if target_lufs < 0: gain = _source_gain(stream, target_lufs, gain)
	_start_stream(player, stream, group, gain, pitch, fade_in)
	_note(group, group)
	if group == "crowd_long": _note("crowd", group)
	return true

func _source_gain(stream: AudioStream, target_lufs: float, fallback: float) -> float:
	if stream.has_meta("integrated_lufs"):
		return clampf(target_lufs - float(stream.get_meta("integrated_lufs")), -30.0, 2.0)
	return fallback

func _start_stream(player: AudioStreamPlayer, stream: AudioStream, group: String, gain: float, pitch: float, fade_in: float, offset: float = 0.0) -> void:
	envelopes.erase(player.get_instance_id())
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = SILENCE_DB if fade_in > 0 else gain
	player.play(offset)
	channel_states[player.get_instance_id()] = {
		"player": player, "remaining": maxf(0.1, (stream.get_length() - offset) / pitch),
		"group": group, "base_gain": gain, "tail_started": false, "continue_live": true, "retiring": false,
	}
	if fade_in > 0: _fade(player, gain, fade_in)

func _fade(player: AudioStreamPlayer, target: float, duration: float, stop_after: bool = false) -> void:
	if not channel_states.has(player.get_instance_id()): return
	var state: Dictionary = channel_states[player.get_instance_id()]
	if state.retiring and not stop_after: return
	if stop_after: state.retiring = true
	envelopes[player.get_instance_id()] = {
		"player": player, "from": db_to_linear(player.volume_db), "to": db_to_linear(target),
		"elapsed": 0.0, "duration": maxf(0.01, duration), "stop": stop_after,
	}
	_note("fade", channel_states[player.get_instance_id()].group)

func _finish(player: AudioStreamPlayer) -> void:
	var id := player.get_instance_id()
	if channel_states.has(id):
		var group: String = channel_states[id].group
		if group in ["rhythm_long", "applause", "drums", "rhythm", "interlude_long", "interlude"]:
			_motif_wait = maxf(_motif_wait, random.randf_range(11, 27))
	player.stop()
	channel_states.erase(id)
	envelopes.erase(id)

func _advance_channels(dt: float) -> void:
	for id in channel_states.keys():
		var state: Dictionary = channel_states[id]
		state.remaining -= dt
		if state.remaining <= 0:
			_finish(state.player)
			continue
		var tail := 3.0 if state.group in ["ambient_bed", "rhythm_long", "interlude_long", "legacy_ambience"] else 0.9
		if state.group in ["whistle", "whistle_real", "whistle_serve", "whistle_point"]: continue
		if not state.tail_started and state.remaining <= tail:
			state.tail_started = true
			_fade(state.player, SILENCE_DB, state.remaining, true)
	for id in envelopes.keys():
		var envelope: Dictionary = envelopes[id]
		envelope.elapsed += dt
		var amount: float = clampf(envelope.elapsed / envelope.duration, 0, 1)
		var easing := amount * amount * (3.0 - 2.0 * amount)
		# Equal-power fades avoid the audible hole of a linear-amplitude crossfade.
		var amplitude: float = sqrt(lerpf(envelope.from * envelope.from, envelope.to * envelope.to, easing))
		envelope.player.volume_db = linear_to_db(maxf(amplitude, 0.0001))
		if amount >= 1:
			if envelope.stop: _finish(envelope.player)
			else: envelopes.erase(id)

func update_match_state(started: bool, phase: String, paused: bool = false) -> void:
	if not started or phase!="SERVE": service_whistled=false
	var active := enabled and started and not paused
	if not active:
		if match_active: _stop_all()
		match_active = false
		match_phase = ""
		return
	if not match_active:
		match_active = true
		_start_ambient()
		_motif_wait = random.randf_range(1.8, 4.5)
	if phase == match_phase: return
	match_phase = phase
	if phase == "SERVE":
		_rally_mix_live = false
		if not service_whistled:
			referee_whistle("serve"); service_whistled=true
		# Existing phrases remain alive; a new service is not a music restart.
	elif phase in LIVE_PHASES:
		_begin_rally()
	elif phase == "POINT":
		_rally_mix_live = false

func _stop_all() -> void:
	_ambient_left = -1
	_motif_wait = -1
	_horn_left = -1
	_interlude_left = -1
	_rally_mix_live = false
	_audience_ducked = false
	envelopes.clear()
	channel_states.clear()
	for player in ambient_players + rhythm_players + reaction_players + interlude_players + [horn, whistle]:
		player.stop()
	for player in voices: player.stop()

func _start_ambient() -> void:
	var previous := ambient_players[_ambient_index]
	_ambient_index = 1 - _ambient_index
	var player := ambient_players[_ambient_index]
	var stream := _choose("ambient_bed", arena_banks)
	var group := "ambient_bed"
	var offset := 0.0
	if stream == null:
		stream = _legacy_ambience
		group = "legacy_ambience"
		if stream: offset = random.randf_range(0, maxf(0, stream.get_length() - 35))
	if stream == null: return
	var length := maxf(8, stream.get_length() - offset)
	var fade := random.randf_range(2.4, 3.8)
	var gain := _source_gain(stream, random.randf_range(-36.0, -34.0), random.randf_range(-25.0, -22.5))
	_start_stream(player, stream, group, gain, 1.0, fade, offset)
	_note("ambient_bed", group)
	_fade(previous, SILENCE_DB, fade, true)
	_ambient_left = maxf(6, length - fade - 0.2)

func _motif_playing() -> bool:
	for player in rhythm_players + interlude_players:
		if channel_states.has(player.get_instance_id()): return true
	return false

func _start_rhythm() -> void:
	var choices := ["applause", "drums", "rhythm"]
	var group: String = "rhythm_long" if arena_banks.has("rhythm_long") and random.randf() < 0.82 else choices[random.randi_range(0, choices.size() - 1)]
	var player := rhythm_players[_rhythm_index]
	_rhythm_index = 1 - _rhythm_index
	var base := random.randf_range(-10.5, -6.0)
	var live := match_phase in LIVE_PHASES
	var target_lufs := random.randf_range(-29.0, -26.0) - (3.0 if live else 0.0)
	if _play_channel(player, group, base - (3.0 if live else 0.0), 1.0, random.randf_range(1.5, 2.8), target_lufs):
		channel_states[player.get_instance_id()].base_gain += 3.0 if live else 0.0
		channel_states[player.get_instance_id()].continue_live = live or random.randf() < 0.64
		_note("rhythm_live" if live else "rhythm_pause", group)
	_motif_wait = random.randf_range(13, 30)

func _begin_rally() -> void:
	if _rally_mix_live: return
	_rally_mix_live = true
	for player in rhythm_players:
		var state: Dictionary = channel_states.get(player.get_instance_id(), {})
		if state.is_empty(): continue
		if state.continue_live:
			_fade(player, state.base_gain - random.randf_range(1.5, 4), random.randf_range(1.3, 2.1))
			_note("rhythm_continues", state.group)
		else:
			_fade(player, SILENCE_DB, random.randf_range(2.2, 3.6), true)
			_note("rhythm_recedes", state.group)
	for player in interlude_players:
		var state: Dictionary = channel_states.get(player.get_instance_id(), {})
		if not state.is_empty(): _fade(player, state.base_gain - 6, random.randf_range(2.0, 3.2))

func stop_pre_serve() -> void:
	# Kept for source compatibility. Service no longer cuts a crowd phrase off.
	_begin_rally()

func _start_interlude() -> void:
	var group := "interlude_long" if arena_banks.has("interlude_long") else "interlude"
	var player := interlude_players[_interlude_index]
	_interlude_index = 1 - _interlude_index
	for previous in interlude_players + rhythm_players:
		if previous != player: _fade(previous, SILENCE_DB, random.randf_range(2.0, 3.5), true)
	var gain := random.randf_range(-13.5, -9.0)
	if match_phase in LIVE_PHASES: gain -= 6.0
	var target_lufs := random.randf_range(-31.5, -28.5) - (6.0 if match_phase in LIVE_PHASES else 0.0)
	_play_channel(player, group, gain, 1.0, random.randf_range(1.5, 2.6), target_lufs)
	_motif_wait = random.randf_range(18, 32)

func _process(dt: float) -> void:
	if not match_active: return
	audio_clock += dt
	_shoe_cooldown = maxf(0, _shoe_cooldown - dt)
	_step_cooldown = maxf(0, _step_cooldown - dt)
	_point_cooldown = maxf(0, _point_cooldown - dt)
	_advance_channels(dt)
	_ambient_left -= dt
	if _ambient_left <= 0: _start_ambient()
	var ducked := false
	for player in reaction_players:
		if channel_states.has(player.get_instance_id()): ducked = true
	if ducked != _audience_ducked:
		_audience_ducked = ducked
		for player in ambient_players:
			var state: Dictionary = channel_states.get(player.get_instance_id(), {})
			if not state.is_empty() and not state.tail_started:
				_fade(player, state.base_gain - (3.0 if ducked else 0.0), 1.4 if ducked else 2.8)
	_motif_wait -= dt
	if _motif_wait <= 0 and not _motif_playing() and _interlude_left < 0:
		if match_phase == "SERVE" or (match_phase in LIVE_PHASES and random.randf() < 0.48):
			_start_rhythm()
		else:
			_motif_wait = random.randf_range(6, 14)
	if _horn_left >= 0:
		_horn_left -= dt
		if _horn_left <= 0:
			_horn_left = -1
			if _home_point: _play_channel(horn, "horn", random.randf_range(-10, -5.5), 1.0, 0.18)
	if _interlude_left >= 0:
		_interlude_left -= dt
		if _interlude_left <= 0:
			_interlude_left = -1
			if _home_point: _start_interlude()

func point_event(home_point: bool) -> void:
	if not enabled or not match_active or _point_cooldown > 0: return
	_point_cooldown = 0.65
	_home_point = home_point
	referee_whistle("point")
	if not home_point:
		_horn_left = -1
		_interlude_left = -1
		_fade(horn, SILENCE_DB, 1.0, true)
		for player in reaction_players + interlude_players:
			_fade(player, SILENCE_DB, 1.8, true)
		for player in rhythm_players:
			_fade(player, SILENCE_DB, random.randf_range(2.4, 3.8), true)
		_motif_wait = maxf(_motif_wait, random.randf_range(9, 18))
		_note("away_point")
		return
	var player := reaction_players[_reaction_index]
	_reaction_index = 1 - _reaction_index
	for previous in reaction_players:
		if previous != player: _fade(previous, SILENCE_DB, 1.0, true)
	var crowd_group := "crowd_long" if arena_banks.has("crowd_long") else "crowd"
	_play_channel(player, crowd_group, random.randf_range(-7.0, -3.5), random.randf_range(0.995, 1.005), 0.22, random.randf_range(-27.0, -24.5))
	_note("home_celebration")
	_horn_left = random.randf_range(0.35, 0.8) if random.randf() < 0.29 else -1.0
	_interlude_left = random.randf_range(0.8, 1.6) if random.randf() < 0.24 else -1.0

func referee_whistle(reason: String) -> void:
	if not enabled or not match_active: return
	var group := "whistle_real" if arena_banks.has("whistle_real") else "whistle"
	if arena_banks.has("whistle_"+reason): group="whistle_"+reason
	if _play_channel(whistle, group, random.randf_range(-7.0,-5.0), random.randf_range(.992,1.008)):
		_note("referee"); _note("referee_"+reason)

func movement(point: Vector3, speed: float, lateral: float = 0.0) -> void:
	if not enabled or not match_active or not match_phase in LIVE_PHASES + ["SERVE"]: return
	if speed < 0.65: return
	if _step_cooldown <= 0:
		_spatial("step", point, clampf(speed / 8.0, 0.15, 0.65), banks)
		_step_cooldown = random.randf_range(0.055, 0.095)
	if _shoe_cooldown <= 0 and (absf(lateral) > 0.35 or speed > 2.1) and random.randf() < 0.6:
		_spatial("sneaker", point, clampf(speed / 7.0, 0.2, 0.8), arena_banks)
		_shoe_cooldown = random.randf_range(0.15, 0.28)

func contact(action: String, point: Vector3, intensity: float = 0.7) -> void:
	if not enabled or not match_active: return
	if action == "cheer":
		# Legacy callers cannot know who scored. New callers use point_event(team==0).
		return
	if action == "serve": _begin_rally()
	if action == "step":
		movement(point, 3.0)
		return
	if action == "squeak":
		if _shoe_cooldown <= 0:
			_spatial("sneaker", point, intensity, arena_banks)
			_shoe_cooldown = 0.2
		return
	_spatial(action, point, intensity, banks)

func _spatial(action: String, point: Vector3, intensity: float, source_banks: Dictionary) -> void:
	var stream := _choose(action, source_banks)
	if stream == null: return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = stream
	voice.global_position = point
	voice.pitch_scale = random.randf_range(0.97, 1.03)
	voice.volume_db = lerpf(-7, 3, intensity)
	if action == "step": voice.volume_db -= 8
	if action == "sneaker": voice.volume_db -= 2
	voice.play()
	_note(action, action)

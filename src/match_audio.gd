extends Node
## Court foley and a separate arena mix. Menu songs never enter this bus.
const ARENA_MANIFEST := "res://assets/audio/arena/manifest.json"
const ARENA_BUS := "Arena"
const LIVE_PHASES := ["RECEIVE", "CPU_RECEIVE", "SET", "CPU_SET", "ATTACK", "CPU_ATTACK", "LOOSE"]

var banks: Dictionary = {}
var arena_banks: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var crowd: AudioStreamPlayer
var rhythm: AudioStreamPlayer
var reaction: AudioStreamPlayer
var horn: AudioStreamPlayer
var whistle: AudioStreamPlayer
var interlude: AudioStreamPlayer
var next_voice := 0
var random := RandomNumberGenerator.new()
var enabled := true
var match_active := false
var match_phase := ""
var last_choice: Dictionary = {}
var event_counts: Dictionary = {}
var _rhythm_left := -1.0
var _horn_left := -1.0
var _interlude_left := -1.0
var _shoe_cooldown := 0.0
var _step_cooldown := 0.0
var _point_cooldown := 0.0
var _ambient_left := 0.0
var _ambient_target := -25.0
var _rhythm_fade: Tween
var _interlude_fade: Tween

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
	if FileAccess.file_exists(ARENA_MANIFEST):
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(ARENA_MANIFEST))
		if manifest is Dictionary:
			for entry in manifest.get("variants", []):
				var path := "res://assets/audio/arena/" + str(entry.file)
				var stream := AudioStreamOggVorbis.load_from_file(path)
				if stream:
					if not arena_banks.has(entry.group): arena_banks[entry.group] = []
					arena_banks[entry.group].append(stream)
	for i in 18:
		var player := AudioStreamPlayer3D.new()
		player.max_distance = 65
		player.unit_size = 12
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.max_db = 0
		player.bus = ARENA_BUS
		add_child(player)
		voices.append(player)
	crowd = _channel()
	rhythm = _channel()
	reaction = _channel()
	horn = _channel()
	whistle = _channel()
	interlude = _channel()
	if FileAccess.file_exists("res://assets/audio/crowd.ogg"):
		var stream := AudioStreamOggVorbis.load_from_file("res://assets/audio/crowd.ogg")
		stream.loop = true
		crowd.stream = stream
		crowd.volume_db = -25

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
	add_child(player)
	return player

func _choose(group: String, source_banks: Dictionary) -> AudioStream:
	if not source_banks.has(group) or source_banks[group].is_empty(): return null
	var size: int = source_banks[group].size()
	var index := random.randi_range(0, size - 1)
	var key := ("arena:" if source_banks == arena_banks else "foley:") + group
	if size > 1 and index == last_choice.get(key, -1):
		index = (index + random.randi_range(1, size - 1)) % size
	last_choice[key] = index
	return source_banks[group][index]

func _play_channel(player: AudioStreamPlayer, group: String, gain: float, pitch: float = 1.0) -> bool:
	var stream := _choose(group, arena_banks)
	if stream == null: return false
	player.stream = stream
	player.volume_db = gain
	player.pitch_scale = pitch
	player.play()
	event_counts[group] = event_counts.get(group, 0) + 1
	return true

func update_match_state(started: bool, phase: String, paused: bool = false) -> void:
	var active := enabled and started and not paused
	if not active:
		if match_active: _stop_all()
		match_active = false
		match_phase = ""
		return
	if not match_active:
		match_active = true
		if crowd.stream: crowd.play(random.randf_range(0, maxf(0, crowd.stream.get_length() - 1)))
	if phase == match_phase: return
	match_phase = phase
	if phase == "SERVE":
		_rhythm_left = random.randf_range(0.2, 0.65)
		_fade_interlude()
	elif phase in LIVE_PHASES:
		stop_pre_serve()
		_fade_interlude()
	elif phase == "POINT":
		stop_pre_serve()
		# contact("cheer") owns the one-off point cue, not this transition.

func _stop_all() -> void:
	_rhythm_left = -1
	_horn_left = -1
	_interlude_left = -1
	if _rhythm_fade: _rhythm_fade.kill()
	if _interlude_fade: _interlude_fade.kill()
	for player in [crowd, rhythm, reaction, horn, whistle, interlude]:
		if player: player.stop()
	for player in voices: player.stop()

func stop_pre_serve() -> void:
	_rhythm_left = -1
	if not rhythm.playing: return
	if _rhythm_fade: _rhythm_fade.kill()
	_rhythm_fade = create_tween()
	_rhythm_fade.tween_property(rhythm, "volume_db", -60.0, 0.08)
	_rhythm_fade.tween_callback(rhythm.stop)

func _fade_interlude() -> void:
	_interlude_left = -1
	if not interlude.playing: return
	if _interlude_fade: _interlude_fade.kill()
	_interlude_fade = create_tween()
	_interlude_fade.tween_property(interlude, "volume_db", -60.0, 0.12)
	_interlude_fade.tween_callback(interlude.stop)

func _process(dt: float) -> void:
	if not match_active: return
	_shoe_cooldown = maxf(0, _shoe_cooldown - dt)
	_step_cooldown = maxf(0, _step_cooldown - dt)
	_point_cooldown = maxf(0, _point_cooldown - dt)
	_ambient_left -= dt
	if _ambient_left <= 0:
		_ambient_target = random.randf_range(-26.5, -23.5)
		_ambient_left = random.randf_range(7, 13)
	var ambient_gain := -30.0 if reaction.playing else _ambient_target
	crowd.volume_db = lerpf(crowd.volume_db, ambient_gain, 1.0 - exp(-dt * 1.4))
	if _rhythm_left >= 0:
		_rhythm_left -= dt
		if _rhythm_left <= 0:
			_rhythm_left = -1
			if match_phase == "SERVE":
				if _rhythm_fade: _rhythm_fade.kill()
				var selection := random.randf()
				var group := "applause" if selection < 0.48 else ("drums" if selection < 0.82 else "rhythm")
				_play_channel(rhythm, group, -5.0)
	if _horn_left >= 0:
		_horn_left -= dt
		if _horn_left <= 0:
			_horn_left = -1
			_play_channel(horn, "horn", -4.0)
	if _interlude_left >= 0:
		_interlude_left -= dt
		if _interlude_left <= 0:
			_interlude_left = -1
			if match_phase == "POINT": _play_channel(interlude, "interlude", -9.0)

func point_event() -> void:
	if not enabled or not match_active or _point_cooldown > 0: return
	_point_cooldown = 0.65
	stop_pre_serve()
	_play_channel(whistle, "whistle", -4.0, random.randf_range(0.985, 1.015))
	_play_channel(reaction, "crowd", -3.5, random.randf_range(0.985, 1.015))
	# A horn is an occasional spectator response, not an obligatory point alarm.
	_horn_left = random.randf_range(0.22, 0.48) if random.randf() < 0.42 else -1.0
	_interlude_left = random.randf_range(0.8, 1.15) if random.randf() < 0.32 else -1.0

func movement(point: Vector3, speed: float, lateral: float = 0.0) -> void:
	if not enabled or not match_active or not match_phase in LIVE_PHASES + ["SERVE"]: return
	if speed < 0.65: return
	if _step_cooldown <= 0:
		_spatial("step", point, clampf(speed / 8.0, 0.15, 0.65), banks)
		_step_cooldown = random.randf_range(0.055, 0.095)
	# Shoes sound on a planted adjustment/cut; never a permanent squeak loop.
	if _shoe_cooldown <= 0 and (absf(lateral) > 0.35 or speed > 2.1) and random.randf() < 0.6:
		_spatial("sneaker", point, clampf(speed / 7.0, 0.2, 0.8), arena_banks)
		_shoe_cooldown = random.randf_range(0.15, 0.28)

func contact(action: String, point: Vector3, intensity: float = 0.7) -> void:
	if not enabled or not match_active: return
	if action == "cheer":
		point_event()
		return
	if action == "serve": stop_pre_serve()
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
	event_counts[action] = event_counts.get(action, 0) + 1

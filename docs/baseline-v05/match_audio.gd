extends Node
## Actual local Spike Volleyball foley, played once at physical contact events.
var banks: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var crowd: AudioStreamPlayer
var next_voice := 0
var random := RandomNumberGenerator.new()
var enabled := true

func _ready() -> void:
	random.seed = 441002
	for action in ["receive", "set", "attack", "serve", "block", "bounce", "step", "squeak", "cheer"]:
		banks[action] = []
		for i in 3:
			var path := "res://assets/audio/%s_%d.wav" % [action, i]
			if FileAccess.file_exists(path):
				var stream := AudioStreamWAV.load_from_file(path)
				if stream: banks[action].append(stream)
	for i in 18:
		var player := AudioStreamPlayer3D.new()
		player.max_distance = 65
		player.unit_size = 12
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.max_db = 0
		add_child(player)
		voices.append(player)
	crowd = AudioStreamPlayer.new()
	add_child(crowd)
	if FileAccess.file_exists("res://assets/audio/crowd.ogg"):
		var stream := AudioStreamOggVorbis.load_from_file("res://assets/audio/crowd.ogg")
		stream.loop = true
		crowd.stream = stream
		crowd.volume_db = -14
		if enabled: crowd.play()
	var effect := AudioEffectReverb.new()
	effect.room_size = 0.72
	effect.damping = 0.65
	effect.wet = 0.13
	effect.dry = 0.95
	if AudioServer.get_bus_effect_count(0) == 0: AudioServer.add_bus_effect(0, effect)

func contact(action: String, point: Vector3, intensity: float = 0.7) -> void:
	if not enabled or not banks.has(action) or banks[action].is_empty(): return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = banks[action][random.randi_range(0, banks[action].size() - 1)]
	voice.global_position = point
	voice.pitch_scale = random.randf_range(0.96, 1.04)
	voice.volume_db = lerpf(-7, 3, intensity)
	if action == "step": voice.volume_db -= 8
	if action == "squeak": voice.volume_db -= 10
	if action == "cheer": voice.volume_db -= 10
	voice.play()

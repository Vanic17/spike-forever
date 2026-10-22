extends RefCounted
## Individual perception and movement response. Never changes a contact deadline.
var individuality := 0.5
var delay := 0.0
var react_at := 0.0
var cue := ""
var task := "cover"
var filtered_target := Vector3.ZERO
var initialized := false
var reacted := false
var cue_age := 0.0
var reaction_log: Array[Dictionary] = []

func configure(team: int, number: int) -> void:
	individuality = float(posmod(number * 5 + team * 3, 11)) / 10.0

func reset(position: Vector3) -> void:
	filtered_target = position
	initialized = true
	cue = ""
	reacted = false
	cue_age = 0.0

func observe(key: String, role: String, assignment: String, clock: float) -> void:
	var changed := cue != key or task != assignment
	if not changed: return
	cue = key
	task = assignment
	match task:
		"contact": delay = 0.0
		"approach": delay = 0.015 + individuality * 0.045
		"block": delay = 0.025 + individuality * 0.095
		"yield": delay = 0.015 + individuality * 0.035
		"recover": delay = 0.12 + individuality * 0.20
		_:
			if role == "S": delay = 0.035 + individuality * 0.055
			elif role == "L": delay = 0.055 + individuality * 0.075
			elif role.begins_with("MB"): delay = 0.075 + individuality * 0.11
			else: delay = 0.10 + individuality * 0.17
	react_at = clock + delay
	reacted = false
	cue_age = 0.0

func perceive(target: Vector3, clock: float, dt: float) -> Vector3:
	if not initialized: reset(target)
	cue_age += dt
	if cue_age + 0.000001 < delay: return filtered_target
	if not reacted:
		reacted = true
		reaction_log.append({"cue":cue, "task":task, "time":clock, "delay":delay})
		if reaction_log.size() > 128: reaction_log.pop_front()
	if task == "contact":
		filtered_target = target
	else:
		var response := (14.0 if task in ["approach", "block", "yield"] else 5.0) + individuality * 3.0
		var threshold := 0.045 + individuality * 0.035
		if filtered_target.distance_to(target) > threshold:
			filtered_target = filtered_target.lerp(target, 1.0 - exp(-dt * response))
	return filtered_target

func support_speed(emergency: bool) -> float:
	return (3.2 + individuality * 0.8) * (1.10 if emergency else 1.0)

func response_time() -> float:
	return 0.10 + individuality * 0.07

func settle_distance() -> float:
	return 0.075 + individuality * 0.045

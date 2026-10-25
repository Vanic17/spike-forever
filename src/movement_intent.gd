extends RefCounted
## Individual perception and movement response. Never changes a contact deadline.
var individuality := 0.5
var delay := 0.0
var react_at := 0.0
var cue := ""
var task := "cover"
var filtered_target := Vector3.ZERO
var target_velocity := Vector3.ZERO
var accepted_target := Vector3.ZERO
var initialized := false
var reacted := false
var cue_age := 0.0
var reaction_log: Array[Dictionary] = []

func configure(team: int, number: int) -> void:
	individuality = float(posmod(number * 5 + team * 3, 11)) / 10.0

func reset(position: Vector3) -> void:
	filtered_target = position
	accepted_target = position
	target_velocity = Vector3.ZERO
	initialized = true
	cue = ""
	reacted = false
	cue_age = 0.0

func observe(key: String, role: String, assignment: String, clock: float) -> void:
	var new_cue := cue != key
	var changed := new_cue or task != assignment
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
			if role == "S": delay = 0.025 + individuality * 0.045
			elif role == "L": delay = 0.040 + individuality * 0.060
			elif role.begins_with("MB"): delay = 0.055 + individuality * 0.085
			else: delay = 0.075 + individuality * 0.13
	# Yielding a lane and returning to coverage are parts of one read. Adding
	# another full reaction delay at every assignment change caused stop/start
	# shuffles beside the setter, even though the athlete had already read it.
	if not new_cue and task != "contact": delay = minf(delay, 0.025)
	react_at = clock + delay
	reacted = false
	cue_age = 0.0

func perceive(target: Vector3, clock: float, dt: float) -> Vector3:
	if not initialized: reset(target)
	cue_age += dt
	if cue_age + 0.000001 < delay:
		# Finish the preceding read while perceiving the next touch, rather than
		# freezing the steering point and restarting the whole team afterwards.
		follow_target(dt)
		return filtered_target
	if not reacted:
		reacted = true
		reaction_log.append({"cue":cue, "task":task, "time":clock, "delay":delay})
		if reaction_log.size() > 128: reaction_log.pop_front()
	if task == "contact":
		filtered_target = target
		accepted_target = target
		target_velocity = Vector3.ZERO
	else:
		var threshold := 0.045 + individuality * 0.035
		if accepted_target.distance_to(target) > threshold: accepted_target = target
		follow_target(dt)
	return filtered_target

func follow_target(dt: float) -> void:
	# Exact critically damped integration keeps both target position and its
	# velocity continuous through a new phase or a corrected reading. The
	# direct contact assignment above deliberately bypasses this filter.
	var frequency := (30.0 if task in ["approach", "block", "yield"] else 12.0) + individuality * 3.0
	var offset := filtered_target - accepted_target
	var decay := exp(-frequency * dt)
	var travel := (target_velocity + offset * frequency) * dt
	filtered_target = accepted_target + (offset + travel) * decay
	target_velocity = (target_velocity - travel * frequency) * decay
	filtered_target.y = accepted_target.y
	target_velocity.y = 0.0

func support_speed(emergency: bool) -> float:
	return (3.2 + individuality * 0.8) * (1.10 if emergency else 1.0)

func response_time() -> float:
	return 0.10 + individuality * 0.07

func settle_distance() -> float:
	return 0.075 + individuality * 0.045

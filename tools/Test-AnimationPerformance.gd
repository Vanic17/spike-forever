extends SceneTree
const Avatar = preload("res://src/avatar.gd")
var game
var frame := 0
var costs: Array[float] = []
var intervals: Array[float] = []
var previous := 0
var mode := "default"
var output_label := ""

func _initialize() -> void: call_deferred("setup")

func setup() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--benchmark-output="): output_label = argument.trim_prefix("--benchmark-output=")
	if "--benchmark-native" in OS.get_cmdline_user_args():
		Avatar.native_animation_enabled = true
		mode = "native"
	if "--benchmark-psa" in OS.get_cmdline_user_args():
		Avatar.native_animation_enabled = false
		mode = "psa"
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started = true
	game.demo = true
	game.paused = false
	for athlete in game.players:
		athlete.render_at_draw = true
		athlete.set_process(false)
	previous = Time.get_ticks_usec()

func _process(_dt: float) -> bool:
	if game == null: return false
	var now := Time.get_ticks_usec()
	if frame > 45: intervals.append(float(now - previous) / 1000.0)
	previous = now
	var begin := Time.get_ticks_usec()
	game.step(1.0 / 120.0)
	game.step(1.0 / 120.0)
	for athlete in game.players:
		athlete.apply_pose(athlete.pending_pose_dt)
		athlete.pending_pose_dt = 0
	if frame > 45: costs.append(float(Time.get_ticks_usec() - begin) / 1000.0)
	frame += 1
	if frame == 405:
		costs.sort()
		intervals.sort()
		var sum := 0.0
		for value in costs: sum += value
		var evaluation_rigs := 0
		for athlete in game.players:
			if athlete.pose_tree != null: evaluation_rigs += 1
		if not Avatar.native_animation_enabled and evaluation_rigs != 0:
			push_error("Default/PSA mode allocated experimental evaluation rigs")
			quit(1)
			return false
		var report := {"mode": mode, "native_enabled": Avatar.native_animation_enabled, "evaluation_rigs": evaluation_rigs, "frames": costs.size(), "cpu_mean_ms": sum / costs.size(), "cpu_p50_ms": costs[costs.size() / 2], "cpu_p95_ms": costs[int(costs.size() * 0.95)], "frame_p50_ms": intervals[intervals.size() / 2], "frame_p95_ms": intervals[int(intervals.size() * 0.95)], "display": DisplayServer.get_name()}
		var output := FileAccess.open("res://docs/animation-performance-" + (output_label if not output_label.is_empty() else mode) + ".json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "\t"))
		print("ANIMATION PERFORMANCE: ", JSON.stringify(report))
		quit()
	return false

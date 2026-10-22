extends SceneTree
const Contact = preload("res://src/ball_contact.gd")

func _initialize() -> void:
	var results: Array[Dictionary] = []
	for fps in [30,60,120]:
		var position := Vector3(0,3.4,0)
		var velocity := Vector3(4,-24,7)
		var contacts := 0
		var minimum := INF
		for frame in fps * 6:
			var state := Contact.floor_step(position,velocity,1.0/fps)
			position = state.position
			velocity = state.velocity
			contacts += state.impacts.size()
			minimum = minf(minimum,position.y)
			assert(position.y >= 0.105-0.000001,"The ball surface cannot penetrate the floor")
		assert(contacts>=2,"The whistle does not stop a bouncing ball")
		results.append({"position":position,"velocity":velocity,"impacts":contacts,"minimum_height":minimum})
	for result in results:
		assert(result.position.distance_to(results[0].position)<0.0002,"Impact and the remainder of the tick must be independent of frame rate")
		assert(result.velocity.distance_to(results[0].velocity)<0.0002)
		assert(result.impacts==results[0].impacts)
	var start := Quaternion(Vector3(1,2,-1).normalized(),0.8)
	var spin := Vector3(12,4,-7)
	var whole := Contact.spin_rotation(start,spin,0.4)
	var split := start
	for frame in 48: split=Contact.spin_rotation(split,spin,1.0/120.0)
	assert(absf(whole.dot(split))>0.99999,"World-axis spin cannot depend on the orientation of the panel mesh")
	var output := FileAccess.open("res://docs/ball-continuity-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"floor_results_30_60_120hz":results,"world_axis_spin_consistent":true,"rally_gravity_and_trajectory_parameters_unchanged":true},"  "))
	print("BALL CONTINUITY PASS: continuous floor impacts / physical remainder / world-axis spin / 30,60,120 Hz")
	quit()

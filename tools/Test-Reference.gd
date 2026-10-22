extends SceneTree
const Tactics = preload("res://src/tactics.gd")
const Reference = preload("res://src/reference_style.gd")
const Flight = preload("res://src/ball_flight.gd")
const PreviousFlight = preload("res://docs/baseline-v08/ball_flight.gd")

func _initialize() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/reference-killer-aces/reference-profile.json"))
	assert(source.assembly_sha256 == Reference.data.assembly_sha256)
	var source_ids := [5,4,3,2,1,0]
	var compared := 0
	var signatures: Dictionary = {}
	for serving in [true,false]:
		var raw: Array = source.positions.locServe if serving else source.positions.locReceive
		for rotation in 6:
			var signature := ""
			var servers := 0
			for i in 6:
				var original: Array = raw[rotation*7+posmod(source_ids[i]+rotation,6)].position
				var expected := Vector3(-float(original[2]),0,-float(original[0]))
				var human := Tactics.serve_position(i,0,rotation,serving)
				var cpu := Tactics.serve_position(i+6,1,rotation,serving)
				assert(Reference.formation(i,rotation,serving).distance_to(expected)<0.00005,"Historical reference data must remain intact")
				assert(cpu.distance_to(-human)<0.00005,"Live spec formations must mirror correctly")
				signature += str(human)
				if Tactics.slot(i,rotation)==3:
					servers += 1
					assert(Tactics.server(0,rotation)==i)
				for j in range(i+1,6):
					assert(human.distance_to(Tactics.serve_position(j,0,rotation,serving))>=0.78)
				compared += 2
			assert(servers==1)
			signatures[signature]=true
	assert(compared==144 and signatures.size()==12)
	for rotation in 6:
		assert(Tactics.server(0,rotation)==posmod(rotation+5,6))
		var front := 0
		var libero := 0
		for i in 6:
			if Tactics.front(i,rotation): front += 1
			if Tactics.libero(i,rotation,false): libero += 1
		assert(front==3 and libero==1)
	assert(is_equal_approx(Reference.serve_seconds(1,false),0.76))
	assert(is_equal_approx(Reference.serve_seconds(1,true),0.92))
	assert(is_equal_approx(Reference.serve_seconds(0,false),1.06))
	var quick := Reference.set_seconds(1,true,1,3,false)
	var normal := Reference.set_seconds(0,false,1,6,false)
	var emergency := Reference.set_seconds(0,false,0.3,8,true)
	assert(is_equal_approx(quick,0.42) and is_equal_approx(normal,1.02))
	assert(is_equal_approx(emergency,1.895))
	assert(is_equal_approx(Reference.receive_seconds(1),1.05))
	assert(is_equal_approx(Reference.receive_seconds(0),1.50))
	assert(is_equal_approx(Reference.attack_seconds(1,0.5,false,false),0.456))
	assert(is_equal_approx(Reference.attack_seconds(0,0.5,true,true),0.72))
	assert(is_equal_approx(Reference.arc_gravity(0.62,4.5),9.81))
	assert(Flight.acceleration(Vector3(2,3,-4),Vector3(1,2,3),70).distance_to(PreviousFlight.acceleration(Vector3(2,3,-4),Vector3(1,2,3)))<0.000001)
	var previous := 0.0
	for step in 81:
		var quality := Reference.receive_quality(8.0-step*0.1,1.0)
		assert(quality+0.00001>=previous,"Arrival quality must not oscillate")
		previous = quality
	assert(previous>0.99)
	var trajectories := [
		[Vector3(0,3.2,10),Vector3(-2,1.29,-6),Reference.serve_seconds(1,false)],
		[Vector3(0,2.68,10),Vector3(2,1.29,-5),Reference.serve_seconds(1,true)],
		[Vector3(-2,1.29,6),Vector3(0,2.53,1.5),Reference.receive_seconds(0.8)],
		[Vector3(0,2.53,1.5),Vector3(-3.4,3.3,1.05),normal],
		[Vector3(0,2.53,1.5),Vector3(0,3.3,1.05),quick],
		[Vector3(-3.4,3.3,1.05),Vector3(3.85,0.105,-8),Reference.attack_seconds(1,0.5,false,false)],
	]
	for fps in [30,60,120]:
		for trajectory in trajectories:
			assert_previous_flight(trajectory[0],trajectory[1],trajectory[2],fps)
	print("REFERENCE PASS: 144 mirrored placements / 12 unique formations / all rotations and roles / revision 08 ball flight restored / monotonic arrival curve / baseline trajectories at 30,60,120 Hz")
	quit()

func assert_previous_flight(origin: Vector3, target: Vector3, seconds: float, fps: int) -> void:
	var spin := Vector3(0.3,0.6,-0.2)
	var position := origin
	var previous_position := origin
	var velocity := Flight.velocity_to(origin,target,seconds,spin)
	var previous_velocity := PreviousFlight.velocity_to(origin,target,seconds,spin)
	assert(velocity.distance_to(previous_velocity)<0.000001)
	var elapsed := 0.0
	while elapsed<seconds-0.000001:
		var dt := minf(1.0/fps,seconds-elapsed)
		var current := Flight.advance(position,velocity,spin,dt)
		var previous := PreviousFlight.advance(previous_position,previous_velocity,spin,dt)
		position=current[0]
		velocity=current[1]
		previous_position=previous[0]
		previous_velocity=previous[1]
		assert(position.distance_to(previous_position)<0.000001)
		assert(velocity.distance_to(previous_velocity)<0.000001)
		elapsed += dt
	assert(position.distance_to(target)<0.01)

extends RefCounted
## One deterministic integrator shared by the ball, trajectory planning and digs.
const GRAVITY := Vector3(0, -9.81, 0)

static func acceleration(velocity: Vector3, spin: Vector3) -> Vector3:
	return GRAVITY + spin.cross(velocity) * 0.005 - velocity * velocity.length() * 0.0008

static func advance(origin: Vector3, velocity: Vector3, spin: Vector3, seconds: float) -> Array[Vector3]:
	var remaining := seconds
	while remaining > 0.000001:
		var dt := minf(remaining, 1.0 / 120.0)
		remaining -= dt
		var midpoint := velocity + acceleration(velocity, spin) * dt * 0.5
		origin += midpoint * dt
		velocity += acceleration(midpoint, spin) * dt
	return [origin, velocity]

static func velocity_to(origin: Vector3, target: Vector3, seconds: float, spin: Vector3) -> Vector3:
	var velocity := (target - origin) / seconds - GRAVITY * seconds * 0.5
	for iteration in 5:
		var predicted := advance(origin, velocity, spin, seconds)
		velocity += (target - predicted[0]) / seconds
	return velocity

static func intercept(origin: Vector3, velocity: Vector3, spin: Vector3, height: float) -> Dictionary:
	var elapsed := 0.0
	for step in 480:
		var next := advance(origin, velocity, spin, 1.0 / 120.0)
		if next[0].y <= height and next[1].y < 0:
			var fraction := clampf((origin.y - height) / maxf(0.00001, origin.y - next[0].y), 0, 1)
			return {"point":origin.lerp(next[0], fraction), "seconds":elapsed + fraction / 120.0}
		origin = next[0]
		velocity = next[1]
		elapsed += 1.0 / 120.0
	return {}

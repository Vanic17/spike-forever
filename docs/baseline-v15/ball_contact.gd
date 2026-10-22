extends RefCounted
## Continuous floor contact; the rally integrator and shot tuning stay unchanged.
const GRAVITY := 9.81
const RADIUS := 0.105

static func floor_step(position: Vector3, velocity: Vector3, seconds: float) -> Dictionary:
	var impacts: Array[float] = []
	var remaining := seconds
	while remaining > 0.000001:
		var dt := minf(remaining, 1.0 / 240.0)
		remaining -= dt
		var predicted := position + velocity * dt + Vector3.DOWN * (0.5 * GRAVITY * dt * dt)
		if predicted.y >= RADIUS:
			position = predicted
			velocity.y -= GRAVITY * dt
			continue
		var clearance := maxf(0, position.y - RADIUS)
		var impact_time := clampf((velocity.y + sqrt(velocity.y * velocity.y + 2.0 * GRAVITY * clearance)) / GRAVITY, 0, dt)
		position += velocity * impact_time + Vector3.DOWN * (0.5 * GRAVITY * impact_time * impact_time)
		position.y = RADIUS
		velocity.y -= GRAVITY * impact_time
		var tail := dt - impact_time
		if velocity.y < -0.65:
			impacts.append(-velocity.y)
			velocity.y *= -0.76
			velocity.x *= 0.88
			velocity.z *= 0.88
			position += velocity * tail + Vector3.DOWN * (0.5 * GRAVITY * tail * tail)
			velocity.y -= GRAVITY * tail
		else:
			velocity.y = 0
			velocity.x = move_toward(velocity.x, 0, dt * 1.6)
			velocity.z = move_toward(velocity.z, 0, dt * 1.6)
			position += velocity * tail
		position.y = maxf(RADIUS, position.y)
	return {"position":position,"velocity":velocity,"impacts":impacts}

static func spin_rotation(orientation: Quaternion, angular_velocity: Vector3, seconds: float) -> Quaternion:
	var speed := angular_velocity.length()
	if speed < 0.000001: return orientation
	return (Quaternion(angular_velocity / speed, speed * seconds) * orientation).normalized()

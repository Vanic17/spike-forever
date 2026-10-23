extends RefCounted
static func court_direction(screen: Vector2, mode: int) -> Vector2:
	# TV camera sits on +X: top of the screen is the old left pin (-X),
	# screen right is the far court (-Z). Gameplay continues in court axes.
	return Vector2(screen.y,-screen.x) if mode==2 else screen
static func origin(mode: int) -> Vector3:
	if mode==2: return Vector3(16.5,8.5,-5.0)
	return Vector3(0,9.8,18.4) if mode==0 else Vector3(0,11.5,23)

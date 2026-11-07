extends RefCounted
static func next_camera(mode: int) -> int:
	return 2 if mode==0 else (3 if mode==2 else 0)
static func court_direction(screen: Vector2, mode: int) -> Vector2:
	# TV camera sits on +X: top of the screen is the old left pin (-X),
	# screen right is the far court (-Z). Gameplay continues in court axes.
	return Vector2(screen.y,-screen.x) if mode==2 else screen
static func origin(mode: int) -> Vector3:
	if mode==2: return Vector3(16.5,8.5,-5.0)
	if mode==3: return Vector3(0,9.8,18.4)
	return Vector3(0,6.3,18.4)
static func framed_origin(mode: int,phase: String) -> Vector3:
	var eye:=origin(mode)
	if mode==0 and phase=="SERVE":eye.z=20.5
	return eye
static func field_of_view(mode: int,phase: String) -> float:
	if mode==0:return 48.0 if phase=="SERVE" else 42.0
	return 40.0 if mode==2 else 48.0

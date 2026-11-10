extends RefCounted
## A real failed touch loses platform control but retains a driven flight.
## A miss never assigns last_touch or changes the original incoming velocity.
static func shank(game) -> void:
	var c: Dictionary=preload("res://src/serve_target106.gd").settings().failure
	var short: bool=game.rng.randf()<c.short_shank_chance
	var side:=1.0 if game.possession==0 else -1.0
	var lateral: float=game.rng.randf_range(.3,1.2) if short else game.rng.randf_range(c.lateral_min,c.lateral_max)
	if game.rng.randf()<.5:lateral=-lateral
	var target:=Vector3(game.ball_pos.x+lateral,.105,game.ball_pos.z+side*game.rng.randf_range(-1.2,2.8))
	var seconds: float=game.rng.randf_range(.20,.36) if short else game.rng.randf_range(.35,.68)
	game.ball_vel=game.BallFlight.velocity_to(game.ball_pos,target,seconds,game.flight_spin,game.flight_gravity)
	game.last_touch=game.possession
	game.log_rally_event("failed_platform106",{"defender":game.receiver,"short":short,"target":target,"seconds":seconds})
	game.finish_contact_attempt(game.receiver)
	game.phase="LOOSE";game.flight_left=100;game.marker.visible=false

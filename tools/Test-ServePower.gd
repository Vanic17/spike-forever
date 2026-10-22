extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.self_test=true
	game.started=true
	game.demo=false
	game.server=0
	var cases:=0
	var faults:=0
	var excess_valid:=0
	var min_clearance:=INF
	var full_speeds: Dictionary={}
	for rotation in 6:
		for x in [-3.4,0.0,3.4]:
			for action in ["power","float"]:
				for direction in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(-1,-1).normalized(),Vector2(1,1).normalized()]:
					for power in [1.0,1.1]:
						game.rotations=[rotation,rotation]
						game.reset_rally()
						game.input_quality=1
						game.aim=direction
						game.serve_type=0 if action=="float" else 1
						var player=game.players[game.server_index(0)]
						player.position.x=x
						player.position+=Basis(Vector3.UP,player.rotation.y)*(player.action_root_motion(action,game.clips[action].contact_time)-player.action_root_motion(action,game.serve_start_time(action)))
						game.ball_pos=player.contact_world(action)
						var origin: Vector3=game.ball_pos
						var target: Vector3=game.serve_aim_target(0,direction)
						game.serve_ball(0,power)
						assert(is_equal_approx(game.incoming_power,power) and is_equal_approx(game.last_power,power),"Excess charge must survive into actual service state")
						if game.last_serve_fault!="":
							assert(power>1 and game.phase=="LOOSE")
							faults+=1
							continue
						assert(game.phase=="CPU_RECEIVE" and game.flight_target.distance_to(target)<0.001,"Actual serve must retain LS court target from every server position and rotation")
						var key:=str([rotation,x,action,direction])
						var speed:=Vector2(game.ball_vel.x,game.ball_vel.z).length()
						if power==1.0: full_speeds[key]=speed
						else: assert(absf(speed/float(full_speeds[key])-1.1)<0.005,"110% must increase real launch speed, not merely the displayed percentage")
						if power>1: excess_valid+=1
						assert(is_equal_approx(game.flight_left,game.Reference.serve_seconds(power,action=="float")))
						var position:=origin
						var velocity: Vector3=game.ball_vel
						for frame in int(ceil(game.flight_left*120)):
							var next=game.BallFlight.advance(position,velocity,game.flight_spin,1.0/120)
							if position.z>=0 and next[0].z<0:
								var height: float=position.lerp(next[0],position.z/(position.z-next[0].z)).y
								min_clearance=minf(min_clearance,height-2.535)
								assert(height>2.535,"A correctly directed 100-110% serve must clear the net when no excess fault is sampled")
							position=next[0]
							velocity=next[1]
						cases+=1
	assert(faults>0 and excess_valid>0)
	# LS depth and lateral signs agree with the behind-court camera.
	assert(absf(game.serve_aim_target(0,Vector2.UP).z)>absf(game.serve_aim_target(0,Vector2.DOWN).z))
	assert(game.serve_aim_target(0,Vector2.LEFT).x<0 and game.serve_aim_target(0,Vector2.RIGHT).x>0)
	assert(game.Timing.SERVE_CHARGE_SECONDS<1.05)
	for floating in [false,true]:
		assert(is_equal_approx(game.Reference.serve_seconds(1,floating)/game.Reference.serve_seconds(1.1,floating),1.1))
	assert(is_equal_approx(game.Timing.serve_risk(1.1),0.25))
	assert(is_equal_approx(game.Timing.serve_risk(1.2),0.50))
	assert(is_equal_approx(game.Timing.serve_risk(1.4),1.0))
	print("SERVE POWER PASS: ",cases," actual aimed serves / ",faults," proportional excess faults / ",excess_valid," uncapped 110% serves / six rotations / three origins / jump-float / net clearance=",min_clearance)
	game.free()
	quit()

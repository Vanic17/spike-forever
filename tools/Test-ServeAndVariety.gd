extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.self_test=true
	game.started=true
	game.demo=false
	var maximum_hold_gap:=0.0
	for fps in [30,60,120]:
		for action in ["power","float"]:
			game.server=0
			game.reset_rally()
			game.serve_type=1 if action=="power" else 0
			game.serve_power=0.8
			game.input_quality=1
			game.begin_serve_toss()
			var player=game.players[game.server_index(0)]
			for frame in fps*4:
				game.step(1.0/fps)
				if game.phase!="SERVE": break
				if game.serve_windup_left>0:
					var gap: float=game.ball_pos.distance_to(player.current_hand(action=="float")+Vector3(0,0.105,0))
					maximum_hold_gap=maxf(maximum_hold_gap,gap)
					assert(gap<0.015,"The ball must remain on the sampled throwing palm before release")
					if action=="power" and game.serve_motion_time>0.85:
						var local_ball: Vector3=player.global_transform.affine_inverse()*game.ball_pos
						assert(local_ball.z>0.1,"The power-serve ball cannot follow the backswing behind the torso")
				if action=="power" and game.serve_windup_left<=0 and game.toss_elapsed>0:
					assert(game.toss_velocity.y-game.G*game.serve_toss_duration < -1.0,"The jump serve must meet a descending toss, not chase a rising ball")
			assert(game.phase=="CPU_RECEIVE","The calibrated throw must meet the hitting hand")
	var variants: Dictionary={"receive_follow":"receive","receive_left_up":"receive","receive_right_up":"receive","set_back":"set","fast_set_back":"fast_set","attack_line":"attack","attack_left":"attack","dive_short":"dive"}
	var contact_gaps: Dictionary={}
	var player=game.players[0]
	for variant in variants:
		var action: String=variants[variant]
		player.play("idle",1,true)
		player.select_variant(action,variant)
		player.setting_yaw=-PI/2
		player.rotation.y=-PI/2 if action in ["set","fast_set"] else PI
		player.dive_yaw=PI
		game.ball_pos=Vector3(0,game.contact_height(action),5)
		player.position=player.stance_for_contact(action,game.ball_pos)
		assert(game.validate_contact(0,action),"An added variant must make the same scheduled live contact: "+variant)
		contact_gaps[variant]=game.contact_log[-1].gap
	var output=FileAccess.open("res://docs/serve-variety-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"maximum_held_ball_gap_m":maximum_hold_gap,"variant_contact_gaps_m":contact_gaps,"serve_frame_rates":[30,60,120]},"  "))
	print("SERVE VARIETY PASS: palm-aligned throw and hand hit / 30,60,120 Hz / eight original contextual clips")
	game.queue_free()
	quit()

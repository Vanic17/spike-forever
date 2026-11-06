extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();restart("S");adapter.active=false;game.started=true;game.paused=false
	var smoother=game.render_smoother
	var p=game.players[0];p.position=Vector3(0,0,6);p.play("run",1,true)
	game.phase="LOOSE";game.rally_serial+=1;game.clock_time=1;game.ball_pos=Vector3(0,3,5);game.ball.position=game.ball_pos
	smoother.after_tick(game)
	var old_ball: Vector3=game.ball_pos;var old_actor: Vector3=p.position
	game.clock_time+=1.0/120;game.ball_pos+=Vector3(.25,0,0);game.ball.position=game.ball_pos;p.position+=Vector3(.04,0,0);p.animation_time+=.01
	game.ball.quaternion=Quaternion(Vector3.UP,.2)
	smoother.after_tick(game)
	var authoritative_rotation: Quaternion=game.ball.quaternion
	var simulation: Array=[game.clock_time,game.ball_pos,game.ball_vel,p.transform,p.animation_time,p.idle_time,p.blend_left,p.travel_animation_time,game.touches.duplicate(),game.rng.state]
	var pose_angles: Array=[]
	for alpha in [0.0,.25,.5,.75,1.0]:
		smoother.draw(game,alpha)
		check(game.ball.position.is_equal_approx(old_ball.lerp(game.ball_pos,alpha)),"ball interpolated at "+str(alpha))
		check(p.visual_root.global_position.is_equal_approx(old_actor.lerp(p.position,alpha)),"visual root interpolated at "+str(alpha))
		p.draw_interpolated84(1.0/240)
		check(simulation==[game.clock_time,game.ball_pos,game.ball_vel,p.transform,p.animation_time,p.idle_time,p.blend_left,p.travel_animation_time,game.touches.duplicate(),game.rng.state],"draw preserves simulation and RNG")
		pose_angles.append(p.last_pose[12].basis.get_rotation_quaternion())
	check(pose_angles[0].angle_to(pose_angles[-1])>.00001,"pose evaluated between physics states")
	for i in p.animation_bones.size():
		var bone: int=p.animation_bones[i]
		if bone<0:continue
		var expected: Transform3D=p.last_pose[bone]
		if i>0:
			var parent: int=p.animation_bones[p.model_bank.body.parents[i]]
			if parent>=0:expected=p.last_pose[parent].affine_inverse()*expected
		var actual: Transform3D=p.skeleton.get_bone_pose(i)
		check(actual.origin.distance_to(expected.origin)<.00001 and actual.basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion())<.001,"native bone upload equivalence")
		check(actual.basis.get_scale().distance_to(Vector3.ONE)<.00001,"bone scale preserved")
	smoother.before_tick(game)
	check(game.ball.quaternion.is_equal_approx(authoritative_rotation),"spin resumes from authoritative tick")
	check(p.transform==simulation[3],"physics retains authoritative actor transform")
	var cadence: Array=[]
	for fps in [60,90,120,144,165,240,360]:
		var shown: Array[float]=[];var old: Array[float]=[]
		for frame in range(1,fps+1):
			var now: float=float(frame)/fps;var ticks: int=floori(now*120+1e-8);var alpha: float=now*120-ticks
			var a:=float(ticks-1)*30/120;var b:=float(ticks)*30/120
			smoother.previous.ball=Vector3(a,3,5);smoother.current.ball=Vector3(b,3,5)
			smoother.draw(game,alpha);shown.append(game.ball.position.x);old.append(b)
		var max_error:=0.0;var repeats:=0;var old_repeats:=0
		for frame in range(1,shown.size()):
			max_error=maxf(max_error,absf((shown[frame]-shown[frame-1])-30.0/fps))
			if absf(shown[frame]-shown[frame-1])<1e-6:repeats+=1
			if absf(old[frame]-old[frame-1])<1e-6:old_repeats+=1
		check(max_error<.0001 and repeats==0,"continuous fast ball at "+str(fps))
		cadence.append({"fps":fps,"maximum_step_error_m":max_error,"repeated_ball_frames":repeats,"previous_repeated_frames":old_repeats})
	# Spawn/reset is an explicit discontinuity, not a flight across the court.
	game.rally_serial+=1;game.ball_pos=Vector3(0,1,11);game.ball.position=game.ball_pos;smoother.after_tick(game);smoother.draw(game,.2)
	check(game.ball.position.is_equal_approx(game.ball_pos),"rally reset snaps without streak")
	game.paused=true;smoother.draw(game,.5)
	check(p.render_current84.is_empty() and p.visual_root.transform.is_equal_approx(Transform3D.IDENTITY),"pause releases presentation")
	game.paused=false;game.replay.active=true;smoother.draw(game,.5)
	check(smoother.current.is_empty(),"replay owns transforms exclusively")
	game.replay.active=false
	# Packet arrivals alternate between early and late. The guest clock must
	# never rewind, and its correction must not create a large forward step.
	var net=game.online_session;net.render_clock84=-1;net.buffered=[]
	var sequence:=0;var new_before:=-1.0;var old_before:=-1.0;var old_backwards:=0;var maximum_online_step:=0.0
	for frame in range(1,481):
		var now: float=.04+frame/240.0
		while (sequence+1)/30.0+.03+sin((sequence+1)*2.1)*.012<=now:sequence+=1
		var arrived: float=sequence/30.0+.03+sin(sequence*2.1)*.012
		net.buffered=[{"clock_time":1+sequence/30.0,"arrived":arrived}]
		var old_clock: float=1+sequence/30.0+maxf(0,now-arrived)-.055
		var new_clock: float=preload("res://src/online_state.gd").presentation_time84(net,1.0/240,now)
		if new_before>=0:
			check(new_clock>=new_before-.000001,"online presentation never rewinds")
			maximum_online_step=maxf(maximum_online_step,new_clock-new_before)
			if old_clock<old_before:old_backwards+=1
		new_before=new_clock;old_before=old_clock
	check(old_backwards>0 and maximum_online_step<=1.12/240+.000001,"online jitter corrected with bounded rate")
	FileAccess.open("res://docs/fluidity84-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"cadence":cadence,"online_previous_clock_rewinds":old_backwards,"online_maximum_visual_step_s":maximum_online_step},"  "))
	print("FLUIDITY84 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

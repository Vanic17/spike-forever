extends SceneTree
const Second=preload("res://src/setter_second96.gd")
const Select=preload("res://src/stroke_selection96.gd")
var checks:=0
var failures: Array=[]
func check(value: bool,message: String):
	checks+=1
	if not value:failures.append(message);print("FAIL96 ",message)
func _initialize():call_deferred("run")
func run():
	check("strikes96" in OS.get_environment("APPDATA"),"isolated profile")
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false)
	for p in g.players:p.set_process(false);p.render_at_draw=false
	await process_frame
	var rows: Array=[]
	for name in ["attack_shorttip96","attack_cut96","set_first96","dump_back96","dump_down96","dump_forward96"]:
		check(g.clips.has(name),"registered "+name)
		var clip=g.clips[name];print("CLIP96 ",name," contact=",clip.contact_offset)
		if g.players[0].native_animation_enabled:check(g.players[0].pose_tree.library.has_animation(name),"native AnimationTree "+name)
		for frame in 31:
			var pose: Array[Transform3D]=g.players[0].normalized_pose("source:"+name,clip.duration*frame/30.0,false)
			for bone in pose.size():check(pose[bone].origin.is_finite() and pose[bone].basis.is_finite(),"finite pose "+name)
	for height in [175,195,210]:
		var p=g.players[0];preload("res://src/player_stature90.gd").apply(p,{"height_cm":height})
		for action in ["attack","block","power"]:
			var peak: float=0
			for frame in 101:
				var pose: Array[Transform3D]=p.normalized_pose(action,p.clips[action].duration*frame/100.0,false)
				peak=maxf(peak,(pose[p.clips[action].names.find("Head")].origin.y+.12)*p.height_scale90)
			check(peak>2.62 and peak<2.69,"intermediate jump height "+str(peak))
	preload("res://src/player_stature90.gd").apply(g.players[0],{"height_cm":189.4563})
	for power in [.4,.8,1.0,1.1]:
		for floating in [true,false]:
			var original: float=((.76 if floating else .60)+(1-power)*.30) if power<=1 else (.76 if floating else .60)/power
			check(absf(g.Reference.serve_seconds(power,floating)*1.04-original)<.000001,"serve 4% faster, including overcharge")
	for team in 2:
		g.possession=team;g.setter=team*6+5;g.players[g.setter].setting_yaw=-PI/2 if team==0 else PI/2
		for aim in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			g.aim=aim;var kind: int=Second.kind(g)
			check(kind==(3 if aim==Vector2.DOWN else (7 if (aim.x<0)==(team==0) else 2)),"direction follows setter face")
			g.setter_second96=kind;g.ball_pos=Vector3(0,2.9,.7 if team==0 else -.7)
			var delivery:=Second.trajectory(g)
			var v: Vector3=g.BallFlight.velocity_to(g.ball_pos,delivery.target,delivery.seconds,delivery.spin,g.flight_gravity)
			var point: Vector3=g.ball_pos;var crossing:=false
			for step in 160:
				var next: Array=g.BallFlight.advance(point,v,delivery.spin,1.0/120,g.flight_gravity)
				if point.z*next[0].z<=0 and not crossing:
					var y: float=lerpf(point.y,next[0].y,absf(point.z)/maxf(.0001,absf(point.z-next[0].z)))
					check(y>2.525,"second touch clears net "+str(kind));crossing=true
				point=next[0];v=next[1]
				if point.y<.105:break
			check(crossing,"second crosses net")
			rows.append({"team":team,"kind":kind,"seconds":delivery.seconds,"target":str(delivery.target)})
	g.possession=0;g.input_team=0;g.setter=5;g.touches=[1,0];g.phase="SET";g.out_of_system=1;g.pass_quality=1;g.armed=false
	for rotation in 6:
		if not g.Tactics.front(5,rotation):continue
		g.rotations=[rotation,0]
		for left in [false,true]:
			var p=g.players[5];p.left_handed=left
			for aim in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
				g.phase="SET";g.possession=0;g.input_team=0;g.touches=[1,0];g.armed=false;g.setter_dump=false;g.setter_second96=0;g.aim=aim
				var kind: int=Second.kind(g);var name: String={2:"dump_back96",3:"dump_down96",7:"dump_forward96"}[kind]
				p.play("set",1,false);p.blend_left=0;p.select_variant("dump","dump")
				p.position=Vector3(0,0,.85);p.rotation.y=PI
				var target: Vector3=p.position+Basis(Vector3.UP,PI)*Vector3(0,g.clips[name].contact_offset.y,.1)
				g.flight_target=target
				g.ball_pos=target+Vector3(.1,1.1,.1);g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,target,.55,Vector3.ZERO);g.airborne=true;g.flight_left=.55
				var ok:=Second.request(g);check(ok,"request second "+str(kind)+" rotation "+str(rotation)+" left "+str(left))
				if ok:
					p.position=p.target;p.rotation.y=p.setting_yaw;p.blend_left=0;g.ball_pos=g.flight_target
					check(g.validate_contact(5,"dump"),"second physical palm contact "+str(kind))
					g.armed=true;g.touches=[1,0];g.dump_ball()
					check(g.last_touch==0 and g.phase=="CPU_RECEIVE","second completes as real second touch")
	# Explicitly unavailable on a libero/non-setter, back-row setter or no command.
	for rotation in 6:
		for depth in [.55,1.5]:
			g.rotations=[rotation,0];g.server=1;g.reset_rally();g.phase="SET";g.started=true;g.paused=false;g.possession=0;g.input_team=0;g.setter=5;g.touches=[1,0];g.out_of_system=1;g.pass_quality=1;g.armed=false;g.set_dir=1
			var p=g.players[5];p.position=Vector3(1.1,0,depth);p.setting_yaw=-PI/2
			g.ball_pos=Vector3(1.1,3.8,depth);g.flight_target=Vector3(1.1,p.contact_local("set").y,depth);g.flight_left=.65;g.airborne=true;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,g.flight_left,Vector3.ZERO)
			g.press_action("action")
			check(p.variant_names.get("set","")!="set_first96" or depth<.85,"first tempo hand only on tight ball rotation "+str(rotation))
			if depth<.85:
				p.position=p.stance_for_contact("set",g.flight_target);p.rotation.y=p.setting_yaw;p.blend_left=0;g.ball_pos=g.flight_target
				check(g.validate_contact(5,"set"),"one handed first physical contact")
	# Real controller event routing: triangle is a stroke; L1 changes camera.
	g.phase="SERVE";g.server=0;g.started=true;g.paused=false;g.charging=false;g.input_team=0
	var triangle:=InputEventJoypadButton.new();triangle.button_index=JOY_BUTTON_Y;triangle.pressed=true
	var old_camera: int=g.camera_mode;g._unhandled_input(triangle)
	check(g.camera_mode==old_camera and not g.charging,"triangle cannot change camera or start service")
	var shoulder:=InputEventJoypadButton.new();shoulder.button_index=JOY_BUTTON_LEFT_SHOULDER;shoulder.pressed=true;g._unhandled_input(shoulder)
	check(g.camera_mode!=old_camera,"L1 / LB changes camera")
	g.phase="SET";g.armed=false;g.possession=0;g.setter=0;check(not Second.request(g),"no special for OH")
	g.setter=5;g.rotations=[0,0]
	# The command may now be attempted from any position. Legality is still
	# judged by the ordinary attack rules at actual contact.
	g.hitter=0;g.hitter_action="attack";g.phase="ATTACK";g.attack_tip=false
	for origin in [-3.4,3.4]:
		g.players[0].position.x=origin;g.aim=Vector2(-signf(origin),1).normalized();Select.update(g)
		check(g.players[0].wrist_tip_variant=="attack_cut96","short cross both sides")
		g.aim=Vector2(signf(origin),1).normalized();Select.update(g);check(g.players[0].wrist_tip_variant!="attack_cut96","no cut animation on short line")
		g.aim=Vector2(-signf(origin),-1).normalized();Select.update(g);check(g.players[0].wrist_tip_variant!="attack_cut96","no cut animation on deep cross")
	for left in [false,true]:
		var p=g.players[0];p.left_handed=left;p.play("attack",1,false);p.blend_left=0;p.animation_time=p.clips.attack.contact_time;p.wrist_tip_variant="";p.apply_pose(0)
		var palm: Vector3=p.current_hand(false)
		for style in ["attack_shorttip96","attack_cut96"]:
			p.wrist_tip_variant=style;p.apply_pose(0);check(p.current_hand(false).distance_to(palm)<.001,"contact unchanged "+style+" left "+str(left))
	var state=preload("res://src/online_state.gd");var snapshot: Dictionary=state.capture(g);var decoded: Dictionary=state.decode(state.encode(snapshot))
	check(decoded.setter_second96==g.setter_second96 and decoded.players[0].wrist_tip_variant==g.players[0].wrist_tip_variant,"online codec new actions")
	var audio=g.match_audio;audio.enabled=true;audio.match_active=true
	var index: int=audio.next_voice;audio.contact("attack",Vector3.ZERO,.7);var hard: float=audio.voices[index].volume_db
	index=audio.next_voice;audio.contact("tip",Vector3.ZERO,.7)
	check(audio.voices[index].stream in audio.banks.set,"tip uses soft contact bank")
	check(is_equal_approx(hard-audio.voices[index].volume_db,11.0),"tip is 11 dB quieter than spike")
	audio.enabled=false;audio.match_active=false
	FileAccess.open("res://docs/strokes96-tests"+("" if g.players[0].native_animation_enabled else "-fallback")+".json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"second_deliveries":rows},"  "))
	print("STROKES96 ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)

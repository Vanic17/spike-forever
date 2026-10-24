extends SceneTree
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")
const Motion = preload("res://src/dive_motion41.gd")
var preview_game
var preview_frames := 0

func _initialize() -> void:
	call_deferred("run")

func normalized(clip, time: float) -> Array[Transform3D]:
	var pose: Array[Transform3D] = clip.pose(time, false)
	var source_root: Vector3 = pose[0].origin
	var offset: Vector3 = Vector3(-source_root.x, -clip.ground_y * 100.0, source_root.y) * 0.01 - clip.body_center
	for i in pose.size():
		pose[i] = PSK.to_godot(pose[i])
		pose[i].origin += offset
	return pose

func run() -> void:
	if "--preview" in OS.get_cmdline_user_args():
		setup_preview()
		return
	if "--dump" in OS.get_cmdline_user_args():
		dump_sources()
	var clip = PSA.new()
	clip.load_file("res://assets/active/" + Motion.SOURCE + ".psa")
	clip.load_hierarchy("res://assets/active/skeleton.psk")
	clip.detect_contact("dive")
	var max_difference := 0.0
	var max_length_error := 0.0
	var max_foot_error := 0.0
	var max_support_error := 0.0
	var max_root_error := 0.0
	var min_foot := INF
	var previous_time := -1.0
	var max_phase_step := 0.0
	for frame in 361:
		var t: float = clip.duration * frame / 360.0
		var st := Motion.source_time(t,clip.contact_time,clip.duration)
		assert(st >= previous_time,"Dive retiming must remain monotonic")
		max_phase_step = maxf(max_phase_step,st-previous_time if frame > 0 else 0.0)
		previous_time=st
		var source_pose := normalized(clip,st)
		var shaped := Motion.shape(source_pose,clip.names,clip.parents,t,clip.contact_time,clip.duration)
		for i in clip.names.size():
			max_difference=maxf(max_difference,source_pose[i].origin.distance_to(shaped[i].origin))
			var parent: int = clip.parents[i]
			if parent >= 0 and parent < i:
				var before := source_pose[i].origin.distance_to(source_pose[parent].origin)
				var after := shaped[i].origin.distance_to(shaped[parent].origin)
				max_length_error=maxf(max_length_error,absf(after-before))
			assert(shaped[i].basis.is_finite(),"Dive produced a non-finite basis")
		for n in ["LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:
			var i: int = clip.names.find(n)
			max_foot_error=maxf(max_foot_error,source_pose[i].origin.distance_to(shaped[i].origin))
			min_foot=minf(min_foot,shaped[i].origin.y)
		var hand: int = clip.names.find("LeftHand")
		if source_pose[hand].origin.y < 0.17:
			max_support_error=maxf(max_support_error,source_pose[hand].origin.distance_to(shaped[hand].origin))
		max_root_error=maxf(max_root_error,source_pose[0].origin.distance_to(shaped[0].origin))
	for anchor in [0.0,clip.contact_time,clip.duration]:
		assert(absf(Motion.source_time(anchor,clip.contact_time,clip.duration)-anchor)<0.00001)
	var contact_pose := normalized(clip,clip.contact_time)
	var contact_new := Motion.shape(contact_pose,clip.names,clip.parents,clip.contact_time,clip.contact_time,clip.duration)
	var right: int = clip.names.find("RightHand")
	var contact_error := contact_pose[right].origin.distance_to(contact_new[right].origin)
	assert(contact_error<0.00001,"Right hand at ball event moved")
	assert(max_difference>0.08,"Authored dig must be visibly different from source")
	assert(max_length_error<0.00001,"Authored dig changed a bone's length")
	assert(max_foot_error<0.00001,"Authored dig changed foot support")
	assert(max_support_error<0.00001,"Authored dig moved its supporting palm")
	assert(max_root_error<0.00001,"Authored dig changed physical root")
	assert(min_foot>0.0,"Authored dig pushed a foot through parquet")
	print("PASS DIVE41 source=",Motion.SOURCE," samples=361 max_pose_delta_m=",max_difference," max_bone_length_error_m=",max_length_error," feet_delta_m=",max_foot_error," planted_palm_delta_m=",max_support_error," contact_RHand_delta_m=",contact_error," min_foot_height_m=",min_foot," max_source_step_s=",max_phase_step)
	quit()

func dump_sources() -> void:
	for candidate in ["dive","dive_short","recovery","dive_v26_01","dive_v26_02","dive_v26_03","dive_v26_04","dive_v26_05","dive_v26_06"]:
		var other = PSA.new()
		other.load_file("res://assets/active/" + candidate + ".psa")
		other.load_hierarchy("res://assets/active/skeleton.psk")
		other.detect_contact("dive")
		var min_hip: float = INF
		var min_hand: float = INF
		for frame in other.frames:
			var p := normalized(other, float(frame)/other.fps)
			min_hip = minf(min_hip,p[other.names.find("Hips")].origin.y)
			min_hand = minf(min_hand,p[other.names.find("LeftHand")].origin.y)
		print("CANDIDATE41 ",candidate," dur=",other.duration," ct=",other.contact_time," hips=",min_hip," left=",min_hand)
	var clip = PSA.new()
	clip.load_file("res://assets/active/dive_v26_06.psa")
	clip.load_hierarchy("res://assets/active/skeleton.psk")
	clip.detect_contact("dive")
	print("DIVE41 frames=",clip.frames," duration=",clip.duration," contact=",clip.contact_time," recovery_end=",clip.recovery_end)
	print("NAMES41 ",clip.names)
	for fraction in [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]:
		var t: float = clip.duration * fraction
		var pose := normalized(clip, t)
		var points := {}
		for n in ["Hips","Spine","Spine1","Spine2","Neck","Head","LeftShoulder","LeftArm","LeftForeArm","LeftHand","RightHand","LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:
			points[n] = pose[clip.names.find(n)].origin
		print("POINTS41 t=",snappedf(t,0.001)," ",points)

func setup_preview() -> void:
	preview_game=load("res://src/main.tscn").instantiate()
	root.add_child(preview_game)
	preview_game.set_process(false)
	preview_game.set_physics_process(false)
	preview_game.started=true
	preview_game.demo=false
	preview_game.self_test=true
	preview_game.hud.hide()
	preview_game.marker.hide()
	preview_game.ball.hide()
	preview_game.dynamic_net.hide()
	AudioServer.set_bus_mute(0,true)
	var clip=preview_game.clips[Motion.SOURCE]
	var times: Array[float] = [clip.contact_time * 0.40,clip.contact_time,clip.contact_time+0.30,clip.contact_time+0.62,clip.contact_time+1.04,clip.duration-0.30]
	for row in 2:
		for column in 6:
			var avatar=preview_game.players[row*6+column]
			avatar.render_at_draw=false
			avatar.position=Vector3((column-2.5)*2.0,0.0,float(row)*3.3-1.65)
			avatar.rotation.y=0.0
			avatar.visual_root.rotation.y=0.0
			avatar.indicator.hide()
			avatar.jersey_number.hide()
			var t: float=times[column]
			var sample_time: float=Motion.source_time(t,clip.contact_time,clip.duration) if row==1 else t
			var pose := normalized(clip,sample_time)
			if row==1:
				pose=Motion.shape(pose,clip.names,clip.parents,t,clip.contact_time,clip.duration)
			var body=avatar.model_bank.body
			for bone in body.names.size():
				var i: int=avatar.animation_bones[bone]
				if i<0: continue
				var local := pose[i]
				if bone>0:
					var parent: int=avatar.animation_bones[body.parents[bone]]
					if parent>=0: local=pose[parent].affine_inverse()*local
				avatar.skeleton.set_bone_pose_position(bone,local.origin)
				avatar.skeleton.set_bone_pose_rotation(bone,local.basis.get_rotation_quaternion())
	preview_game.camera.position=Vector3(0,8,10)
	preview_game.camera.look_at(Vector3(0,0.3,0.5))
	preview_game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	preview_game.camera.size=7.8
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	label.position=Vector2(24,24)
	label.text="TUFFO 41 — confronto di pose\nOriginale: fila lontana / Nuovo: fila vicina\nPreparazione  |  Contatto  |  Caduta  |  Assorbimento  |  Appoggi  |  Rialzata"
	label.add_theme_font_size_override("font_size",22)
	layer.add_child(label)

func _process(_delta: float) -> bool:
	if preview_game==null: return false
	preview_frames+=1
	if preview_frames==5:
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/dive41-author-preview.png"),CONNECT_ONE_SHOT)
	if preview_frames>9:
		quit()
	return false

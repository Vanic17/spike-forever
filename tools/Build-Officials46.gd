extends SceneTree
const PSK=preload("res://src/psk.gd")
const PSA=preload("res://src/psa.gd")
const Converter=preload("res://src/psa_animation_library.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model=PSK.new(); assert(model.load_file("res://assets/art/officials46/referee.psk"))
	var library:=AnimationLibrary.new()
	var rows: Array=[]
	for key in ["idle","serve_left","serve_right","point_left","point_right","end_set"]:
		var clip=PSA.new(); assert(clip.load_file("res://assets/art/officials46/"+key+".psa"))
		clip.load_hierarchy("res://assets/art/officials46/referee.psk")
		clip.detect_contact("relaxed")
		var sampler=func(time: float):
			var pose: Array[Transform3D]=clip.pose(time,false)
			var anchor: Vector3=clip.positions[0]
			var offset: Vector3=Vector3(-anchor.x,-clip.ground_y*100,anchor.y)*.01-clip.body_center
			for bone in pose.size():
				pose[bone]=PSK.to_godot(pose[bone]); pose[bone].origin+=offset
			return pose
		# Some cinematic exports contain thousands of redundant keys in 2s.
		# Bake their actual trajectory at 30 Hz, never thousands of keys/frame.
		var animation:=Animation.new(); animation.length=clip.duration
		for bone in clip.names.size():
			for type in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
				var track:=animation.add_track(type); animation.track_set_path(track,NodePath("Rig:"+clip.names[bone]))
		for frame in ceili(clip.duration*30)+1:
			var time: float=minf(frame/30.0,clip.duration)
			var pose: Array[Transform3D]=sampler.call(time)
			for bone in clip.names.size():
				var local: Transform3D=pose[bone]
				if bone>0 and clip.parents[bone]>=0: local=pose[clip.parents[bone]].affine_inverse()*local
				animation.position_track_insert_key(bone*2,time,local.origin)
				animation.rotation_track_insert_key(bone*2+1,time,local.basis.get_rotation_quaternion())
		animation.loop_mode=Animation.LOOP_LINEAR if key=="idle" else Animation.LOOP_NONE
		library.add_animation(key,animation)
		var reach:=Vector3.ZERO
		for frame in clip.frames:
			var pose: Array[Transform3D]=sampler.call(float(frame)/clip.fps)
			for hand in ["LeftHand","RightHand"]:
				var p: Vector3=pose[clip.names.find(hand)].origin
				if absf(p.x)>absf(reach.x): reach=p
		rows.append({"gesture":key,"frames":clip.frames,"bones":clip.names.size(),"seconds":clip.duration,"max_lateral_hand":str(reach)})
	assert(ResourceSaver.save(library,"res://assets/art/officials46/gestures.res",ResourceSaver.FLAG_COMPRESS)==OK)
	FileAccess.open("res://docs/officials46-assets.json",FileAccess.WRITE).store_string(JSON.stringify({"mesh_bones":model.names.size(),"materials":model.material_names,"triangles":model.triangle_count,"gestures":rows},"\t"))
	print("OFFICIALS46 BUILD PASS ",JSON.stringify(rows))
	quit()

extends SceneTree
const PSA=preload("res://src/psa.gd")
const PSK=preload("res://src/psk.gd")
const SOURCES={
	"bench_idle_l":"Substitute/Cine_NPC_HJ_lookL_D0_Idle1.psa",
	"bench_idle_r":"Substitute/Cine_NPC_HJ_lookR_D0_Idle1.psa",
	"bench_clap_l":"Substitute/Cine_NPC_HJ_lookL_D0_SeatApplause_TO_LookR_D0.psa",
	"bench_clap_r":"Substitute/Cine_NPC_HJ_lookR_D0_SeatApplause_TO_LookL_D0.psa",
	"bench_stand_l":"Substitute/Cine_NPC_HJ_lookL_D0_StandApplause.psa",
	"bench_stand_r":"Substitute/Cine_NPC_HJ_lookR_D0_StandApplause.psa",
	"coach_idle":"Coach/Cine_NPC_C_armsReleased_Idle_02.psa",
	"coach_advice":"Coach/Cine_NPC_C_armsRelease_Advice.psa",
	"coach_win":"Coach/Cine_NPC_C_armsReleased_WIN_1.psa",
	"walk":"Move/Cine_Move_Walk_L_S1_in_place.psa"
,	"stand":"Idle/Cine_Idle_Static.psa"
}
func _initialize(): call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/art/sideline69")
	var model=PSK.new(); assert(model.load_file("res://assets/active/body.psk"))
	var library:=AnimationLibrary.new(); var report: Dictionary={}
	for key in SOURCES:
		var clip=PSA.new(); assert(clip.load_file("res://assets/spike/Game/CharactersV1/Animations/_Cinematic/"+SOURCES[key]))
		clip.load_hierarchy("res://assets/active/skeleton.psk"); clip.detect_contact("idle")
		var indices: Array[int]=[]
		for bone in model.names: indices.append(clip.names.find(bone))
		var initial: Array=clip.pose(0,false); var converted: Array[Transform3D]=[]
		for pose in initial: converted.append(PSK.to_godot(pose))
		var hips: Vector3=converted[clip.names.find("Hips")].origin
		var across: Vector3=converted[clip.names.find("LeftUpLeg")].origin-converted[clip.names.find("RightUpLeg")].origin
		var forward:=across.cross(Vector3.UP).normalized(); var heading:=atan2(forward.x,forward.z)
		var turn:=Basis(Vector3.UP,-heading)
		var animation:=Animation.new(); animation.length=clip.duration; animation.loop_mode=Animation.LOOP_LINEAR if "idle" in key or key=="walk" else Animation.LOOP_NONE
		for bone in model.names:
			for type in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
				var track:=animation.add_track(type); animation.track_set_path(track,NodePath("Visual/Rig:"+bone))
		var count:=ceili(clip.duration*30)
		var first_hip:=0.0; var last_hip:=0.0; var stand_at:=-1.0; var initial_local: Array[Transform3D]=[]
		for frame in count+1:
			var time:=minf(clip.duration,frame/30.0); var raw: Array=clip.pose(time,false); var world: Array[Transform3D]=[]
			var root: Vector3=PSK.to_godot(raw[0]).origin
			for pose in raw:
				var transform: Transform3D=PSK.to_godot(pose)
				transform=Transform3D(turn*transform.basis,turn*(transform.origin-Vector3(root.x+hips.x,clip.ground_y,root.z+hips.z)))
				world.append(transform)
			for i in model.names.size():
				var index: int=indices[i]; var local: Transform3D=world[index]
				if i>0: local=world[indices[model.parents[i]]].affine_inverse()*local
				if frame==0: initial_local.append(local)
				elif key=="walk": local=local.interpolate_with(initial_local[i],smoothstep(.86,1,time/clip.duration))
				animation.position_track_insert_key(i*2,time,local.origin)
				animation.rotation_track_insert_key(i*2+1,time,local.basis.get_rotation_quaternion())
			if frame==0: first_hip=world[clip.names.find("Hips")].origin.y
			last_hip=world[clip.names.find("Hips")].origin.y
			if stand_at<0 and last_hip>.99: stand_at=time
		library.add_animation(key,animation); report[key]={"source":SOURCES[key],"seconds":clip.duration,"heading":heading,"hip_first":first_hip,"hip_last":last_hip,"stand_at":stand_at}
	assert(ResourceSaver.save(library,"res://assets/art/sideline69/animations.res")==OK)
	FileAccess.open("res://docs/sideline69-sources.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	FileAccess.open("res://assets/art/sideline69/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SIDELINES69 BUILT ",JSON.stringify(report)); quit()

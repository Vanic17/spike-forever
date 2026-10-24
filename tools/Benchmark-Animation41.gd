extends SceneTree
## Fixed 12-player visual workload. No rendering/GPU claim in headless mode.
## Keep this scenario unchanged between before/after; no arena/audio/AI noise.
const Avatar = preload("res://src/avatar.gd")
const PSA = preload("res://src/psa.gd")
const PSK = preload("res://src/psk.gd")
const Converter = preload("res://src/psa_animation_library.gd")
const WARMUP := 90
const SAMPLES := 600
const DT := 1.0/60.0
var avatars: Array = []
var bank: Dictionary = {}
var frame := 0
var cpu: Array[float] = []
var animation: Array[float] = []
var samples: Array[float] = []
var intervals: Array[float] = []
var previous := 0
var label := "before-native"
var mode := "native"
var initial: Dictionary
var source_hashes: Dictionary = {}
var setup_ms := 0.0

func _initialize() -> void: call_deferred("setup")

func snapshot() -> Dictionary:
	return {"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"peak_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC_MAX),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)}

func stats(values: Array[float]) -> Dictionary:
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in ordered: total += value
	return {"mean_ms":total/ordered.size(),"p50_ms":ordered[int(ordered.size()*0.50)],"p95_ms":ordered[int(ordered.size()*0.95)],"p99_ms":ordered[int(ordered.size()*0.99)],"max_ms":ordered.back()}

func setup() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="): label=argument.trim_prefix("--label=")
		if argument == "--psa-original": mode="psa"
	Avatar.native_animation_enabled=mode=="native"
	var begin:=Time.get_ticks_usec()
	for name in Converter.CLIPS:
		var clip=PSA.new()
		assert(clip.load_file("res://assets/active/"+name+".psa"))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(name)
		bank[name]=clip
	var models: Dictionary={}
	var body=PSK.new()
	assert(body.load_file("res://assets/active/body.psk"))
	models.body=body
	for name in ["cloth","head","hair","eyes","shoes"]:
		var model=PSK.new()
		assert(model.load_file("res://assets/active/"+name+".psk",body.names))
		models[name]=model
	for i in 12:
		var athlete=Avatar.new()
		root.add_child(athlete)
		athlete.setup(bank,i/6,i%6+1,models)
		athlete.position=Vector3((i%3-1)*2.5,0,(1 if i<6 else -1)*(2.0+3.0*(i%6/3)))
		athlete.rotation.y=PI if i<6 else 0.0
		athlete.render_at_draw=false
		athlete.set_process(false)
		avatars.append(athlete)
	for path in ["src/avatar.gd","src/pose_animation_tree.gd","src/psa.gd","src/psa_animation_library.gd","src/animation_expansion.gd"]:
		source_hashes[path]=FileAccess.get_sha256("res://"+path)
	setup_ms=float(Time.get_ticks_usec()-begin)/1000.0
	previous=Time.get_ticks_usec()
	print("ANIMATION41 READY ",mode," players=",avatars.size()," source_clips=",bank.size()," bones=",bank.idle.names.size())

func _process(_elapsed: float) -> bool:
	if avatars.is_empty(): return false
	var now:=Time.get_ticks_usec()
	if frame>=WARMUP: intervals.append(float(now-previous)/1000.0)
	previous=now
	var begin:=Time.get_ticks_usec()
	for i in avatars.size():
		var athlete=avatars[i]
		# Staggered 2-second cycles keep travel, planted contact, recovery and
		# transitions present without random gameplay outcomes changing the test.
		var phase: int=((frame+i*17)/120)%4
		var action: String=["shuffle_left","receive","attack","dive"][phase]
		var local_frame: int=(frame+i*17)%120
		if athlete.clip_name!=action or local_frame==0:
			athlete.play(action,1.0,phase==0)
		athlete.velocity=Vector3(sin(float(frame+i*9)*0.017)*1.6,0,cos(float(frame+i*13)*0.013)*1.2) if phase<2 else Vector3.ZERO
		athlete.acceleration=Vector3(cos(float(frame+i*9)*0.017)*1.6,0,-sin(float(frame+i*13)*0.013)*1.2)
		athlete.ready_stance=true
		athlete.look_target=athlete.global_position+Vector3(sin(float(frame)*0.02),1.6,1.0)
		athlete.tick(DT,false,false)
	var animation_begin:=Time.get_ticks_usec()
	for athlete in avatars: athlete.apply_pose(DT)
	var animation_end:=Time.get_ticks_usec()
	if frame>=WARMUP:
		cpu.append(float(animation_end-begin)/1000.0)
		animation.append(float(animation_end-animation_begin)/1000.0)
	# Measure raw sample separately; do not charge this probe to the 12-avatar
	# update result. It also exercises the immutable native sample cache.
	var sample_begin:=Time.get_ticks_usec()
	for athlete in avatars:
		var pose: Array[Transform3D]=athlete.normalized_pose(athlete.clip_name,athlete.animation_time,athlete.looping)
		assert(pose.size()==bank.idle.names.size())
	if frame>=WARMUP: samples.append(float(Time.get_ticks_usec()-sample_begin)/1000.0)
	if frame==WARMUP: initial=snapshot()
	frame+=1
	if frame==WARMUP+SAMPLES:
		var final:=snapshot()
		var evaluations:=0
		var cache_hits:=0
		var rig_count:=0
		for athlete in avatars:
			if athlete.pose_tree!=null:
				rig_count+=1
				evaluations+=athlete.pose_tree.evaluations
				cache_hits+=athlete.pose_tree.cache_hits
		var report: Dictionary={"scenario":"fixed-12-avatars-v1","label":label,"backend":mode,"display":DisplayServer.get_name(),"headless":DisplayServer.get_name()=="headless","samples":cpu.size(),"warmup_frames":WARMUP,"simulation_dt":DT,"players":avatars.size(),"bones_per_player":bank.idle.names.size(),"source_clips":bank.size(),"evaluation_rigs":rig_count,"cpu_update_12_players":stats(cpu),"animation_apply_12_players":stats(animation),"sample_probe_12_players":stats(samples),"callback_interval_with_probe":stats(intervals),"setup_ms":setup_ms,"memory_after_warmup":initial,"memory_final":final,"resource_count_delta":final.resources-initial.resources,"object_count_delta":final.objects-initial.objects,"static_bytes_delta":final.static_bytes-initial.static_bytes,"native_evaluations":evaluations,"native_cache_hits":cache_hits,"source_sha256":source_hashes,"limitations":["CPU timings only; headless does not measure GPU rendering or visible FPS","Godot memory/resource counters are retained-state measurements, not a transient allocation or file-I/O trace","Sampling probe is excluded from update timings but included in callback intervals","Fixed workload isolates animation and excludes arena, tactical AI and ball simulation"]}
		var output:=FileAccess.open("res://docs/animation41-"+label+".json",FileAccess.WRITE)
		output.store_string(JSON.stringify(report,"\t"))
		print("ANIMATION41 PASS ",JSON.stringify(report))
		quit()
	return false

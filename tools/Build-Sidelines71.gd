extends SceneTree
## Bake gestures on original seated cinematics. Feet, hips and seat remain native.
const Motion=preload("res://src/sideline_animation.gd")
const Crowd=preload("res://src/crowd.gd")
func _initialize():call_deferred("run")
func turn(rig,world: Array,bone: int,rotation: Basis):
	var pivot: Vector3=world[bone].origin
	for i in world.size():
		var ancestor: int=i
		while ancestor>0 and ancestor!=bone:ancestor=rig.parents[ancestor]
		if ancestor==bone:world[i]=Transform3D(rotation*world[i].basis,pivot+rotation*(world[i].origin-pivot))
func reach(rig,world: Array,side: String,target: Vector3,weight: float):
	var arm: int=rig.names.find(side+"Arm");var fore: int=rig.names.find(side+"ForeArm");var hand: int=rig.names.find(side+"Hand")
	target=world[hand].origin.lerp(target,weight)
	var origin: Vector3=world[arm].origin
	var upper: float=origin.distance_to(world[fore].origin);var lower: float=world[fore].origin.distance_to(world[hand].origin)
	var direction: Vector3=(target-origin).normalized();var distance:=clampf(origin.distance_to(target),absf(upper-lower)+.002,upper+lower-.005)
	var pole:=Vector3(.7 if side=="Left" else -.7,-.65,0);pole=(pole-direction*pole.dot(direction)).normalized()
	var cosine:=clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1)
	var elbow:=origin+direction*cosine*upper+pole*sqrt(maxf(0,1-cosine*cosine))*upper
	Crowd.rotate_chain(world,rig,arm,elbow-origin,fore)
	Crowd.rotate_chain(world,rig,fore,origin+direction*distance-world[fore].origin,hand)
func run():
	Motion.library=load("res://assets/art/sideline69/animations.res")
	var rig=preload("res://src/psk.gd").new();assert(rig.load_file("res://assets/active/body.psk"))
	var extra=AnimationLibrary.new();var report={}
	for gesture in ["sign","point","nod","open","turn","work"]:
		for suffix in ["l","r","coach","official"]:
			if suffix=="official" and gesture!="work":continue
			if suffix!="official" and gesture=="work":continue
			if suffix=="coach" and not gesture in ["sign","point","nod"]:continue
			var duration: float={"sign":2.25,"point":2.6,"nod":1.9,"open":2.5,"turn":3.0,"work":4.7}[gesture]
			var name: String=("coach_"+gesture if suffix=="coach" else ("official_work" if suffix=="official" else "bench_"+gesture+"_"+suffix))
			var base: String="coach_idle" if suffix=="coach" else ("bench_idle_l" if suffix=="official" else "bench_idle_"+suffix)
			var animation=Animation.new();animation.length=duration
			if gesture=="work":animation.loop_mode=Animation.LOOP_LINEAR
			for bone in rig.names:
				for type in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
					var track=animation.add_track(type);animation.track_set_path(track,NodePath("Visual/Rig:"+bone))
			for frame in ceili(duration*30)+1:
				var time=minf(duration,frame/30.0);var phase=time/duration
				var weight=smoothstep(0,.22,phase)*(1-smoothstep(.65,1,phase))
				var source: Array=Motion.sample(rig,base,time)
				var world: Array[Transform3D]=[]
				for i in rig.names.size():world.append(world[rig.parents[i]]*source[i] if i>0 else source[i])
				var chest: Vector3=world[rig.names.find("Spine")].origin+Vector3(0,.20,.12)
				if gesture=="sign":reach(rig,world,"Right",chest+Vector3(-.16,.40,.26),weight)
				elif gesture=="point":reach(rig,world,"Right",chest+Vector3(-.12,.12,.56),weight)
				elif gesture=="open":
					reach(rig,world,"Left",chest+Vector3(.34,.02,.30),weight)
					reach(rig,world,"Right",chest+Vector3(-.34,.02,.30),weight)
				elif gesture=="nod":turn(rig,world,rig.names.find("Head"),Basis(Vector3.RIGHT,.13*sin(phase*TAU*2)*weight))
				elif gesture=="turn":turn(rig,world,rig.names.find("Spine"),Basis(Vector3.UP,(.22 if suffix=="l" else -.22)*weight))
				elif gesture=="work":
					reach(rig,world,"Left",Vector3(.18,.855+.003*sin(time*TAU*2),.48),1)
					reach(rig,world,"Right",Vector3(-.18,.855+.003*cos(time*TAU*2),.48),1)
					for side in ["Left","Right"]:
						Crowd.rotate_chain(world,rig,rig.names.find(side+"Hand"),Vector3(0,-.12,1),rig.names.find(side+"HandMiddle1"))
				for i in rig.names.size():
					var local: Transform3D=world[rig.parents[i]].affine_inverse()*world[i] if i>0 else world[i]
					animation.position_track_insert_key(i*2,time,local.origin)
					animation.rotation_track_insert_key(i*2+1,time,local.basis.get_rotation_quaternion())
			extra.add_animation(name,animation);report[name]={"seconds":duration,"base":base,"family":gesture,"legs":"original cinematic"}
	DirAccess.make_dir_recursive_absolute("res://assets/art/sideline71")
	assert(ResourceSaver.save(extra,"res://assets/art/sideline71/animations.res")==OK)
	FileAccess.open("res://assets/art/sideline71/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SIDELINES71 BUILT: ",extra.get_animation_list().size()," native sideline clips");quit()

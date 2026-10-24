extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	# Service movement is independent from aim until the charge starts.
	for camera in 3:
		g.camera_mode=camera; g.server=0; g.reset_rally(); var index: int=g.server_index(0)
		var start: Vector3=g.players[index].position
		Input.action_press("right")
		for frame in 90: g.step(1.0/120)
		Input.action_release("right")
		assert(g.players[index].position.distance_to(start)>.5,"Left stick must move the server before charging")
		assert(g.players[index].position.z>=9.299 and absf(g.players[index].position.x)<=4.351,"Server remains behind endline and inside service width")
	# The correction must be a real backward step, followed by a valid toss.
	var serves: Array=[]
	for style in 2:
		g.camera_mode=0; g.server=0; g.reset_rally(); var index: int=g.server_index(0)
		g.players[index].position=Vector3(1,0,9.30); g.players[index].velocity=Vector3.ZERO
		g.serve_type=style; g.serve_power=.75; g.input_quality=1
		var before: int=g.test_contacts
		g.begin_serve_toss(); var adjusted: bool=g.serve_adjusting
		for frame in 1000:
			if g.test_contacts>before or g.phase=="POINT": break
			g.step(1.0/120)
			if frame%4==0: g.players[index].apply_pose(1.0/30)
		assert(g.test_contacts==before+1,"Both service styles must retain their real hand/ball contact after a backward step")
		serves.append({"style":style,"backward_step":adjusted,"contact":true})
	# S has priority on a playable ball; L replaces him after S's first touch.
	g.server=1; g.rotations=[0,0]; g.reset_rally(); g.receiver=0
	var point: Vector3=g.Tactics.setter_position(0)+Vector3.UP*g.contact_height("set")
	g.players[5].position=g.players[5].stance_for_contact("set",point)+Vector3(.4,0,.4)
	assert(g.choose_setter(0,point,1.0)==5,"S must keep the ordinary second touch")
	g.receiver=5; assert(g.choose_setter(0,point,1.0)!=5,"S cannot make consecutive touches")
	# Physical block families retain mirror symmetry and a meaningful range.
	var response=load("res://src/block_response.gd"); var rng=RandomNumberGenerator.new(); rng.seed=47001
	var kinds: Dictionary={}; var details: Dictionary={}; var y_min:=INF; var y_max:=-INF
	for n in 2000:
		var strength:=rng.randf_range(.18,1); var q:=rng.randf_range(.5,1); var edge:=rng.randf_range(-1.25,1.25)
		var r: Dictionary=response.solve(Vector3(1,-3,30),0,strength,q,edge,Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)))
		assert(r.velocity.is_finite()); kinds[r.kind]=kinds.get(r.kind,0)+1; details[r.get("detail",r.kind)]=true
		y_min=minf(y_min,r.velocity.y); y_max=maxf(y_max,r.velocity.y)
		if r.kind=="stuff_block": assert(r.velocity.y<=-8.5 and r.velocity.z<0)
	assert(kinds.size()==3 and details.size()>=6 and y_max-y_min>20,"Blocks include hard stuffs, tools, high/low and playable rebounds")
	FileAccess.open("res://docs/gameplay47-report.json",FileAccess.WRITE).store_string(JSON.stringify({"service_cameras":3,"serves":serves,"setter_priority":true,"block_sample_count":2000,"synthetic_block_families":kinds,"details":details.keys(),"vertical_velocity_range":[y_min,y_max]},"  "))
	print("GAMEPLAY47 PASS: serve movement/line bounds/2 real serves; S priority; 2000 varied block responses ",kinds)
	g.free(); quit()

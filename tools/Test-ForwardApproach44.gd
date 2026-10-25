extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true; g.demo=false
	var cases:=0
	for scenario in [[0,0],[4,2],[2,3]]:
		g.rotations=[scenario[0],scenario[0]]; g.server=1; g.rng.seed=40001; g.shot_serial=0; g.reset_rally(); g.possession=0
		g.set_dir=scenario[1]
		for i in 6:
			if g.Tactics.libero(i,scenario[0],false): g.receiver=i
		g.players[g.receiver].position=g.Tactics.world(0,0,5.5); g.players[5].position=g.Tactics.world(0,1.65,2)
		g.ball_pos=g.players[g.receiver].contact_world("receive"); g.phase="RECEIVE"; g.armed=true; g.input_quality=1; g.incoming_kind="spike"; g.incoming_power=0.3
		var contacts: int=g.test_contacts; g.receive_ball(); g.press_action("action")
		var runner: int=g.planned_hitter; var running:=false
		for frame in 700:
			if g.test_contacts>=contacts+3 or g.phase in ["POINT","LOOSE"]: break
			if g.phase in ["SET","ATTACK"]:
				if g.players[runner].travel_animation_name=="run" and g.players[runner].velocity.length()>1.25: running=true
			if g.phase=="ATTACK":
				g.armed=true; g.charge=0.7; g.input_quality=1
				if g.players[runner].travel_animation_name=="run" and g.players[runner].velocity.length()>1.25: running=true
			g.step(1.0/120)
		assert(g.test_contacts==contacts+3 and running,"Wing, back-row opposite and pipe must use a running approach and retain physical contact")
		var root: Vector3=g.players[runner].position
		assert(g.attack_run.landing(runner,g.clock_time))
		if scenario[1] in [2,3]: assert(root.z<3.0 and g.attack_run.air_start.z>3.0,"Back-row players take off behind the line and contact inside it")
		g.block_time=-100
		for frame in 42: g.step(1.0/120)
		assert(root.z-g.players[runner].position.z>0.025,"The physical root must continue forward through the follow-through, not only the mesh")
		print("FORWARD APPROACH44 scenario=",scenario," root_forward_m=",root.z-g.players[runner].position.z)
		cases+=1
	print("FORWARD APPROACH44 PASS cases=",cases," / running legs / real contacts / legal back row / forward landing")
	g.free(); quit()

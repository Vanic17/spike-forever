extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	g.rng.seed=44001; g.possession=1; g.out_of_system=1; g.set_quality=0.9; g.ball_pos=Vector3(3.4,3.3,-1.1)
	var soft:=0; var over:=0; var minimum:=1.0
	for i in 2000:
		g.block_count=0 if i%2==0 else 2
		var power: float=g.RallyAI.cpu_attack_power(g)
		assert(power>=0.80 and power<0.97)
		minimum=minf(minimum,power)
		var shot: Dictionary=g.RallyAI.attack_choice(g,1,power)
		if shot.soft: soft+=1
		else: assert(shot.power>=0.8,"An open court cannot weaken a hard CPU swing")
		g.incoming_power=0.90; g.flight_left=0.6; g.receiver=7
		g.cpu_defense.prepare(g)
		if g.cpu_defense.outcome=="overpass": over+=1
	assert(soft>0 and soft<200,"Soft shots remain occasional tactical alternatives")
	assert(over>0 and over<90,"Overpasses are rare, without removing their legal follow-up")
	var response=load("res://src/block_response.gd")
	for team in 2:
		var incoming:=Vector3(1,-3,30 if team==0 else -30)
		var full: Dictionary=response.solve(incoming,team,0.95,1,0)
		assert(full.kind=="stuff_block" and full.velocity.y<0 and full.velocity.z*incoming.z<0)
		var tool: Dictionary=response.solve(incoming,team,0.45,0.65,1.1)
		assert(tool.kind=="block_tool" and tool.velocity.x>3 and tool.velocity.z*incoming.z>0)
		var touch: Dictionary=response.solve(incoming,team,0.45,0.7,0.2)
		assert(touch.kind=="block_touch" and touch.velocity.is_finite())
	print("RALLY BALANCE44 PASS hard_cpu_min=",minimum," soft=",soft,"/2000 overpass=",over,"/2000 / mirrored stuff, tool and playable touches")
	FileAccess.open("res://docs/balance44-report.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":44001,"samples":2000,"cpu_hard_power_min":minimum,"soft_choices":soft,"cpu_overpasses":over,"pressure":0.9,"alternating_block_counts":[0,2],"ordinary_power_range":[0.82,0.965]},"  "))
	g.free(); quit()

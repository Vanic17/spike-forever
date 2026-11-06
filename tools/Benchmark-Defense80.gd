extends SceneTree
const OLD:=["receive_low","receive_left_step","receive_right_step","dive_v26_01"]
const NEW:=["receive_platform80","receive_knee80","receive_knee_right80","dive_platform80"]
var game
func _initialize(): call_deferred("run")
func measure(variants: Array) -> Dictionary:
	var costs: Array[float]=[]
	for frame in 660:
		var start:=Time.get_ticks_usec()
		for index in 12:
			var p=game.players[index]; var slot: int=(frame/120+index)%4
			var action: String="dive" if slot==3 else "receive"
			var variant: String=variants[slot]
			if p.variant_names.get(action,"")!=variant or p.clip_name!=action:
				p.motion_lock=0; p.contact_scheduled=false; p.looping=true
				p.select_variant(action,variant); p.play(action,1,false)
			p.animation_time=fposmod(float(frame+index*17)/60,p.clips[action].duration)
			p.idle_time=float(frame)/60; p.reach_weight=0; p.velocity=Vector3.ZERO
			p.apply_pose(1.0/60)
		if frame>=60: costs.append(float(Time.get_ticks_usec()-start)/1000)
	costs.sort(); var sum:=0.0
	for value in costs: sum+=value
	return {"samples":costs.size(),"mean_ms":sum/costs.size(),"p95_ms":costs[int(costs.size()*.95)]}
func run():
	game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.self_test=true
	for child in game.find_children("*","Node",true,false): child.set_process(false)
	for p in game.players: p.render_at_draw=false
	var old:=measure(OLD); var added:=measure(NEW)
	var report={"pass":added.mean_ms<old.mean_ms*1.20,"base":old,"new":added,"ratio":added.mean_ms/old.mean_ms,"players":12,"native":true,"limits":"CPU animation/skin only; no FPS or GPU claim; same 600-pose workload after 60 warmup frames"}
	FileAccess.open("res://docs/defense80-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("DEFENSE80 PERFORMANCE ",JSON.stringify(report)); game.free(); quit(0 if report.pass else 1)

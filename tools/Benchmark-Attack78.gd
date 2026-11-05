extends SceneTree
var game
func _initialize():call_deferred("run")
func measure(variant: String) -> Dictionary:
	var values: Array[float]=[]
	for frame in 720:
		var start:=Time.get_ticks_usec()
		for index in 12:
			var p=game.players[index]
			if p.variant_names.get("attack","")!=variant:p.looping=true;p.select_variant("attack",variant)
			# Two approaching attackers, ten standard moving defenders. This
			# measures the added layer in a complete twelve-avatar workload.
			p.velocity=Vector3(0,0,4.2);p.intent.task="approach" if index<2 else "cover"
			p.clip_name="run";p.looping=true;p.animation_time=fposmod(float(frame+index*9)/60,p.clips.run.duration)
			p.pin_reference_load=1.0 if index<2 and variant.begins_with("attack_reference") else 0.0
			p.reach_weight=0;p.blend_left=0;p.idle_time=float(frame)/60
			p.apply_pose(1.0/60)
		if frame>=120:values.append(float(Time.get_ticks_usec()-start)/1000)
	values.sort();var total:=0.0
	for value in values:total+=value
	return {"mean_ms":total/values.size(),"p95_ms":values[int(values.size()*.95)],"samples":values.size()}
func run():
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true
	for child in game.find_children("*","Node",true,false):child.set_process(false)
	for p in game.players:p.render_at_draw=false
	var old:=measure("attack_pin_left");var added:=measure("attack_reference78")
	var report={"pass":added.mean_ms<old.mean_ms*1.25,"base":old,"new":added,"ratio":added.mean_ms/old.mean_ms,"players":12,"approaching_attackers":2,"native":true,"limits":"CPU animation/skinning only; no GPU or total FPS claim; cached upper-body pose and 600 measured frames"}
	FileAccess.open("res://docs/attack78-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ATTACK78 PERFORMANCE ",JSON.stringify(report));game.free();quit(0 if report.pass else 1)

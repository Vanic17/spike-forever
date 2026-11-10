extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("attack105" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false
	var p=g.players[0];var rows: Array=[]
	for name in ["attack_pin_left","attack_pin_right","attack_reference78","attack_reference_right78","attack_middle_style80","attack_middle_style_right80"]:
		p.select_variant("attack",name)
		rows.append({"name":name,"height":p.contact_local("attack").y,"takeoff":p.clips.attack.takeoff_time,"contact":p.clips.attack.contact_time})
	print("VARIANTS105 ",JSON.stringify(rows));quit()

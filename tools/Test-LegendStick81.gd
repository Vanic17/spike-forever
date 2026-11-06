extends "res://tools/Test-LegendInputs75.gd"
const View=preload("res://src/view_controls.gd")
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var rows: Array=[]
	for camera_mode in [0,2,3]:
		for phase in ["RECEIVE","SET","ATTACK"]:
			var p=restart("S");var index: int=adapter.controlled_index
			game.phase=phase;game.possession=0;game.receiver=index;game.setter=index;game.hitter=index;game.armed=true;game.camera_mode=camera_mode;game.set_camera()
			for octant in 8:
				var screen:=Vector2.from_angle(octant*PI/4)*.9
				await axis(JOY_AXIS_LEFT_X,screen.x);await axis(JOY_AXIS_LEFT_Y,screen.y)
				await axis(JOY_AXIS_RIGHT_X,-screen.x);await axis(JOY_AXIS_RIGHT_Y,-screen.y)
				adapter.apply_controls(0)
				var expected: Vector2=View.court_direction(screen,camera_mode).normalized()
				check(game.aim.normalized().distance_to(expected)<.002,"LS aims in court coordinates "+str([camera_mode,phase,octant]))
				check(adapter.movement_vector().length()>.8,"Same LS supplies player movement")
				rows.append({"camera":camera_mode,"phase":phase,"octant":octant,"aim":game.aim,"movement":adapter.movement_vector()})
			await axis(JOY_AXIS_LEFT_X,0);await axis(JOY_AXIS_LEFT_Y,0)
			check(adapter.current_aim()==Vector2.ZERO,"Right stick cannot continue aiming after LS release")
			await axis(JOY_AXIS_RIGHT_X,0);await axis(JOY_AXIS_RIGHT_Y,0)
	var p=restart("S");game.server=0;game.rotations=[0,0];game.reset_rally();game.started=true;game.demo=false;game.paused=false
	var index: int=adapter.controlled_index;p.position=Vector3(0,0,9.31);clear_around(index)
	adapter.return_positions[index]=Vector3(0,0,12)
	await axis(JOY_AXIS_LEFT_X,0);await axis(JOY_AXIS_LEFT_Y,-1)
	for frame in 120:game.step(1.0/120)
	check(p.position.z>=9.299,"Walking cannot enter court before serve")
	check(not adapter.return_positions.has(index),"LS takes over automatic return route")
	await axis(JOY_AXIS_LEFT_Y,1)
	var start_z: float=p.position.z
	for frame in 120:game.step(1.0/120)
	check(p.position.z>start_z+.5,"LS walks backwards for service approach")
	await button(JOY_BUTTON_A);var origin: Vector3=p.position
	await axis(JOY_AXIS_LEFT_X,.9);await axis(JOY_AXIS_LEFT_Y,-.5)
	for frame in 70:game.step(1.0/120)
	var braking_distance: float=p.position.distance_to(origin)
	check(absf(p.position.x-origin.x)<.02 and p.position.z>=origin.z and p.velocity.length()<.15,"Charging brakes prior momentum instead of walking toward LS aim")
	check(game.aim.x>.7 and game.aim.y<0,"Same LS aims charged serve")
	FileAccess.open("res://docs/legend81-stick.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"braking_distance_m":braking_distance,"final_charging_speed":p.velocity.length(),"failures":failures},"  "))
	print("LEGEND STICK81 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

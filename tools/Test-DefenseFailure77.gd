extends "res://tools/Test-LegendInputs75.gd"
const Visual=preload("res://src/defense_visual77.gd")
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated fixture")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();restart()
	var rows: Array=[]
	for sign in [-1,1]:
		var p=game.players[6];game.phase="CPU_RECEIVE";game.possession=1;game.receiver=6;game.shot_serial=2
		game.incoming_kind="spike";game.ball_vel=Vector3(1,-9,2);game.armed=true;game.late_receive=false;game.winner_team=-1;game.dive_motions.clear()
		p.position=Vector3(0,0,-5);p.rotation.y=0;p.motion_lock=0;p.contact_scheduled=false;p.play("ready",1,true)
		game.ball_pos=p.position+Vector3(sign*1.8,.65,.2)
		var before: Array=[game.ball_pos,game.ball_vel,game.touches.duplicate(),game.scores.duplicate(),game.last_touch,p.position,game.test_contacts]
		game.miss_contact()
		check(p.variant_names.get("dive","")==("defense_miss77" if sign>0 else "defense_miss_right77"),"extreme gesture only on failed lateral ball")
		check(game.phase=="LOOSE","miss remains a miss")
		check(before==[game.ball_pos,game.ball_vel,game.touches.duplicate(),game.scores.duplicate(),game.last_touch,p.position,game.test_contacts],"failed animation cannot alter ball, touches, score or teleport root")
		check(p.blend_left>0,"transition from actual pose remains blended")
		rows.append({"side":sign,"variant":p.variant_names.get("dive",""),"ball_unchanged":true,"root_unchanged":true})
		p.play("ready",1,true);game.phase="CPU_RECEIVE"
		game.ball_pos=p.position+Vector3(.3,.65,.2)
		check(not Visual.extreme_attempt(game,6),"ordinary reachable ball cannot trigger extreme miss")
		game.ball_pos=p.position+Vector3(1.8,.65,.2);game.incoming_kind="serve"
		check(not Visual.extreme_attempt(game,6),"serve never triggers extreme dive")
		game.incoming_kind="spike";game.phase="CPU_SET"
		check(not Visual.extreme_attempt(game,6),"setter never given a false failed dive")
	game.phase="RECEIVE";game.possession=0;game.receiver=0;game.armed=false
	var p=game.players[0];p.play("ready",1,true);p.rotation.y=PI;game.ball_pos=p.position+Vector3(-1.8,.65,-.2)
	check(not Visual.extreme_attempt(game,0),"no automatic move when human gives no command")
	FileAccess.open("res://docs/defense77-failed-attempts.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":rows,"failures":failures},"  "))
	print("DEFENSE FAILURE77 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

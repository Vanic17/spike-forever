extends "res://tools/Test-LegendInputs75.gd"
func run():
	check(ProjectSettings.globalize_path("user://").contains("legend75"),"isolated appdata")
	if not failures.is_empty():quit(2);return
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	adapter=game.legend_match
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false);child.panel.hide();child.play_hub.hide();child.legend_menu.hide()
	await settle();var cases: Array=[]
	for fps in [60,120]:
		for side in [-1,1]:
			var p=restart();var index: int=adapter.controlled_index
			p.position=Vector3(0,0,6);p.rotation.y=PI;p.velocity=Vector3.ZERO;p.play("ready",1,true);clear_around(index)
			game.phase="RECEIVE";game.possession=0;game.receiver=index;game.incoming_kind="spike";game.shot_serial=1;game.armed=true
			game.input_quality=.9;game.winner_team=-1;game.late_receive=false;game.last_touch=1;game.touches=[0,0]
			game.flight_spin=Vector3.ZERO;game.flight_gravity=game.G
			var point:=Vector3(side*.9,.65,5)
			game.ball_pos=point+Vector3(0,1.4,.2);game.launch(point,.28)
			game.shot_serial=1
			adapter.allow_requested_recovery=true
			var queued: bool=game.queue_recovery(true)
			adapter.allow_requested_recovery=false
			check(queued,"native lateral dive queued")
			check(p.variant_names.get("dive","")==("dive_slide77" if side<0 else "dive_slide_right77"),"correct native dive orientation")
			var limit: float=game.clock_time+1.0
			while game.phase=="RECEIVE" and game.clock_time<limit:game.step(1.0/fps)
			var contacts: Array=game.contact_log.filter(func(row):return int(row.player)==index and row.action=="dive")
			check(not contacts.is_empty(),"new supported dive meets real ball at "+str(fps)+" Hz")
			var recovery_elapsed:=0.0
			while game.dive_motions.has(index) and recovery_elapsed<1.5:
				game.advance_dive_body(index,1.0/fps);recovery_elapsed+=1.0/fps
			check(not game.dive_motions.has(index) and recovery_elapsed<1.15,"new lateral recovery releases old roll lock within 1.15 seconds after contact")
			cases.append({"fps":fps,"side":side,"queued":queued,"variant":p.variant_names.get("dive",""),"contacts":contacts,"recovery_seconds":recovery_elapsed})
	FileAccess.open("res://docs/defense77-dive-contacts.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"cases":cases,"failures":failures},"  "))
	print("DEFENSE DIVE77 ","PASS" if failures.is_empty() else "FAIL",failures);game.free();quit(0 if failures.is_empty() else 1)

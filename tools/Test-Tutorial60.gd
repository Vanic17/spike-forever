extends SceneTree
const Lessons=preload("res://src/tutorial_lessons.gd")
func _initialize(): call_deferred("run")
func clear_inputs():
	for key in ["left","right","up","down","action","alternate","dump","block_left","block_right"]: Input.action_release(key)
func aim(direction: Vector2):
	for key in ["left","right","up","down"]: Input.action_release(key)
	if direction.x<-.1: Input.action_press("left",absf(direction.x))
	if direction.x>.1: Input.action_press("right",direction.x)
	if direction.y<-.1: Input.action_press("up",absf(direction.y))
	if direction.y>.1: Input.action_press("down",direction.y)
func run():
	var hz:=120
	var report_path:="res://docs/tutorial60-gameplay.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hz="): hz=int(arg.trim_prefix("--hz="))
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
		if arg=="--psa": load("res://src/avatar.gd").native_animation_enabled=false
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.match_audio.enabled=false
	var t=g.tutorial; var menu
	for node in g.get_children():
		if node.get_script()==load("res://src/start_menu.gd"): menu=node
	t.open(menu)
	var rows: Array=[]
	var filter:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--category="): filter=arg.trim_prefix("--category=")
	for cat in Lessons.categories():
		if not filter.is_empty() and cat.id!=filter: continue
		var lessons=Lessons.all(cat.id)
		for index in lessons.size():
			clear_inputs(); t.start_lesson(cat.id,index); t.resume()
			var item: Dictionary=lessons[index]; var pushed:=false; var attack_pressed:=false; var frames: Array=[]
			for frame in hz*20:
				if not t.pending.is_empty(): break
				if cat.id=="serve":
					if not pushed:
						if item.has("move") and t.max_move<float(item.move)+.06:
							aim(Vector2(-1,0))
						else:
							aim(Vector2.ZERO); g.send_test_button(JOY_BUTTON_X if item.get("style",1)==0 else JOY_BUTTON_A); pushed=true
					else:
						var direction:=Vector2(0,-1)
						if item.has("zone"): direction.x=signf(item.zone.x)
						aim(direction)
						var power:=1.12 if item.get("experiment",false) else (.97 if item.id=="power" else .75)
						if g.charging and g.current_charge()>=power: g.send_test_button(JOY_BUTTON_X if item.get("style",1)==0 else JOY_BUTTON_A,false)
				elif cat.id=="receive":
					if not pushed and ((g.clock_time>=g.receive_deadline+.025) if item.get("late",false) else g.flight_left<=.025): g.send_test_button(JOY_BUTTON_A); pushed=true
				elif cat.id=="set":
					if not pushed:
						var direction: Vector2=[Vector2.LEFT,Vector2.UP,Vector2.RIGHT,Vector2.DOWN][int(item.direction)]
						aim(direction); g.send_test_button(JOY_BUTTON_B if item.get("dump",false) else (JOY_BUTTON_X if item.fast else JOY_BUTTON_A)); pushed=true
				elif cat.id=="attack":
					if g.phase=="ATTACK":
						var direction:=Vector2(0,-1)
						if item.has("zone"): direction.x=signf(item.zone.x)
						if item.get("tip",false): direction=Vector2(1,1)
						aim(direction)
						if not attack_pressed and g.flight_left<=.53: g.send_test_button(JOY_BUTTON_X if item.get("tip",false) else JOY_BUTTON_A); attack_pressed=true
						if g.charging and (g.current_charge()>=(.93 if item.id=="full" else .66) or g.flight_left<.01): g.send_test_button(JOY_BUTTON_X if item.get("tip",false) else JOY_BUTTON_A,false)
				elif cat.id=="block":
					if item.get("left",false): Input.action_press("block_left")
					if item.get("right",false): Input.action_press("block_right")
					var x: float=g.tutorial.coach_attack_target().x if g.phase=="CPU_ATTACK" else 0.0
					if g.phase=="CPU_SET":
						var planned: Vector3=g.RallyAI.attack_contact(g,int(item.direction),g.planned_hitter,g.flight_target); x=planned.x
					var goal: float=x
					if x>1.5: goal=x-.9
					if x< -1.5: goal=x+.9
					if item.get("central_feed",false): goal=0
					var difference: float=goal-g.block_helper_x
					aim(Vector2(signf(difference)*minf(1,absf(difference)*4),0))
					if g.phase=="CPU_ATTACK" and g.flight_left<=(.07 if item.get("central_feed",false) else .22) and not pushed: g.send_test_button(JOY_BUTTON_A); pushed=true
				g.step(1.0/hz)
				if cat.id=="block" and g.phase=="RECEIVE" and absf(g.ball_pos.z)<.7:
					var hands: Array=[]
					for player_index in g.blocking_players(0):
						var player=g.players[player_index]; player.apply_pose(0); hands.append({"index":player_index,"left":player.current_hand(true),"right":player.current_hand(false),"root":player.position,"clip":player.clip_name})
					frames.append({"ball":g.ball_pos,"hands":hands,"age":g.clock_time-g.block_time})
				if frame%maxi(1,hz/30)==0:
					for p in g.players: p.apply_pose(1.0/30)
			var row={"category":cat.id,"lesson":item.id,"success":t.pending_ok,"feedback":t.pending,"phase":g.phase,"contacts":g.test_contacts,"position":str(g.ball_pos),"input":pushed or attack_pressed,"net_frames":frames}
			rows.append(row); print("TUTORIAL60 CASE ",JSON.stringify(row))
			if cat.id=="set" and not t.pending_ok: print("TUTORIAL60 SET DEBUG ",g.play_log[-1]," hitterpos=",g.players[g.hitter].position," target=",g.players[g.hitter].target," planned=",g.planned_fast)
			clear_inputs()
			t.restore()
	var failures:=rows.filter(func(row): return not row.success).size()
	if not filter.is_empty(): report_path=report_path.trim_suffix(".json")+"-"+filter+".json"
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify({"cases":rows,"failures":failures,"hz":hz,"native":load("res://src/avatar.gd").native_animation_enabled},"  "))
	print("TUTORIAL60 RESULTS ",rows.size()-failures,"/",rows.size())
	g.free(); quit(1 if failures else 0)

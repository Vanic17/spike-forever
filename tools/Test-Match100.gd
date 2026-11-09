extends SceneTree
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message);push_error("MATCH100 "+message)
func _initialize():call_deferred("run")
func run():
	assert("match100" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var start=g.get_children().filter(func(n):return n.get_script()==load("res://src/start_menu.gd"))[0];start.startup_scan=false;start.installed_version="999.0.0"
	var db=start.clubs.db;var teams: Array=[db.teams[0],db.teams[1]];var squads: Array=[db.lineup(teams[0]),db.lineup(teams[1])]
	for team in 2:
		g.team_names[team]=teams[team].name
		for i in 6:g.players[team*6+i].set_roster_identity(squads[team][i],squads[team][6],{}, {})
	g.match_management.configure_rosters(teams,squads,{}, {"fatigue":false});g.started=true;g.demo=false;g.paused=false
	var sponsors=g.arena_visuals.sponsors
	for cycle in 3:
		sponsors.cycle=cycle;sponsors.apply_cycle();var same=sponsors.panels[0].get_shader_parameter("logo_a")
		for material in sponsors.panels:check(material.get_shader_parameter("logo_a")==same,"continuous sponsor feed through corners and upper fascia")
	var B=preload("res://src/block_response.gd");var S=preload("res://src/player_stats_gameplay.gd")
	for side in 2:
		for edge in [-1.1,-.4,0,.4,1.1]:
			for seal in [.3,.7,1.0]:
				var incoming:=Vector3(1,-1,7 if side==0 else -7)
				var soft: Dictionary=B.solve(incoming,side,seal,1,edge,Vector3(.2,.6,-.2),true)
				check(soft.velocity.length()<=incoming.length()*.78+.001,"soft block energy bounded")
				check(absf(soft.velocity.y)<4,"tip not driven down at spike speed")
				check(S.block(incoming,side,seal,1,edge,Vector3(.2,.6,-.2),99,0,true)==soft,"stats do not force spike response for tip")
	var m=g.match_management;var id: String=squads[0][0].id
	m.last_attack={"id":id,"side":0};m.last_block={};m.point(1,"FUORI");check(m.stat(id).attack_errors==1,"unblocked attack error counted")
	m.last_attack={"id":id,"side":0};m.last_block={"id":str(squads[1][1].id),"side":1};m.point(1,"PALLA A TERRA");check(m.stat(id).attacks_blocked==1 and m.stat(id).attack_errors==1,"blocked attacks separated from unforced errors")
	m.stat(id).attack_attempts=8;m.stat(id).attack_kills=5;m.stat(id).points=5
	g.report100.capture([25,21]);g.sets=[1,0];g.phase="POINT";g.phase_time=2.2;g.report100._process(0)
	check(g.report100.opened and g.paused,"set summary pauses match")
	check(g.report100.totals(0).attack_kills==5,"set report measured totals")
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution;g.report100.draw_page();await process_frame;await process_frame
		for button in g.report100.UI.controls(g.report100.panel):
			var parent99=button.get_parent();var scrolling99:=false
			while parent99!=null:
				if parent99 is ScrollContainer:scrolling99=true
				parent99=parent99.get_parent()
			if scrolling99:continue
			check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(button.get_global_rect()),"report control within screen "+button.text)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/match100-report-"+str(resolution.x)+".png")
	var shoulder:=InputEventJoypadButton.new();shoulder.button_index=JOY_BUTTON_RIGHT_SHOULDER;shoulder.pressed=true;g.report100._input(shoulder);check(g.report100.side==1,"controller switches roster")
	var accept:=InputEventJoypadButton.new();accept.button_index=JOY_BUTTON_A;accept.pressed=true;g.report100._input(accept);check(not g.paused and g.phase=="SERVE","controller confirms next set")
	m.stat(id).attack_attempts=12;m.stat(id).attack_kills=7;m.stat(id).points=7
	g.report100.capture([25,19]);g.sets=[2,0];g.match_finished=true;g.phase="POINT";g.phase_time=2.2;g.report100._process(0)
	check(g.report100.payload.final and g.report100.history.size()==2,"final report includes both sets")
	check(g.report100.totals(0).attack_kills==7,"match totals not doubled")
	g.report100.selected_set=1;check(g.report100.totals(0).attack_kills==2,"second set is delta not cumulative")
	g.report100.resolve("rematch");check(not g.match_finished and g.sets==[0,0] and m.measured.is_empty(),"offline rematch resets statistics")
	# Triangle trajectories retain their own hand animation while reaching wider corners.
	var Second=preload("res://src/setter_second96.gd")
	for team in 2:
		g.possession=team;g.setter=team*6+5;g.players[g.setter].setting_yaw=-PI/2 if team==0 else PI/2;g.ball_pos=Vector3(0,3.1,.55 if team==0 else -.55)
		for kind in [2,7]:
			g.setter_second96=kind;var shot: Dictionary=Second.trajectory(g)
			check(absf(shot.target.x)>=3.6 and absf(shot.target.z)<3,"triangle lateral finishes wide inside three metres")
			check(Second.crosses_cleanly(g,shot.target,shot.seconds,shot.spin),"corner trajectory clears net")
	FileAccess.open("res://docs/match100-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors},"  "))
	print("MATCH100 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)

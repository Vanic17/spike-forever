extends SceneTree
var game
var age:=0.0
var done:=false
var frames: Array[float]=[]
var last_draw:=0
var maximum_memory:=0
var completed: Dictionary={}
var previous_score:=""
var maximum_attacks:=false
func _initialize():call_deferred("run")
func run():
	maximum_attacks="--maximum-attacks" in OS.get_cmdline_user_args()
	assert(ProjectSettings.globalize_path("user://").contains("graphics89"))
	root.mode=Window.MODE_WINDOWED;root.position=Vector2i(19000,19000);root.size=Vector2i(1920,1080);root.content_scale_size=root.size
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.queue_free()
	game.preferences.data.merge(game.preferences.PRESETS[2],true);game.preferences.apply(game.preferences.data,false)
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game.match_audio.enabled=false;game.replay.enabled=false
	var db=load("res://src/league.gd").new();var kits=load("res://src/club_kits.gd");var clubs: Array=[];var squads: Array=[]
	for id in ["acqua-santanna-cuneo","cucine-lube-civitanova"]:
		var club: Dictionary=db.teams.filter(func(t):return t.id==id)[0];clubs.append(club);squads.append(db.lineup(club))
	for side in 2:
		game.team_names[side]=clubs[side].name
		for i in 6:game.players[side*6+i].set_roster_identity(squads[side][i],squads[side][6],kits.selection(clubs[side].id,"home" if side==0 else "away"),kits.selection(clubs[side].id,"home" if side==0 else "away",true))
	assert(game.match_management.configure_rosters(clubs,squads,{}, {"fatigue":false,"injuries":false,"auto_subs":false,"seed":85017}))
	game.match_management.match_completed.connect(func(result):completed=result.duplicate(true))
	game.set_home_club(clubs[0].id,0);game.match_best_of=1;game.match_points=15;game.use_player_stats=false;game.scores=[0,0];game.sets=[0,0];game.rotations=[0,0];game.server=0;game.rng.seed=85017
	game.started=true;game.paused=false;game.demo=true;game.reset_rally()
	RenderingServer.frame_post_draw.connect(sample)
	print("GRAPHICS89 STABILITY READY 1 set / 15 points")
func _physics_process(_dt: float) -> bool:
	# An explicit test driver, like the repeatable rendering benchmark. The
	# production demo bot normally stops at 65%, creating very long rallies.
	if game!=null and maximum_attacks and game.phase=="ATTACK":game.armed=true;game.charge=.99;game.input_quality=1;game.charging=false
	return false
func _process(dt: float) -> bool:
	if game==null or done:return false
	age+=dt
	var score: String=str([game.scores,game.sets])
	if score!=previous_score:previous_score=score;print("GRAPHICS89 SCORE ",score," elapsed ",snapped(age,.1))
	if game.match_finished and not completed.is_empty():finish(true)
	elif age>900:finish(false)
	return false
func sample():
	if done:return
	var now:=Time.get_ticks_usec()
	if age>4 and last_draw>0:frames.append(float(now-last_draw)/1000)
	last_draw=now
	maximum_memory=maxi(maximum_memory,int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
func finish(passed: bool):
	done=true;frames.sort();var sum:=0.0;var over25:=0;var over50:=0
	for value in frames:sum+=value;over25+=1 if value>25 else 0;over50+=1 if value>50 else 0
	var report: Dictionary={"pass":passed,"real_seconds":age,"game_seconds":game.clock_time,"sets":game.sets,"result":completed,"points":game.test_points,"contacts":game.test_contacts,"resolution":str(root.size),"preset":"high","frames":frames.size(),"mean_frame_ms":sum/maxi(1,frames.size()),"p99_frame_ms":frames[int(frames.size()*.99)] if not frames.is_empty() else 0,"frames_over_25ms":over25,"frames_over_50ms":over50,"peak_video_memory_bytes":maximum_memory,"replay":"validated separately; disabled for this full-match soak","test_driver":"99% human attacks, normal CPU/serve/receive/set" if maximum_attacks else "original 65% demo attack driver"}
	FileAccess.open("res://docs/stature90-full-match.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAPHICS89 STABILITY ","PASS" if passed else "FAIL",JSON.stringify(report));quit(0 if passed else 1)

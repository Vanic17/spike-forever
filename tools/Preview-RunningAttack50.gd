extends "res://tools/Preview-Approach42.gd"
func setup() -> void:
	super.setup()
	game.camera.position=Vector3(9,7.5,12.5); game.camera.look_at(Vector3(0,1,2.2)); game.camera.fov=53
	var db=load("res://src/league.gd").new(); var kits=load("res://src/club_kits.gd")
	var club: Dictionary=db.teams.filter(func(t): return t.id=="allianz-milano")[0]
	var squad: Array=db.lineup(club)
	for i in 6: game.players[i].set_roster_identity(squad[i],squad[6],kits.selection(club.id,"home"),kits.selection(club.id,"home",true))
func begin(stage: int) -> void:
	var direction: int=[0,2,3][stage]
	var rotation: int=[3,4,2][stage]
	game.rotations=[rotation,rotation]; game.server=1; game.rng.seed=40001; game.shot_serial=0
	game.reset_rally(); game.possession=0; game.set_dir=direction
	for i in 6:
		if game.Tactics.libero(i,rotation,false): game.receiver=i
	game.players[game.receiver].position=game.Tactics.world(0,0,5.5)
	game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[game.receiver].contact_world("receive"); game.phase="RECEIVE"
	game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=.3
	before_contacts=game.test_contacts; game.receive_ball(); game.press_action("alternate" if direction==3 else "action")
	title.text="v50 / "+["Banda #15: cambio di ala, rincorsa e schiacciata","Opposto: stacco fuori dai 3 m, attacco dentro","Pipe veloce: rincorsa e salto in avanzamento"][stage]
func _process(_elapsed: float) -> bool:
	if game==null: return false
	frame+=1
	if frame>=150 and "--crossing-only" in OS.get_cmdline_user_args(): print("RUNNING50 PREVIEW PASS"); quit(); return false
	if frame in [151,301]: begin(int((frame-1)/150))
	for substep in 4:
		if game.phase=="ATTACK": game.armed=true; game.charge=.85; game.input_quality=1
		game.step(1.0/120)
	for p in game.players: p.apply_pose(1.0/30)
	if frame in [30,57,70,180,207,220,330,350,365]:
		var capture:=frame
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/running50-"+str(capture)+".png"),CONNECT_ONE_SHOT)
	if frame>=450: print("RUNNING50 PREVIEW PASS"); quit()
	return false

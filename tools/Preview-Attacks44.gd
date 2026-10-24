extends "res://tools/Preview-Approach42.gd"
func begin(stage: int) -> void:
	var direction: int=[0,2,3,1][stage]
	var rotation: int=[0,4,2,0][stage]
	game.rotations=[rotation,rotation]; game.server=1; game.rng.seed=40001; game.shot_serial=0
	game.reset_rally(); game.possession=0; game.set_dir=direction
	for i in 6:
		if game.Tactics.libero(i,rotation,false): game.receiver=i
	game.players[game.receiver].position=game.Tactics.world(0,0,5.5)
	game.players[5].position=game.Tactics.world(0,1.65,2)
	game.ball_pos=game.players[game.receiver].contact_world("receive"); game.phase="RECEIVE"
	game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=0.3
	before_contacts=game.test_contacts; game.receive_ball()
	game.press_action("alternate" if direction==1 else "action")
	seen_contacts=game.test_contacts
	title.text="v44 / "+["Zona 4: corsa, ultimi passi, salto e ricaduta","Opposto di seconda linea: attacco da dietro","Pipe: rincorsa e salto in avanzamento","Centrale: primo tempo anticipato"][stage]
func _process(_elapsed: float) -> bool:
	if game==null: return false
	frame+=1
	if frame in [151,301,451]: begin(int((frame-1)/150))
	for substep in 4:
		if game.phase=="ATTACK": game.armed=true; game.charge=0.85; game.input_quality=1
		game.step(1.0/120)
	for player in game.players: player.apply_pose(1.0/30)
	if game.test_contacts>seen_contacts:
		print("ATTACKS44 PREVIEW contact frame=",frame," phase=",game.phase," hitter=",game.hitter)
		seen_contacts=game.test_contacts
	if frame in [35,65,190,220,340,370,475,490]:
		var capture:=frame
		RenderingServer.frame_post_draw.connect(func(): root.get_texture().get_image().save_png("res://docs/attacks44-"+str(capture)+".png"),CONNECT_ONE_SHOT)
	if frame>=600: quit()
	return false

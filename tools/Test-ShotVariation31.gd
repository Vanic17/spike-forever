extends SceneTree
const Shots=preload("res://src/shot_variation.gd")
const Net=preload("res://src/net_dynamics.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true; game.demo=false
	for team in 2:
		for index in 7:
			game.reset_rally(); game.possession=team; game.phase="ATTACK" if team==0 else "CPU_ATTACK"; game.hitter=team*6
			game.hitter_action="attack"; game.attack_tip=true; game.armed=true; game.charge=0.1; game.input_quality=1
			var p=game.players[game.hitter]; p.play("idle",1,true); p.animation_time=0
			p.select_variant("attack","attack_tip_"+str(index)); p.position=Vector3(-3,0,1.3 if team==0 else -1.3); p.rotation.y=PI if team==0 else 0.0
			p.prepare_contact("attack",0); game.ball_pos=p.contact_world("attack")
			var before: int=game.test_contacts
			game.attack_ball()
			assert(game.test_contacts==before+1,"Each source drop-shot must make a real hand contact")
			assert(game.incoming_kind=="soft" and game.winner_team==-1)
			assert(game.ball_vel.is_finite())
	# Square/X must change the actual hitter's animation and arm a live shot.
	game.reset_rally(); game.phase="ATTACK"; game.possession=0; game.hitter=0; game.armed=false
	game.ball_pos=Vector3(-3,4,1.3); game.ball_vel=Vector3(0,-1,0); game.flight_spin=Vector3.ZERO
	game.send_test_button(JOY_BUTTON_X)
	game.release_action()
	assert(game.attack_tip and game.armed and game.players[0].variant_names.attack.begins_with("attack_tip_"))
	for direction in [0,1,2]:
		game.server=1; game.reset_rally(); game.possession=0; game.setter=5; game.receiver=4
		game.set_phase("SET"); game.armed=true; game.input_quality=1; game.pass_quality=1; game.out_of_system=1
		game.players[5].position=Vector3(0,0,1.7); game.players[5].setting_yaw=-PI/2; game.players[5].rotation.y=-PI/2
		game.ball_pos=game.players[5].contact_world("set"); game.plan_attack(direction,false)
		game.players[game.planned_hitter].position=Vector3([-3.5,1.4,3.5][direction],0,2.8)
		game.set_ball()
		assert(game.phase=="ATTACK")
		if direction==2:
			while game.flight_left>0.08: game.step(1.0/120)
		game.armed=false; game.press_action("alternate")
		game.charge_start=game.clock_time-game.Timing.ATTACK_CHARGE_SECONDS*0.7; game.release_action()
		var before: int=game.test_contacts
		for frame in 300:
			if game.phase!="ATTACK": break
			game.step(1.0/120)
		print("LIVE TIP direction=",direction," phase=",game.phase," hitter=",game.hitter," position=",game.players[game.hitter].position," target=",game.flight_target," variant=",game.players[game.hitter].variant_names.get("attack")," hand=",game.players[game.hitter].contact_world("attack"))
		assert(game.test_contacts==before+1 and game.phase=="CPU_RECEIVE","A live set must remain reachable after selecting a wrist tip")
	var speeds: Array=[]
	for power in [0.969,0.97]:
		game.server=0; game.reset_rally(); game.rng.seed=234
		var p=game.players[game.server_index(0)]; p.prepare_contact("power",0)
		game.ball_pos=p.contact_world("power"); game.input_quality=1; game.serve_type=1
		game.serve_ball(0,power); speeds.append(game.ball_vel.length())
	assert(absf(speeds[0]-speeds[1])<0.1,"Entering the gold band must not slow the serve")
	var charge_speeds: Array=[]
	for power in [0.4,1.0,1.1]:
		for seed_value in range(100,130):
			game.server=0; game.reset_rally(); game.rng.seed=seed_value
			var p=game.players[game.server_index(0)]; p.prepare_contact("power",0)
			game.ball_pos=p.contact_world("power"); game.input_quality=1; game.serve_type=1
			game.serve_ball(0,power)
			if game.last_serve_fault=="":
				charge_speeds.append(Vector2(game.ball_vel.x,game.ball_vel.z).length()); break
	assert(charge_speeds.size()==3 and charge_speeds[0]<charge_speeds[1]*0.9)
	assert(absf(charge_speeds[2]/charge_speeds[1]-1.1)<0.005,"Overcharge must increase actual horizontal velocity")
	var faults: Dictionary={}
	for attempt in 4:
		game.server=0; game.reset_rally(); game.input_quality=1; game.serve_type=1
		var p=game.players[game.server_index(0)]; p.prepare_contact("power",0); game.ball_pos=p.contact_world("power")
		game.serve_ball(0,1.5); faults[game.last_serve_fault]=true
		var before_net: int=game.net_contacts
		for frame in 500:
			if game.phase=="POINT": break
			game.step(1.0/120)
		assert(game.phase=="POINT")
		if game.last_serve_fault=="NET": assert(game.net_contacts>before_net,"A coded net fault must physically touch the mesh")
		else: assert(game.net_contacts==before_net and absf(game.ball_pos.z)>9.105,"An out fault must clear the net and physically land out")
	assert(faults.has("NET") and faults.has("OUT"))
	var targets: Array=[]
	for attempt in 8:
		game.reset_rally(); game.phase="ATTACK"; game.possession=0; game.hitter=0; game.armed=true; game.input_quality=1; game.charge=0.8; game.aim=Vector2(1,1).normalized()
		var p=game.players[0]; p.position=Vector3(-3.5,0,1.3); p.rotation.y=PI; p.prepare_contact("attack",0); game.ball_pos=p.contact_world("attack")
		game.attack_ball(); targets.append(game.marker.position)
		assert(game.marker.position.x>2.5 and absf(game.marker.position.z)<4.2,"Tight diagonal must stay in the chosen zone")
	assert(targets[0].distance_to(targets[1])>0.02,"Repeated aims must have bounded landing variety")
	game.possession=0; game.receive_offset=0.5; game.rng.seed=1
	var early: Vector3=Shots.pass_target(game,Vector3(0,2,1.5),0.3)
	game.receive_offset=-0.07; game.rng.seed=1
	var late: Vector3=Shots.pass_target(game,Vector3(0,2,1.5),0.3)
	assert(early.z<1.5 and late.z>3.5)
	assert(Shots.reception_label(0.7)=="MOLTO IN ANTICIPO" and Shots.reception_label(-0.08)=="MOLTO IN RITARDO" and Shots.reception_label(0)=="PERFETTA")
	for speed in [10.0,25.0,40.0]:
		var before:=Vector3(3,-2,speed); var after:=Net.response(before,2.0)
		assert(after.z<0 and absf(after.z)<speed*0.2 and after.length()<before.length() and after.y<0,"The mesh absorbs energy instead of reflecting like a wall")
	assert(Net.response(Vector3(0,-1,15),2.46).z>0,"The tape may let a ball roll across")
	game.team_names=["Milano","Trento"]; game.award(1,"TEST")
	assert("Trento" in game.feedback and "EMBER" not in game.feedback)
	print("SHOT31 PASS: 14 source drop-shot contacts / Square-X command / early-late pass depth and feedback / dissipative mesh and tape / selected team announcement")
	quit()

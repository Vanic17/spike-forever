extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	for team in 2:
		for depth in [6.2,8.4]:
			for quick in [false,true]:
				g.rotations=[0,0]; g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4; g.setter=team*6+5
				g.out_of_system=-1; g.pass_quality=.70; g.input_quality=.75; g.armed=true; g.phase="SET" if team==0 else "CPU_SET"
				g.rng.seed=65015; g.plan_attack(0,quick)
				var p=g.players[g.setter]; p.rotation.y=p.setting_yaw
				g.ball_pos=g.Tactics.world(team,1.0,depth); g.ball_pos.y=p.contact_local("receive").y
				p.position=p.stance_for_contact("receive",g.ball_pos); p.blend_left=0; p.prepare_contact("receive",0); p.apply_pose(0)
				var h=g.players[g.planned_hitter]; h.position=g.Tactics.world(team,-2.7,depth-.6); h.velocity=Vector3.ZERO
				var before: int=g.test_contacts; g.set_ball()
				assert(g.phase in ["ATTACK","CPU_ATTACK"] and g.hitter_action=="attack","A high deep recovery remains spikeable by an attacker")
				var apex: float=g.ball_pos.y
				var set_seconds: float=g.flight_left
				for frame in 1800:
					if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+2: break
					if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
					g.step(1.0/120)
					apex=maxf(apex,g.ball_pos.y)
					if frame%4==0:
						for player in g.players: player.apply_pose(1.0/30)
				assert(g.test_contacts>=before+2,"The emergency approach must actually complete its physical spike contact")
				assert(g.incoming_kind in ["spike","soft"])
				rows.append({"team":team,"depth":depth,"quick_request":quick,"set_seconds":set_seconds,"apex":apex,"kind":g.incoming_kind,"contacts":g.test_contacts-before,"power":g.incoming_power})
	FileAccess.open("res://docs/gameplay65-high-recovery.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("HIGH RECOVERY65 PASS 8 deep forearm sets with actual attack contacts, both teams")
	g.free(); quit()

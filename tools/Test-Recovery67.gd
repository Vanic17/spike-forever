extends SceneTree
const Delivery=preload("res://src/recovery_delivery.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true; g.demo=false; g.replay.set_process(false); g.match_audio.enabled=false
	var rows=[]
	for enabled in [false,true]:
		g.use_player_stats=enabled
		for team in 2:
			g.possession=team; g.rotations=[0,0]; g.server=1-team
			assert(Delivery.can_spike(g,team*6,.20,g.Tactics.world(team,1,8.4)+Vector3.UP*1.25),"Low grade is not an automatic free ball")
			assert(not Delivery.can_spike(g,team*6,.15,Vector3(0,1.2,5)))
			assert(not Delivery.can_spike(g,team*6,.8,Vector3(0,.35,5)),"A low emergency ball remains a forearm return")
			assert(not Delivery.can_spike(g,team*6+4,.95,Vector3(0,2,5)),"Libero retains forearm returns")
			for direction in [0,2,3]:
				g.server=1-team; g.reset_rally(); g.possession=team; g.receiver=team*6+4; g.setter=team*6+5; g.out_of_system=-1; g.pass_quality=.20; g.input_quality=.20; g.armed=true; g.phase="SET" if team==0 else "CPU_SET"; g.rng.seed=67015
				g.plan_attack(direction,false)
				var p=g.players[g.setter]; p.rotation.y=p.setting_yaw
				g.ball_pos=g.Tactics.world(team,1.0,7.2); g.ball_pos.y=p.contact_local("receive").y
				p.position=p.stance_for_contact("receive",g.ball_pos); p.blend_left=0; p.prepare_contact("receive",0); p.apply_pose(0)
				var h=g.players[g.planned_hitter]; h.position=g.Tactics.world(team,(-2.7 if direction==0 else 2.7 if direction==2 else 0),6.2); h.velocity=Vector3.ZERO
				var before=g.test_contacts; g.set_ball(); assert(g.hitter_action=="attack")
				for frame in 2000:
					if g.phase in ["POINT","LOOSE"] or g.test_contacts>=before+2: break
					if g.phase=="ATTACK": g.armed=true; g.charge=.83; g.input_quality=1
					g.step(1.0/120)
					if frame%4==0:
						for player in g.players: player.apply_pose(1.0/30)
				assert(g.test_contacts>=before+2 and g.incoming_kind in ["spike","soft"],"Attackable poor forearm set completes its actual third touch")
				rows.append({"stats":enabled,"team":team,"direction":direction,"poor_quality":.2,"kind":g.incoming_kind,"power":g.incoming_power})
			# A high own-net rebound is planned before it falls to bagher height.
			g.reset_rally(); g.possession=team; g.setter=team*6+5; g.touches[team]=2; g.last_touch=team; g.pass_quality=.7; g.phase="SET" if team==0 else "CPU_SET"
			var side=1 if team==0 else -1
			g.ball_pos=Vector3(0,2.3,side*.75); g.ball_vel=Vector3(0,8,side*1.0); g.flight_spin=Vector3.ZERO; g.flight_gravity=g.G; g.airborne=true
			for i in range(team*6,team*6+6): g.players[i].position=Vector3(7+(i%6),0,side*8); g.players[i].velocity=Vector3.ZERO; g.players[i].play("idle",1,true)
			g.players[team*6].position=Vector3(0,0,side*2.5)
			var before=g.test_contacts; var velocity=g.ball_vel
			g.resume_deflection("net"); assert(g.phase in ["ATTACK","CPU_ATTACK"] and g.hitter==team*6 and g.touches[team]==2,"High rebound prefers a reachable spike without adding touches")
			assert(g.ball_vel==velocity,"Planning never replaces the real rebound trajectory")
			for frame in 600:
				if g.phase in ["POINT","LOOSE"] or g.test_contacts>before: break
				if g.phase=="ATTACK": g.armed=true; g.charge=.8; g.input_quality=1
				g.step(1.0/120)
				if frame%4==0:
					for player in g.players: player.apply_pose(1.0/30)
			assert(g.test_contacts==before+1 and g.incoming_kind in ["spike","soft"],"The planned rebound attack really contacts the ball")
	FileAccess.open("res://docs/gameplay67-recovery.json",FileAccess.WRITE).store_string(JSON.stringify({"poor_sets":rows,"high_net_rebound_attacks":4,"real_trajectory_preserved":true,"libero_and_low_saves_remain_bump":true},"  "))
	print("RECOVERY67 PASS 12 poor-set physical attacks / four high net rebound attacks / DB ON and OFF / low and libero bump retained"); g.free(); quit()


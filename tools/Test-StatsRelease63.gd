extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	for enabled in [false,true]:
		g.use_player_stats=enabled
		for float_serve in [false,true]:
			g.clock_time=0; g.server=0; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=63013
			g.press_action("alternate" if float_serve else "action"); g.charge_start=g.clock_time-g.charge_seconds("serve"); g.release_action()
			var before: int=g.test_contacts
			for frame in 700:
				g.step(1.0/120)
				for p in g.players: p.apply_pose(0)
				if g.phase!="SERVE": break
			print("RELEASE63 serve stats=",enabled," float=",float_serve," contacts=",g.test_contacts-before," power=",g.last_power," phase=",g.phase," toss=",g.toss_active)
			assert(g.phase=="CPU_RECEIVE" and g.last_power>.9999 and g.last_power<1.0001)
			assert(g.winner_team==(-1 if enabled else 0),"Perfect serve is not an automatic ace in stats mode")
			rows.append({"stats":enabled,"serve":"float" if float_serve else "jump","winner_flag":g.winner_team,"power":g.last_power})
		for pre_release in [false,true]:
			g.server=1; g.reset_rally(); g.possession=0; g.setter=5; g.receiver=4; g.out_of_system=1; g.pass_quality=1; g.input_quality=1
			g.phase="SET"; g.armed=true; g.setter_dump=false; g.plan_attack(0,false)
			g.attack_buffer_start=g.clock_time-.4; g.attack_buffer_power=.7 if pre_release else -1.0
			g.ball_pos=g.Tactics.world(0,0,1.8); g.ball_pos.y=g.players[g.setter].contact_local("set").y
			var p=g.players[g.setter]; p.rotation.y=p.setting_yaw; p.position=p.stance_for_contact("set",g.ball_pos); p.blend_left=0; p.prepare_contact("set",0)
			g.set_ball(); assert(g.phase=="ATTACK")
			if enabled:
				assert(g.stats_release_clock==g.clock_time and g.stats_release_flight==g.flight_left)
				assert(g.current_charge()==0,"Pre-set hold/release must not accumulate attack power in stats mode")
			else: assert(g.current_charge()>.69)
			rows.append({"stats":enabled,"pre_released":pre_release,"power_at_set_release":g.current_charge(),"flight":g.flight_left})
		g.server=1; g.reset_rally(); g.possession=0; g.setter=5; g.hitter=0; g.out_of_system=1; g.stats_set_grade=2
		g.phase="ATTACK"; g.armed=true; g.charge=1; g.input_quality=1; g.hitter_action="attack"
		g.ball_pos=g.Tactics.world(0,-3.4,1.05); g.ball_pos.y=g.players[0].contact_local("attack").y
		var p=g.players[0]; p.rotation.y=PI; p.position=p.stance_for_contact("attack",g.ball_pos); p.blend_left=0; p.prepare_contact("attack",0); p.apply_pose(0)
		g.attack_ball()
		assert(g.phase=="CPU_RECEIVE" and g.winner_team==(-1 if enabled else 0),"Perfect stats attack remains physically defendable")
		rows.append({"stats":enabled,"attack100_winner_flag":g.winner_team})
	FileAccess.open("res://docs/stats63-release.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("STATS RELEASE63 PASS real jump/float gold / real attack gold / actual set event / held and released buffering")
	g.free(); quit()

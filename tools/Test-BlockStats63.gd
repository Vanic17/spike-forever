extends SceneTree
## Regression: an already commanded real jump survives the phase change;
## then a normal ballistic attack meets that animated body on either side.
func _initialize(): call_deferred("run")
func press_boundary_cases() -> int:
	var contact=load("res://src/block_contact.gd")
	var cases:=0
	for defender in [0,1]:
		var outward: float=-1 if defender==0 else 1
		var incoming:=Vector3(.5,-14,outward*2.8)
		for point in [Vector3(0,2.50,-outward*.2),Vector3(0,3.15,outward*.2)]:
			assert(contact.pressed_velocity(incoming,point,defender)==incoming,"Below-tape and already opposite-side rebounds must not receive a clearance correction")
			cases+=1
		var reversed:=Vector3(.5,-14,-outward*2.8)
		assert(contact.pressed_velocity(reversed,Vector3(0,3.15,-outward*.2),defender)==reversed,"A ball continuing into the blocker's court remains a soft cover, not a forced press")
		cases+=1
		var deep: Vector3=contact.pressed_velocity(Vector3(.5,-30,outward*2.8),Vector3(0,2.621,-outward*2.0),defender)
		assert(deep.is_finite() and absf(deep.z)<=10.5 and deep.y==-30 and deep.x==.5,"A nearly below-tape or deep-side contact must remain bounded and must not gain vertical lift")
		cases+=1
		var point:=Vector3(0,3.15,-outward*.2)
		var pressed: Vector3=contact.pressed_velocity(incoming,point,defender)
		assert(pressed.x==incoming.x and pressed.y==incoming.y and pressed.z*outward>2.8)
		var crossed:=false
		for frame in 60:
			var state: Array=load("res://src/ball_flight.gd").advance(point,pressed,Vector3.ZERO,1.0/240)
			var next: Vector3=state[0]
			if point.z*next.z<=0:
				var fraction:=absf(point.z)/maxf(.000001,absf(next.z-point.z))
				assert(lerpf(point.y,next.y,fraction)>2.535,"A press above the tape must physically clear it under normal gravity")
				crossed=true; break
			point=next; pressed=state[1]
		assert(crossed); cases+=1
	return cases
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false; g.use_player_stats=true
	var rows: Array=[]; var touched:=0; var pressed:=0
	for native in [false,true]:
		g.Avatar.native_animation_enabled=native
		for hz in [60,120]:
			for defender in [0,1]:
				g.rotations=[0,0]; g.server=defender; g.reset_rally(); g.clock_time=10; g.rng.seed=59011
				var attacker: int=1-defender
				g.possession=attacker; g.setter=attacker*6+5; g.hitter=g.Tactics.attacker(attacker,0,0,g.setter)
				g.phase="ATTACK" if attacker==0 else "CPU_ATTACK"; g.hitter_action="attack"; g.attack_serial+=1
				g.destination=0; g.committed_destination=0; g.out_of_system=1; g.test_rallies=3
				g.blocking_team=defender; g.block_count=1; g.block_anchor=0; g.block_helper_x=0
				g.block_time=-100; g.block_quality=1; g.winner_team=-1; g.block_checked=false; g.block_commanded=false
				g.block_rosters.clear(); g.block_orders.clear(); g.block_jumps.clear(); g.manual_wall.reset()
				var index: int=g.manual_wall.line(g)[1] if defender==0 else defender*6+1
				g.block_rosters[defender]=[index]; g.block_orders[defender]=[index]
				for i in range(defender*6,defender*6+6):
					var p=g.players[i]; p.position=g.Tactics.world(defender,(i%6-2.5)*1.5,5.5); p.velocity=Vector3.ZERO
					p.play("ready",1,true); p.blend_left=0; p.reach_weight=0; p.apply_pose(0)
				var p=g.players[index]
				p.position=g.Tactics.world(defender,0,.68); p.rotation.y=PI if defender==0 else 0; p.play("block_ready",1,true)
				g.flight_target=g.Tactics.world(attacker,0,1.05); g.flight_target.y=3.35; g.flight_left=.14
				# Model actual attack coverage instead of leaving non-hitters in
				# their pre-serve front row directly underneath this test's ball.
				for i in range(attacker*6,attacker*6+6):
					var cover=g.players[i]
					cover.position=g.RallyAI.coverage(g,i,attacker); cover.velocity=Vector3.ZERO
					cover.play("ready",1,true); cover.blend_left=0; cover.reach_weight=0; cover.apply_pose(0)
				var spiker=g.players[g.hitter]
				spiker.rotation.y=PI if attacker==0 else 0
				spiker.position=spiker.stance_for_contact("attack",g.flight_target)
				spiker.prepare_contact("attack",0); spiker.apply_pose(0)
				g.attack_run.finish(g,g.hitter)
				if defender==0:
					g.press_action("action"); pressed+=1
					assert(g.block_commanded and index in g.manual_wall.jumped,"The normal X/A command must choose and jump the middle")
				else:
					assert(g.request_block_jump(index,.22)); g.block_time=g.clock_time; g.block_quality=.85
				var jump_key: int=g.block_jumps[index]
				for frame in int(round(.14*hz)):
					g.clock_time+=1.0/hz
					p.tick(1.0/hz,false,false)
				g.ball_pos=g.flight_target; g.last_touch=attacker; g.incoming_kind="spike"; g.incoming_power=.85
				var floor_target: Vector3=g.Tactics.world(defender,0,8.0); floor_target.y=.105
				var seconds: float=g.Reference.attack_seconds(.85,.125,false,false)
				seconds=load("res://src/winning_shot.gd").flight_seconds(g,floor_target,g.Reference.attack_seconds(1.0,.125,false,false))*seconds/g.Reference.attack_seconds(1.0,.125,false,false)
				g.send_to_court(attacker,floor_target,seconds)
				assert(g.block_jumps.get(index,-999)==jump_key,"The spike launch must preserve the already airborne defending jumper")
				assert(g.block_pose_locked(index),"The same attack id must keep the blocker locked after ATTACK -> RECEIVE")
				var start: Vector3=p.position; var event_start: int=g.rally_events.size(); var kind:=""
				for frame in hz:
					if g.block_checked or g.phase=="POINT": break
					g.step(1.0/hz)
					for player in g.players: player.apply_pose(0)
				for event in g.rally_events.slice(event_start):
					if event.kind in ["stuff_block","block_touch","block_tool"]: kind=event.kind
				if not kind.is_empty(): touched+=1
				var hit_position: Vector3=g.ball_pos; var outgoing: Vector3=g.ball_vel
				var root_travel:=start.distance_to(p.position)
				var after_contact: int=g.test_contacts; var after_net: int=g.net_contacts
				var before_score: Array=g.scores.duplicate(); var continuation: Array=[]
				for frame in hz*3:
					if g.phase=="POINT" or g.test_contacts>after_contact: break
					if g.phase=="RECEIVE" and not g.armed and g.flight_left<=1.0/hz: g.press_action("action")
					g.step(1.0/hz)
					for player in g.players: player.apply_pose(0)
				for event in g.rally_events.slice(event_start):
					if event.kind in ["net_rebound","net_tape_over","missed_contact"]: continuation.append(event)
				rows.append({"native":native,"hz":hz,"defender":defender,"jump_key":jump_key,"kind":kind,"root_travel":root_travel,"contact_position":str(hit_position),"outgoing":str(outgoing),"net_contacts":g.net_contacts-after_net,"recovered":g.test_contacts>after_contact,"block_point":g.scores[defender]>before_score[defender],"point_against_block":g.scores[attacker]>before_score[attacker],"phase":g.phase,"final_ball":str(g.ball_pos),"events":continuation})
				assert(not kind.is_empty(),"An aligned real attack must contact the authored block hands on each side and animation backend")
				assert(root_travel<.0001,"An airborne block root must not leave the net before the ball arrives")
				p.animation_time=p.clips.block.recovery_end+.01
				assert(not g.block_pose_locked(index),"Landing must release the pose lock")
				print("BLOCK STATS63 ",rows[-1])
	var hard_points:=0; var hard_net_contacts:=0; var tools:=0
	for row in rows:
		if row.kind=="stuff_block":
			if row.block_point: hard_points+=1
			hard_net_contacts+=row.net_contacts
		else: tools+=1
	var boundary_cases:=press_boundary_cases()
	FileAccess.open("res://docs/stats63-block-flight.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":"Aligned physical block; generated attack flight; actual attack coverage plus landing hitter; human next reception commanded at its deadline","lock_checks":rows.size(),"manual_commands":pressed,"actual_ball_contacts":touched,"hard_block_floor_points":hard_points,"hard_block_net_contacts":hard_net_contacts,"genuine_tools":tools,"press_boundary_cases":boundary_cases,"cases":rows},"  "))
	assert(touched==8,"Normal attacks must meet an aligned real block on both mirrored sides")
	assert(hard_net_contacts==0,"A physically pressed monster must clear the tape")
	assert(hard_points+tools<=8)
	print("BLOCK STATS63 PASS locks=",rows.size()," manual_commands=",pressed," actual_ball_contacts=",touched," hard_floor_points=",hard_points," press_boundary_cases=",boundary_cases)
	g.free(); quit()

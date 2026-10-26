extends SceneTree
## Matched contact samples and actual, mirrored ball-flight/game continuations.
const Flight=preload("res://src/ball_flight.gd")
const Net=preload("res://src/net_dynamics.gd")
const BEFORE=preload("res://docs/baseline-v57/block_response.gd")
const AFTER=preload("res://src/block_response.gd")
const TRIALS:=10000
func _initialize(): call_deferred("run")

func trajectory(origin: Vector3, velocity: Vector3, defender: int, hz: int) -> Dictionary:
	var point:=origin
	var elapsed:=0.0
	var receive_at:=-1.0
	var net_hits:=0
	for frame in hz*8:
		var previous:=point
		var state:=Flight.advance(point,velocity,Vector3.ZERO,1.0/hz)
		point=state[0]; velocity=state[1]; elapsed+=1.0/hz
		if previous.z*point.z<0:
			var fraction:=absf(previous.z)/maxf(.00001,absf(previous.z-point.z))
			var impact:=previous.lerp(point,fraction)
			if impact.y<2.535 and absf(impact.x)<4.65:
				var tape_over:=impact.y>=2.43 and absf(velocity.z)>4
				point=impact
				point.z=-signf(previous.z)*.106 if tape_over else signf(previous.z)*.106
				velocity=Net.response(velocity,impact.y); net_hits+=1
		if receive_at<0 and point.y<=1.2 and velocity.y<0: receive_at=elapsed
		if point.y<=.105:
			var own: bool=point.z*(1 if defender==0 else -1)>0
			var inside:=absf(point.x)<=4.605 and absf(point.z)<=9.105
			return {"own":own,"inside":inside,"floor":point,"seconds":elapsed,"receive_at":receive_at,"own_playable":own and inside and receive_at>=.25,"net_hits":net_hits}
	return {"own":false,"inside":false,"floor":point,"seconds":elapsed,"receive_at":receive_at,"own_playable":false,"net_hits":net_hits}

func tally() -> Dictionary:
	return {"stuff_block":0,"block_tool":0,"block_touch":0,"flight_samples":0,"own_playable_touch":0,"opponent_inside_stuff":0,"outside":0,"details":{}}

func run():
	var rng=RandomNumberGenerator.new(); rng.seed=58101
	var stats: Array=[tally(),tally()]
	var mirror_checks:=0
	var hz_checks:=0
	for trial in TRIALS:
		var incoming:=Vector3(rng.randf_range(-9,9),rng.randf_range(-8,1),rng.randf_range(18,38))
		var strength:=rng.randf_range(.18,1)
		var quality:=rng.randf_range(.60,1)
		var edge:=rng.randf_range(-1.25,1.25)
		var variation:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1))
		for version in 2:
			var solver=BEFORE if version==0 else AFTER
			var response: Dictionary=solver.solve(incoming,0,strength,quality,edge,variation)
			var mirrored: Dictionary=solver.solve(Vector3(-incoming.x,incoming.y,-incoming.z),1,strength,quality,-edge,Vector3(-variation.x,variation.y,variation.z))
			assert(response.velocity.is_finite() and mirrored.velocity.is_finite())
			assert(response.kind==mirrored.kind)
			assert(Vector3(-response.velocity.x,response.velocity.y,-response.velocity.z).distance_to(mirrored.velocity)<.0001,"The two sides must use the same response")
			mirror_checks+=1
			stats[version][response.kind]+=1
			if response.kind=="block_touch":
				var detail: String=response.get("detail","cushion")
				stats[version].details[detail]=stats[version].details.get(detail,0)+1
			# Physical subset is stratified through the same 10,000 contact draws.
			# Three starting widths exercise central and lateral block contacts.
			if trial%20!=0: continue
			var x: float=[-3.0,0.0,3.0][posmod(trial/20,3)]
			for defender in 2:
				var velocity: Vector3=response.velocity if defender==0 else mirrored.velocity
				var origin:=Vector3(x*(1 if defender==0 else -1),3.05,.035 if defender==0 else -.035)
				var a:=trajectory(origin,velocity,defender,60)
				var b:=trajectory(origin,velocity,defender,120)
				assert(a.own==b.own and a.inside==b.inside,"Court outcome must agree at60/120Hz")
				hz_checks+=1
				stats[version].flight_samples+=1
				if response.kind=="block_touch" and b.own_playable: stats[version].own_playable_touch+=1
				if response.kind=="stuff_block" and not b.own and b.inside: stats[version].opponent_inside_stuff+=1
				if not b.inside: stats[version].outside+=1
	print("BLOCK58 MATCHED ",JSON.stringify(stats))
	assert(stats[1].block_tool<stats[0].block_tool and stats[1].block_tool>stats[0].block_tool*.70,"A modest reduction must retain genuine hands out")
	assert(stats[1].stuff_block>stats[0].stuff_block and stats[1].stuff_block<stats[0].stuff_block*1.25,"Increase hard blocks modestly")
	assert(stats[1].own_playable_touch>stats[0].own_playable_touch,"More touches must actually land playable on the blocking side")
	assert(stats[1].opponent_inside_stuff>=stats[0].opponent_inside_stuff)
	var rows:=physical_game_cases()
	var report={"seed":58101,"matched_contacts_per_version":TRIALS,"before":stats[0],"after":stats[1],"mirror_checks":mirror_checks,"flight_hz_checks":hz_checks,"physical_flight_subset":"Every20th contact; two mirrored courts; actual gravity, drag and net response;60/120Hz; starts x=-3,0,3m. Own playable means inside the blocking team's court with at least.25s before receive height.","real_game_cases":rows,"baseline_sha256":FileAccess.get_sha256("res://docs/baseline-v57/block_response.gd"),"current_sha256":FileAccess.get_sha256("res://src/block_response.gd")}
	FileAccess.open("res://docs/block-balance58-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("BLOCK BALANCE58 PASS matched contacts / mirrored fields / physical nets and floors / live own-side digs and hard blocks")
	quit()

func physical_game_cases() -> Array:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	for defender in 2:
		for hz in [60,120]:
			for hard in [false,true]:
				g.server=1-defender; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=58111
				g.test_rallies=3; g.winner_team=-1; g.last_touch=defender; g.block_checked=true; g.block_time=-100
				for i in 12:
					g.players[i].position=g.Tactics.world(int(i/6),-3.8+(i%3)*3.8,7+(i%2)); g.players[i].play("relaxed",1,true); g.players[i].apply_pose(0)
				g.ball_pos=Vector3(0,3.05,.035 if defender==0 else -.035)
				var response: Dictionary=AFTER.solve(Vector3(0,-3,30 if defender==0 else -30),defender,.96 if hard else .54,.96 if hard else .84,0 if hard else .88,Vector3(0,.2,0))
				assert(response.kind==("stuff_block" if hard else "block_touch"))
				g.ball_vel=response.velocity; g.flight_spin=Vector3.ZERO; g.airborne=true
				var count: int=g.test_contacts; var score: int=g.scores[defender]
				g.resume_deflection("block")
				assert(g.possession==(1-defender if hard else defender),"A cushion must be assigned to the actual blocking side")
				if hard:
					# A real stuff reaches the floor before deep coverage can arrive.
					g.armed=true; g.input_quality=.85
				else:
					var p=g.players[g.receiver]
					p.position=p.stance_for_contact("receive",g.flight_target); p.rotation.y=PI if g.receiver<6 else 0
					p.prepare_contact("receive",g.flight_left); p.apply_pose(0)
					g.armed=true; g.input_quality=.85
				for frame in hz*5:
					if g.phase=="POINT" or g.test_contacts>count: break
					g.step(1.0/hz)
					if frame%maxi(1,hz/30)==0:
						for p in g.players: p.apply_pose(1.0/30)
				var point: bool=g.scores[defender]>score
				var touched: bool=g.test_contacts>count
				rows.append({"defender":defender,"hz":hz,"kind":response.kind,"detail":response.get("detail",""),"real_floor_point":point,"actual_defensive_touch":touched,"pass_quality":g.pass_quality if touched else -1,"phase":g.phase})
				assert(point if hard else touched,"Hard and cushioned blocks need real, distinct continuations")
				if not hard: assert(g.pass_quality>0 and g.pass_quality<.999,"A playable cushion must not grant a perfect reception")
	# A playable ball is an opportunity, not a new automatic human contact.
	for hz in [60,120]:
		g.server=1; g.rotations=[0,0]; g.reset_rally(); g.rng.seed=58111
		g.test_rallies=3; g.winner_team=-1; g.last_touch=0; g.block_checked=true; g.block_time=-100
		for i in 12:
			g.players[i].position=g.Tactics.world(int(i/6),-3.8+(i%3)*3.8,7+(i%2)); g.players[i].play("relaxed",1,true); g.players[i].apply_pose(0)
		g.ball_pos=Vector3(0,3.05,.035)
		var response: Dictionary=AFTER.solve(Vector3(0,-3,30),0,.54,.84,.88,Vector3(0,.2,0))
		g.ball_vel=response.velocity; g.flight_spin=Vector3.ZERO; g.airborne=true
		var count: int=g.test_contacts
		g.resume_deflection("block")
		var p=g.players[g.receiver]
		p.position=p.stance_for_contact("receive",g.flight_target); p.rotation.y=PI
		p.prepare_contact("receive",g.flight_left); p.apply_pose(0)
		assert(not g.armed)
		for frame in hz*5:
			if g.phase=="POINT": break
			g.step(1.0/hz)
			if frame%maxi(1,hz/30)==0:
				for player in g.players: player.apply_pose(1.0/30)
		assert(g.test_contacts==count and g.phase=="POINT" and g.scores[1]>0,"No human button must still miss a physically playable cushion")
		rows.append({"defender":0,"hz":hz,"case":"no_human_input","actual_defensive_touch":false,"phase":g.phase})
	g.free()
	return rows

extends SceneTree
## Physical entry into the contact envelope must not weaken a centred palm hit.
const Contact=preload("res://src/block_contact.gd")
const Response=preload("res://src/block_response.gd")
func _initialize(): call_deferred("run")

func first_contact(left: Vector3, right: Vector3, crossing: Vector3, velocity: Vector3, hz: int, phase: float) -> Dictionary:
	var time: float=-.065-phase/hz
	var previous:=crossing+velocity*time
	for step in hz:
		time+=1.0/hz
		var point:=crossing+velocity*time
		var pair:=Geometry3D.get_closest_points_between_segments(previous,point,left,right)
		var gap: float=pair[0].distance_to(pair[1])
		if gap<.20:
			var projected:=Contact.palm_crossing(pair[0],velocity,left,right)
			var half_width:=maxf(.15,absf(right.x-left.x)*.5)
			var center:=(left.x+right.x)*.5
			return {"strength":Contact.alignment(pair[0],velocity,left,right),"old_strength":clampf(1.0-gap/.24,.18,1),"edge":clampf((projected.x-center)/half_width,-1.25,1.25),"old_edge":clampf((pair[0].x-center)/half_width,-1.25,1.25),"hit":pair[0],"gap":gap}
		previous=point
		if time>.07: break
	return {}

func unit_cases() -> Dictionary:
	var count:=0; var old_span:=0.0; var new_span:=0.0; var max_edge_error:=0.0; var old_edge_error:=0.0
	var rows: Array=[]
	for fixture in [{"name":"square","x":0.0,"y":0.0},{"name":"inside","x":.12,"y":.02},{"name":"graze","x":.05,"y":.16},{"name":"edge_inside","x":.22*.909,"y":.12},{"name":"edge_outside","x":.22*.911,"y":.12},{"name":"outer_finger","x":.33,"y":0.0},{"name":"outside","x":.65,"y":0.0}]:
		var strengths: Array[float]=[]; var previous_strengths: Array[float]=[]
		var fixture_kind:="none"
		for team in 2:
			var mirror:=Vector3(1,1,1) if team==0 else Vector3(-1,1,-1)
			var left:=Vector3(-.22,3.08,.035)*mirror
			var right:=Vector3(.22,3.08,.035)*mirror
			var crossing:=Vector3(fixture.x,3.08+float(fixture.y),.035)*mirror
			var velocity:=Vector3(5,-3,30)*mirror
			var expected:=Contact.alignment(crossing,velocity,left,right)
			var expected_edge:=clampf(crossing.x/.22,-1.25,1.25)
			var expected_response: Dictionary=Response.solve(velocity,team,expected,.85,expected_edge,Vector3.ZERO)
			fixture_kind=expected_response.kind
			for hz in [60,120,240]:
				for phase in [0.0,.125,.25,.375,.5,.625,.75,.875]:
					var hit:=first_contact(left,right,crossing,velocity,hz,phase)
					if fixture.name=="outside":
						assert(hit.is_empty(),"An attack away from the real hands must never touch")
						count+=1; continue
					assert(not hit.is_empty(),fixture.name)
					assert(absf(float(hit.strength)-expected)<.0001,"Sealing must depend on palm alignment, not the first sample's forward distance")
					var edge_error:=absf(float(hit.edge)-expected_edge)
					max_edge_error=maxf(max_edge_error,edge_error); old_edge_error=maxf(old_edge_error,absf(float(hit.old_edge)-expected_edge))
					assert(edge_error<.0001,"An oblique ray must keep the same edge at60/120/240Hz")
					var response: Dictionary=Response.solve(velocity,team,hit.strength,.85,hit.edge,Vector3.ZERO)
					assert(response.kind==expected_response.kind,"A fixed path must not switch between playable touch and hands-out as the sample phase changes")
					strengths.append(hit.strength); previous_strengths.append(hit.old_strength)
					count+=1
		if not strengths.is_empty():
			var new_range: float=strengths.max()-strengths.min()
			var old_range: float=previous_strengths.max()-previous_strengths.min()
			new_span=maxf(new_span,new_range); old_span=maxf(old_span,old_range)
			rows.append({"fixture":fixture.name,"strength":strengths[0],"kind":fixture_kind,"range_60_120_240":new_range,"previous_range":old_range})
	assert(old_span>.20,"The fixture must expose the old contact-shell dependence")
	assert(new_span<.0001)
	var histogram={"stuff_block":0,"block_touch":0,"block_tool":0}
	var intermediate:=0
	for iy in 41:
		for ix in 61:
			var point:=Vector3((ix-30)*.012,3.08+(iy-20)*.01,.035)
			var left:=Vector3(-.22,3.08,.035); var right:=Vector3(.22,3.08,.035)
			if point.distance_to(Geometry3D.get_closest_point_to_segment(point,left,right))>=.20: continue
			var strength:=Contact.alignment(point,Vector3(0,-3,30),left,right)
			var edge:=clampf(point.x/.22,-1.25,1.25)
			var solved: Dictionary=Response.solve(Vector3(0,-3,30),0,strength,.85,edge,Vector3.ZERO)
			histogram[solved.kind]+=1
			if strength>.30 and strength<.90: intermediate+=1
	assert(histogram.stuff_block>0 and histogram.block_touch>0 and histogram.block_tool>0,"Keep sealed stuffs, playable touches and genuine outside fingers")
	assert(intermediate>200,"Do not collapse the alignment curve into a binary switch")
	var palm_strength:=Contact.alignment(Vector3(0,3.08,.035),Vector3(0,-3,30),Vector3(-.22,3.08,.035),Vector3(.22,3.08,.035))
	var arm_strength:=Contact.alignment(Vector3(0,3.08,.035),Vector3(0,-3,30),Vector3(-.22,3.08,.035),Vector3(.22,3.08,.035),true)
	assert(arm_strength<palm_strength and is_equal_approx(arm_strength,palm_strength*.80))
	for velocity in [Vector3.ZERO,Vector3(.2,-1,.5),Vector3(0,0,1.01),Vector3(100,-100,100)]:
		var strength:=Contact.alignment(Vector3(.12,3.2,-.12),velocity,Vector3(-.22,3.08,.035),Vector3(.22,3.08,.035))
		assert(is_finite(strength) and strength>=.22 and strength<=.98)
	assert(max_edge_error<.0001 and old_edge_error>.03,"The test must expose the oblique pre-projection edge error")
	return {"phase_checks":count,"rows":rows,"new_max_range":new_span,"previous_max_range":old_span,"edge_max_error":max_edge_error,"previous_edge_max_error":old_edge_error,"contact_grid":histogram,"intermediate_strengths":intermediate}

func game_cases() -> Array:
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	for team in 2:
		for hz in [60,120,240]:
			for fixture in ["square","graze","edge_inside","edge_outside","outside","bad_jump","not_blocking"]:
				g.rotations=[0,0]; g.server=0; g.reset_rally(); g.clock_time=10
				g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.possession=team; g.last_touch=1-team; g.blocking_team=team
				g.block_time=9.75 if fixture!="bad_jump" else 9.99; g.block_quality=.85; g.block_commanded=true; g.winner_team=-1; g.block_count=1
				var index: int=team*6+1
				if team==0: g.manual_wall.jumped.assign([index])
				else: g.block_rosters[team]=[index]
				var p=g.players[index]
				p.position=Vector3(0,0,.68 if team==0 else -.68); p.rotation.y=PI if team==0 else 0
				p.play("block",1,false); p.reach_action="block"; p.reach_weight=1
				p.reach_target=Vector3(p.contact_world("block").x,3.08,.035 if team==0 else -.035)
				p.prepare_contact("block",0)
				var left: Vector3=p.current_hand(true); var right: Vector3=p.current_hand(false)
				var point: Vector3=(left+right)*.5
				if fixture=="graze": point.y+=.16
				if fixture.begins_with("edge_"):
					point.x+=maxf(.15,absf(right.x-left.x)*.5)*(.909 if fixture=="edge_inside" else .911)
					point.y+=.12
				if fixture=="outside": point.x+=2
				if fixture=="not_blocking": p.play("idle",1,true); p.apply_pose(0)
				var velocity:=Vector3(5 if team==0 else -5,-3,30 if team==0 else -30)
				var previous:=point-velocity*.065
				var time:=-.065; var event_start: int=g.rally_events.size()
				g.block_checked=false; g.incoming_kind="spike"; g.flight_spin=Vector3.ZERO
				for frame in hz:
					time+=1.0/hz
					g.ball_pos=point+velocity*time; g.ball_vel=velocity
					g.try_block(previous,1.0/hz)
					if g.block_checked or time>.07: break
					previous=g.ball_pos
				var should_hit: bool=fixture in ["square","graze","edge_inside","edge_outside"]
				assert(g.block_checked==should_hit,"Physical palms, active jump and real path are still required: %s team%s hz%s"%[fixture,team,hz])
				var kind:="none"; var strength:=-1.0
				if should_hit:
					assert(g.last_touch==team)
					for event in g.rally_events.slice(event_start):
						if event.kind in ["stuff_block","block_touch","block_tool"]:
							kind=event.kind; strength=event.strength
					var expected_kind: String="stuff_block" if fixture=="square" else ("block_tool" if fixture=="edge_outside" else "block_touch")
					assert(kind==expected_kind,"Square, grazing and oblique near-edge skeleton hits must retain their responses at everyHz: %s team%s hz%s got%s"%[fixture,team,hz,kind])
				rows.append({"team":team,"hz":hz,"fixture":fixture,"touched":g.block_checked,"kind":kind,"strength":strength})
	g.free()
	return rows

func run():
	var report=unit_cases()
	report.game_cases=game_cases()
	FileAccess.open("res://docs/block-seal59-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("BLOCK SEAL59 PASS phase_checks=",report.phase_checks," live_cases=",report.game_cases.size()," grid=",JSON.stringify(report.contact_grid)," seal_range=",report.new_max_range," old_range=",report.previous_max_range)
	quit()

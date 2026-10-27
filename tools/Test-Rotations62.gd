extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true; g.started=true
	var rows: Array=[]; var checks:=0
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally()
			var label: String=g.Tactics.Layout.label(rotation)
			assert(label=="P"+str(g.Tactics.ZONES[g.Tactics.slot(team*6+5,rotation)]))
			var capture: Dictionary=g.rotation_context.capture(g,g.server)
			assert(capture.legal,"Receiving overlap must remain legal: "+label)
			for i in range(team*6,team*6+6):
				var p: Vector3=g.Tactics.serve_position(i,team,rotation,false)
				assert(p.distance_to(g.Tactics.serve_position((1-team)*6+i%6,1-team,rotation,false)*-1)<.001)
				assert(absf(p.x)<=4.05 and absf(p.z)<=8.05)
				var role: String=g.Tactics.role(i,rotation,false)
				var base: Vector3=g.RallyAI.defensive_base(g,i,team)*(1 if team==0 else -1)
				if role=="L": assert(base.x< -2 and base.z>4)
				if role.begins_with("OH") and not g.Tactics.front(i,rotation): assert(absf(base.x)<.1)
				checks+=1
			var row: Array=g.rally_lanes.line(team)
			if rotation==0:
				g.flight_left=.8
				assert(g.choose_receiver(team,g.players[team*6+2].contact_world("receive"),true)==team*6+2,"P1's short Z4 serve must permit OPP reception")
			var expected: Array=[2,1,0] if rotation==0 else ([3,1,2] if rotation==1 else ([3,4,2] if rotation==2 else ([3,4,5] if rotation==3 else ([0,4,5] if rotation==4 else [0,1,5]))))
			if team==1: expected.reverse()
			assert(row==expected.map(func(i): return team*6+i),"Block pillars must follow the diagram")
			for x in [-3.6,0,3.6]:
				for z in [2.1,5.6,7.4]:
					var point: Vector3=g.Tactics.world(team,x,z)+Vector3.UP*1.15
					g.flight_left=.8; var receiver: int=g.choose_receiver(team,point,true)
					if g.Tactics.ROLES[receiver%6]=="OPP": assert(rotation==0 and x< -2.5 and z<3.3)
			rows.append({"team":team,"rotation":rotation,"label":label,"legal":capture.legal,"wall":row})
	# The supplied whistle must replace, rather than join, the previous bank.
	g.phase="CPU_ATTACK"; g.possession=1; g.destination=3; g.setter=10
	g.flight_target=g.Tactics.world(1,0,2.45)
	var libero_cover: Vector3=g.RallyAI.coverage(g,10,1)
	var setter_cover: Vector3=g.RallyAI.coverage(g,11,1)
	assert(libero_cover.distance_to(setter_cover)>1.12,"Backup L and S must not be assigned the same pipe exit")
	assert(g.match_audio.arena_banks.whistle_real.size()==1)
	assert(g.match_audio.arena_banks.whistle_real[0].get_length()<1.4)
	FileAccess.open("res://docs/rotations62-layouts.json",FileAccess.WRITE).store_string(JSON.stringify({"player_checks":checks,"cases":rows},"  "))
	print("ROTATIONS62 PASS: 12 mirrored layouts, legal grounded feet, P labels, assigned wall pillars, reception exclusions, exact whistle bank; player checks=",checks)
	g.free(); quit()

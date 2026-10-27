extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	for rotation in 6:
		for choice in range(6):
			var wait: float=[0.0,.35,.65][choice%3]
			var quick: bool=choice>=3
			g.clock_time=0; g.rotations=[rotation,rotation]; g.server=1; g.reset_rally(); g.possession=0; g.receiver=4 if rotation in [0,1,5] else 1
			g.rng.seed=40001; g.phase="RECEIVE"; g.phase_time=0; g.incoming_kind="serve"; g.incoming_power=.2; g.armed=true; g.input_quality=1; g.set_dir=0
			for p in g.players: p.blend_left=0; p.apply_pose(0)
			var point: Vector3=g.players[g.receiver].contact_world("receive"); g.select_receive_pose(g.receiver,point); point=g.players[g.receiver].contact_world("receive")
			g.ball_pos=g.Tactics.world(1,0,7)+Vector3.UP*3; g.launch(point,.85); g.armed=true; g.input_quality=1
			var middle: int=g.Tactics.attacker(0,rotation,1,5); var chosen:=false; var start:=-1.0; var previous:=-1.0; var rewinds: Array=[]; var initial: int=g.test_contacts
			for frame in 1000:
				if g.phase in ["LOOSE","POINT"] or g.test_contacts>=initial+3: break
				if g.phase=="SET":
					if start<0: start=g.clock_time
					if not chosen and g.clock_time-start>=wait: chosen=true; g.set_dir=1; g.press_action("alternate" if quick else "action")
				if g.phase=="ATTACK": g.armed=true; g.charge=.85; g.input_quality=1
				g.step(1.0/120)
				var p=g.players[middle]
				if p.clip_name=="attack":
					if previous>=0 and p.animation_time<previous-.025: rewinds.append({"time":g.clock_time,"before":previous,"after":p.animation_time,"phase":g.phase,"left":g.flight_left,"jumped":g.middle_decoy.jumped,"real":g.middle_decoy.real_started})
					previous=p.animation_time
				else: previous=-1
				if frame%4==0:
					for player in g.players: player.apply_pose(1.0/30)
			rows.append({"rotation":rotation,"delay":wait,"quick":quick,"contacts":g.test_contacts-initial,"rewinds":rewinds})
			if not rewinds.is_empty(): print("MIDDLE64 REWIND ",JSON.stringify(rows[-1]))
			assert(rewinds.is_empty() and g.test_contacts==initial+3,"One continuous central jump must complete the physical construction")
	FileAccess.open("res://docs/middle64-clock.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  ")); print("MIDDLE64 CLOCK PASS 36 constructions / X first / Square 7 / early and delayed choices / no rewind"); g.free(); quit()

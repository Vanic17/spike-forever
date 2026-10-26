extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	var rows: Array=[]
	var preserve: bool="--preserve-jumps" in OS.get_cmdline_user_args()
	var report_path:="res://docs/block-geometry59-current.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	for direction in [0,1,2,3]:
		for aim in [Vector2.ZERO,Vector2(-1,-1),Vector2(1,-1),Vector2(0,-1),Vector2(-1,1),Vector2(1,1)]:
			g.rotations=[0,0]; g.server=1; g.reset_rally(); g.clock_time=10; g.rng.seed=59001
			g.possession=0; g.setter=5; g.hitter=g.Tactics.attacker(0,0,direction,5); g.hitter_action="attack"; g.destination=direction; g.committed_destination=direction
			g.set_quality=.9; g.out_of_system=1; g.phase="ATTACK"; g.block_count=2; g.blocking_team=1; g.block_anchor=0
			g.test_rallies=3; g.armed=true; g.charge=.85; g.input_quality=1; g.aim=aim; g.fast_set=false
			var hitter=g.players[g.hitter]
			hitter.select_variant("attack","attack_pin_right" if direction==2 else "attack_pin_left")
			if direction==1: hitter.select_variant("attack","attack_v26_01")
			var point: Vector3=g.RallyAI.attack_contact(g,direction,g.hitter,g.Tactics.world(0,1.5,1.7)); point.y=hitter.contact_local("attack").y
			hitter.position=hitter.stance_for_contact("attack",point); hitter.rotation.y=PI; hitter.velocity=Vector3.ZERO
			g.ball_pos=point; g.flight_target=point; g.flight_left=.32; g.block_anchor=point.x*.88; g.block_time=-100; g.block_checked=false
			g.block_rosters.clear(); g.block_orders.clear(); g.block_jumps.clear()
			var blockers: Array=g.blocking_players(1)
			for i in blockers:
				g.players[i].position=g.blocking_target(i,1); g.players[i].velocity=Vector3.ZERO; g.players[i].rotation.y=0; g.players[i].play("block_ready",1,true)
			# Advance the real AI jump schedule while holding only the impending
			# hitter contact fixed; then execute a normal generated attack.
			for frame in 39:
				g.move_players(1.0/120)
				for p in g.players: p.tick(1.0/120,false,false)
				g.clock_time+=1.0/120; g.flight_left=maxf(0,g.flight_left-1.0/120)
			hitter.position=hitter.stance_for_contact("attack",point); hitter.rotation.y=PI; hitter.velocity=Vector3.ZERO; hitter.prepare_contact("attack",0)
			g.ball_pos=point; g.ball_vel=Vector3.ZERO; g.flight_spin=Vector3.ZERO; g.armed=true; g.charge=.85; g.input_quality=1
			var jumps: Dictionary=g.block_jumps.duplicate()
			g.attack_ball()
			if preserve: g.block_jumps=jumps
			var launch: Vector3=g.ball_pos; var initial_velocity: Vector3=g.ball_vel
			var minimum:=INF; var closest: Dictionary={}; var contact:=""; var initial_events: int=g.rally_events.size()
			for frame in 100:
				if g.phase=="POINT": break
				var old: Vector3=g.ball_pos
				g.step(1.0/120)
				for p in g.players: p.apply_pose(0)
				if absf(old.z)<1.5:
					for i in blockers:
						var p=g.players[i]
						var a: Vector3=p.current_hand(true); var b: Vector3=p.current_hand(false)
						var pair: PackedVector3Array=Geometry3D.get_closest_points_between_segments(old,g.ball_pos,a,b)
						var gap: float=pair[0].distance_to(pair[1])
						if gap<minimum:
							minimum=gap; closest={"ball":str(pair[0]),"hand":str(pair[1]),"root":str(p.position),"clip":p.clip_name,"source_time":p.animation_time,"jump_age":g.clock_time-g.block_time,"player":i}
				if g.block_checked: break
			for event in g.rally_events.slice(initial_events):
				if event.kind in ["block_touch","block_tool","stuff_block","winning_shot_block_break"]: contact=event.kind
			rows.append({"direction":direction,"aim":str(aim),"launch":str(launch),"velocity":str(initial_velocity),"jump_count":g.block_jumps.size(),"minimum_gap":minimum,"contact":contact,"closest":closest})
			print("GEOMETRY59 ",rows[-1])
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify({"preserve_jumps":preserve,"main_sha":FileAccess.get_sha256("res://src/main.gd"),"cases":rows},"  "))
	g.free(); quit()

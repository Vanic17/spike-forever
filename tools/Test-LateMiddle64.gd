extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.demo=false
	for quick in [false,true]:
		g.clock_time=0; g.server=1; g.rotations=[0,0]; g.reset_rally(); g.possession=0; g.setter=5; g.receiver=4; g.out_of_system=1; g.pass_quality=1; g.input_quality=1; g.phase="SET"; g.armed=true; g.setter_dump=false
		g.plan_attack(1,quick); var middle: int=g.planned_hitter; var p=g.players[middle]
		p.position=g.Tactics.world(0,-1.6,1.5); p.rotation.y=PI; p.select_variant("attack",g.MiddleDecoy.PERFORMANCE); p.play("attack",1.15,false)
		p.animation_time=p.clips.attack.contact_time+.15
		var decoy=g.middle_decoy; decoy.index=middle; decoy.team=0; decoy.cue="0:"+str(g.shot_serial); decoy.jumped=true; decoy.real_attack=false; decoy.motion_origin=p.position; decoy.motion_yaw=PI; decoy.source_time=p.animation_time; decoy.source_begin=p.animation_time; decoy.finish_at=.35
		g.flight_left=.1; decoy.update(g); assert(decoy.late_recipient==middle and decoy.jumped)
		g.ball_pos=g.Tactics.world(0,0,1.8); g.ball_pos.y=g.players[5].contact_local("fast_set" if quick else "set").y
		var s=g.players[5]; s.rotation.y=s.setting_yaw; s.position=s.stance_for_contact("fast_set" if quick else "set",g.ball_pos); s.blend_left=0; s.prepare_contact("fast_set" if quick else "set",0)
		var initial: int=g.test_contacts; g.touches=[1,0]; g.set_ball(); assert(g.hitter_action=="receive" and g.phase=="ATTACK")
		var previous: float=p.animation_time
		for frame in 500:
			if g.test_contacts>=initial+2 or g.phase in ["POINT","LOOSE"]: break
			g.armed=true; g.charge=.75; g.input_quality=1; g.step(1.0/120)
			if p.clip_name=="attack":
				assert(p.animation_time>=previous-.001,"Expired fake must continue landing without a new jump"); previous=p.animation_time
			if frame%4==0:
				for player in g.players: player.apply_pose(1.0/30)
		assert(g.test_contacts==initial+2,"A very late central choice must remain recoverable as a grounded third touch")
	print("LATE MIDDLE64 PASS X / Square / expired fake preserved / grounded third touch physically completed"); g.free(); quit()

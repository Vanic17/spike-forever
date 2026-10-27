extends SceneTree
const Delivery=preload("res://src/recovery_delivery.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true; g.replay.set_process(false); g.demo=false
	var arcs: Array=[]; var deliveries: Array=[]
	for team in 2:
		for depth in [1.05,2.65,5.0,7.0]:
			for power in [.60,.95]:
				g.possession=team; g.ball_pos=g.Tactics.world(team,2.8,depth)+Vector3.UP*2.9
				var target: Vector3=g.Tactics.world(1-team,-2.8,3.3)+Vector3.UP*.105
				var result:=Delivery.spike(g,target,g.Reference.attack_seconds(power,0,false,false),power)
				var spin:=Vector3((-1 if team==0 else 1)*20,0,.5)
				var velocity: Vector3=g.BallFlight.velocity_to(g.ball_pos,result.target,result.seconds,spin)
				var height: float=g.ball_pos.y; var crossing:=0.0; var old: Vector3=g.ball_pos; var v:=velocity
				for frame in ceili(result.seconds*120):
					var now: Array=g.BallFlight.advance(old,v,spin,1.0/120)
					height=maxf(height,now[0].y)
					if old.z*now[0].z<=0: crossing=lerpf(old.y,now[0].y,absf(old.z)/maxf(.00001,absf(old.z)+absf(now[0].z)))
					old=now[0]; v=now[1]
				assert(crossing>=2.53,"Hard swing must clear the tape")
				assert(height<g.ball_pos.y+1.2,"No unintended towering hard attack")
				arcs.append({"team":team,"depth":depth,"power":power,"apex":height,"net":crossing,"seconds":result.seconds})
		g.possession=team; g.rotations=[0,0]; g.server=1-team
		var libero: int=team*6+4
		assert(not Delivery.can_spike(g,libero,.9,Vector3(0,2,6)))
		assert(Delivery.can_spike(g,team*6,.65,Vector3(0,2,8.5)))
		assert(not Delivery.can_spike(g,team*6,.15,Vector3(0,2,8.5)))
		g.ball_pos=g.Tactics.world(team,1.0,5.2)+Vector3.UP*1.15
		for sample in 40:
			var result:=Delivery.free_ball(g,team); assert(result.target.z*(1 if team else -1)>0)
			deliveries.append({"team":team,"target":str(result.target),"seconds":result.seconds})
	# A third blocker requires both an actual recovery and enough flight time.
	g.possession=0; g.fast_set=false; g.destination=0; g.set_quality=.7
	g.ball_pos=Vector3(0,2.3,2.5)
	for i in range(6,12): g.players[i].position=Vector3((i-8)*1.0,0,-.4)
	var target:=Vector3(-2.5,2.9,1.05)
	g.out_of_system=1; assert(Delivery.cpu_blockers(g,true,2.5,target)<=2)
	g.out_of_system=0; assert(Delivery.cpu_blockers(g,true,1.1,target)<=2)
	assert(Delivery.cpu_blockers(g,true,2.8,target)==3)
	g.fast_set=true; assert(Delivery.cpu_blockers(g,true,2.8,target)<=2)
	# Independent audio RNG and nonrepeating short/long whistle queues.
	var audio=g.match_audio; audio.update_match_state(true,"SERVE")
	audio.choice_queues.clear()
	var used: Dictionary={}; var rng_before: int=g.rng.state
	for kind in ["serve","point"]:
		for i in 4:
			audio.referee_whistle(kind)
			var key: String=kind+str(audio.whistle.stream.get_instance_id()); assert(not used.has(key)); used[key]=true
	assert(g.rng.state==rng_before)
	FileAccess.open("res://docs/gameplay65-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"hard_arcs":arcs,"free_deliveries":deliveries,"block_policy":true,"whistles_distinct":used.size(),"libero_keeps_forearm":true},"  "))
	print("GAMEPLAY65 PASS 16 physical attack arcs / 80 varied free balls / blocker eligibility / eight whistle variants / performer eligibility")
	g.free(); quit()

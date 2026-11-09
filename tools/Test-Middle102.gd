extends SceneTree
const First=preload("res://src/first_set102.gd")
const Delivery=preload("res://src/middle_delivery102.gd")
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message);push_error("MIDDLE102 "+message)
func _initialize():call_deferred("run")
func prepare(g,serial: int):
	g.possession=0;g.setter=5;g.phase="SET";g.rally_serial=serial;g.shot_serial=serial;g.planned_direction=1;g.planned_fast=false;g.setter_dump=false;g.setter_spike=false;g.setter_disguise=false;g.pass_quality=1;g.out_of_system=1;g.airborne=true;g.flight_gravity=9.81
	var p=g.players[5];p.play("idle",1,true);p.select_variant("set","set");p.setting_yaw=-PI/2;p.position=Vector3(0,0,.7)
	g.ball_pos=Vector3(0,3.8,.7);g.flight_target=Vector3(0,2.53,.7);g.flight_left=.65;g.flight_spin=Vector3.ZERO;g.ball_vel=g.BallFlight.velocity_to(g.ball_pos,g.flight_target,.65,g.flight_spin)
func run():
	assert("middle102" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var samples: Array=[]
	var Motion=preload("res://src/motion_prototypes.gd")
	var baked=load(Motion.LIBRARY_PATH)
	check(baked.get_meta("motion_signature","")==Motion.signature(g.clips),"baked AnimationTree library matches current poses and contact offsets")
	for team in 2:
		g.possession=team;g.hitter=team*6+1;g.destination=1;g.hitter_action="attack";g.attack_tip=false;g.out_of_system=1
		g.ball_pos=Vector3(-.8,2.95,.5 if team==0 else -.5)
		for aim in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2(1,1),Vector2.UP]:
			g.aim=aim;var sign_z: float=-1 if team==0 else 1
			var target:=Vector3(3.8*signf(aim.x),.105,sign_z*(3.3 if aim.y>0 else (8.0 if aim.y<0 else 5.0)))
			var previous:=INF
			for power in [.6,.78,.85,.95,1.0]:
				var ordinary: float=g.Reference.attack_seconds(power,.7,false,false)
				ordinary=preload("res://src/winning_shot.gd").flight_seconds(g,target,ordinary,2.565)
				var result: Dictionary=Delivery.solve(g,target,ordinary,power)
				check(result.target==target,"aim targets preserved")
				check(result.seconds<=previous+.00001,"more charge never slows central attack")
				previous=result.seconds
				if power<.78:check(is_equal_approx(result.seconds,ordinary),"controlled charges unchanged")
				var direction: float=signf(target.z-g.ball_pos.z);var spin:=Vector3(direction*20,aim.x*2,.5)
				var velocity: Vector3=g.BallFlight.velocity_to(g.ball_pos,target,result.seconds,spin)
				var point: Vector3=g.ball_pos;var crossed:=false
				for frame in 240:
					var state: Array=g.BallFlight.advance(point,velocity,spin,1.0/240);velocity=state[1]
					if point.z*state[0].z<=0:
						var hit: Vector3=point.lerp(state[0],absf(point.z)/maxf(.000001,absf(point.z-state[0].z)))
						check(hit.y>2.525,"actual spinning ball clears net");crossed=true;break
					point=state[0]
				check(crossed,"ball reaches opposing court")
				if power==1:samples.append({"team":team,"aim":str(aim),"ordinary_seconds":ordinary,"boosted_seconds":result.seconds})
	# The resting interval is per team and counts completed first tempos only.
	g.first_set_cooldown102=[0,0];g.first_set_contact102=["",""]
	prepare(g,10000);g.players[5].select_variant("set","set_first96");First.contact(g,"set")
	check(g.first_set_cooldown102==[3,0],"successful one hand starts three-play interval")
	for i in 3:
		prepare(g,10001+i);check(not First.choose(g),"next three first tempos cannot use one hand")
		First.contact(g,"set");check(g.first_set_cooldown102[0]==2-i,"interval decreases once per completed first tempo")
		First.contact(g,"set");check(g.first_set_cooldown102[0]==2-i,"duplicate callback does not consume interval")
	prepare(g,10005);g.planned_fast=true;g.first_set_cooldown102[0]=2;First.contact(g,"fast_set");check(g.first_set_cooldown102[0]==2,"7 does not consume first-tempo interval")
	g.first_set_cooldown102=[0,0];g.rng.seed=102421;var selected:=0
	for i in 1000:
		prepare(g,20000+i)
		if First.choose(g):selected+=1
	check(selected>=210 and selected<=290,"25 percent among eligible available first tempos")
	prepare(g,30000);g.pass_quality=.95;check(not First.choose(g),"strictly above 95 percent reception")
	prepare(g,30001);g.planned_fast=true;check(not First.choose(g),"one hand exclusive to first tempo, not 7")
	# Visible arm separation and contact metadata in both handed variants.
	var p=g.players[5]
	for left in [false,true]:
		p.play("idle",1,true);p.left_handed=left;p.rotation.y=p.setting_yaw;p.select_variant("set","set_first96");p.play("set",1,false);p.animation_time=p.clips.set.contact_time;p.blend_left=0;p.reach_weight=0;p.apply_pose(0)
		var hand: Vector3=p.current_hand(left);var free: Vector3=p.current_hand(not left)
		check(hand.y-free.y>.40,"one raised hand and visibly lowered free arm")
		check(hand.distance_to(p.contact_world("set"))<.15,"native one-hand palm/contact alignment")
	FileAccess.open("res://docs/middle102-tests-fallback.json" if "--psa-original" in OS.get_cmdline_user_args() else "res://docs/middle102-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors,"eligible_onehand_per_1000":selected,"power_samples":samples},"  "))
	print("MIDDLE102 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," onehand=",selected," errors=",errors);quit(0 if errors.is_empty() else 1)

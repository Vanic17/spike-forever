extends SceneTree
const Flight=preload("res://src/ball_flight.gd")
const Delivery=preload("res://src/attack_delivery104.gd")
const Ref=preload("res://src/reference_style.gd")
var errors: Array=[]
var checks:=0
func check(ok: bool,message: String):
	checks+=1
	if not ok:errors.append(message)
func _initialize():call_deferred("run")
func run():
	assert("attack105" in OS.get_environment("APPDATA"))
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false);g.self_test=true;g.started=true;g.demo=false;g.match_audio.enabled=false;g.replay.enabled=false
	for p in g.players:p.set_process(false);p.render_at_draw=false
	var p=g.players[0];p.rotation.y=PI
	var samples: Array=[]
	for left in [false,true]:
		p.left_handed=left
		var speeds: Array[float]=[]
		for name in ["attack_pin_left","attack_pin_right","attack_reference78","attack_reference_right78","attack_middle_style80","attack_middle_style_right80"]:
			p.play("idle",1,true);p.select_variant("attack",name)
			g.possession=0;g.hitter_action="attack";g.attack_tip=false;g.incoming_kind="spike";g.out_of_system=1;g.aim=Vector2.DOWN
			g.ball_pos=Vector3(-3.4,p.contact_local("attack").y,.55)
			var target:=Vector3(0,.105,-3.3)
			var a:=Delivery.solve(g,target,.42,.98,false);var b:=Delivery.solve(g,target,.75,.98,false)
			check(is_equal_approx(a.seconds,b.seconds),"same geometry/power is independent of older duration")
			var v:=Flight.velocity_to(g.ball_pos,target,a.seconds,a.spin)
			speeds.append(v.length());check(v.y< -14,"closed attack leaves hand steeply downward")
			check(Delivery.crossing(g.ball_pos,target,a.seconds,a.spin)>2.543-.0001,"strong close hit clears actual net")
			samples.append({"variant":name,"left":left,"speed":v.length(),"vertical":v.y,"seconds":a.seconds})
			var clip=p.clips.attack
			p.play("attack",1,false);p.animation_time=clip.contact_time;p.reach_weight=0;p.blend_left=0;p.pin_reference_load=1;p.apply_pose(0)
			var before: Array=p.last_pose.duplicate();p.pin_reference_load=0;p.apply_pose(0)
			for bone in before.size():check(before[bone].origin.distance_to(p.last_pose[bone].origin)<.0001,"hit pose untouched after approach")
		check(speeds.max()/speeds.min()<1.02,"all six attack performances have consistent power")
	# The winning band cannot rewrite an incoming spike, even if hands reach it.
	for winner in [0,1]:
		g.possession=1-winner;g.receiver=6 if winner==0 else 0;g.winner_team=winner;g.attack_tip=false;g.incoming_kind="spike";g.ball_pos=Vector3(1,1,2);g.ball_vel=Vector3(2,-12,22);g.flight_spin=Vector3(7,0,0)
		var v: Vector3=g.ball_vel;var spin: Vector3=g.flight_spin;var pos: Vector3=g.ball_pos
		g.receive_ball();check(g.ball_vel==v and g.flight_spin==spin and g.ball_pos==pos,"winning spike preserves physical speed at defence")
	check(Ref.serve_seconds(1,true)<.76/1.04,"float faster")
	check(Ref.serve_seconds(1,false)<.60/1.04,"jump serve faster")
	check(absf(Ref.serve_seconds(1,true)/Ref.serve_seconds(1.1,true)-1.1)<.00001,"float overload remains proportional")
	check(absf(Ref.serve_seconds(1,false)/Ref.serve_seconds(1.1,false)-1.1)<.00001,"jump overload remains proportional")
	var serves: Array=[]
	for floating in [true,false]:
		g.ball_pos=Vector3(0,2.68 if floating else 3.18,10.0);g.flight_gravity=9.81;g.aim=Vector2.ZERO
		var target:=Vector3(0,.105,-7.5)
		var old: float=preload("res://src/winning_shot.gd").flight_seconds(g,target,(.76 if floating else .60)/1.04,2.60 if floating else 2.54)
		var delivery:=preload("res://src/serve_delivery105.gd").full(g,target,floating)
		check(delivery.seconds<old,"serve is really faster after net constraint")
		check(Delivery.crossing(g.ball_pos,target,delivery.seconds,delivery.spin)>=2.543-.0001,"serve clears net in real integrator")
		var overloaded_spin: Vector3=preload("res://src/serve_delivery105.gd").charged_spin(g,target,delivery.seconds/1.1,delivery.spin,1.1)
		check(Delivery.crossing(g.ball_pos,target,delivery.seconds/1.1,overloaded_spin)>=2.543-.0001,"legal 110 percent does not automatically hit net")
		serves.append({"float":floating,"old_seconds":old,"seconds":delivery.seconds,"gain":old/delivery.seconds})
	var approach=g.clips.approach105
	var early: Array=p.normalized_pose("source:approach105",0,false)
	var late: Array=p.normalized_pose("source:approach105",approach.duration*.9,false)
	check(early[approach.names.find("RightHand")].origin.distance_to(late[approach.names.find("RightHand")].origin)>.25,"visible relaxed-to-backswing preparation")
	var f:=FileAccess.open("res://docs/attack105-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors,"samples":samples,"serves":serves},"\t"));f.close()
	print("ATTACK105 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)

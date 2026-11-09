extends SceneTree
const Spec=preload("res://src/net_spec94.gd")
const Net=preload("res://src/net_dynamics.gd")
const Motion=preload("res://src/motion_prototypes.gd")
const Flight=preload("res://src/ball_flight.gd")
var checks:=0
func check(value: bool,message: String):
	checks+=1;assert(value,message)
func _initialize():call_deferred("run")
func run():
	check("net-tip94" in OS.get_environment("APPDATA"),"isolated user profile")
	var net=Net.new();root.add_child(net)
	check(absf(net.position.y+net.mesh.size.y*.5-2.42)<.000001,"top of mesh is 242 cm")
	check(absf(net.mesh.size.x/95.0-Spec.DEPTH/10.0)<.000001,"square 10 cm cells")
	var materials=load("res://src/visual_materials85.gd");var saved_detail: int=materials.detail
	materials.detail=0;net.update_detail();check(not net.cords.visible,"low quality removes 3D cords")
	materials.detail=2;net.update_detail();check(net.cords.visible,"high quality enables actual cylindrical cords")
	materials.detail=saved_detail;net.update_detail()
	for speed in [2.0,10.0,25.0,45.0]:
		for vertical in [-10.0,-2.0,0.0,8.0]:
			for height in [1.5,2.0,2.40,2.46,2.50]:
				var v:=Vector3(3,vertical,speed);var q:=Vector3(2,height,0)
				var hit: Vector3=Net.response(v,height,q)
				var reverse: Vector3=Net.response(Vector3(-v.x,v.y,-v.z),height,Vector3(-q.x,q.y,0))
				check(hit.is_finite() and hit.length()<=v.length()+.00001,"net contact absorbs energy")
				check(reverse.is_equal_approx(Vector3(-hit.x,hit.y,-hit.z)),"same net response on both ends")
	check(Spec.crossing(Vector3(0,2.6,.2),Vector3(0,2.6,-.2),Vector3(0,0,-20)).is_empty(),"clean clearance does not collide")
	check(Spec.crossing(Vector3(0,2.47,.2),Vector3(0,2.47,-.2),Vector3(0,0,-20)).over,"sphere clips top tape")
	check(Spec.crossing(Vector3(0,.9,.2),Vector3(0,.9,-.2),Vector3(0,0,-20)).under,"no invisible cloth below net")
	net.impact(Vector3(1,2,0),Vector3(0,-2,25));net.impact(Vector3(-1,1.8,0),Vector3(0,-3,-18))
	check(net.hits[0].z>0 and net.hits[1].z<0,"opposite impacts deform in opposite directions")
	net._process(.25);check(net.hits[0].w>.24,"deformation decays on elapsed time")
	var game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.demo=false;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"):child.set_process(false)
	await process_frame
	check(game.clips.has("attack_wrist94"),"authored tip registered")
	var source=game.clips.attack;var tip=game.clips.attack_wrist94
	check(source.contact_time==tip.contact_time and source.takeoff_time==tip.takeoff_time,"original takeoff/contact event retained")
	for time in [0.0,source.contact_time-.1,source.contact_time,source.contact_time+.12]:
		var a: Array[Transform3D]=Motion.normalized(source,time);var b: Array[Transform3D]=Motion.normalized(tip,time)
		for name in ["Hips","LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:
			var index: int=source.names.find(name)
			if index>=0:check(a[index].is_equal_approx(b[index]),"tip retains lower body "+name)
	var a: Array[Transform3D]=Motion.normalized(source,source.contact_time);var b: Array[Transform3D]=Motion.normalized(tip,tip.contact_time)
	var hand: int=source.names.find("RightHand")
	check(a[hand].origin.distance_to(b[hand].origin)<.00001,"palm contact point unchanged")
	var player=game.players[0]
	for left in [false,true]:
		player.left_handed=left;player.play("attack",1,false);player.blend_left=0;player.animation_time=player.clips.attack.contact_time;player.wrist_tip_variant="";player.apply_pose(0)
		var original_hand: Vector3=player.current_hand(false)
		check(original_hand.y>Spec.TOP,"actual contact pose has hand above net")
		var original_contact: Vector3=player.contact_world("attack");player.wrist_tip_variant="attack_wrist94";player.apply_pose(0)
		check(player.current_hand(false).distance_to(original_hand)<.0001,"visual palm remains aligned at contact")
		check(player.contact_world("attack").distance_to(original_contact)<.0001,"tip hand layer preserves contact for both hands")
		if player.native_animation_enabled:check(player.pose_tree!=null and player.pose_tree.initialized and player.pose_tree.library.has_animation("attack_wrist94"),"new tip uses native AnimationTree")
		else:check(player.pose_tree==null,"PSA fallback retains pose ownership")
	game.reset_rally();game.possession=0;game.input_team=0;game.phase="ATTACK";game.hitter=0;game.hitter_action="attack";game.armed=false;game.charging=false;game.aim=Vector2(0,1);game.flight_left=.22
	player.left_handed=false;player.play("attack",1,false);player.animation_time=maxf(0,player.clips.attack.contact_time-.22)
	var saved_time: float=player.animation_time;var saved_clip: String=player.clip_name
	game.press_action("alternate")
	check(game.attack_tip and player.wrist_tip_variant=="attack_shorttip96","Square / Xbox X activates short tip gesture")
	check(player.clip_name==saved_clip and player.animation_time==saved_time and game.flight_left==.22,"tip input preserves scheduled approach and contact")
	game.charging=false;game.armed=true;game.input_quality=1;game.charge=.8;game.touches=[2,0]
	player.position=Vector3(-2.8,0,1.2);player.rotation.y=PI;player.prepare_contact("attack",0);game.ball_pos=player.contact_world("attack")
	game.attack_ball()
	check(game.incoming_kind=="soft" and game.ball_vel.is_finite() and absf(game.marker.position.z)<2.6,"actual attack launches playable short tip")
	game.players[0].wrist_tip_variant="attack_wrist94"
	var codec=load("res://src/online_state.gd")
	var decoded: Dictionary=codec.decode(codec.encode(codec.capture(game)))
	check(decoded.players[0].wrist_tip_variant=="attack_wrist94","online compact snapshot preserves new gesture")
	check(game.online_session.PROTOCOL!="SF090","reject old numeric animation dictionaries")
	for team in 2:
		for power in [.3,.8,1.0]:
			game.possession=team;game.aim=Vector2(0,1);game.flight_gravity=9.81;game.ball_pos=Vector3(-2.8,3.10,1.1 if team==0 else -1.1)
			var landing:=Vector3(0,.105,-3.3 if team==0 else 3.3)
			var delivery: Dictionary=preload("res://src/tip_delivery94.gd").solve(game,landing,power)
			var v: Vector3=Flight.velocity_to(game.ball_pos,delivery.target,delivery.seconds,Vector3.ZERO)
			var point: Vector3=game.ball_pos;var crossed:=false
			for frame in ceili(delivery.seconds*240):
				var next: Array[Vector3]=Flight.advance(point,v,Vector3.ZERO,1.0/240)
				if point.z*next[0].z<0:
					check(Spec.crossing(point,next[0],next[1]).is_empty(),"charged short tip clears mesh with ball radius")
					crossed=true
				point=next[0];v=next[1]
			check(crossed and absf(delivery.target.z)<2.6,"tip drops behind block")
	var report: Dictionary={"pass":true,"checks":checks,"net_top_m":Spec.TOP,"cell_m":Spec.CELL,"native_tip":player.native_animation_enabled,"contact_clock_unchanged":true,"both_hands":true}
	FileAccess.open("res://docs/net-tip94-validation"+("" if player.native_animation_enabled else "-fallback")+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NET TIP94 PASS ",checks);quit()

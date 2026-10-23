extends SceneTree
## Acceptance criteria for a three-passer shape: legal feet, useful lateral
## separation and a covered central seam. Coordinates are not copied from the
## formation table, so two legal passers stacked at one edge still fail.
const Tactics=preload("res://src/tactics.gd")
const Rotation=preload("res://src/rotation_model.gd")
var checks:=0
var failures: Array[String]=[]
var worst_central_gap:=0.0
var live_serves:=0
var reports: Array=[]

func _initialize() -> void: call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks+=1
	if not condition and not message in failures: failures.append(message)

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.started=true
	game.self_test=true
	game.demo=false
	for native in [false,true]:
		game.Avatar.native_animation_enabled=native
		for rotation in 6:
			for receiving in 2:
				game.rotations=[rotation,rotation]
				game.server=1-receiving
				game.reset_rally()
				var label: String="R"+str(rotation+1)+" team="+str(receiving)+" native="+str(native)
				var passers: Array[Vector3]=[]
				var roles: Array[String]=[]
				var by_zone: Dictionary={}
				for index in range(receiving*6,receiving*6+6):
					var identity:=Rotation.state(index,rotation,false)
					by_zone[identity.rotation_slot]=index
					expect(identity.is_front_row==Rotation.front(index,rotation),label+" row status derives from slot")
					if identity.role.begins_with("OH") or identity.role=="L":
						passers.append(Tactics.serve_position(index,receiving,rotation,false)*(1 if receiving==0 else -1))
						roles.append(identity.role)
				expect(passers.size()==3 and "L" in roles and "OH1" in roles and "OH2" in roles,label+" has three distinct qualified receivers")
				passers.sort_custom(func(a,b): return a.x<b.x)
				expect(passers[0].x<=-1.8 and absf(passers[1].x)<=1.0 and passers[2].x>=1.8,label+" passers must cover left, centre and right lanes")
				for pair in 2:
					expect(passers[pair+1].x-passers[pair].x>=1.7,label+" passers cannot stack on the same sideline")
				var local_gap:=0.0
				for x in [-0.75,0.0,0.75]:
					for depth in [4.5,5.0,5.5]:
						var nearest:=INF
						for point in passers: nearest=minf(nearest,point.distance_to(Vector3(x,0,depth)))
						local_gap=maxf(local_gap,nearest)
				worst_central_gap=maxf(worst_central_gap,local_gap)
				expect(local_gap<=2.3,label+" central reception seam is uncovered: nearest passer "+str(local_gap)+"m away")
				# Evaluate the actual grounded shoes in both visual backends,
				# including the small idle adjustments before serve contact.
				for frame in 25:
					if frame%12==0:
						var snapshot=game.rotation_context.capture(game,game.server)
						expect(snapshot.legal,label+" legal grounded feet before the serve")
					game.phase_time+=1.0/60.0
					game.clock_time+=1.0/60.0
					game.move_players(1.0/60.0)
					for player in game.players: player.tick(1.0/60.0,false,false)
				# The new shape cannot silently assign attacks or blocks to a
				# different identity merely to make a visually convenient row.
				game.possession=receiving
				var designated_setter:=receiving*6+5
				for direction in 4:
					var attacker:=Tactics.attacker_for(game,receiving,direction,designated_setter)
					expect(attacker>=0 and not Tactics.libero(attacker,rotation,false),label+" existing attack eligibility")
					if direction in [0,1]: expect(Tactics.front(attacker,rotation),label+" front-row left/middle attack rights")
				var row: Array[int]=game.rally_lanes.line(receiving)
				expect(row.size()==3,label+" three legal blocking identities")
				for blocker in row: expect(Tactics.front(blocker,rotation),label+" back-row setter cannot become blocker after penetration")
				reports.append({"rotation":rotation+1,"team":receiving,"native":native,"passers":passers,"central_gap_m":local_gap})
	# Exercise real serve_ball(), receiver selection, first flight and hand
	# contact from every rotation, with jump/float and both receiving teams.
	# Correct timing is supplied only for the human's existing receive input.
	game.Avatar.native_animation_enabled=true
	for rotation in 6:
		for serving in 2:
			for floating in [false,true]:
				game.rng.seed=20261023+rotation*100+serving*10+int(floating)
				game.rotations=[rotation,rotation]
				game.server=serving
				game.reset_rally()
				game.input_quality=1.0
				game.aim=Vector2.ZERO
				game.serve_type=0 if floating else 1
				var action: String="float" if floating else "power"
				var server=game.players[game.server_index(serving)]
				server.position+=Basis(Vector3.UP,server.rotation.y)*(server.action_root_motion(action,game.clips[action].contact_time)-server.action_root_motion(action,game.serve_start_time(action)))
				game.ball_pos=server.contact_world(action)
				var before: int=game.test_contacts
				var before_hands: int=game.contact_log.size()
				game.serve_ball(serving,0.55)
				var expected_phase: String="RECEIVE" if serving==1 else "CPU_RECEIVE"
				expect(game.phase==expected_phase,"actual serve R"+str(rotation+1)+" enters receiving flight")
				var role:=Tactics.role(game.receiver,rotation,false)
				expect(role.begins_with("OH") or role=="L","actual serve uses a qualified receiver R"+str(rotation+1)+" role="+role)
				var libero: int=(1-serving)*6+(1 if rotation in [2,3,4] else 4)
				for frame in 240:
					if game.phase!=expected_phase: break
					if serving==1:
						game.armed=true
						game.input_quality=1.0
					game.step(1.0/120.0)
					if rotation in [1,4] and game.receiver!=libero and game.phase==expected_phase:
						expect(absf(game.players[libero].position.x)<1.25,"R2/R5 nonreceiving libero must keep the central seam during serve flight")
				expect(game.phase in ["SET","CPU_SET"] and game.test_contacts==before+1 and game.contact_log.size()==before_hands+2,"actual serve and receive hand contacts R"+str(rotation+1)+" serving="+str(serving)+" float="+str(floating)+" phase="+game.phase)
				live_serves+=1
	FileAccess.open("res://docs/v26-rotation-coverage.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"worst_central_gap_m":worst_central_gap,"actual_serves":live_serves,"cases":reports},"  "))
	for failure in failures: push_error(failure)
	print("ROTATION COVERAGE ","PASS" if failures.is_empty() else "FAIL",": ",checks," checks / 24 grounded-foot layouts / central seam max ",worst_central_gap,"m / ",live_serves," actual jump-float serve/reception sequences / identity and rights preserved")
	game.free()
	quit(0 if failures.is_empty() else 1)

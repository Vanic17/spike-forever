extends SceneTree
const Plans=preload("res://src/bench_reactions.gd")
const Motion=preload("res://src/sideline_animation.gd")
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true;game.match_audio.enabled=false
	await process_frame
	var bench=game.arena_visuals.get_node("TeamBenches")
	# Show all seats for this stress test, independently of the chosen roster size.
	for e in bench.actors:e.actor.visible=true
	var previous={};var combinations={};var families={};var count=0
	var seed=game.rng.state
	for point in 200:
		var entries: Array=bench.actors.filter(func(e):return e.team==0)
		var plan=Plans.plan(entries,0,true,"score-"+str(point),previous)
		var used=[]
		for slot in plan:
			var p: Dictionary=plan[slot]
			assert(not p.family in used,"Duplicate bench reaction in one point")
			if slot!=8:assert(p.family!=previous.get(slot,""),"Repeated gesture by same player on successive points")
			assert(Motion.bank().has_animation(p.clip))
			used.append(p.family);previous[slot]=p.family;families[p.family]=true
			count+=1
		assert(plan.size()>=2 and plan.size()<=5)
		combinations[str(plan.keys())]=true
	assert(families.size()==6 and combinations.size()>50)
	assert(game.rng.state==seed,"Cosmetic planning cannot alter gameplay RNG")
	# Verify the real per-frame dispatcher actually plays every scheduled gesture.
	game.started=true;game.paused=false;bench.identity_poll=-10000
	game.phase="SERVE";game.scores=[0,0];bench._process(.034)
	for point in range(1,5):
		game.phase="POINT";game.server=0;game.scores=[point,0]
		var seen={}
		for step in 65:
			bench._process(1.0/30)
			for entry in bench.actors:
				if entry.team==0 and entry.motion.player.current_animation!=entry.motion.idle:seen[entry.slot]=true
		for slot in bench.reaction_plans[0]:assert(seen.has(slot),"Planned reaction never played")
		assert(seen.size()>=2 and seen.size()<=5)
	# New poses keep the complete original seated lower body, with no foot sliding.
	var rig=game.models.body
	for family in ["sign","point","nod","open","turn"]:
		for suffix in ["l","r"]:
			var name="bench_"+family+"_"+suffix
			var length=Motion.bank().get_animation(name).length
			for step in 15:
				var time=length*step/14.0
				var original=Motion.sample(rig,"bench_idle_"+suffix,time);var gesture=Motion.sample(rig,name,time)
				for bone in ["Hips","LeftUpLeg","RightUpLeg","LeftLeg","RightLeg","LeftFoot","RightFoot"]:
					var i: int=rig.names.find(bone)
					assert(original[i].origin.distance_to(gesture[i].origin)<.0002)
					assert(original[i].basis.get_rotation_quaternion().angle_to(gesture[i].basis.get_rotation_quaternion())<.002)
	# Ensure no floor decal intersects either end line, in any club profile.
	var profiles=preload("res://src/arena_profiles.gd").data().clubs
	for club in profiles:
		game.set_home_club(club)
		for placement in profiles[club].floor:
			var half_x: float=float(placement.height)*.5
			var half_z: float=float(placement.width)*.5
			for end in [-9,9]:
				assert(absf(float(placement.z)-end)>half_z or absf(float(placement.x))-half_x>4.55,"Sponsor obscures end line: "+club)
	var table=game.arena_visuals.get_node("ScorersTableTop")
	assert(is_equal_approx(table.position.y,.80))
	for official in bench.officials:
		var skeleton=official.skeleton
		var neck=skeleton.get_bone_global_pose(skeleton.find_bone("Neck")).origin.y+official.position.y
		assert(neck>table.position.y+.20,"Officials' upper bodies must rise above the desk")
		for hand in ["LeftHand","RightHand"]:assert(skeleton.get_bone_global_pose(skeleton.find_bone(hand)).origin.y>table.position.y+.04,"Hands must rest above the desk")
	FileAccess.open("res://docs/bench71-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"points":200,"unique_families":families.keys(),"different_seat_combinations":combinations.size(),"planned_gestures":count,"lower_body_samples":150,"clear_end_lines":profiles.size(),"table_height":table.position.y,"match_rng_preserved":true},"\t"))
	print("BENCH71 PASS: 200 points / unique simultaneous gestures / varied seats / original lower body / 12 unobstructed courts / visible officials");quit()

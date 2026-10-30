extends Node3D
## Cosmetic bench rigs: no AnimationTree, IK, ball contacts or match authority.
const Avatar=preload("res://src/avatar.gd")
const Crowd=preload("res://src/crowd.gd")
const Sideline=preload("res://src/sideline_pose.gd")
var actors: Array=[]
var officials: Array=[]
var official_motions: Array=[]
var pose_bank: Dictionary={}
var animated_bones: Array[int]=[]
var staff_model
var staff_bank: Dictionary={}
var staff_bones: Array[int]=[]
var game
var elapsed:=0.0
var tick:=0.0
var score_key:=""
var reaction_team:=-1
var reaction_age:=20.0
var scores: Array=[]
var identity_key:=""
var updates:=0
var identity_poll:=0.0
var database
var reaction_plans: Array[Dictionary]=[{},{}]
var previous_reactions: Array[Dictionary]=[{},{}]

func _ready() -> void:
	name="TeamBenches"
	game=get_parent().get_parent()
	# Arena is built before the twelve match players.
	call_deferred("build")

func build() -> void:
	if not game.models.has("body"): return
	database=preload("res://src/league.gd").new()
	staff_model=preload("res://src/psk.gd").new(); staff_model.load_file("res://assets/art/officials46/referee.psk")
	for team in 2:
		for slot in 9:
			var actor:=Avatar.new(); add_child(actor)
			actor.team=team; actor.number=slot%6+1; actor.clips=game.clips
			actor.model_bank={"body":staff_model} if slot==8 else game.models; actor.visual_root=Node3D.new(); actor.add_child(actor.visual_root)
			actor.setup_meshes(); actor.jersey_number.hide()
			var coach:=slot==8
			actor.position=Vector3(-7.42 if not coach else -6.45,0, (1 if team==0 else -1)*(4.65+slot*.72 if not coach else 5.55))
			actor.rotation.y=PI/2
			actor.set_process(false); actor.set_physics_process(false)
			var rig=actor.model_bank.body
			var rest: Array[Transform3D]=[]
			for i in rig.names.size(): rest.append(rest[rig.parents[i]]*rig.rest[i] if i>0 else rig.rest[i])
			var pose: Array[Transform3D]=rest.duplicate()
			if not coach:
				for i in pose.size(): pose[i].origin.y-=.48
			for side in ["Left","Right"]:
				if not coach:
					Crowd.rotate_chain(pose,rig,rig.names.find(side+"UpLeg"),Vector3(0,-.08,1),rig.names.find(side+"Leg"))
					Crowd.rotate_chain(pose,rig,rig.names.find(side+"Leg"),Vector3(0,-1,.04),rig.names.find(side+"Foot"))
				Crowd.rotate_chain(pose,rig,rig.names.find(side+"Arm"),Vector3(-.12 if side=="Right" else .12,-1,.18),rig.names.find(side+"ForeArm"))
				Crowd.rotate_chain(pose,rig,rig.names.find(side+"ForeArm"),Vector3(.12 if side=="Right" else -.12,-.25,1),rig.names.find(side+"Hand"))
			var base: Array[Transform3D]=[]
			for i in pose.size():
				var local: Transform3D=pose[rig.parents[i]].affine_inverse()*pose[i] if i>0 else pose[i]
				base.append(local); actor.skeleton.set_bone_pose(i,local)
			actors.append({"actor":actor,"base":base,"team":team,"slot":slot,"coach":coach})
			if coach:
				dress_staff(actor,Color("426486") if team==0 else Color("68788c"))
	for seated in [true,false]:
		var prefix: String="sit" if seated else "stand"
		for gesture in ["rest","clap","point","talk","highfive"]:
			for open in [0,1]: pose_bank[prefix+gesture+str(open)]=Sideline.pose(game.models.body,seated,gesture,float(open))
	for joint in ["Spine","Head","LeftArm","RightArm","LeftForeArm","RightForeArm","LeftHand","RightHand"]:
		var bone: int=game.models.body.names.find(joint)
		if bone>=0: animated_bones.append(bone)
		var staff_bone: int=staff_model.names.find(joint)
		if staff_bone>=0: staff_bones.append(staff_bone)
	for seated in [true,false]:
		for gesture in ["rest","clap","point","talk"]:
			for open in [0,1]: staff_bank[("sit" if seated else "stand")+gesture+str(open)]=Sideline.pose(staff_model,seated,gesture,float(open))
	for entry in actors:
		var base: Array=staff_bank.standrest0 if entry.coach else pose_bank.sitrest0
		Sideline.apply(entry.actor,base,base,0)
	for slot in 3:
		var official=Avatar.new(); add_child(official); official.team=0; official.number=slot+1; official.clips=game.clips
		official.model_bank={"body":staff_model}; official.visual_root=Node3D.new(); official.add_child(official.visual_root); official.setup_meshes(); official.jersey_number.hide()
		official.set_process(false); official.set_physics_process(false); official.position=Vector3(-8.35,0,(slot-1)*1.22); official.rotation.y=PI/2
		dress_staff(official,Color("849bb3") if slot!=1 else Color("c7d1d8"))
		officials.append(official)
		Sideline.apply(official,staff_bank.sitrest0,staff_bank.sitrest0,0)
	for entry in actors:
		var motion=preload("res://src/sideline_animation.gd").new(); entry.actor.add_child(motion)
		motion.setup(entry.actor,"coach_idle" if entry.coach else ("bench_idle_l" if entry.slot%2==0 else "bench_idle_r"),entry.slot*.67+entry.team*.41)
		entry["motion"]=motion; entry["reacted"]=""; entry["advice_at"]=entry.team*4.7
	for i in officials.size():
		var motion=preload("res://src/sideline_animation.gd").new(); officials[i].add_child(motion)
		motion.setup(officials[i],"official_work",i*.81); official_motions.append(motion)
	sync_identity()

func dress_staff(actor,color: Color) -> void:
	var descriptions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/officials46/materials.json"))
	var mesh=actor.body_parts.body; mesh.material_override=null
	for i in staff_model.material_names.size():
		var key: String=staff_model.material_names[i]; var textures: Dictionary=descriptions.get(key,{})
		var mat=preload("res://src/source_assets.gd").material(textures.get("Diffuse",""),textures.get("Normal",""),color if "Cloth_Referee" in key else Color.WHITE,.8)
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		if "Whistle" in key: mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color=Color(0,0,0,0)
		elif "Eyelashes" in key or "Occlusion" in key: mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; mat.alpha_scissor_threshold=.4
		mesh.set_surface_override_material(i,mat)

func sync_identity() -> void:
	if game.players.size()!=12: return
	if game.substitution_scene!=null and game.substitution_scene.active: return
	var starters: Array=[]
	for p in game.players: starters.append(p.roster_identity.get("id",""))
	var key:=str([game.players[0].kit_identity,game.players[6].kit_identity,game.team_names,starters,game.match_management.current if game.match_management!=null else []])
	if key==identity_key: return
	identity_key=key
	for team in 2:
		var template=game.players[team*6]
		var club: String=template.kit_identity.get("_club_id","")
		var teams: Array=database.teams.filter(func(t): return t.id==club)
		var reserve: Array=[]
		if not teams.is_empty():
			var used: Array=[]
			for p in game.players.slice(team*6,team*6+6):
				used.append(p.roster_identity.get("id","")); used.append(p.libero_identity.get("id",""))
			reserve=teams[0].roster.filter(func(p): return not p.id in used)
		if game.match_management!=null and game.match_management.active: reserve=game.match_management.bench(team).filter(func(p): return str(p.role)!="libero")
		var retained: Dictionary={}; var seats: Array=actors.filter(func(e): return e.team==team and not e.coach)
		for entry in seats:
			var old: String=str(entry.actor.roster_identity.get("id",""))
			if reserve.any(func(p): return str(p.id)==old): retained[old]=true
		var remaining: Array=reserve.filter(func(p): return not retained.has(str(p.id)))
		for entry in seats:
			var old: String=str(entry.actor.roster_identity.get("id",""))
			var person: Dictionary={}
			if retained.has(old): person=reserve.filter(func(p): return str(p.id)==old)[0]
			elif not remaining.is_empty(): person=remaining.pop_front()
			entry.actor.visible=not person.is_empty()
			if not person.is_empty(): entry.actor.set_roster_identity(person,{},template.kit_identity,{})

func _process(dt: float) -> void:
	if actors.is_empty() or not game.started or game.paused: return
	elapsed+=dt; tick+=dt; reaction_age+=dt; identity_poll+=dt
	if tick<1.0/30: return
	var frame_dt:=tick; tick=fmod(tick,1.0/30); updates+=1
	if identity_poll>=1:
		identity_poll=0; sync_identity()
	var key:=str([game.scores,game.sets])
	if key!=score_key:
		if game.phase=="POINT" and not scores.is_empty():
			reaction_team=game.server;reaction_age=0
			for entry in actors:
				if entry.motion.player.current_animation!=entry.motion.idle:entry.motion.play(entry.motion.idle,.25)
			for team in 2:
				reaction_plans[team]=preload("res://src/bench_reactions.gd").plan(actors.filter(func(e):return e.team==team),team,team==reaction_team,key,previous_reactions[team])
				for slot in reaction_plans[team]:previous_reactions[team][slot]=reaction_plans[team][slot].family
		else:reaction_plans=[{},{}]
		score_key=key; scores=game.scores.duplicate()
	for entry in actors:
		var actor=entry.actor
		if not actor.visible: continue
		var plan: Dictionary=reaction_plans[entry.team].get(entry.slot,{})
		var age: float=reaction_age-float(plan.get("delay",100))
		if not plan.is_empty() and age>=0 and age<.6 and entry.reacted!=score_key:
			entry.reacted=score_key
			entry.motion.play(plan.clip,.25,plan.speed)
		elif entry.coach and game.phase in ["SET","CPU_SET","ATTACK","CPU_ATTACK"] and elapsed-entry.advice_at>12 and reaction_age>7:
			entry.advice_at=elapsed; entry.motion.play("coach_point" if int(elapsed/12+entry.team)%2==0 else "coach_nod",.30,1.0)
		entry.motion.advance(frame_dt)
	for motion in official_motions: motion.advance(frame_dt)

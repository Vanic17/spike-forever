extends Node3D
## Cosmetic bench rigs: no AnimationTree, IK, ball contacts or match authority.
const Avatar=preload("res://src/avatar.gd")
const Crowd=preload("res://src/crowd.gd")
var actors: Array=[]
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

func _ready() -> void:
	name="TeamBenches"
	game=get_parent().get_parent()
	# Arena is built before the twelve match players.
	call_deferred("build")

func build() -> void:
	if not game.models.has("body"): return
	database=preload("res://src/league.gd").new()
	for team in 2:
		for slot in 7:
			var actor:=Avatar.new(); add_child(actor)
			actor.team=team; actor.number=slot%6+1; actor.clips=game.clips
			actor.model_bank=game.models; actor.visual_root=Node3D.new(); actor.add_child(actor.visual_root)
			actor.setup_meshes(); actor.jersey_number.hide()
			var coach:=slot==6
			actor.position=Vector3(-7.42 if not coach else -6.45,0, (1 if team==0 else -1)*(4.65+slot*.72 if not coach else 5.55))
			actor.rotation.y=PI/2
			actor.set_process(false); actor.set_physics_process(false)
			var rig=game.models.body
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
				var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("192b40"); mat.roughness=.9
				actor.body_parts.cloth.material_override=mat
	sync_identity()

func sync_identity() -> void:
	if game.players.size()!=12: return
	var starters: Array=[]
	for p in game.players: starters.append(p.roster_identity.get("id",""))
	var key:=str([game.players[0].kit_identity,game.players[6].kit_identity,game.team_names,starters])
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
		for entry in actors:
			if entry.team!=team or entry.coach: continue
			var person: Dictionary=reserve[entry.slot] if entry.slot<reserve.size() else {"name":"","jersey_number":entry.slot+18}
			entry.actor.set_roster_identity(person,{},template.kit_identity,{})

func _process(dt: float) -> void:
	if actors.is_empty() or not game.started or game.paused: return
	elapsed+=dt; tick+=dt; reaction_age+=dt; identity_poll+=dt
	if tick<1.0/20: return
	tick=fmod(tick,1.0/20); updates+=1
	if identity_poll>=1:
		identity_poll=0; sync_identity()
	var key:=str([game.scores,game.sets])
	if key!=score_key:
		if game.phase=="POINT" and not scores.is_empty(): reaction_team=game.server; reaction_age=0
		score_key=key; scores=game.scores.duplicate()
	for entry in actors:
		var actor=entry.actor
		var phase: float=entry.slot*1.73+entry.team*.91
		var age: float=reaction_age-.12-entry.slot*.11
		var cheer: float=sin(clampf(age/3.8,0,1)*PI) if age>0 and age<3.8 and reaction_team==entry.team else 0.0
		var breathe:=sin(elapsed*1.65+phase)*.012
		var nod:=sin(elapsed*.62+phase)*.045
		for joint in ["Spine","Head","LeftArm","RightArm","LeftForeArm","RightForeArm"]:
			var bone: int=actor.skeleton.find_bone(joint)
			if bone<0: continue
			var tilt:=Vector3.ZERO
			if joint=="Spine": tilt=Vector3(breathe+cheer*.07,0,0)
			elif joint=="Head": tilt=Vector3(nod*.4,nod+clampf(game.ball_pos.z-actor.position.z,-5,5)*.018,0)
			elif joint.ends_with("ForeArm"): tilt=Vector3(cheer*(.18+sin(elapsed*9+phase)*.10),0,0)
			else: tilt=Vector3(-cheer*.65,0,cheer*(.32 if joint.begins_with("Left") else -.32))
			if entry.coach and joint=="RightArm": tilt.x-=maxf(0,sin(elapsed*.8+phase))*.22
			actor.skeleton.set_bone_pose_rotation(bone,entry.base[bone].basis.get_rotation_quaternion()*Quaternion.from_euler(tilt))

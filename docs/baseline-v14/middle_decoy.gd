extends RefCounted
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
const GOOD_PASS:=0.75
var index:=-1
var team:=-1
var cue:=""
var target:=Vector3.ZERO
var jump_at:=0.0
var finish_at:=0.0
var jumped:=false
var source_time:=0.0
var motion_origin:=Vector3.ZERO
var motion_yaw:=0.0
var events: Array[Dictionary]=[]

func reset() -> void:
	index=-1
	team=-1
	cue=""
	jumped=false

func update(game) -> void:
	if game.phase in ["SET","CPU_SET"]:
		var next: String=str(game.possession)+":"+str(game.shot_serial)
		if next!=cue:
			reset()
			cue=next
	if jumped:
		if game.clock_time>=finish_at:
			index=-1
		return
	if game.phase not in ["SET","CPU_SET"]: return
	if game.pass_quality<GOOD_PASS or game.out_of_system<0 or game.planned_hitter<0:
		index=-1
		return
	team=game.possession
	var middle:=Tactics.attacker(team,game.rotations[team],1,game.setter)
	if middle<0 or middle==game.planned_hitter:
		index=-1
		return
	index=middle
	var point:=AI.attack_contact(game,1,middle,game.flight_target)
	point.y=game.contact_height("attack")
	target=game.players[index].stance_for_contact("attack",point)
	if game.clips.has("attack_decoy"):
		var clip=game.clips.attack_decoy
		var direction:=Basis(Vector3.UP,PI if team==0 else 0.0)
		var offset: Vector3=direction*(Vector3(clip.contact_offset.x,0,clip.contact_offset.z)+clip.root_motion(clip.contact_time))
		target=Vector3(point.x-offset.x,0,point.z-offset.z)
	var preparation: float=game.clips.attack_decoy.contact_time/1.15 if game.clips.has("attack_decoy") else 0.45
	jump_at=game.clock_time+game.flight_left+0.08-preparation

func holds(player: int) -> bool:
	return index==player and jumped

func try_jump(game) -> void:
	if index<0 or jumped or game.clock_time<jump_at: return
	if game.phase not in ["SET","CPU_SET","ATTACK","CPU_ATTACK"] or game.possession!=team: return
	if game.planned_hitter==index: index=-1; return
	if game.phase=="SET" and not game.armed and not game.demo: return
	var player=game.players[index]
	if player.position.distance_to(target)>0.30: return
	if player.clip_name=="block" and player.clips.has("block") and not player.looping and player.animation_time<player.clips.block.recovery_end: return
	player.select_variant("attack","attack_decoy")
	player.play("attack",1.15,false)
	player.contact_scheduled=true
	player.reach_weight=0
	player.velocity=Vector3.ZERO
	player.acceleration=Vector3.ZERO
	player.rotation.y=PI if team==0 else 0.0
	motion_yaw=player.rotation.y
	motion_origin=player.position
	source_time=0
	target=player.position
	jumped=true
	finish_at=game.clock_time+((player.clips.attack.recovery_end+0.12)/1.15 if player.clips.has("attack") else 0.9)
	events.append({"player":index,"team":team,"rotation":game.rotations[team],"quality":game.pass_quality,"time":game.clock_time,"apex_at":game.clock_time+(player.clips.attack.contact_time/1.15 if player.clips.has("attack") else 0.45),"shot":game.shot_serial})
	game.log_rally_event("middle_decoy",events[-1])
	if events.size()>512: events.pop_front()

func advance_body(game, dt: float) -> void:
	var player=game.players[index]
	if not player.clips.has("attack"): return
	var clip=player.clips.attack
	source_time=minf(clip.recovery_end+0.12,source_time+dt*1.15)
	var previous: Vector3=player.position
	var destination: Vector3=motion_origin+Basis(Vector3.UP,motion_yaw)*clip.root_motion(source_time)
	destination.z=maxf(0.40,destination.z) if team==0 else minf(-0.40,destination.z)
	player.position+=game.collision_safe_step(index,destination-player.position)
	player.velocity=(player.position-previous)/maxf(0.00001,dt)
	player.acceleration=Vector3.ZERO
	player.rotation.y=motion_yaw
	player.target=player.position
	player.animation_time=source_time
	player.contact_scheduled=true
	game.travel[index]+=player.position.distance_to(previous)

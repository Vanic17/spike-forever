extends RefCounted
var cue:=""
var commits:=false
var used:=false
func route(game,index: int,target: Vector3) -> Vector3:
	if not commits or used or game.network_match() or game.phase not in ["SET","CPU_SET"] or int(index/6)==game.possession or game.middle_decoy.index<0:return target
	if not game.cpu_team(int(index/6)) or cue!=str(game.rally_serial)+":"+str(game.middle_decoy.cue):return target
	if not game.Tactics.role_for(game,index).begins_with("MB") or not game.Tactics.front(index,game.rotations[int(index/6)]):return target
	return Vector3(clampf(game.middle_decoy.target.x,-3.6,3.6),0,.65 if index<6 else -.65)
func update(game):
	# Human online walls are never driven by this offline CPU decision.
	if game.network_match() or game.phase not in ["SET","CPU_SET"]:return
	var defender: int=1-game.possession
	if not game.cpu_team(defender) or game.middle_decoy.index<0:return
	var current: String=str(game.rally_serial)+":"+str(game.middle_decoy.cue)
	if current!=cue:
		cue=current;used=false
		# Read reception quality and the visible middle approach, not the user's
		# chosen destination. A convincing decoy can therefore fool this read.
		commits=game.pass_quality>.62 and game.rng.randf()<lerpf(.10,.22,clampf(game.pass_quality,0,1))
	if used or not commits or game.flight_left>.19:return
	for i in range(defender*6,defender*6+6):
		if not game.Tactics.front(i,game.rotations[defender]) or not game.Tactics.role_for(game,i).begins_with("MB"):continue
		var player=game.players[i]
		if absf(player.position.z)>1.5 or absf(player.position.x-game.middle_decoy.target.x)>1.25:return
		if game.request_block_jump(i,maxf(.12,game.flight_left+.12)):
			game.block_time=game.clock_time;game.block_quality=.78;used=true
			game.log_rally_event("cpu_middle_commit",{"player":i,"middle":game.middle_decoy.index})
		return

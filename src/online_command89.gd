extends RefCounted
## Semantic input envelopes. An old reception/attack can never become a wall jump.
static func capture(g,side: int,button: String,pending_set: Dictionary={}) -> Dictionary:
	var phase: String=g.phase.trim_prefix("CPU_")
	var owner: int=g.server if phase=="SERVE" else g.possession
	var intent:="none"
	if side!=owner:
		if button=="action" and g.human_wall():intent="block"
	elif phase=="SERVE":intent="serve"
	elif phase=="RECEIVE" and button=="action":intent="receive"
	elif phase=="SET":
		var predicted: bool=pending_set.get("rally",-1)==g.rally_serial and pending_set.get("shot",-1)==g.shot_serial
		intent="attack" if button=="action" and (g.armed or predicted) else "set"
	elif phase=="ATTACK":intent="attack"
	return {"intent":intent,"rally":g.rally_serial,"shot":g.shot_serial,"attack":g.wall_attack_id(),"owner":owner,"clock":g.clock_time,"deadline":g.receive_deadline}

static func valid(g,side: int,c: Dictionary) -> bool:
	if c.size()>8 or not c.get("intent") is String:return false
	for key in ["rally","shot","attack","owner"]:
		if not c.get(key) is int:return false
	for key in ["clock","deadline"]:
		if not (c.get(key) is float or c.get(key) is int) or not is_finite(float(c[key])):return false
	if side<0 or side>1 or c.get("rally",-1)!=g.rally_serial:return false
	var at: float=float(c.get("clock",-1000))
	if not is_finite(at) or at>g.clock_time+.035 or g.clock_time-at>.60:return false
	var phase: String=g.phase.trim_prefix("CPU_")
	var owner: int=g.server if phase=="SERVE" else g.possession
	if c.get("owner",-1)!=owner:return false
	match str(c.get("intent","none")):
		"serve":return phase=="SERVE" and side==g.server
		"receive":return phase=="RECEIVE" and side==g.possession and c.get("shot",-1)==g.shot_serial and absf(float(c.get("deadline",-1000))-g.receive_deadline)<.003 and not g.armed
		"set":return phase=="SET" and side==g.possession and c.get("shot",-1)==g.shot_serial and not g.armed
		"attack":return phase in ["SET","ATTACK"] and side==g.possession and c.get("attack",-1)==g.wall_attack_id() and (phase!="SET" or g.armed)
		"block":return side==g.wall_team() and g.human_wall() and c.get("attack",-1)==g.wall_attack_id()
	return false

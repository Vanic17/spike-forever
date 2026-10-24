extends SceneTree
var label:="after"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label=arg.trim_prefix("--label=")
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for rotation in 6:
			g.rotations=[rotation,rotation]; g.server=1-team; g.reset_rally(); g.possession=team
			for i in range(team*6,team*6+6):
				if g.Tactics.libero(i,rotation,false): g.receiver=i
			g.phase="RECEIVE" if team==0 else "CPU_RECEIVE"; g.phase_time=0
			g.incoming_kind="serve"; g.flight_target=g.Tactics.world(team,0,6)+Vector3.UP*1.3
			g.ball_pos=g.flight_target+Vector3.UP*4; g.airborne=true
			var setter: int=team*6+5; var middle: int=g.Tactics.attacker(team,rotation,1,setter)
			var row: Dictionary={"team":team,"rotation":rotation,"setter_ready":null,"middle_ready":null,"max_speed":0.0}
			for frame in 240:
				g.clock_time+=1.0/120; g.phase_time+=1.0/120; g.flight_left=maxf(0.2,2.0-g.phase_time)
				g.move_players(1.0/120)
				for p in g.players: p.tick(1.0/120,false,false)
				var sd: float=g.players[setter].position.distance_to(g.Tactics.setter_position(team))
				var md: float=g.players[middle].position.distance_to(g.Tactics.world(team,0,1.95))
				if row.setter_ready==null and sd<0.35: row.setter_ready=g.phase_time
				if row.middle_ready==null and md<0.45: row.middle_ready=g.phase_time
				if frame==119: row.setter_gap_1s=sd; row.middle_gap_1s=md
				row.max_speed=maxf(row.max_speed,maxf(g.players[setter].velocity.length(),g.players[middle].velocity.length()))
			rows.append(row)
	FileAccess.open("res://docs/preparation43-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	if label=="after":
		var before: Array=JSON.parse_string(FileAccess.get_file_as_string("res://docs/preparation43-before.json"))
		assert(before.size()==rows.size())
		for field in ["middle_ready","setter_ready"]:
			for i in rows.size():
				if before[i][field]!=null:
					assert(rows[i][field]!=null and rows[i][field]<=before[i][field]+0.025,"Existing reachable preparations must not become slower")
	print("PREPARATION43 PASS label=",label," cases=",rows.size())
	g.free(); quit()

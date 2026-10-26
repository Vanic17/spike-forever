extends SceneTree
const Access=preload("res://src/setter_access.gd")
func _initialize(): call_deferred("run")
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.started=true; g.self_test=true
	var rows: Array=[]
	for team in 2:
		for hz in [60,120]:
			for backup in [false,true]:
				g.server=1-team; g.rotations=[0,0]; g.reset_rally(); g.possession=team; g.receiver=team*6; g.setter=team*6+(4 if backup else 5)
				g.set_phase("SET" if team==0 else "CPU_SET"); g.armed=true; g.pass_quality=.64; g.input_quality=.64; g.out_of_system=0; g.setter_dump=false; g.fast_set=false
				for index in range(team*6,team*6+6):
					var player=g.players[index]; player.position=g.Tactics.world(team,-3.8+(index%2)*7.6,8+(index%3)*1.2); player.velocity=Vector3.ZERO; player.play("idle",1,true); player.blend_left=0
				var p=g.players[g.setter]; p.position=g.Tactics.world(team,3.1,6.8); p.setting_yaw=-PI/2 if team==0 else PI/2; p.rotation.y=p.setting_yaw
				g.plan_attack(0,false)
				var target: Vector3=g.Tactics.world(team,-.56,.68); target.y=p.contact_local("set").y
				g.ball_pos=g.Tactics.world(team,.75,5.3)+Vector3.UP*1.2
				var seconds: float=Access.pass_seconds(g,target,1.24,g.setter,"set")
				assert(seconds>1.5 and seconds<=2.0901,"The finalized long route needs the existing bounded arrival allowance")
				g.launch(target,seconds); g.touches=[0,0]; g.touches[team]=1
				var count: int=g.test_contacts
				for frame in int((seconds+1)*hz):
					if g.phase not in ["SET","CPU_SET"]: break
					g.step(1.0/hz)
					for player in g.players: player.apply_pose(1.0/hz)
				var contact: bool=g.test_contacts==count+1 and g.phase in ["ATTACK","CPU_ATTACK"]
				rows.append({"team":team,"hz":hz,"backup":backup,"seconds":seconds,"contact":contact})
				assert(contact,"A long but reachable second-touch route must complete")
	FileAccess.open("res://docs/long-pass57-report.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("LONG PASS57 PASS 8 finalized S/libero routes / bounded before launch / both sides 60-120Hz")
	g.free(); quit()

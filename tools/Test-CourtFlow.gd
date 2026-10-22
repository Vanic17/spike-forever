extends SceneTree
const Shape=preload("res://src/court_shape.gd")
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
func _initialize() -> void:
	var cases:=0
	for rotation in 6:
		for team in 2:
			var setter:=team*6+5
			var fixture: Dictionary={"phase":"SET" if team==0 else "CPU_SET","phase_time":0.3,"shot_serial":4,"planned_hitter":Tactics.attacker(team,rotation,0,setter),"possession":team,"server":0,"rotations":[rotation,rotation],"incoming_kind":"block","setter":setter,"receiver":team*6+3,"hitter":team*6,"flight_target":Tactics.world(team,0,1.5),"flight_left":0.8,"fast_set":false,"out_of_system":1,"attack_serial":3,"destination":0,"players":[]}
			for i in 12:
				var p:=Tactics.home(i,int(i/6),rotation,int(i/6)==0,false)
				fixture.players.append({"position":p,"target":p})
			fixture.players[team*6].position=Tactics.world(team,0.3,2.0)
			fixture.players[setter].position=Tactics.world(team,1.0,3.5)
			var nominal: Array[Vector3]=[]
			for i in 12: nominal.append(AI.target(fixture,i,int(i/6)))
			nominal[setter]=Tactics.world(team,0,1.5)
			var planner=Shape.new()
			var result:=planner.arrange(fixture,nominal,setter,"set",[])
			assert(result[setter]==nominal[setter],"Court organisation cannot displace a scheduled contact")
			var routes: Dictionary=planner.bypass.duplicate()
			for i in routes:
				fixture.players[i].position+=Vector3(0.03,0,0.01)
			var next:=planner.arrange(fixture,nominal,setter,"set",[])
			for i in routes:
				assert(planner.bypass[i]==routes[i],"The exit route cannot move with the player every tick")
				assert(next[i]==result[i],"A small readjustment must not reverse the bypass target")
			for first in routes:
				for second in routes:
					if first!=second: assert(routes[first].distance_to(routes[second])>=1.05,"Teammates cannot be given the same bypass waypoint")
			fixture.phase="RECEIVE" if team==0 else "CPU_RECEIVE"
			fixture.phase_time=0.3
			fixture.shot_serial+=1
			var receiver:=team*6+3
			for i in 12: nominal[i]=AI.target(fixture,i,int(i/6))
			var preparation:=planner.arrange(fixture,nominal,receiver,"receive",[])
			for i in range(team*6,team*6+6):
				if i==receiver or i==setter or not Tactics.front(i,rotation): continue
				assert(absf(preparation[i].z)>1.9,"Front attackers must already leave the net before the dig becomes a set")
			# The third front-row player covers tips behind the actual wall.
			# A defensive base at the net must not create a third blocking body.
			fixture.phase="ATTACK"
			fixture.shot_serial+=1
			fixture.possession=1-team
			var front: Array=[]
			for i in range(team*6,team*6+6):
				if Tactics.front(i,rotation): front.append(i)
			var wall: Array=[front[0],front[1]]
			for i in 12: nominal[i]=AI.target(fixture,i,int(i/6))
			var defense:=planner.arrange(fixture,nominal,(1-team)*6,"attack",wall)
			assert(absf(defense[front[2]].z)>2.4,"The front-row player outside the chosen wall must drop into tip coverage")
			cases+=1
	print("COURT FLOW PASS: ",cases," rotation/team transitions / committed routes / distinct waypoints / early attack preparation / weak-side tip coverage")
	quit()

extends SceneTree
const Tactics=preload("res://src/tactics.gd")
const AI=preload("res://src/rally_ai.gd")
var checks:=0

func _initialize() -> void:
	for team in 2:
		var side:=1.0 if team==0 else -1.0
		for rotation in 6:
			var by_slot: Array[int]=[]
			by_slot.resize(6)
			for index in range(team*6,team*6+6): by_slot[Tactics.slot(index,rotation)]=index
			for serving in [false,true]:
				for row in [[0,1,2],[5,4,3]]:
					for column in 2:
						var left:=Tactics.serve_position(by_slot[row[column]],team,rotation,serving)
						var right:=Tactics.serve_position(by_slot[row[column+1]],team,rotation,serving)
						# The serving team's server is exempt from on-court order.
						if serving and 3 in [row[column],row[column+1]]: continue
						# Source serving formations already switch after their serve;
						# strict initial overlap constraints apply to our receivers.
						if not serving: expect(left.x*side<right.x*side,"Receiving row order must agree with the actual rotation")
				if not serving:
					for front_slot in 3:
						var front:=Tactics.serve_position(by_slot[front_slot],team,rotation,false)
						var back:=Tactics.serve_position(by_slot[5-front_slot],team,rotation,false)
						expect(absf(back.z)>absf(front.z)+0.15,"The receiving back row must stay behind its corresponding front row")
			var game: Dictionary={"rotations":[rotation,rotation],"server":1-team,"possession":team,"phase":"SET" if team==0 else "CPU_SET","phase_time":0.3,"flight_left":0.9,"flight_target":Tactics.world(team,1.5,0.5)+Vector3(0,2.53,0),"incoming_kind":"serve","fast_set":false,"out_of_system":1,"players":[],"setter":team*6+5,"receiver":team*6,"hitter":-1,"planned_hitter":-1,"destination":0,"attack_serial":1}
			for index in 12: game.players.append({"position":Tactics.serve_position(index,int(index/6),rotation,int(index/6)==game.server)})
			expect(Tactics.first_ball(game),"Receiving the serve must preserve first-ball lanes")
			for direction in 4:
				var hitter:=Tactics.attacker(team,rotation,direction,game.setter,true)
				expect(hitter>=0 and hitter!=game.setter,"A setter cannot become his own first-ball hitter")
				expect(not Tactics.libero(hitter,rotation,false),"The libero cannot be assigned an attack lane")
				var contact:=AI.attack_contact(game,direction,hitter,game.flight_target)
				var opening:=AI.opening(game,hitter,team)
				if direction in [0,2]:
					expect(signf(contact.x*side)==(-1.0 if direction==0 else 1.0),"The selected left/right control must retain its actual court direction")
					expect(signf(opening.x)==signf(contact.x),"Opening and attack contact must use the same pin")
				if not Tactics.front(hitter,rotation): expect(absf(contact.z)>3.0,"Back-row hitters retain legal takeoff lanes")
				if rotation==0 and direction in [0,2]:
					var ready:=Tactics.serve_position(hitter,team,rotation,false)
					expect(absf(ready.x-contact.x)<1.1,"P1 pin hitters must not cross the whole court after reception")
					var expected:=team*6+(2 if direction==0 else 0)
					expect(hitter==expected,"P1: opposite offers zone 4, receiving outside offers zone 2")
			game.incoming_kind="spike"
			expect(not Tactics.first_ball(game),"Transition plays return to the standard specialist lanes")
			var outside:=Tactics.attacker(team,rotation,0,game.setter,false)
			expect(Tactics.ROLES[outside%6].begins_with("OH") and Tactics.front(outside,rotation),"After transition the front outside resumes zone 4")
	print("RECEPTION LANES PASS: ",checks," checks / six rotations / both teams / legal reception row order / P1 first-ball pins / specialist transition lanes / no libero or setter assigned illegally")
	quit()

func expect(condition: bool, message: String) -> void:
	assert(condition,message)
	checks+=1

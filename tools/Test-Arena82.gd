extends SceneTree
var game
var errors: Array[String]=[]
var checks:=0
func check(ok: bool,label: String):
	checks+=1
	if not ok:errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	game=load("res://src/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.self_test=true;game.started=true;game.demo=false;game.match_audio.enabled=false;game.replay.enabled=false
	for p in game.players:p.set_process(false);p.render_at_draw=false
	await process_frame;await process_frame
	var collisions=game.arena_contacts
	check(collisions.shapes.size()>game.arena_visuals.crowd_positions.size(),"Scenery and crowd proxies built")
	check(collisions.resolve(Vector3(0,3,5),Vector3(0,1,4),Vector3(0,-20,-10),.1).is_empty(),"No scenery wall in regulation court")
	var bench=collisions.resolve(Vector3(-5.8,.95,7.5),Vector3(-8.2,.95,7.5),Vector3(-30,0,0),.08)
	check(not bench.is_empty() and bench.velocity.x>0,"Swept ball hits bench body without tunnelling")
	var table=collisions.resolve(Vector3(-6,1.06,-1.2),Vector3(-8.8,1.06,-1.2),Vector3(-35,0,0),.08)
	check(not table.is_empty() and table.velocity.x>0,"Ball interacts with table/monitor")
	var seat: Vector3=game.arena_visuals.crowd_positions[10]
	var crowd=collisions.resolve(seat+Vector3(0,2,0),seat+Vector3(0,.8,0),Vector3(0,-20,0),.06)
	check(not crowd.is_empty(),"Ball interacts with spectators")
	game.phase="LOOSE";game.last_touch=0;game.ball_pos=Vector3(-5.8,.95,7.5);game.ball_vel=Vector3(-30,0,0);game.airborne=true;game.flight_left=100;game.winner_team=-1
	var scores: Array=game.scores.duplicate();game.step(.08)
	check(game.phase=="POINT" and game.scores[1]==scores[1]+1,"External touch ends live rally as out")
	var awarded: Array=game.scores.duplicate();game.step(.10)
	check(game.scores==awarded,"Dead ball scenery bounce cannot score twice")
	var sponsor=game.arena_visuals.sponsors;sponsor.set_process(false)
	var clubs: Array=preload("res://src/arena_profiles.gd").data().clubs.keys()
	for club in clubs:
		game.set_home_club(club,0)
		check(not sponsor.celebrate("ACE",1,game) and sponsor.event_left==0,"Away point never triggers LED "+club)
		for kind in ["ACE","MONSTER BLOCK"]:
			check(sponsor.celebrate(kind,0,game),"Home event "+club+kind)
			var graphic=sponsor.event_views.back().get_child(0)
			check(graphic.club==club and graphic.caption==kind,"Correct home logo/caption "+club)
			var kit: Dictionary=preload("res://src/club_kits.gd").selection(club,"home")
			var expected:=Color(kit.primary_hex_approx)
			if expected.get_luminance()>.8 or expected.v<.26:expected=Color(kit.secondary_hex_approx)
			check(graphic.tint.is_equal_approx(expected),"Exact home palette "+club)
			sponsor._process(.1);var gain_a: float=sponsor.panels[0].get_shader_parameter("event_gain")
			sponsor._process(.12);var gain_b: float=sponsor.panels[0].get_shader_parameter("event_gain")
			check(absf(gain_a-gain_b)>.01,"LED brightness visibly pulses")
			sponsor._process(5)
			check(sponsor.event_left==0 and is_zero_approx(sponsor.panels[0].get_shader_parameter("event_gain")),"Sponsor cycle restored")
		check(sponsor.SOURCES[0].name=="Credem" and sponsor.SOURCES[0].region.size.x==550,"Only Credem wordmark on every court")
	game.set_home_club(clubs[0],0);game.phase="SET";game.setter=5;game.possession=1;game.set_meta("led_block82",{"team":0,"rally":game.rally_serial})
	check(preload("res://src/arena_events82.gd").point_kind(game,0)=="MONSTER BLOCK","Actual monster candidate recognized")
	game.register_touch(6)
	check(preload("res://src/arena_events82.gd").point_kind(game,0)!="MONSTER BLOCK","Recovered block does not create a later false monster event")
	var db=preload("res://src/league.gd").new()
	game.match_management.configure_rosters(db.teams.slice(0,2),[db.lineup(db.teams[0]),db.lineup(db.teams[1])])
	game.match_management.touch(0,"serve")
	check(preload("res://src/arena_events82.gd").point_kind(game,0)=="ACE","Real serve ledger recognizes ace")
	game.match_management.touch(6,"set")
	check(preload("res://src/arena_events82.gd").point_kind(game,0)=="","A rally continuing after a set cannot be an ace")
	FileAccess.open("res://docs/arena82-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"colliders":collisions.shapes.size(),"spatial_cells":collisions.grid.size(),"bench":bench,"table":table,"crowd":crowd,"clubs":clubs.size(),"failures":errors},"  "))
	print("ARENA82 TEST ","PASS" if errors.is_empty() else "FAIL",errors);game.free();quit(0 if errors.is_empty() else 1)

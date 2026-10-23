extends SceneTree

class AudioProbe:
	extends Node
	var events: Array[bool]=[]
	func point_event(home_point: bool) -> void: events.append(home_point)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.set_physics_process(false)
	game.started=true; game.self_test=true; game.demo=false
	game.match_audio.enabled=false
	var probe:=AudioProbe.new(); root.add_child(probe); game.match_audio=probe
	game.scores=[0,0]; game.sets=[0,0]; game.phase="RECEIVE"
	game.feedback="feedback precedente"; game.feedback_left=0
	game.arena_visuals.crowd_excitement=0
	game.award(1,"PALLA A TERRA")
	assert(game.scores==[0,1] and probe.events==[false],"Away point must reach audio as a non-celebrated point")
	assert(game.arena_visuals.crowd_excitement==0,"Home audience must not celebrate an away point")
	assert(game.feedback=="feedback precedente" and game.feedback_left==0,"An ordinary point must not create a team-name notice")
	game.phase="RECEIVE"
	game.award(0,"PALLA A TERRA")
	assert(game.scores==[1,1] and probe.events==[false,true],"Home point enables its own celebration")
	assert(game.arena_visuals.crowd_excitement>0.9,"Home audience reacts to home point")
	game.award(0,"PALLA A TERRA")
	assert(game.scores==[1,1] and probe.events.size()==2,"Repeated POINT cannot replay sound or score")
	assert(game.phase=="POINT" and game.airborne,"Ball and between-rally gameplay continue after scoring")
	print("POINT PRESENTATION39 PASS: real award hooks / home-only crowd / both winner identities / duplicate guard / no team-name popup / dead ball preserved")
	game.free(); probe.free(); quit()

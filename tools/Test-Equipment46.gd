extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.set_physics_process(false); game.started=true; game.self_test=true
	var equipment=game.arena_visuals.get_node("NetEquipment")
	assert(equipment.posts.size()==2)
	assert(is_equal_approx(equipment.posts[0].position.x,-5.2) and is_equal_approx(equipment.posts[1].position.x,5.2))
	assert(equipment.stand.position.x<equipment.posts[0].position.x)
	var official=equipment.official
	game.phase="SERVE"; game.server=0; official._process(0)
	assert(official.player.current_animation=="serve_left")
	var count: int=official.gestures_started
	for i in 30: official._process(1.0/60)
	assert(official.gestures_started==count,"A gesture may not restart every frame")
	game.phase="POINT"; game.server=1; game.scores=[0,1]; official._process(0)
	assert(official.player.current_animation=="point_left")
	game.phase="SERVE"; official._process(0)
	assert(official.player.current_animation=="serve_right")
	game.phase="POINT"; game.sets=[0,1]; official._process(0)
	assert(official.player.current_animation=="end_set")
	for gesture in ["idle","serve_left","serve_right","point_left","point_right","end_set"]:
		assert(official.player.has_animation(gesture))
		var clip=official.player.get_animation(gesture)
		assert(clip.get_track_count()==290)
		assert(clip.track_get_key_count(0)<=160,"Cinematic exports must be resampled offline")
	var menu
	for child in game.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): menu=child
	game.started=false; menu.clubs.match_setup()
	var previews=menu.clubs.find_children("*","PanelContainer",true,false).filter(func(node): return node.get_script()==load("res://src/kit_preview.gd"))
	assert(previews.size()==2)
	var preview=previews[0]
	preview.show_kit("allianz-milano","home"); var home=preview.image.texture
	preview.show_kit("allianz-milano","away"); assert(preview.image.texture!=home)
	preview.show_kit("allianz-milano","home"); assert(preview.image.texture==home,"Preview textures must be cached")
	print("EQUIPMENT46 PASS: 2 posts, left stand, 6 native gestures, correct serving/point side, cached actual-kit previews")
	quit()

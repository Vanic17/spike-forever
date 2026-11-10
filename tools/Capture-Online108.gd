extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert("online108" in OS.get_environment("APPDATA"))
	root.position=Vector2i(19000,19000);root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var g=load("res://src/main.tscn").instantiate();root.add_child(g);g.set_process(false);g.set_physics_process(false)
	g.match_audio.enabled=false
	var net=g.online_session
	net.connections108.remember(preload("res://src/room_code.gd").encode("127.0.0.1",26761,123456),"Partite con Marco")
	net.menu.open()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/online108-menu.png")
	var before: Array=net.menu.host.clubs.match_rosters[0].duplicate(true)
	net.catalog108.capture(net.menu.host.clubs.db);net.catalog_ready108=true;net.catalog_hash108=preload("res://src/online_catalog108.gd").digest(net.catalog108.payload());net.active=true;net.menu.catalog_changed108()
	var value: Dictionary=net.menu.choice();var C=preload("res://src/condition99.gd");net.forms99[0]=C.fresh(108);C.ensure(net.forms99[0],value.roster+value.bench)
	value.condition99=net.forms99[0];net.choices[0]=value;net.menu.pending_formation99=true;net.menu.show_forms99()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/online108-formation.png")
	net.menu.host.clubs.match_rosters[0]=value.roster
	net.menu.finish_formation108(true)
	assert(net.menu.host.clubs.match_rosters[0]==before)
	assert(net.menu.online_roster108.size()==7)
	net.active=false
	print("UI108 PASS formation selection does not mutate local exhibition formation");quit()

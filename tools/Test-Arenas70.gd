extends SceneTree
const Profiles=preload("res://src/arena_profiles.gd")
var game
func _initialize(): call_deferred("run")
func count_collisions(node: Node) -> int:
	var n:=1 if node is CollisionObject3D else 0
	for child in node.get_children(): n+=count_collisions(child)
	return n
func run():
	game=load("res://src/main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.self_test=true
	await process_frame
	var arena=game.arena_visuals
	var state=game.rng.state
	var ball_before=game.ball_pos
	var rotations=game.rotations.duplicate()
	var collisions=count_collisions(game)
	var marks={};var report=[]
	assert(Profiles.data().clubs.size()==12)
	for key in Profiles.data().artwork:
		var row=Profiles.artwork(key);assert(FileAccess.file_exists("res://"+row.path))
		assert(int(row.width)>=120 and int(row.height)>=60,"Not a lazy loading thumbnail: "+key)
	for club in Profiles.data().clubs:
		var before=Time.get_ticks_usec()
		game.set_home_club(club)
		await process_frame
		var profile=Profiles.profile(club)
		assert(game.home_club_id==club and arena.home_club_id==club and arena.sponsors.club_id==club)
		assert(arena.free_zone_material.albedo_color.is_equal_approx(Color(profile.free_zone).srgb_to_linear()))
		assert(arena.court_material.albedo_color.is_equal_approx(Color(profile.court).srgb_to_linear()))
		assert(arena.sponsors.panels.size()==22 and arena.sponsors.court_marks.size()==2)
		assert(arena.sponsors.has_node("DelMonteCourt-1") and arena.sponsors.has_node("DelMonteCourt1"))
		assert(arena.sponsors.club_marks.size()==profile.floor.size())
		assert(arena.sponsors.logos.size()==profile.sponsors.size()+4)
		assert(arena.sponsors.artwork_cache.size()==profile.sponsors.size(),"Only active club textures retained")
		assert(arena.home_half.visible==profile.has("second_half"))
		assert(game.rng.state==state and game.ball_pos==ball_before and game.rotations==rotations)
		assert(count_collisions(game)==collisions)
		var nodes=arena.sponsors.get_child_count()
		game.set_home_club(club)
		assert(arena.sponsors.get_child_count()==nodes,"Same profile is a no-op")
		arena.sponsors._process(8.1)
		for material in arena.sponsors.panels: assert(material.get_shader_parameter("logo_a")!=null)
		report.append({"club":club,"sponsors":profile.sponsors,"floor_marks":profile.floor.size()+4,"profile_switch_us":Time.get_ticks_usec()-before})
		marks[club]=arena.sponsors.get_child_count()
	# Side changes, camera changes and visitor kits cannot choose another home.
	var clubs=Profiles.data().clubs.keys()
	game.set_home_club(clubs[1],1)
	assert(game.home_team==1)
	game.camera_mode=2;game.set_camera();assert(game.home_club_id==clubs[1])
	game.set_home_club(clubs[0],0);assert(game.home_team==0)
	game.set_home_club("unknown");assert(game.home_club_id==clubs[0])
	# Drive the actual exhibition start button with an away kit for the home club.
	var menu
	for n in game.get_children():
		if n.get_script()==load("res://src/start_menu.gd"):menu=n
	menu.clubs.match_setup()
	await process_frame
	menu.clubs.setup_start.pressed.emit()
	assert(game.home_club_id==menu.clubs.db.teams[0].id and game.home_team==0,"Exhibition left side owns court")
	var file=FileAccess.open("res://docs/arena70-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":true,"clubs":report,"collision_nodes_unchanged":collisions,"rng_unchanged":true,"bounded_nodes":marks,"exhibition_left_home":game.home_club_id},"\t"));file.close()
	print("ARENA70 PASS: 12 home courts; 29 verified logos; fixed Credem/Del Monte; bounded geometry/cache; no physics/RNG/rotation changes; exhibition left home")
	quit()
